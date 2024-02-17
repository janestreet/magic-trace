open! Core
open! Async

type t = Perf_map_location.t Int64.Map.t

let perf_map_re =
  (* Example: 3a6caa49c2e f3 LazyCompile:~afterInspector node:internal/errors:753

     Not every runtime contains the file and line, so let's just call all of that stuff the name.
     That matches the spec linked in the mli.
  *)
  Re.Posix.re {|^([0-9a-fA-F]+) ([0-9a-fA-F]+) (.*)$|} |> Re.compile
;;

let parse_line line =
  (* empty string for the last line in a file *)
  if String.is_empty line
  then None
  else (
    try
      match Re.Group.all (Re.exec perf_map_re line) with
      | [| _; start_addr; size; function_ |] ->
        let start_addr = Util.int64_of_hex_string start_addr in
        ( start_addr
        , { Perf_map_location.start_addr
          ; size = Util.int_trunc_of_hex_string size
          ; function_
          } )
        |> Some
      | _ -> failwith "doesn't match regex"
    with
    | exn ->
      raise_s
        [%message
          "error scanning perf map, please add this line to a test in perf_map.ml"
            (exn : exn)
            (line : string)])
;;

let%test_module _ =
  (module struct
    open Core

    let%expect_test "example perf map" =
      let sample =
        {|3a6caa49c2e f3 LazyCompile:~afterInspector node:internal/errors:753
3a6caa49e86 1e LazyCompile:~lazyInternalUtilInspect node:internal/errors:185
3a6caa4a5fe 5 Eval:~ node:internal/tty:1
3a6caa4aa5e 166 Function:~ node:internal/tty:1
3a6caa4b536 3f LazyCompile:~hasColors node:internal/tty:222
3a6caa4c3ae 2fa LazyCompile:~getColorDepth node:internal/tty:106
3a6caa4c90e 5 LazyCompile:~get node:internal/util/inspect:352
3a6caa5142e 18b LazyCompile:~inspect node:internal/util/inspect:292
3a6caa51926 1cf LazyCompile:~formatValue node:internal/util/inspect:745
3a6caa5241e cfd LazyCompile:~formatRaw node:internal/util/inspect:820
3a6caa537c6 13f LazyCompile:~getConstructorName node:internal/util/inspect:567
3a6caa53a96 d LazyCompile:~isInstanceof node:internal/util/inspect:559
00007F5D97BCAE50 22 instance void [System.Private.CoreLib] System.Collections.Generic.Dictionary`2[System.__Canon,System.Double]::.ctor()[QuickJitted]
00007F5D97BCAD40 10 stub<1023> AllocateTemporaryEntryPoints<PRECODE_FIXUP>
00007F5D97BCAD58 48 stub<1024> AllocateTemporaryEntryPoints<PRECODE_FIXUP>
00007F5D97BCAE90 1b4 instance void [System.Private.CoreLib] System.Collections.Generic.Dictionary`2[System.__Canon,System.Double]::.ctor(int32,class System.Collections.Generic.IEqualityComparer`1<!0>)[QuickJitted]
|}
      in
      String.split sample ~on:'\n'
      |> List.map ~f:(fun line -> line, parse_line line)
      |> [%sexp_of: (string * (Int64.Hex.t * Perf_map_location.t) option) list]
      |> print_s;
      [%expect
        {|
        (("3a6caa49c2e f3 LazyCompile:~afterInspector node:internal/errors:753"
          ((0x3a6caa49c2e
            ((start_addr 0x3a6caa49c2e) (size 0xf3)
             (function_ "LazyCompile:~afterInspector node:internal/errors:753")))))
         ("3a6caa49e86 1e LazyCompile:~lazyInternalUtilInspect node:internal/errors:185"
          ((0x3a6caa49e86
            ((start_addr 0x3a6caa49e86) (size 0x1e)
             (function_
              "LazyCompile:~lazyInternalUtilInspect node:internal/errors:185")))))
         ("3a6caa4a5fe 5 Eval:~ node:internal/tty:1"
          ((0x3a6caa4a5fe
            ((start_addr 0x3a6caa4a5fe) (size 0x5)
             (function_ "Eval:~ node:internal/tty:1")))))
         ("3a6caa4aa5e 166 Function:~ node:internal/tty:1"
          ((0x3a6caa4aa5e
            ((start_addr 0x3a6caa4aa5e) (size 0x166)
             (function_ "Function:~ node:internal/tty:1")))))
         ("3a6caa4b536 3f LazyCompile:~hasColors node:internal/tty:222"
          ((0x3a6caa4b536
            ((start_addr 0x3a6caa4b536) (size 0x3f)
             (function_ "LazyCompile:~hasColors node:internal/tty:222")))))
         ("3a6caa4c3ae 2fa LazyCompile:~getColorDepth node:internal/tty:106"
          ((0x3a6caa4c3ae
            ((start_addr 0x3a6caa4c3ae) (size 0x2fa)
             (function_ "LazyCompile:~getColorDepth node:internal/tty:106")))))
         ("3a6caa4c90e 5 LazyCompile:~get node:internal/util/inspect:352"
          ((0x3a6caa4c90e
            ((start_addr 0x3a6caa4c90e) (size 0x5)
             (function_ "LazyCompile:~get node:internal/util/inspect:352")))))
         ("3a6caa5142e 18b LazyCompile:~inspect node:internal/util/inspect:292"
          ((0x3a6caa5142e
            ((start_addr 0x3a6caa5142e) (size 0x18b)
             (function_ "LazyCompile:~inspect node:internal/util/inspect:292")))))
         ("3a6caa51926 1cf LazyCompile:~formatValue node:internal/util/inspect:745"
          ((0x3a6caa51926
            ((start_addr 0x3a6caa51926) (size 0x1cf)
             (function_ "LazyCompile:~formatValue node:internal/util/inspect:745")))))
         ("3a6caa5241e cfd LazyCompile:~formatRaw node:internal/util/inspect:820"
          ((0x3a6caa5241e
            ((start_addr 0x3a6caa5241e) (size 0xcfd)
             (function_ "LazyCompile:~formatRaw node:internal/util/inspect:820")))))
         ("3a6caa537c6 13f LazyCompile:~getConstructorName node:internal/util/inspect:567"
          ((0x3a6caa537c6
            ((start_addr 0x3a6caa537c6) (size 0x13f)
             (function_
              "LazyCompile:~getConstructorName node:internal/util/inspect:567")))))
         ("3a6caa53a96 d LazyCompile:~isInstanceof node:internal/util/inspect:559"
          ((0x3a6caa53a96
            ((start_addr 0x3a6caa53a96) (size 0xd)
             (function_ "LazyCompile:~isInstanceof node:internal/util/inspect:559")))))
         ("00007F5D97BCAE50 22 instance void [System.Private.CoreLib] System.Collections.Generic.Dictionary`2[System.__Canon,System.Double]::.ctor()[QuickJitted]"
          ((0x7f5d97bcae50
            ((start_addr 0x7f5d97bcae50) (size 0x22)
             (function_
              "instance void [System.Private.CoreLib] System.Collections.Generic.Dictionary`2[System.__Canon,System.Double]::.ctor()[QuickJitted]")))))
         ("00007F5D97BCAD40 10 stub<1023> AllocateTemporaryEntryPoints<PRECODE_FIXUP>"
          ((0x7f5d97bcad40
            ((start_addr 0x7f5d97bcad40) (size 0x10)
             (function_ "stub<1023> AllocateTemporaryEntryPoints<PRECODE_FIXUP>")))))
         ("00007F5D97BCAD58 48 stub<1024> AllocateTemporaryEntryPoints<PRECODE_FIXUP>"
          ((0x7f5d97bcad58
            ((start_addr 0x7f5d97bcad58) (size 0x48)
             (function_ "stub<1024> AllocateTemporaryEntryPoints<PRECODE_FIXUP>")))))
         ("00007F5D97BCAE90 1b4 instance void [System.Private.CoreLib] System.Collections.Generic.Dictionary`2[System.__Canon,System.Double]::.ctor(int32,class System.Collections.Generic.IEqualityComparer`1<!0>)[QuickJitted]"
          ((0x7f5d97bcae90
            ((start_addr 0x7f5d97bcae90) (size 0x1b4)
             (function_
              "instance void [System.Private.CoreLib] System.Collections.Generic.Dictionary`2[System.__Canon,System.Double]::.ctor(int32,class System.Collections.Generic.IEqualityComparer`1<!0>)[QuickJitted]")))))
         ("" ())) |}]
    ;;
  end)
