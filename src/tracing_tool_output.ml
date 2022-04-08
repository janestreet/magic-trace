open! Core
open! Async

module Serve = struct
  type t =
    { port : int
    ; perfetto_ui_base_directory : string
    }

  let maybe_param =
    Option.map Env_vars.perfetto_ui_base_directory ~f:(fun perfetto_ui_base_directory ->
        let port = 8080 in
        let%map_open.Command serve =
          flag
            "serve"
            no_arg
            ~doc:[%string " Serves the magic-trace UI on port %{port#Int})"]
        in
        if serve then Some { port; perfetto_ui_base_directory } else None)
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
      (* Core.printf "%s\n%!" path; *)
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

module Share = struct
  type t = { share_command_filename : string }

  let maybe_param =
    Option.map Env_vars.share_command_filename ~f:(fun share_command_filename ->
        let%map_open.Command share = flag "share" no_arg ~doc:"Share trace." in
        if share then Some { share_command_filename } else None)
  ;;

  let share_trace_file { share_command_filename } ~store_path =
    let%map.Deferred.Or_error output =
      Process.run
        ~prog:share_command_filename
        ~args:[ Filename_unix.realpath store_path ]
        ()
    in
    Core.printf "%s%!" output
  ;;
end

module Display_mode = struct
  type t =
    | Serve of Serve.t
    | Share of Share.t
    | Disabled
end

type t =
  { display_mode : Display_mode.t
  ; store_path : string
  }

let param =
  let%map_open.Command store_path =
    let default = "trace.ftf" in
    flag
      "output"
      (optional_with_default default string)
      ~aliases:[ "o" ]
      ~doc:[%string "FILE Where to output the trace. (default: '%{default}')"]
  and display_mode =
    [ Serve.maybe_param
      |> Option.map ~f:(map ~f:(Option.map ~f:(fun serve -> Display_mode.Serve serve)))
    ; Share.maybe_param
      |> Option.map ~f:(map ~f:(Option.map ~f:(fun share -> Display_mode.Share share)))
    ]
    |> List.filter_opt
    |> choose_one ~if_nothing_chosen:(Default_to Display_mode.Disabled)
  in
  { display_mode; store_path }
;;

let notify_trace ~store_path =
  Core.eprintf "Visit https://magic-trace.org/ and open %s to view trace.\n%!" store_path;
  Deferred.Or_error.ok_unit
;;

let maybe_serve t ~filename =
  match t.display_mode with
  | Disabled -> notify_trace ~store_path:t.store_path
  | Serve serve -> Serve.serve_trace_file serve ~filename ~store_path:t.store_path
  | Share share -> Share.share_trace_file share ~store_path:t.store_path
;;

let maybe_stash_old_trace ~filename =
  (* Replicate [perf]'s behavior when the output file already exists. *)
  try Core_unix.rename ~src:filename ~dst:(filename ^ ".old") with
  | Core_unix.Unix_error (ENOENT, (_ : string), (_ : string)) -> ()
;;

let write_and_maybe_serve ?num_temp_strs t ~filename ~f =
  let open Deferred.Or_error.Let_syntax in
  maybe_stash_old_trace ~filename;
  let w = Tracing_zero.Writer.create_for_file ?num_temp_strs ~filename:t.store_path () in
  let%bind res = f w in
  let%map () = maybe_serve t ~filename in
  res
;;

let write_and_maybe_view ?num_temp_strs t ~f =
  let filename = Filename.basename t.store_path in
  write_and_maybe_serve ?num_temp_strs t ~filename ~f
;;
