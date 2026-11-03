open! Core
open! Async

module Function_stats = struct
  type t =
    { name : string
    ; call_count : int
    ; total_time_ns : Int63.t
    ; self_time_ns : Int63.t
    ; min_duration_ns : Int63.t
    ; max_duration_ns : Int63.t
    ; durations_ns : Int63.t list
    }

  let compare_by_self_time a b = Int63.compare b.self_time_ns a.self_time_ns
end

module Collapsed_stack = struct
  type t =
    { frames : string list
    ; time_ns : Int63.t
    }
end

module Result = struct
  type t =
    { function_stats : Function_stats.t list
    ; collapsed_stacks : Collapsed_stack.t list
    ; total_trace_time_ns : Int63.t
    ; event_count : int
    }
end

module Per_function = struct
  type t =
    { mutable call_count : int
    ; mutable total_time_ns : Int63.t
    ; mutable self_time_ns : Int63.t
    ; mutable min_duration_ns : Int63.t
    ; mutable max_duration_ns : Int63.t
    ; mutable durations_ns : Int63.t list
    }

  let create () =
    { call_count = 0
    ; total_time_ns = Int63.zero
    ; self_time_ns = Int63.zero
    ; min_duration_ns = Int63.max_value
    ; max_duration_ns = Int63.zero
    ; durations_ns = []
    }
  ;;

  let record_call t ~duration_ns =
    t.call_count <- t.call_count + 1;
    t.total_time_ns <- Int63.(t.total_time_ns + duration_ns);
    t.durations_ns <- duration_ns :: t.durations_ns;
    if Int63.(duration_ns < t.min_duration_ns) then t.min_duration_ns <- duration_ns;
    if Int63.(duration_ns > t.max_duration_ns) then t.max_duration_ns <- duration_ns
  ;;

  let add_self_time t ~time_ns = t.self_time_ns <- Int63.(t.self_time_ns + time_ns)
end

module Frame = struct
  type t =
    { name : string
    ; enter_time_ns : Int63.t
    }
end

module Thread_state = struct
  type t =
    { stack : Frame.t Stack.t
    ; mutable last_event_time_ns : Int63.t
    }

  let create () = { stack = Stack.create (); last_event_time_ns = Int63.zero }
end

let time_ns_of_span span = Time_ns.Span.to_int63_ns span

let symbol_name (sym : Symbol.t) =
  match sym with
  | From_perf name -> name
  | From_perf_map { function_; _ } -> function_
  | Unknown -> "[unknown]"
  | Untraced -> "[untraced]"
  | Returned -> "[returned]"
  | Syscall -> "[syscall]"
;;

(** Accumulate self-time for the current top-of-stack and update the timestamp. *)
let charge_self_time
  (thread_state : Thread_state.t)
  ~(func_table : Per_function.t String.Table.t)
  ~now_ns
  =
  if Int63.(now_ns > thread_state.last_event_time_ns)
  then (
    let elapsed = Int63.(now_ns - thread_state.last_event_time_ns) in
    (match Stack.top thread_state.stack with
     | None -> ()
     | Some frame ->
       let stats =
         Hashtbl.find_or_add func_table frame.name ~default:Per_function.create
       in
       Per_function.add_self_time stats ~time_ns:elapsed);
    thread_state.last_event_time_ns <- now_ns)
;;

(** Pop a frame, recording its total duration. *)
let pop_frame
  (thread_state : Thread_state.t)
  ~(func_table : Per_function.t String.Table.t)
  ~now_ns
  =
  match Stack.pop thread_state.stack with
  | None -> ()
  | Some frame ->
    let duration_ns =
      if Int63.(now_ns > frame.enter_time_ns)
      then Int63.(now_ns - frame.enter_time_ns)
      else Int63.zero
    in
    let stats = Hashtbl.find_or_add func_table frame.name ~default:Per_function.create in
    Per_function.record_call stats ~duration_ns
;;

(** Push a new frame onto the stack. *)
let push_frame (thread_state : Thread_state.t) ~name ~now_ns =
  Stack.push thread_state.stack { Frame.name; enter_time_ns = now_ns }
;;

(** Snapshot the current stack into the collapsed-stacks accumulator. *)
let snapshot_stack (thread_state : Thread_state.t) ~(stack_times : Int63.t String.Table.t)
  =
  if not (Stack.is_empty thread_state.stack)
  then (
    (* Build the stack key: frames from bottom (root) to top (leaf), semicolon-separated *)
    let frames =
      Stack.fold thread_state.stack ~init:[] ~f:(fun acc frame -> frame.name :: acc)
    in
    let key = String.concat ~sep:";" frames in
    Hashtbl.update stack_times key ~f:(fun existing ->
      Int63.(Option.value existing ~default:zero + one)))