;;

let default_filename_re = Re.Perl.re {|^perf-([0-9]+)\.map$|} |> Re.compile
let default_filename ~pid = [%string "/tmp/perf-%{pid#Pid}.map"]

let pid_of_filename filename =
  try
    Re.Group.get (Re.exec default_filename_re (Filename.basename filename)) 1
    |> Pid.of_string
  with
  | _ ->
    raise_s [%message "Perf map filename did not match default format [perf-%{pid}.map]"]
;;

let%expect_test "pid_of_filename success" =
  print_s [%message "" ~pid:(pid_of_filename "/tmp/perf-512.map" : Pid.t)];
  [%expect {| (pid 512) |}] |> Deferred.return
;;

let%expect_test "pid_of_filename failure 1" =
  Expect_test_helpers_core.require_does_raise [%here] (fun () ->
    print_s [%message "" ~pid:(pid_of_filename "/tmp/per-512.map" : Pid.t)]);
  [%expect {| "Perf map filename did not match default format [perf-%{pid}.map]" |}]
  |> Deferred.return
;;

let%expect_test "pid_of_filename failure 2" =
  Expect_test_helpers_core.require_does_raise [%here] (fun () ->
    print_s [%message "" ~pid:(pid_of_filename "/tmp/perf-512" : Pid.t)]);
  [%expect {| "Perf map filename did not match default format [perf-%{pid}.map]" |}]
  |> Deferred.return
