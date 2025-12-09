open! Core
open Unboxed
module Location = Event.Location
module Nonempty_vec = Nonempty_vec.Valuex3

let debug = false

module Frame : sig
  module Kind : sig
    type t =
      | Physical
      (** A physical stack frame, attributable directly to information given to us by
          [perf] in an [Event.t]. *)
      | Inlined (** An inlined function call, known to us solely via debug-info. *)
  end

  (* The [location], [parent], and [kind] fields are actually **immutable** except for on [Sentinel.t] instances. *)
  type t = private
    { mutable location : Event.Location.t
    ; mutable parent : t or_null
    ; mutable kind : Kind.t
    ; (* TODO Make this an [i64] *)
      mutable instruction_pointer : int64
    }

  val create : Location.t -> parent:t -> kind:Kind.t -> t
  val set_instruction_pointer : t -> int64 -> unit

  (** Find the first [Physical] frame whose [location.symbol] matches the provided
      argument.

      Returns the matching frame (if found) along with:
      - [distance]: the number of frames between the frame provided as an argument, and
        the returned frame (e.g. a call to [find my_frame my_symbol] with a return value
        of [#(This _, ~distance:0, ..)] indicates that [my_frame.location.symbol] is
        [my_symbol]).
      - [physical_distance]: like [distance] but only counting [kind = Physical] frames.
      - [leaf_of_inlined_stack]: the leaf of the stack of [kind = Inlined] frames attached
        to the returned frame (which is always physical), along with its distance from the
        frame provided as an argument. *)
  val find
    :  t
    -> Symbol.t
    -> #(t or_null
        * distance:int
        * physical_distance:int
        * leaf_of_inlined_stack:#(t or_null * int))

  (** Iterate from leaf-to-root up to the given number of frames, or until encountering
      the [Sentinel.t]. *)
  val iter_n : t -> int -> f:local_ (t -> unit) -> unit

  (** Like [iter_n], this iterates from **leaf-to-root**. The "rev" here signifies that
      the callback [f] is invoked in the reverse order of iteration (i.e. root-to-leaf).
      Note that this is *not* tail-recursive, given that frames form a singly-linked list
      from leaf-to-root. *)
  val iter_n_rev : t -> int -> f:local_ (t -> unit) -> unit

  (* If you're still confused between [iter_n] and [iter_n_rev], here's a small example:

      {v
            ┌────────┬────────┐
     root:  │  fn1   │  Null  │
            └────────┴────────┘
                         ▲
                         │
            ┌────────┬────────┐
            │  fn2   │        │
            └────────┴────────┘
                         ▲
                         │
            ┌────────┬────────┐
            │  fn3   │        │
            └────────┴────────┘
                         ▲
                         │
            ┌────────┬────────┐
            │  fn4   │        │
            └────────┴────────┘
                         ▲
                         │
            ┌────────┬────────┐
     leaf:  │  fn5   │        │
            └────────┴────────┘
      v}

      {[
        Frame.iter_n leaf 3 ~f:(fun frame -> printf "%s; " (Symbol.display_name frame.location.symbol));
        > fn5; fn4; fn3
        Frame.iter_n_rev leaf 3 ~f:(fun frame -> printf "%s; " (Symbol.display_name frame.location.symbol));
        > fn3; fn4; fn5
      ]}
  *)

  (** Find [ancestor] searching from [t]. This searches for *exactly* the [Frame.t]
      instance [ancestor] (i.e. comparison is performed via pointer equality). *)
  val find_ancestor
    :  t
    -> ancestor:t
    -> #(distance:int or_null * leaf_of_inlined_stack:#(t or_null * int))

  (** Unlike the other functions, this *can* return a [Sentinel.t]. This is probably a bad
      idea. *)
  val find_first_physical : t -> #(t * distance:int)

  (** Find the last (i.e. root-most) non-sentinel physical frame. *)
  val find_last_physical
    :  t
    -> #(t or_null * distance:int * leaf_of_inlined_stack:#(t or_null * int))

  val nth_ancestor_exn : t -> int -> t

  module Sentinel : sig
    type frame := t

    (** The root of a callstack. A sentinel does not correspond to a real program
        location, and its parent is always [Null]; it is the *only* frame allowed to have
        a [Null] parent.

        Using a sentinel allows us to avoid a variety of special-cases, and lets us update
        the root of all callstacks in a trace in O(1) time. *)
    type t = private frame

    val create : unit -> t

    (** Mutate [t]'s fields to the provided arguments and return [t] as a [frame]. *)
    val become_frame : t -> Location.t -> parent:frame -> kind:Kind.t -> frame
  end

  module For_testing : sig
    val to_string_list : t -> string list
    val print_callstack : t -> unit
  end
end = struct
  module Kind = struct
    type t =
      | Physical
      | Inlined
  end

  type t =
    { mutable location : Event.Location.t
    ; mutable parent : t or_null
    ; mutable kind : Kind.t
    ; mutable instruction_pointer : int64
    }

  let create location ~parent ~kind =
    { location
    ; parent = This parent
    ; kind
    ; instruction_pointer = location.instruction_pointer
    }
  ;;

  let[@inline always] set_instruction_pointer t instruction_pointer =
    t.instruction_pointer <- instruction_pointer
  ;;

  let rec find t target ~distance ~physical_distance ~leaf_of_inlined_stack =
    match t with
    | { parent = Null; _ } ->
      #(Null, ~distance, ~physical_distance, ~leaf_of_inlined_stack)
    | { kind = Physical; location = { symbol; _ }; _ } when Symbol.equal symbol target ->
      #(This t, ~distance, ~physical_distance, ~leaf_of_inlined_stack)
    | { parent = This parent; kind = Physical; _ } ->
      find
        parent
        target
        ~distance:(distance + 1)
        ~physical_distance:(physical_distance + 1)
        ~leaf_of_inlined_stack:#(Null, distance)
    | { parent = This parent; kind = Inlined; _ } ->
      let leaf_of_inlined_stack =
        match leaf_of_inlined_stack with
        | #(Null, _) -> #(This t, distance)
        | leaf_of_inlined_stack -> leaf_of_inlined_stack
      in
      find
        parent
        target
        ~distance:(distance + 1)
        ~physical_distance
        ~leaf_of_inlined_stack
  ;;

  let find t target =
    find t target ~distance:0 ~physical_distance:0 ~leaf_of_inlined_stack:#(Null, 0)
  ;;

  let rec iter_n t n ~f =
    match t, n with
    | { parent = Null; _ }, _ | _, 0 -> ()
    | { parent = This parent; _ }, n ->
      f t;
      iter_n parent (n - 1) ~f
  ;;

  let rec iter_n_rev t n ~f =
    match t, n with
    | { parent = Null; _ }, _ | _, 0 -> ()
    | { parent = This parent; _ }, n ->
      iter_n_rev parent (n - 1) ~f;
      f t
  ;;

  let rec find_ancestor t ~ancestor ~distance ~leaf_of_inlined_stack =
    if phys_equal t ancestor
    then #(~distance:(This distance), ~leaf_of_inlined_stack)
    else (
      match t with
      | { parent = Null; _ } -> #(~distance:Null, ~leaf_of_inlined_stack:#(Null, distance))
      | { parent = This parent; kind = Physical; _ } ->
        find_ancestor
          parent
          ~ancestor
          ~distance:(distance + 1)
          ~leaf_of_inlined_stack:#(Null, distance)
      | { parent = This parent; kind = Inlined; _ } ->
        let leaf_of_inlined_stack =
          match leaf_of_inlined_stack with
          | #(Null, _) -> #(This t, distance)
          | leaf_of_inlined_stack -> leaf_of_inlined_stack
        in
        find_ancestor parent ~ancestor ~distance:(distance + 1) ~leaf_of_inlined_stack)
  ;;

  let find_ancestor t ~ancestor =
    find_ancestor t ~ancestor ~distance:0 ~leaf_of_inlined_stack:#(Null, 0)
  ;;

  let rec find_first_physical t ~distance =
    match t with
    | { kind = Physical; _ } -> #(t, ~distance)
    | { parent = This parent; _ } -> find_first_physical parent ~distance:(distance + 1)
    | { parent = Null; kind = Inlined; _ } ->
      (* [Sentinel.t]s cannot have [kind = Inlined]. *)
      assert false
  ;;

  let find_first_physical t = find_first_physical t ~distance:0

  let rec find_last_physical t ~distance ~last_physical ~leaf_of_inlined_stack =
    match t with
    | { parent = Null; _ } ->
      let #(last_physical_frame, last_physical_distance) = last_physical in
      #(last_physical_frame, ~distance:last_physical_distance, ~leaf_of_inlined_stack)
    | { parent = This parent; kind = Physical; _ } ->
      find_last_physical
        parent
        ~distance:(distance + 1)
        ~last_physical:#(This t, distance)
        ~leaf_of_inlined_stack:#(Null, distance)
    | { parent = This parent; kind = Inlined; _ } ->
      let leaf_of_inlined_stack =
        match leaf_of_inlined_stack with
        | #(Null, _) -> #(This t, distance)
        | leaf_of_inlined_stack -> leaf_of_inlined_stack
      in
      find_last_physical
        parent
        ~distance:(distance + 1)
        ~last_physical
        ~leaf_of_inlined_stack
  ;;

  let find_last_physical t =
    find_last_physical
      t
      ~distance:0
      ~last_physical:#(Null, 0)
      ~leaf_of_inlined_stack:#(Null, 0)
  ;;

  let nth_ancestor_exn t n =
    let mutable t = t in
    for _ = 1 to n do
      t <- Or_null.value_exn t.parent
    done;
    t
  ;;

  module Sentinel = struct
    type nonrec t = t

    let sentinel_location : Location.t =
      { instruction_pointer = 0L
      ; symbol_offset = 0
      ; (* For the sake of being defensive, we define a special symbol for the sentinel which is *impossible*
           to confuse with a real symbol, because ELF symbol names are NULL-terminated strings.

           See https://refspecs.linuxbase.org/elf/gabi4+/ch4.strtab.html *)
        symbol = From_perf "\x00_"
      ; dso = Null
      }
    ;;

    let[@inline always] create () =
      { location = sentinel_location
      ; parent = Null
      ; kind = Physical
      ; instruction_pointer = 0L
      }
    ;;

    let become_frame t location ~parent ~kind =
      t.location <- location;
      t.parent <- This parent;
      t.kind <- kind;
      t.instruction_pointer <- location.instruction_pointer;
      t
    ;;
  end

  module For_testing = struct
    let rec to_string_list acc t =
      match t.parent with
      | Null -> acc
      | This parent ->
        let kind =
          if not debug
          then ""
          else (
            match t.kind with
            | Physical -> " PHYSICAL"
            | Inlined -> " INLINED")
        in
        to_string_list
          ([%string "%{Symbol.display_name t.location.symbol}%{kind}"] :: acc)
          parent
    ;;

    let to_string_list t = to_string_list [] t
    let print_callstack leaf = to_string_list leaf |> String.concat_lines |> printf "%s"
  end
end

module Control_flow = struct
  type t =
    | Call of { depth : int }
    (** [depth] indicates how many new frames were introduced. *)
    | Return of { distance : int }
    (** [distance] indicates how many frames this return pops off of the callstack.
        [distance = 1] is the usual case of returning from the current frame to its
        parent. *)
  [@@deriving sexp_of]
end

module Callstack = struct
  type t =
    #{ time : Timestamp.t
     ; leaf : Frame.t
     ; control_flow : Control_flow.t
     }
end

type t =
  { mutable root : Frame.Sentinel.t
  ; mutable last_event_time : Timestamp.t
  (** Strictly speaking maintaining [last_event_time] is not necessary, but we do so in
      order to make bugs obvious. *)
  ; callstacks : Callstack.t Nonempty_vec.t
  (** Our reconstruction of the program's control-flow based on the input event stream.
      When appending new elements to [callstacks], it's **vitally important** to maintain
      the following invariants in order for [callstacks] to be correctly processed during
      [write_trace]:

      1. A callstack with [control_flow = Call { depth }] introduces [depth] new frames
         which were not present in the callstack immediately preceding it. These new
         frames are the first [depth] frames starting from this callstack's [leaf].
      2. A callstack with [control_flow = Return { distance }] **exits** [distance]
         frames, starting from the [leaf] of the callstack immediately preceding it. *)
  ; symbolizer : Symbolizer.t
  ; ocaml_exception_info : Ocaml_exception_info.t or_null
  ; exception_handlers : Frame.t Vec.t
  (** The currently active OCaml exception handlers. This is used to determine which frame
      to return to when [ocaml_exception_info] indicates that the current event is an
      OCaml exception being raised in the traced program.

      In contrast to [callstacks] — which records the entire history of control-flow for
      later examination — [exception_handlers] represents the state **as of the event we
      are currently processing**, and as such is only used during the "ingestion" phase
      (i.e. while calls are still being made to [add_event]). We maintain the invariant
      that, after processing an event, every frame in [exception_handlers] should be an
      ancestor of or equal to [current_physical_frame t]. *)
  ; mutable last_known_location : Location.t
  }

let create ocaml_exception_info =
  let root = Frame.Sentinel.create () in
  { root
  ; last_event_time = Timestamp.zero
  ; callstacks =
      Nonempty_vec.create
        (#{ time = Timestamp.zero
          ; leaf = (root :> Frame.t)
          ; control_flow = Return { distance = 0 }
          }
         : Callstack.t)
  ; symbolizer = Symbolizer.create ()
  ; exception_handlers = Vec.create ()
  ; ocaml_exception_info = Or_null.of_option ocaml_exception_info
  ; last_known_location : Location.t =
      { symbol = Unknown
      ; symbol_offset = 0
      ; (* [Ocaml_exception_info.iter_pushtraps_and_poptraps_in_range] does binary search
           under-the-hood; initializing this to [Int64.max_value] intentionally makes the first
           call terminate immediately. *)
        instruction_pointer = Int64.max_value
      ; dso = Null
      }
  }
;;

let create_continuing_from existing =
  let last_callstack = Nonempty_vec.last existing.callstacks in
  { existing with
    callstacks =
      Nonempty_vec.create
        (#{ last_callstack with control_flow = Return { distance = 0 } } : Callstack.t)
  ; exception_handlers = Vec.copy existing.exception_handlers
  }
;;

let[@inline always] current_frame t = (Nonempty_vec.last t.callstacks).#leaf
let[@inline always] current_physical_frame t = Frame.find_first_physical (current_frame t)

let emplace_root t location ~kind =
  let new_sentinel = Frame.Sentinel.create () in
  let root =
    Frame.Sentinel.become_frame t.root location ~parent:(new_sentinel :> Frame.t) ~kind
  in
  t.root <- new_sentinel;
  root
;;

let diff_inlined_frames'
  (t : t)
  time
  ~dso:_
  ~(before : Symbolizer.Info.t Slice.t)
  ~(after : Symbolizer.Info.t Slice.t)
  =
  let length = Int.min (Slice.length before) (Slice.length after) in
  let mutable first_different_index = 0 in
  while
    first_different_index < length
    && Symbolizer.Info.equal
         (Slice.unsafe_get before first_different_index)
         (Slice.unsafe_get after first_different_index)
  do
    first_different_index <- first_different_index + 1
  done;
  let return_distance = Slice.length before - first_different_index in
  if return_distance <> 0
  then
    Nonempty_vec.push_back
      t.callstacks
      #{ time
       ; leaf = Frame.nth_ancestor_exn (current_frame t) return_distance
       ; control_flow = Return { distance = return_distance }
       };
  let mutable parent = current_frame t in
  for i = first_different_index to Slice.length after - 1 do
    let inlined_frame_info = Slice.unsafe_get after i in
    let inlined_frame =
      Frame.create (Symbolizer.Info.to_location inlined_frame_info) ~parent ~kind:Inlined
    in
    parent <- inlined_frame
  done;
  let frames_created = Slice.length after - first_different_index in
  if frames_created > 0
  then
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = parent; control_flow = Call { depth = frames_created } }
;;