;;

let aggregate event_pipes =
  let func_table = String.Table.create () in
  let stack_times = String.Table.create () in
  let thread_states = Hashtbl.create (module Event.Thread) in
  let event_count = ref 0 in
  let earliest_time = ref Int63.max_value in
  let latest_time = ref Int63.zero in
  let get_thread_state thread =
    Hashtbl.find_or_add thread_states thread ~default:Thread_state.create
  in
  let%bind () =
    Deferred.List.iter event_pipes ~how:`Sequential ~f:(fun pipe ->
      Pipe.iter_without_pushback pipe ~f:(fun event ->
        incr event_count;
        match event with
        | Error _decode_error -> ()
        | Ok { thread; time; data; _ } ->
          let now_ns = time_ns_of_span time in
          if Int63.(now_ns < !earliest_time) then earliest_time := now_ns;
          if Int63.(now_ns > !latest_time) then latest_time := now_ns;
          let ts = get_thread_state thread in
          (match data with
           | Trace { kind; src = _; dst; trace_state_change; _ } ->
             charge_self_time ts ~func_table ~now_ns;
             let dst_name = symbol_name dst.symbol in
             (match trace_state_change with
              | Some End ->
                (* Trace ended; pop everything *)
                while not (Stack.is_empty ts.stack) do
                  pop_frame ts ~func_table ~now_ns
                done
              | Some Start ->
                (* Trace started; push the destination *)
                push_frame ts ~name:dst_name ~now_ns
              | None ->
                (match kind with
                 | Some Call | Some Syscall ->
                   snapshot_stack ts ~stack_times;
                   push_frame ts ~name:dst_name ~now_ns
                 | Some Return | Some Sysret | Some Iret ->
                   pop_frame ts ~func_table ~now_ns
                 | Some Jump ->
                   (* A jump into another function is effectively a tail call: pop
                      the current frame and push the destination. *)
                   pop_frame ts ~func_table ~now_ns;
                   push_frame ts ~name:dst_name ~now_ns
                 | Some (Interrupt | Hardware_interrupt) ->
                   push_frame ts ~name:dst_name ~now_ns
                 | Some Async ->
                   (* Async events end the trace for this thread *)
                   while not (Stack.is_empty ts.stack) do
                     pop_frame ts ~func_table ~now_ns
                   done
                 | Some Tx_abort -> ()
                 | None -> ()));
             ts.last_event_time_ns <- now_ns
           | Stacktrace_sample { callstack } ->
             (* For sampling mode: each sample is one observation of the full stack.
                Record it as a collapsed stack entry. *)
             let frames =
               List.filter_map callstack ~f:(fun loc ->
                 let name = symbol_name loc.symbol in
                 match name with
                 | "[unknown]" | "[untraced]" | "[returned]" -> None
                 | _ -> Some name)
             in
             if not (List.is_empty frames)
             then (
               let key = String.concat ~sep:";" frames in
               Hashtbl.update stack_times key ~f:(fun existing ->
                 Int63.(Option.value existing ~default:zero + one)))
           | Event_sample _ | Power _ -> ())))
  in
  (* Flush any remaining frames on all thread stacks *)
  Hashtbl.iter thread_states ~f:(fun ts ->
    let now_ns = !latest_time in
    charge_self_time ts ~func_table ~now_ns;
    while not (Stack.is_empty ts.stack) do
      pop_frame ts ~func_table ~now_ns
    done);
  let total_trace_time_ns =
    if Int63.(!latest_time > !earliest_time)
    then Int63.(!latest_time - !earliest_time)
    else Int63.zero
  in
  let function_stats =
    Hashtbl.fold func_table ~init:[] ~f:(fun ~key:name ~data:pf acc ->
      let (stats : Function_stats.t) =
        { name
        ; call_count = pf.call_count
        ; total_time_ns = pf.total_time_ns
        ; self_time_ns = pf.self_time_ns
        ; min_duration_ns =
            (if Int63.(pf.min_duration_ns = Int63.max_value)
             then Int63.zero
             else pf.min_duration_ns)
        ; max_duration_ns = pf.max_duration_ns
        ; durations_ns = pf.durations_ns
        }
      in
      stats :: acc)
    |> List.sort ~compare:Function_stats.compare_by_self_time
  in
  let collapsed_stacks =
    Hashtbl.fold stack_times ~init:[] ~f:(fun ~key ~data acc ->
      let frames = String.split key ~on:';' in
      { Collapsed_stack.frames; time_ns = data } :: acc)
    |> List.sort ~compare:(fun a b -> Int63.compare b.time_ns a.time_ns)
  in
  return
    { Result.function_stats
    ; collapsed_stacks
    ; total_trace_time_ns
    ; event_count = !event_count
    }
;;
