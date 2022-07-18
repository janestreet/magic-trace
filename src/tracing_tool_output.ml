open! Core
open! Async

module Serve = struct
  type enabled =
    { port : int
    ; perfetto_ui_base_directory : string
    }

  type t =
    | Disabled
    | Enabled of enabled

  let param =
    match Env_vars.perfetto_dir with
    | None -> Command.Param.return Disabled
    | Some perfetto_ui_base_directory ->
      let%map_open.Command serve =
        flag "serve" no_arg ~doc:" Host the magic-trace UI locally."
      and port =
        let default = 8080 in
        flag
          "serve-port"
          (optional_with_default default int)
          ~doc:
            [%string
              "PORT Chooses the port that the local copy of the magic-trace UI will be \
               served on if [-serve] is specified. (default: %{default#Int})"]
      in
      if serve then Enabled { port; perfetto_ui_base_directory } else Disabled
  ;;

  let url t =
    let host = Unix.gethostname () in
    Uri.to_string (Uri.make ~scheme:"http" ~host ~port:t.port ())
  ;;

  let request_path req =
    let uri = Cohttp_async.Request.uri req in
    Uri.path uri
  ;;

  let respond_string ~content_type ?flush ?headers ?status s =
    let headers = Cohttp.Header.add_opt headers "Content-Type" content_type in
    Cohttp_async.Server.respond_string ?flush ~headers ?status s
  ;;

  let respond_index t ~filename =
    respond_string
      ~content_type:"text/html"
      ~status:`OK
      [%string
        {|
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8">
    <title>%{filename} - magic-trace</title>
    <link rel="shortcut icon" href="/ui/favicon.png">
  </head>
  <body>
    <iframe
      src="/ui/index.html#!/viewer?url=%{url t}/trace/%{filename}"
      style="
        position: fixed;
        border: none;
        top: 0px;
        bottom: 0px;
        right: 0px;
        margin: 0;
        padding: 0;
        width: 100%;
        height: 100%;
      ">
    </iframe>
  </body>
  </html>
    |}]
  ;;

  let serve_trace_file t ~filename ~store_path =
    let static_handler =
      Cohttp_static_handler.directory_handler ~directory:t.perfetto_ui_base_directory ()
    in
    let handler ~body addr request =
      let path = request_path request in
      (* Uncomment this to debug routing *)
      Core.printf "%s\n%!" path;
      match path with
      | "" | "/" | "/index.html" -> respond_index t ~filename
      (* Serve the trace under any name under /trace/ so only the HTML has to change *)
      | s when String.is_prefix s ~prefix:"/trace/" ->
        let headers =
          Cohttp.Header.add_opt None "Content-Type" "application/octet-stream"
        in
        Cohttp_async.Server.respond_with_file ~headers store_path
      | _ -> static_handler ~body addr request
    in
    let where_to_listen =
      Tcp.Where_to_listen.bind_to Tcp.Bind_to_address.All_addresses (On_port t.port)
    in
    let open Deferred.Or_error.Let_syntax in
    let%bind server =
      Cohttp_async.Server.create ~on_handler_error:`Raise where_to_listen handler
      |> Deferred.ok
    in
    let stop = Cohttp_async.Server.close_finished server in
    Async_unix.Signal.handle ~stop [ Signal.int ] ~f:(fun (_ : Signal.t) ->
        Cohttp_async.Server.close server |> don't_wait_for);
    Core.eprintf "Open %s to view the %s in Perfetto!\n%!" (url t) filename;
    stop |> Deferred.ok
  ;;
end

type t =
  { serve : Serve.t
  ; output : [ `Fuchsia of string | `Sexp of string ]
  }
[@@deriving fields]

let store_path = function
  | `Fuchsia store_path | `Sexp store_path -> store_path
;;

let param =
  let%map_open.Command store_path =
    let default = "trace.fxt" in
    flag
      "output"
      (optional_with_default default string)
      ~aliases:[ "o" ]
      ~doc:[%string "FILE Where to output the trace. (default: '%{default}')"]
  and serve = Serve.param in
  let output =
    match String.is_suffix ~suffix:".sexp" store_path with
    | true -> `Sexp store_path
    | false -> `Fuchsia store_path
  in
  (match serve, output with
  | Enabled _, `Sexp _ -> raise_s [%message "cannot serve .sexp output"]
  | _ -> ());
  { serve; output }
;;

let notify_trace ~store_path =
  Core.eprintf "Visit https://magic-trace.org/ and open %s to view trace.\n%!" store_path;
  Deferred.Or_error.ok_unit
;;

let maybe_stash_old_trace ~filename =
  (* Replicate [perf]'s behavior when the output file already exists. *)
  try Core_unix.rename ~src:filename ~dst:(filename ^ ".old") with
  | Core_unix.Unix_error (ENOENT, (_ : string), (_ : string)) -> ()
;;

let write_and_maybe_serve ?num_temp_strs t ~filename ~f_sexp ~f_fuchsia =
  let open Deferred.Or_error.Let_syntax in
  maybe_stash_old_trace ~filename;
  match t.output with
  | `Sexp store_path -> Writer.with_file_atomic store_path ~f:f_sexp
  | `Fuchsia store_path ->
    let fd = Core_unix.openfile store_path ~mode:[ O_RDWR; O_CREAT; O_CLOEXEC ] in
    (* Write to and serve from an indirect reference to [store_path], through our process'
     fd table. This is a little grotesque, but avoids a race where the user runs
     magic-trace twice with the same [-output], such that the filename changes under
     [-serve] -- without this hack, the earlier magic-trace serving instance would start
     serving the new trace, which is unlikely to be what the user expected. *)
    let indirect_store_path = [%string "/proc/self/fd/%{fd#Core_unix.File_descr}"] in
    let w =
      Tracing_zero.Writer.create_for_file ?num_temp_strs ~filename:indirect_store_path ()
    in
    let%bind res = f_fuchsia w in
    let%map () =
      match t.serve with
      | Disabled -> notify_trace ~store_path
      | Enabled serve ->
        Serve.serve_trace_file serve ~filename ~store_path:indirect_store_path
    in
    Core_unix.close fd;
    res
;;

let write_and_maybe_view ?num_temp_strs t ~f_sexp ~f_fuchsia =
  let filename = Filename.basename (store_path t.output) in
  write_and_maybe_serve ?num_temp_strs t ~filename ~f_sexp ~f_fuchsia
;;