let symbolize_inlined_frames t ~dso ~addr =
  match Symbolizer.symbolize t.symbolizer ~executable:dso ~addr with
  | Null -> Slice.empty
  | This result -> Symbolizer.Response.inlined_frames result
;;

let diff_inlined_frames (t : t) time ~dso ~(before : int64) ~(after : int64) =
  if Env_vars.check_invariants
  then (
    let #(current_physical_frame, ~distance:_) = current_physical_frame t in
    [%test_eq: Interned_string.t or_null] current_physical_frame.location.dso dso);
  diff_inlined_frames'
    t
    time
    ~dso
    ~before:(symbolize_inlined_frames t ~dso ~addr:before)
    ~after:(symbolize_inlined_frames t ~dso ~addr:after)
;;

let append_inlined_frames
  t
  time
  ~(physical_frame : Frame.t)
  ~and_insert_physical_frame_too
  =
  assert (phys_equal physical_frame.kind Physical);
  let inlined_frames =
    symbolize_inlined_frames
      t
      ~dso:physical_frame.location.dso
      ~addr:physical_frame.instruction_pointer
  in
  let parent = stack_ (ref physical_frame) in
  Slice.iter inlined_frames ~f:(stack_ fun inlined_frame_info ->
    let inlined_leaf_frame =
      Frame.create
        ~kind:Inlined
        (Symbolizer.Info.to_location inlined_frame_info)
        ~parent:!parent
    in
    parent := inlined_leaf_frame);
  let new_frames =
    Bool.to_int and_insert_physical_frame_too + Slice.length inlined_frames
  in
  if new_frames > 0
  then
    (* It's important that a [physical_frame] and all of its inlined children are introduced
       via a single [Callstack.t] for the sake of [smear_times] treating this correctly.
       When control-flow proceeds from one address to another, where the destination address
       corresponds to an inlined chain (e.g. [A -> B -> C]), you should treat all of the
       functions in the chain as having been entered *simultaneously*.

       Producing exactly one [Callstack.t] accomplishes this; if you instead produced N
       [Callstack.t]s each of [Call { depth = 1 }], time would get smeared between them.
       That would produce ugly, aggressively stair-stepped traces, and many more "instantaneous"
       events. I also would argue such traces to be *incorrect*; smearing out a single instruction
       to distribute its execution time amongst the 5 layers of wrapper function that contain it
       is sort of nonsense.
    *)
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = !parent; control_flow = Call { depth = new_frames } }
;;