;;

let map_of_sequence_prefer_later sequence =
  Sequence.fold sequence ~init:Int64.Map.empty ~f:(fun map (key, data) ->
    Map.set map ~key ~data)
;;

let load file_location =
  let%map lines =
    Monitor.try_with_or_error ~rest:`Log (fun () -> Reader.file_lines file_location)
  in
  match lines with
  | Error _ ->
    (* There's no perf.map file detected -- this probably isn 't a JITed executable. *)
    None
  | Ok lines ->
    Sequence.of_list lines
    |> Sequence.filter_map ~f:parse_line
    (* There can be duplicate entries in these files as JITs reuse code that is no longer useful
       in favor of newly compiled code. (e.g. V8 does this). *)
    |> map_of_sequence_prefer_later
    |> Some
;;

let symbol (t : t) ~addr =
  (* This assumes that code for functions can't be inside each other. If that
     assumption is violated, this will attribute code inside both functions to the one with the
     greater address. *)
  match Map.closest_key t `Less_or_equal_to addr with
  | None -> None
  | Some (_, location) ->
    assert (Int64.(location.start_addr <= addr));
    Option.some_if Int64.(location.start_addr + of_int location.size < addr) location
;;

module Table = struct
  type nonrec t = (Pid.t, t) Hashtbl.t

  let create maps =
    List.filter_map maps ~f:(function
      | _, None -> None
      | pid, Some map -> Some (pid, map))
    |> Hashtbl.of_alist_exn (module Pid)
  ;;

  let load_by_files files =
    Deferred.List.map files ~how:`Sequential ~f:(fun filename ->
      load filename |> Deferred.map ~f:(fun map -> pid_of_filename filename, map))
    >>| create
  ;;

  let load_by_pids pids =
    Deferred.List.map pids ~how:`Sequential ~f:(fun pid ->
      load (default_filename ~pid) |> Deferred.map ~f:(fun map -> pid, map))
    >>| create
  ;;

  let symbol t ~pid ~addr =
    match Hashtbl.find t pid with
    | None -> None
    | Some map -> symbol map ~addr
  ;;
end