let return_to_existing_frame
  (t : t)
  time
  ~(new_location : Location.t)
  ~(frame : Frame.t)
  ~(distance : int)
  ~leaf_of_inlined_stack
  =
  match leaf_of_inlined_stack with
  | #(Null, _) ->
    Frame.set_instruction_pointer frame new_location.instruction_pointer;
    Nonempty_vec.push_back
      t.callstacks
      #{ time; leaf = frame; control_flow = Return { distance } };
    append_inlined_frames
      t
      time
      ~physical_frame:frame
      ~and_insert_physical_frame_too:false
  | #(This inlined_leaf, inlined_leaf_distance) ->
    Nonempty_vec.push_back
      t.callstacks
      #{ time
       ; leaf = inlined_leaf
       ; control_flow = Return { distance = inlined_leaf_distance }
       };
    diff_inlined_frames
      t
      time
      ~dso:new_location.dso
      ~before:frame.instruction_pointer
      ~after:new_location.instruction_pointer;
    Frame.set_instruction_pointer frame new_location.instruction_pointer
;;

(** This is intended to mark code we hope is *unreachable*, not merely uncommon. Hopefully
    over time we can strengthen its callsites to assertions. *)
let[@cold] log_unexpected_case ~(here : [%call_pos]) sexp =
  eprintf
    "Warning, unexpected case reached [%s:%d:%d]: %s\n"
    here.pos_fname
    here.pos_lnum
    (here.pos_cnum - here.pos_bol)
    (Sexp.to_string_mach sexp)
;;

(* [handle_call] uses [src], unlike the other event handlers. The rationale for this
   is that in the context of a call, [src] is the parent frame of the call to [dst]
   and thus *it continues to exist*. We want our callstacks to reflect that. *)
let handle_call (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  (* First, reconcile things such that [src] matches [current_physical_frame t] if it doesn't
     already. *)
  let () =
    match Frame.find (current_frame t) src.symbol with
    | #(This _, ~physical_distance:0, ..) ->
      (* The happy case, [src] matches [current_physical_frame t]. The inlined frames
         should already be correct on account of the straightline-execution
         inlined frames logic at the start of [add_event]. *)
      ()
    | #(Null, ~physical_distance:0, ..) ->
      (* I would only ever expect this to occur at the very beginning of a trace. *)
      let src_frame = Frame.create src ~parent:(t.root :> Frame.t) ~kind:Physical in
      append_inlined_frames
        t
        time
        ~physical_frame:src_frame
        ~and_insert_physical_frame_too:true
    | #((This _ | Null), ~physical_distance:_, ..) ->
      log_unexpected_case
        [%message "call [src] does not match known trace state." (src : Location.t)];
      (* We've somehow reached [src] without seeing the control-flow that brought us here.

         To maximize our chances of producing a coherent trace, we create a frame for
         [src] as a child of the current frame. The idea here is that because we support
         "long" [Return]s (i.e. [Return]s with [distance > 1]), inserting the additional
         frame for [src] ( *in addition* to the frame we always create for [dst]) gives us
         better odds of resynchronizing with the event stream, since now we can easily
         handle a later return event to [src], [dst], or even both. *)
      let src_frame = Frame.create src ~parent:(current_frame t) ~kind:Physical in
      append_inlined_frames
        t
        time
        ~physical_frame:src_frame
        ~and_insert_physical_frame_too:true
  in
  let #(src_frame, ~distance:_) = current_physical_frame t in
  assert (not (Or_null.is_null src_frame.parent));
  Frame.set_instruction_pointer src_frame src.instruction_pointer;
  (* Then create the new frame for [dst]. *)
  let dst_frame = Frame.create dst ~parent:(current_frame t) ~kind:Physical in
  append_inlined_frames
    t
    time
    ~physical_frame:dst_frame
    ~and_insert_physical_frame_too:true
;;

(** We are returning into something we did not see the call for. This can happen if
    there's a series of calls like [fn1 -> fn2] and we started tracing during the
    execution of [fn2], then we see a return into [fn1]. *)
let return_to_unseen (t : t) (time : Timestamp.t) ~(dst : Location.t) ~(distance : int) =
  (* We symbolize at one byte before the return address because the callstack we want to
     see reflected as roots of the whole trace corresponds to the code as of the [call]
     instruction we are returning from, *not* whatever comes immediately after it. *)
  let addr = Int64.O.(dst.instruction_pointer - 1L) in
  let inlined_frames = symbolize_inlined_frames t ~dso:dst.dso ~addr in
  let mutable inlined_leaf = Null in
  let last_index = Slice.length inlined_frames - 1 in
  for i = last_index downto 0 do
    let inlined_frame_info = Slice.unsafe_get inlined_frames i in
    let inlined_frame =
      emplace_root t (Symbolizer.Info.to_location inlined_frame_info) ~kind:Inlined
    in
    if i = last_index then inlined_leaf <- This inlined_frame
  done;
  let (physical_root : Frame.t) =
    emplace_root t { dst with instruction_pointer = addr } ~kind:Physical
  in
  Nonempty_vec.push_back
    t.callstacks
    #{ time
     ; leaf = Or_null.value inlined_leaf ~default:physical_root
     ; control_flow = Return { distance }
     };
  diff_inlined_frames t time ~dso:dst.dso ~before:addr ~after:dst.instruction_pointer;
  Frame.set_instruction_pointer physical_root dst.instruction_pointer
;;

let handle_return (t : t) (time : Timestamp.t) ~(dst : Location.t) =
  match current_physical_frame t with
  | #({ parent = Null; _ }, ~distance:_) -> return_to_unseen t time ~dst ~distance:0
  | #({ parent = This parent_frame; _ }, ~distance:distance_to_current_frame) ->
    (* We start our search for [dst] from the parent of the current physical frame because
       otherwise you'd incorrectly handle non-tail recursion, and because returning to the
       current frame is impossible anyway. We add 1 to the distance here to
       account for the one extra frame implicitly traversed by doing this. *)
    let distance_to_parent_frame = distance_to_current_frame + 1 in
    (match Frame.find parent_frame dst.symbol with
     | #(This dst_frame, ~distance, ~leaf_of_inlined_stack, ..) ->
       (* 99% of the time [physical_distance] should be 0, indicating we are returning to
          [parent_frame] as expected. We allow for the possibility of "long" returns to
          account for [Sysret]/[Iret] events that return to userspace directly from deep
          within their kernel/interrupt stack.

          Note that this likely isn't sufficient to handle exotic control flow
          (e.g. [rseq] aborts), but I can't say I've tested that.
       *)
       let #(maybe_inlined_leaf, inlined_leaf_distance) = leaf_of_inlined_stack in
       return_to_existing_frame
         t
         time
         ~new_location:dst
         ~frame:dst_frame
         ~distance:(distance + distance_to_parent_frame)
         ~leaf_of_inlined_stack:
           #(maybe_inlined_leaf, inlined_leaf_distance + distance_to_parent_frame)
     | #(Null, ~physical_distance:0, ~distance, ..) ->
       (* Our [parent_frame] is the sentinel. *)
       return_to_unseen t time ~dst ~distance:(distance + distance_to_parent_frame)
     | #(Null, ~physical_distance:_, ..) ->
       log_unexpected_case
         [%message "return [dst] does not match known trace state." (dst : Location.t)];
       (* Something is probably wrong if we ever make it to this case, where the state
          we're maintaining and the event we are processing seem to completely disagree.
          Treating it like a tail-call seems like the least bad option, and at the very
          least gets us to agree with the event stream that the current frame is [dst]. *)
       Nonempty_vec.push_back
         t.callstacks
         #{ time
          ; leaf = parent_frame
          ; control_flow = Return { distance = distance_to_parent_frame }
          };
       let dst_frame = Frame.create dst ~parent:parent_frame ~kind:Physical in
       append_inlined_frames
         t
         time
         ~physical_frame:dst_frame
         ~and_insert_physical_frame_too:true)
;;

let handle_jump (t : t) (time : Timestamp.t) ~(src : Location.t) ~(dst : Location.t) =
  let #(current_physical_frame, ~distance) = current_physical_frame t in
  if Symbol.equal current_physical_frame.location.symbol dst.symbol
  then (
    (* [dst] matches [current_frame t]. This is either a branch within a function, or tail-recursion. *)
    diff_inlined_frames
      t
      time
      ~dso:dst.dso
      ~before:src.instruction_pointer
      ~after:dst.instruction_pointer;
    Frame.set_instruction_pointer current_physical_frame dst.instruction_pointer)
  else (
    match current_physical_frame.parent with
    | Null ->
      (* This is probably a non-recursive tail-call, but we don't know anything
         about the previous frame, so we treat this is a [Call] because we only
         want to emit a frame-enter while writing out the trace. *)
      let dst_frame = Frame.create dst ~parent:(t.root :> Frame.t) ~kind:Physical in
      append_inlined_frames
        t
        time
        ~physical_frame:dst_frame
        ~and_insert_physical_frame_too:true
    | This parent ->
      (* This is probably a non-recursive tail-call. *)
      Nonempty_vec.push_back
        t.callstacks
        #{ time; leaf = parent; control_flow = Return { distance = distance + 1 } };
      let dst_frame = Frame.create dst ~parent ~kind:Physical in
      append_inlined_frames
        t
        time
        ~physical_frame:dst_frame
        ~and_insert_physical_frame_too:true)
;;

let is_ocaml_exception_handler t ~(dst : Location.t) =
  match t.ocaml_exception_info with
  | Null -> false
  | This ocaml_exception_info ->
    Ocaml_exception_info.is_entertrap ocaml_exception_info ~addr:dst.instruction_pointer
;;

let handle_ocaml_exception (t : t) (time : Timestamp.t) ~(dst : Location.t) =
  match Vec.last t.exception_handlers with
  | This dst_frame ->
    Vec.pop_back_unit_exn t.exception_handlers;
    assert (Symbol.equal dst_frame.location.symbol dst.symbol);
    (match Frame.find_ancestor (current_frame t) ~ancestor:dst_frame with
     | #(~distance:(This distance), ~leaf_of_inlined_stack) ->
       (* This is the happy case where our exception handler tracking is working as expected. *)
       return_to_existing_frame
         t
         time
         ~new_location:dst
         ~frame:dst_frame
         ~distance
         ~leaf_of_inlined_stack
     | #(~distance:Null, ..) ->
       failwithf
         "Invariant violated, exception handler '%s' was not found in the current \
          callstack"
         (Symbol.display_name dst.symbol)
         ())
  | Null ->
    (match Frame.find_last_physical (current_frame t) with
     | #(This frame, ~distance, ~leaf_of_inlined_stack)
       when Symbol.equal frame.location.symbol dst.symbol ->
       (* There are valid (but hopefully rare) ways to reach this case.
          Take the following code for example:
          {v

          let rec process_data x n =
            match n with
            | 100 -> x
            | 50 -> (try process_data x (n + 1) with | _ -> process_data x 76)
            | 75 -> failwith "Raise an exception"
            | n -> n + process_data (x + n) (n + 1)
          ;;

          v}

          If the program calls [process_data _ 0], and we start tracing during the execution of
          [process_data _ 70], then when the program eventually executes [process_data _ 75]
          and raises an exception, the symbol of the exception target [process_data] will be
          found in the current callstack, but [t.exception_handlers] will be **empty** because
          the pushtrap only occurs in [process_data _ 50], which executed before we started tracing.

          Another way this case can occur is a very long-running function that sets up its pushtraps
          early (e.g. the main loop of the async scheduler). Here's a working example:
          {v

          open! Core

          let[@cold] print_that_we_are_done () = print_endline "We are done"

          let[@cold] main_application_loop () =
            let () =
              try
                while true do
                  match (Core_unix.access [@inlined never]) "/tmp/flag.txt" [ `Exists ] with
                  | Error _ -> ()
                  | Ok _ -> failwith "/tmp/flag.txt exists now"
                done
              with
              | _ -> ()
            in
            print_that_we_are_done ();
            let mutable x = 0 in
            while true do
              x <- x + 1
            done
          ;;

          let () = main_application_loop ()

          v}

          If we start tracing this program at any time after startup, the program will already
          be in the first [while true] loop, without us having seen the entertrap for the surrounding
          [try] block. When [/tmp/flag.txt] comes into existence and we raise an exception via [failwith],
          we'll see an entertrap with a destination of [main_application_loop], but [t.exception_handlers]
          will be **empty**.

          It's impossible for magic-trace to distinguish between these two cases, a very
          long-running function that set up its pushtraps early vs. the child of an even
          deeper but unseen stack of non-tail recursive calls. OCaml being what it is,
          unfortunately I think code of both shapes actually exists. We go with the former
          interpretation because it should produce a readable trace in either scenario.
       *)
       return_to_existing_frame
         t
         time
         ~new_location:dst
         ~frame
         ~distance
         ~leaf_of_inlined_stack
     | #(maybe_frame, ~distance, ..) ->
       (* We are probably raising into an exception handler much further up the stack that we never saw the entrance into. *)
       let distance =
         (* - Add 1 to the distance for the [_phantom_frame] we are injecting.
            - Possibly add 1 more to the distance to return past the last physical frame (if it exists)
              all the way to the sentinel.
         *)
         distance + 1 + (Or_null.is_this maybe_frame |> Bool.to_int)
       in
       let _phantom_frame =
         let phantom_location : Location.t =
           { instruction_pointer = 0L
           ; symbol_offset = 0
           ; dso = Null
           ; symbol = From_perf "[zero or more unknowable frames]"
           }
         in
         emplace_root t phantom_location ~kind:Physical
       in
       let dst_frame = emplace_root t dst ~kind:Physical in
       Nonempty_vec.push_back
         t.callstacks
         #{ time; leaf = dst_frame; control_flow = Return { distance } };
       (* Unlike [handle_return] we do *not* make the inlined frames at [dst] (or [dst.instruction_pointer - 1])
          the parents of the existing frames. The rationale is that unlike [handle_return], we have no idea
          where we might've been within the frame for [dst] that we just inferred. *)
       append_inlined_frames
         t
         time
         ~physical_frame:dst_frame
           (* This is subtle; Yes the frame is new, but we *don't* want to reflect that in a
              [Call], because discovered roots are handled separately. *)
         ~and_insert_physical_frame_too:false)
;;

let[@cold] print (event : Event.Ok.Data.t) (time : Timestamp.t) =
  match event with
  | Trace { kind; src; dst; trace_state_change } ->
    eprint_s
      ~mach:()
      [%message
        (kind : Event.Kind.t option)
          ~time:(Time_ns.Span.to_int_ns (time :> Time_ns.Span.t) % 10000000 : int)
          ~src:(Symbol.display_name src.symbol)
          ~src_ip:(src.instruction_pointer : Int64.Hex.t)
          ~dst:(Symbol.display_name dst.symbol)
          ~dst_ip:(dst.instruction_pointer : Int64.Hex.t)
          (trace_state_change : Trace_state_change.t option)]
  | _ -> ()
;;

let[@inline always] print (event : Event.Ok.Data.t) (time : Timestamp.t) =
  if debug then print event time
;;

let add_event (t : t) (event : Event.Ok.Data.t) (time : Timestamp.t) =
  print event time;
  assert (Timestamp.( >= ) time t.last_event_time);
  t.last_event_time <- time;
  (match event with
   | Trace { src; dst; _ } ->
     if Or_null.equal Interned_string.equal t.last_known_location.dso src.dso
        && Int64.( <> ) t.last_known_location.instruction_pointer 0L
        && Int64.( <> ) src.instruction_pointer 0L
     then (
       let mutable prev_inlined_frames =
         symbolize_inlined_frames
           t
           ~dso:t.last_known_location.dso
           ~addr:t.last_known_location.instruction_pointer
       in
       (* TODO I fear symbolizing at every byte like this is likely to be *very* expensive, but let's focus on just getting things working for now. *)
       let mutable addr = I64.of_int64 t.last_known_location.instruction_pointer in
       let src_addr = I64.of_int64 src.instruction_pointer in
       (* There are no [i64] for-loops yet :( *)
       while I64.O.(addr <= src_addr) do
         let addr_inlined_frames =
           symbolize_inlined_frames t ~dso:src.dso ~addr:(I64.box addr)
         in
         diff_inlined_frames'
           t
           time
           ~dso:src.dso
           ~before:prev_inlined_frames
           ~after:addr_inlined_frames;
         prev_inlined_frames <- addr_inlined_frames;
         addr <- I64.O.(addr + #1L)
       done);
     (match t.ocaml_exception_info with
      | Null -> ()
      | This ocaml_exception_info ->
        let #(current_physical_frame, ~distance:_) = current_physical_frame t in
        Ocaml_exception_info.iter_pushtraps_and_poptraps_in_range
          ocaml_exception_info
          ~from:t.last_known_location.instruction_pointer
          ~to_:src.instruction_pointer
          ~f:(stack_ fun (_address, kind) ->
            match kind with
            | Pushtrap -> Vec.push_back t.exception_handlers current_physical_frame
            | Poptrap ->
              (match Vec.last t.exception_handlers with
               | This current_exception_handler
                 when phys_equal current_exception_handler current_physical_frame ->
                 Vec.pop_back_unit_exn t.exception_handlers
               | Null ->
                 (* Hitting this case a couple of times early in the trace is not unusual. *)
                 ()
               | This current_exception_handler ->
                 log_unexpected_case
                   [%message
                     "[exception_handlers] appears to be out-of-sync with [callstacks]; \
                      the active exception handler does not match the current physical \
                      frame."
                       ~current_exception_handler:
                         (current_exception_handler.location : Location.t)
                       ~current_physical_frame:
                         (current_physical_frame.location : Location.t)])));
     t.last_known_location <- dst
   | _ -> ());
  (match event with
   (* TODO Get the untraced "kind" right instead of always showing [Location.untraced] for untraced time. *)
   | Trace { trace_state_change = Some Start; dst; _ } -> handle_return t time ~dst
   | Trace { trace_state_change = Some End; src; dst = _; _ } ->
     handle_call t time ~src ~dst:Location.untraced
   | Trace { trace_state_change = None; kind = Some kind; src; dst } ->
     (match kind with
      | (Return | Jump | Interrupt) when is_ocaml_exception_handler t ~dst ->
        handle_ocaml_exception t time ~dst
      | Call | Syscall | Hardware_interrupt | Interrupt -> handle_call t time ~src ~dst
      | Return | Sysret | Iret -> handle_return t time ~dst
      | Jump | Tx_abort | Async -> handle_jump t time ~src ~dst)
   | Trace { kind = None; _ } -> ()
   (* All of the below events are handled in [new_trace_writer.ml]. *)
   | Power _ | Stacktrace_sample _ | Event_sample _ -> ());
  if debug
  then (
    Frame.For_testing.print_callstack (current_frame t);
    print_endline "-------------------------------");
  if Env_vars.check_invariants
  then (
    let #(current_physical_frame, ~distance) = current_physical_frame t in
    (* Maintaining [t.last_known_location] separately is a minor optimization so that
       we don't have to walk from [current_frame t] to find the current physical frame
       at the start of processing each event. The corollary is that updating the [instruction_pointer]
       on the current physical frame on each event **is truly necessary**; maintaining *only*
       [t.last_known_location] would be insufficient to accurately process traces.
       In particular this comes up when handling returns (and by extension, exceptions),
       where you need to know what the instruction-pointer was in the physical frame you
       are returning to the last time the program was there, so that you can
       [diff_inlined_frames] in order to return to *the correct inlined child* of that
       physical frame. *)
    [%test_eq: Int64.Hex.t]
      ~message:
        "Recorded [last_known_location] does not match the current physical frame after \
         processing this event"
      t.last_known_location.instruction_pointer
      current_physical_frame.instruction_pointer;
    let () =
      let actual_inlined_frames = ref [] in
      Frame.iter_n
        (current_frame t)
        distance
        ~f:(stack_ fun { location = { symbol; _ }; _ } ->
          actual_inlined_frames := Symbol.display_name symbol :: !actual_inlined_frames);
      let expected_inlined_frames =
        symbolize_inlined_frames
          t
          ~dso:t.last_known_location.dso
          ~addr:t.last_known_location.instruction_pointer
        |> Slice.map_to_list ~f:(stack_ fun { demangled_name } -> demangled_name)
      in
      [%test_result: string list]
        ~message:"Inlined frames in callstacks did not match expectation"
        !actual_inlined_frames
        ~expect:expected_inlined_frames
    in
    let mutable frame = current_physical_frame in
    for i = Vec.length t.exception_handlers - 1 downto 0 do
      let exception_handler = Vec.unsafe_get t.exception_handlers i in
      let #(~distance, ~leaf_of_inlined_stack:_) =
        Frame.find_ancestor frame ~ancestor:exception_handler
      in
      [%test_result: bool]
        ~message:
          "Expected all [exception_handler] frames to be an ancestor of \
           [current_physical_frame]"
        ~expect:false
        (Or_null.is_null distance);
      frame <- exception_handler
    done)
;;

module Writer : sig
  type 'thread t

  val create
    :  (module Trace_writer_intf.S_trace with type thread = 'thread)
    -> 'thread
    -> 'thread t @ local

  val emit_frame_enter : 'thread t @ local -> Timestamp.t -> Frame.t -> unit
  val emit_frame_exit : 'thread t @ local -> Timestamp.t -> Frame.t -> unit
end = struct
  type 'thread t =
    { mutable last_time : Timestamp.t @@ global
    ; active_frames : Symbol.t Vec.t @@ global
    (** Strictly speaking maintaining [last_time] and [active_frames] is not necessary
        assuming the rest of the code is written correctly, but not checking our
        invariants makes it *much* harder to figure out where things go wrong, because you
        would just end up with a mangled Perfetto trace but the [magic-trace] invocation
        would complete silently and successfully. *)
    ; write_duration_begin :
        args:Tracing.Trace.Arg.t list
        -> name:string
        -> time:Time_ns.Span.t
        -> category:string
        -> unit
      @@ global
    ; write_duration_end :
        args:Tracing.Trace.Arg.t list
        -> name:string
        -> time:Time_ns.Span.t
        -> category:string
        -> unit
      @@ global
    }

  let create
    (type thread)
    (trace : (module Trace_writer_intf.S_trace with type thread = thread))
    (thread : thread)
    = exclave_
    let module T = (val trace) in
    stack_
      { last_time = Timestamp.zero
      ; active_frames = Vec.create ()
      ; write_duration_begin =
          (fun ~args ~name ~time ~category ->
            T.write_duration_begin ~args ~thread ~name ~time ~category ())
      ; write_duration_end =
          (fun ~args ~name ~time ~category ->
            T.write_duration_end ~args ~thread ~name ~time ~category ())
      }
  ;;

  let emit_frame_enter (local_ (t : _ t)) (time : Timestamp.t) (frame : Frame.t) =
    let location = frame.location in
    assert (Timestamp.( >= ) time t.last_time);
    t.last_time <- time;
    Vec.push_back t.active_frames location.symbol;
    if debug then eprintf "Enter %s\n" (Symbol.display_name location.symbol);
    (* TODO In the future we can surface more detailed information in [args]
       (e.g. filename, line number, etc.) since LLVM can easily provide it to us,
       but for now we omit it given that the traces are already huge. *)
    let #(args, category) : #(Tracing.Trace.Arg.t list * string) =
      match frame.kind with
      | Inlined -> #([], "Inlined")
      | Physical -> #([ "address", Pointer location.instruction_pointer ], "")
    in
    t.write_duration_begin
      ~args
      ~name:(Symbol.display_name location.symbol)
      ~time:(time :> Time_ns.Span.t)
      ~category
  ;;

  let emit_frame_exit (t : _ t) (time : Timestamp.t) (frame : Frame.t) =
    let location = frame.location in
    assert (Timestamp.( >= ) time t.last_time);
    t.last_time <- time;
    [%test_result: Symbol.t] ~expect:(Vec.pop_back_exn t.active_frames) location.symbol;
    if debug then eprintf "Exit %s\n" (Symbol.display_name location.symbol);
    t.write_duration_end
      ~args:[]
      ~name:(Symbol.display_name location.symbol)
      ~time:(time :> Time_ns.Span.t)
      ~category:""
  ;;
end

(* Intel PT may produce many events with the same timestamp due to resolution limitations.
   To produce better visual traces, we "smear" time, evenly distributing time amongst runs
   of consecutive events that all have the same timestamp. *)
let smear_times (callstacks : Callstack.t Nonempty_vec.t) =
  (* It would be reasonable to also have [Return]s consume time, but making them not consume
     time substantially reduces the frequency where we need to use zero-duration events.
     In general the traces are easier to read if returns aren't counted as consuming time. *)
  let[@inline always] consumes_time : Callstack.t -> bool = function
    | #{ control_flow = Call _; _ } -> true
    | _ -> false
  in
  let len = Nonempty_vec.length callstacks in
  let mutable i = 0 in
  while i < len do
    let t1 = (Nonempty_vec.get callstacks i).#time in
    (* Find the end of the run of events with the same timestamp *)
    let mutable run_end = i in
    let mutable num_time_consuming_events =
      consumes_time (Nonempty_vec.get callstacks i) |> Bool.to_int
    in
    while
      run_end + 1 < len
      && Timestamp.equal (Nonempty_vec.get callstacks (run_end + 1)).#time t1
    do
      num_time_consuming_events
      <- num_time_consuming_events
         + (consumes_time (Nonempty_vec.get callstacks (run_end + 1)) |> Bool.to_int);
      run_end <- run_end + 1
    done;
    num_time_consuming_events <- Int.max 1 num_time_consuming_events;
    let run_length = run_end - i + 1 in
    if run_end + 1 < len
    then (
      (* Smear times across this run *)
      let t2 = (Nonempty_vec.get callstacks (run_end + 1)).#time in
      let duration_ns =
        Time_ns.Span.( - ) (t2 :> Time_ns.Span.t) (t1 :> Time_ns.Span.t)
        |> Time_ns.Span.to_int_ns
      in
      let mutable time_consuming_events_seen = 0 in
      for k = 0 to run_length - 1 do
        let cs = Nonempty_vec.get callstacks (i + k) in
        let offset_ns =
          duration_ns * time_consuming_events_seen / num_time_consuming_events
        in
        let smeared_time =
          Timestamp.create Time_ns.Span.((t1 :> Time_ns.Span.t) + of_int_ns offset_ns)
        in
        (* Rewriting the entire [Callstack.t] instead of modifying just the [time] field
           in-place is sad, but I'm not sure the microoptimization is worth the hassle
           it'd take to achieve it. *)
        Nonempty_vec.set callstacks (i + k) #{ cs with time = smeared_time };
        time_consuming_events_seen
        <- time_consuming_events_seen + (consumes_time cs |> Bool.to_int)
      done
      (* else: final run - keep original times *));
    i <- run_end + 1
  done
;;

let write_trace
  (type thread)
  (t : t)
  (trace : (module Trace_writer_intf.S_trace with type thread = thread))
  (thread : thread)
  =
  let writer = Writer.create trace thread in
  smear_times t.callstacks;
  let () =
    (* Call [emit_frame_enter] for everything in the initial callstack. This takes care of
       entering any root frames that we discovered by returning into them (i.e. the places
       where we call [emplace_root]). *)
    let%tydi #{ leaf; time; _ } = Nonempty_vec.first t.callstacks in
    Frame.iter_n_rev leaf Int.max_value ~f:(stack_ fun frame ->
      Writer.emit_frame_enter writer time frame)
  in
  Nonempty_vec.iter_pairs
    t.callstacks
    ~f:(stack_ fun (#(prev, curr) : #(Callstack.t * Callstack.t)) ->
      let time = curr.#time in
      match curr.#control_flow with
      | Call { depth } ->
        Frame.iter_n_rev curr.#leaf depth ~f:(stack_ fun frame ->
          Writer.emit_frame_enter writer time frame)
        [@nontail]
      | Return { distance } ->
        Frame.iter_n prev.#leaf distance ~f:(stack_ fun frame ->
          Writer.emit_frame_exit writer time frame)
        [@nontail]);
  let () =
    (* Call [emit_frame_exit] for all remaining frames at the end of the segment. *)
    let last_callstack = Nonempty_vec.last t.callstacks in
    Frame.iter_n last_callstack.#leaf Int.max_value ~f:(stack_ fun frame ->
      Writer.emit_frame_exit writer last_callstack.#time frame)
    [@nontail]
  in
  ()
;;

module%test _ = struct
  (* Takes a string like "a-b-c-d-e" which describes a callstack in root-to-leaf order,
     each letter being a function name. *)
  let parse_frames string =
    let root = Frame.Sentinel.create () in
    let leaf =
      String.split string ~on:'-'
      |> List.fold
           ~init:(root :> Frame.t)
           ~f:(fun root leaf_name ->
             Frame.create
               Location.
                 { symbol_offset = 0
                 ; instruction_pointer = 0L
                 ; symbol = From_perf leaf_name
                 ; dso = Null
                 }
               ~parent:root
               ~kind:Physical)
    in
    #(~root, ~leaf)
  ;;

  (* Throughout this test-suite, things are rendered vertically in the same way they'd
     appear in the Perfetto viewer. *)

  let print_frame_callstack = Frame.For_testing.print_callstack

  let%expect_test "[parse_frames] utility" =
    let #(~root:_, ~leaf) = parse_frames "a-b-c-d-e" in
    print_frame_callstack leaf;
    [%expect {|
      a
      b
      c
      d
      e
      |}]
  ;;

  module%test Smear_times = struct
    let create_callstacks_with_control_flow (items : (int * Control_flow.t) list)
      : Callstack.t Nonempty_vec.t
      =
      let #(~root:_, ~leaf) = parse_frames "a" in
      match items with
      | [] -> assert false
      | (first_time, first_cf) :: rest ->
        let vec =
          Nonempty_vec.create
            (#{ time = Timestamp.create (Time_ns.Span.of_int_ns first_time)
              ; leaf
              ; control_flow = first_cf
              }
             : Callstack.t)
        in
        List.iter rest ~f:(fun (t, cf) ->
          Nonempty_vec.push_back
            vec
            (#{ time = Timestamp.create (Time_ns.Span.of_int_ns t)
              ; leaf
              ; control_flow = cf
              }
             : Callstack.t));
        vec
    ;;

    let create_callstacks (times : int list) : Callstack.t Nonempty_vec.t =
      List.map ~f:(fun time -> time, Control_flow.Call { depth = 1 }) times
      |> create_callstacks_with_control_flow
    ;;

    let print_times (callstacks : Callstack.t Nonempty_vec.t) =
      Nonempty_vec.iter callstacks ~f:(fun (cs : Callstack.t) ->
        printf "%2d " (Time_ns.Span.to_int_ns (cs.#time :> Time_ns.Span.t)));
      print_endline ""
    ;;

    let%expect_test "[smear_times] with all different timestamps (no smearing needed)" =
      let callstacks = create_callstacks [ 0; 10; 20; 30 ] in
      print_times callstacks;
      [%expect {|  0 10 20 30 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 10 20 30 |}]
    ;;

    let%expect_test "[smear_times] with consecutive same timestamps" =
      let callstacks = create_callstacks [ 0; 0; 0; 30 ] in
      print_times callstacks;
      [%expect {|  0  0  0 30 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 10 20 30 |}]
    ;;

    let%expect_test "[smear_times] with multiple runs of same timestamps" =
      let callstacks = create_callstacks [ 0; 0; 20; 20; 20; 50 ] in
      print_times callstacks;
      [%expect {|  0  0 20 20 20 50 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 10 20 30 40 50 |}]
    ;;

    let%expect_test "[smear_times] final run keeps original time" =
      let callstacks = create_callstacks [ 0; 0; 30; 30; 30 ] in
      print_times callstacks;
      [%expect {|  0  0 30 30 30 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 15 30 30 30 |}]
    ;;

    let%expect_test "[smear_times] single event" =
      let callstacks = create_callstacks [ 100 ] in
      print_times callstacks;
      [%expect {| 100 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {| 100 |}]
    ;;

    let%expect_test "[smear_times] all same timestamp (final run)" =
      let callstacks = create_callstacks [ 50; 50; 50 ] in
      print_times callstacks;
      [%expect {| 50 50 50 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {| 50 50 50 |}]
    ;;

    let%expect_test "[smear_times] only Call events consume time" =
      let callstacks =
        create_callstacks_with_control_flow
          [ 0, Return { distance = 1 }
          ; 0, Call { depth = 1 }
          ; 0, Return { distance = 1 }
          ; 0, Call { depth = 1 }
          ; 100, Call { depth = 1 }
          ]
      in
      print_times callstacks;
      [%expect {|  0  0  0  0 100 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0  0 50 50 100 |}]
    ;;

    let%expect_test "[smear_times] first event is a Call" =
      let callstacks =
        create_callstacks_with_control_flow
          [ 0, Call { depth = 1 }
          ; 0, Return { distance = 1 }
          ; 0, Call { depth = 1 }
          ; 90, Call { depth = 1 }
          ]
      in
      print_times callstacks;
      [%expect {|  0  0  0 90 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0 45 45 90 |}]
    ;;

    let%expect_test "[smear_times] only Returns uses fallback" =
      let callstacks =
        create_callstacks_with_control_flow
          [ 0, Return { distance = 1 }
          ; 0, Return { distance = 1 }
          ; 0, Return { distance = 1 }
          ; 90, Call { depth = 1 }
          ]
      in
      print_times callstacks;
      [%expect {|  0  0  0 90 |}];
      smear_times callstacks;
      print_times callstacks;
      [%expect {|  0  0  0 90 |}]
    ;;
  end

  let setup_test () =
    let t = create None in
    let ip = ref (-1) in
    let time = ref Time_ns.Span.zero in
    let incr_time () = time := Time_ns.Span.(!time + of_int_ns 1) in
    let location (name : string) : Location.t =
      incr ip;
      Location.
        { instruction_pointer = Int64.of_int !ip
        ; symbol_offset = 0
        ; symbol = From_perf name
        ; dso = Null
        }
    in
    let call ~src ~dst =
      incr_time ();
      let event =
        Event.Ok.Data.Trace
          { kind = Some Call
          ; src = location src
          ; dst = location dst
          ; trace_state_change = None
          }
      in
      add_event t event (Timestamp.create !time)
    in
    let return ~src ~dst =
      incr_time ();
      let event =
        Event.Ok.Data.Trace
          { kind = Some Return
          ; src = location src
          ; dst = location dst
          ; trace_state_change = None
          }
      in
      add_event t event (Timestamp.create !time)
    in
    let jump ~src ~dst =
      incr_time ();
      let event =
        Event.Ok.Data.Trace
          { kind = Some Jump
          ; src = location src
          ; dst = location dst
          ; trace_state_change = None
          }
      in
      add_event t event (Timestamp.create !time)
    in
    #(~t, ~call, ~return, ~jump)
  ;;

  let frames_to_list t =
    let result = ref [] in
    Nonempty_vec.iter t.callstacks ~f:(fun (cs : Callstack.t) ->
      result := cs.#leaf :: !result);
    List.rev !result
  ;;

  let concat_horizontal (lists : string list list) : string =
    let max_len =
      List.fold lists ~init:0 ~f:(fun acc lst -> Int.max acc (List.length lst))
    in
    let width = 20 in
    List.init max_len ~f:(fun row_idx ->
      List.map lists ~f:(fun lst ->
        let s = List.nth lst row_idx |> Option.value ~default:"" in
        sprintf "%-*s" width s)
      |> String.concat)
    |> String.concat ~sep:"\n"
  ;;

  let print_callstacks (t : t) =
    frames_to_list t
    (* Skip the initial sentinel callstack *)
    |> List.tl
    |> Option.value ~default:[]
    |> List.map ~f:(fun frame -> Frame.For_testing.to_string_list frame)
    |> concat_horizontal
    |> print_endline;
    (* So that the closing |}] of the [%expect ...] block is on its own line. *)
    print_endline "-"
  ;;

  (* In all of the following examples, unless otherwise specified assume no
     tail-call-optimization is performed. *)

  (*=
       let fn2 () = ()
       let fn3 () = ()

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = fn1 ()
    *)
  let%expect_test "Sanity-check [add_event]" =
    let #(~t, ~call, ~return, ~jump:_) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn3";
    (* Return from [fn3] *)
    return ~src:"fn3" ~dst:"fn1";
    (* Return from [fn1] *)
    return ~src:"fn1" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}]
  ;;

  (*=
       Assume we started tracing during the execution of [main] so we never saw the calls to [start] or [init]

       let fn2 () = ()
       let fn3 () = ()

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = fn1 ()

       let start () = main ()
       let init () = start ()
    *)
  let%expect_test "A return to a function we never saw the call for" =
    let #(~t, ~call, ~return, ~jump:_) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn3";
    return ~src:"fn3" ~dst:"fn1";
    return ~src:"fn1" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}];
    (* Return for a call we didn't see *)
    return ~src:"main" ~dst:"start";
    print_callstacks t;
    [%expect
      {|
      start               start               start               start               start               start               start               start
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}];
    (* Another return for a call we didn't see *)
    return ~src:"start" ~dst:"init";
    print_callstacks t;
    [%expect
      {|
      init                init                init                init                init                init                init                init                init
      start               start               start               start               start               start               start               start
      main                main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}]
  ;;

  (*=
       let fn2 () = ()
       let fn3 () = raise Failure

       let fn1 () =
         fn2 ()
         fn3 ()
       ;;

       let main () = try fn1 () with _ -> ()
       *)
  let%expect_test "Return multiple levels up the stack" =
    let #(~t, ~call, ~return, ~jump:_) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"fn1";
    call ~src:"fn1" ~dst:"fn3";
    (* Raise from [fn3] into the [try] in [main] *)
    return ~src:"fn3" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main                main
                          fn1                 fn1                 fn1                 fn1
                                              fn2                                     fn3
      -
      |}]
  ;;

  (*=
       let fn1 () =
         if something then do_something else do_something_else
       ;;

       let main () = fn1 ()
       *)
  let%expect_test "Simple jumps within a function" =
    let #(~t, ~call, ~return, ~jump) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    jump ~src:"fn1" ~dst:"fn1";
    return ~src:"fn1" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main
                          fn1
      -
      |}]
  ;;

  (*=

       let fn2 () = ()
       let fn1 () = fn2() [@tail]

       let main () = fn1 ()
       *)
  let%expect_test "Tail-call" =
    let #(~t, ~call, ~return, ~jump) = setup_test () in
    call ~src:"main" ~dst:"fn1";
    (* Tail-call [fn2] from [fn1] *)
    jump ~src:"fn1" ~dst:"fn2";
    return ~src:"fn2" ~dst:"main";
    print_callstacks t;
    [%expect
      {|
      main                main                main                main                main
                          fn1                                     fn2
      -
      |}]
  ;;
end
