open! Core

let direct_file_destination ?(buffer_size = 4096 * 16) ~filename () =
  let buf = Iobuf.create ~len:buffer_size in
  let file = Core_unix.openfile ~mode:[ O_CREAT; O_TRUNC; O_RDWR ] filename in
  let written = ref 0 in
  let flush () =
    Iobuf.rewind buf;
    Iobuf.advance buf !written;
    Iobuf.flip_lo buf;
    Iobuf_unix.write buf file;
    written := 0;
    Iobuf.reset buf
  in
  let module Dest = struct
    let next_buf ~ensure_capacity =
      flush ();
      if ensure_capacity > Iobuf.length buf
      then failwith "Not enough buffer space in [direct_file_destination]";
      buf
    ;;

    let wrote_bytes count = written := !written + count

    let close () =
      flush ();
      Core_unix.close file
    ;;
  end
  in
  (module Dest : Writer_intf.Destination)
;;

(* While Zstandard has the best compression, perfetto does not yet understand the format. *)
let zstd_file_destination ?(buffer_size = 64 * 1024) ~filename () =
  let buf = Iobuf.create ~len:buffer_size in
  let compression_level = 5 in
  (* Ensure the compression buffer is large enough for the worst case of an input of
     [buffer_size]. *)
  let compressed_buf =
    let len =
      buffer_size
      |> Int64.of_int
      |> Zstandard.compression_output_size_bound
      |> Int64.to_int_exn
    in
    Iobuf.create ~len
  in
  let file = Core_unix.openfile ~mode:[ O_CREAT; O_TRUNC; O_CLOEXEC; O_RDWR ] filename in
  let written = ref 0 in
  let compression_context = Zstandard.Compression_context.create () in
  let flush () =
    Iobuf.rewind buf;
    Iobuf.advance buf !written;
    Iobuf.flip_lo buf;
    let input =
      Zstandard.Input.from_bigstring
        ~pos:(Iobuf.Expert.lo buf)
        ~len:(Iobuf.length buf)
        (Iobuf.Expert.buf buf)
    in
    let output =
      Zstandard.Output.in_buffer
        ~pos:(Iobuf.Expert.lo compressed_buf)
        ~len:(Iobuf.length compressed_buf)
        (Iobuf.Expert.buf compressed_buf)
    in
    let compressed_length =
      Zstandard.With_explicit_context.compress
        compression_context
        ~compression_level
        ~input
        ~output
    in
    Iobuf.advance compressed_buf compressed_length;
    Iobuf.flip_lo compressed_buf;
    Iobuf_unix.write compressed_buf file;
    written := 0;
    Iobuf.reset buf;
    Iobuf.reset compressed_buf
  in
  let module Dest = struct
    let next_buf ~ensure_capacity =
      flush ();
      if ensure_capacity > Iobuf.length buf
      then failwith "Not enough buffer space in [zstd_file_destination]";
      buf
    ;;

    let wrote_bytes count = written := !written + count

    let close () =
      flush ();
      Zstandard.Compression_context.free compression_context;
      Core_unix.close file
    ;;
  end
  in
  (module Dest : Writer_intf.Destination)
;;

let gzip_file_destination ?(buffer_size = 64 * 1024) ~filename () =
  let buf = Iobuf.create ~len:buffer_size in
  let bytes = Bytes.create buffer_size in
  let file = Core_unix.openfile ~mode:[ O_CREAT; O_TRUNC; O_CLOEXEC; O_RDWR ] filename in
  let out_channel =
    let oc = Core_unix.out_channel_of_descr file in
    (* Consider making the compression level an environment variable for
       experimentation. *)
    Gzip.open_out_chan ~level:6 oc
  in
  let written = ref 0 in
  let flush () =
    Iobuf.rewind buf;
    Iobuf.advance buf !written;
    Iobuf.flip_lo buf;
    Iobuf.Peek.To_bytes.blit
      ~src:(Iobuf.read_only buf) ~src_pos:0 ~dst:bytes ~dst_pos:0 ~len:!written;
    Gzip.output out_channel bytes 0 !written;
    written := 0;
    Iobuf.reset buf;
  in
  let module Dest = struct
    let next_buf ~ensure_capacity =
      flush ();
      if ensure_capacity > Iobuf.length buf
      then failwith "Not enough buffer space in [gzip_file_destination]";
      buf
    ;;

    let wrote_bytes count = written := !written + count

    let close () =
      flush ();
      (* [close_out] also closes the underlying file descr. *)
      Gzip.close_out out_channel
    ;;
  end
  in
  (module Dest : Writer_intf.Destination)
;;

let file_destination ?(file_format = Writer_intf.File_format.Uncompressed) ~filename () =
  match file_format with
  | Uncompressed -> direct_file_destination ~filename ()
  | Gzip -> gzip_file_destination ~filename ()
  | Zstandard -> zstd_file_destination ~filename ()
;;

let iobuf_destination buf =
  (* We give out an [Iobuf] with a shared underlying [Bigstring] but different pointers
     so that when this is closed the provided buffer keeps its window, and we can test
     the [Buffer_until_initialized] feature to ignore writes after close.

     This also ensures our logic works when the window of [buf] is narrower than the
     limits because [sub_shared] leads to a buffer with equal window and limits. *)
  let provided_buf = Iobuf.sub_shared buf in
  let total_written = ref 0 in
  (* Ensure we update the length of the buffer based on [wrote_bytes]
     and thus test that things are calling it correctly. *)
  let set_cur_length () =
    Iobuf.rewind provided_buf;
    Iobuf.advance provided_buf !total_written
  in
  let module Dest = struct
    (* [next_buf] can be called multiple times even without running out of room, for
       example via [Writer.Expert.force_switch_buffers]. But we can just keep giving back
       the same buffer as long as it has room *)
    let next_buf ~ensure_capacity =
      if ensure_capacity > Iobuf.length provided_buf
      then failwith "No more room in [iobuf_destination]";
      provided_buf
    ;;

    let wrote_bytes count =
      total_written := !total_written + count;
      set_cur_length ()
    ;;

    let close () =
      set_cur_length ();
      (* Now that it's closed we set the bounds on the buffer we were originally given to
         match the total length of everything written. *)
      Iobuf.resize buf ~len:!total_written
    ;;
  end
  in
  (module Dest : Writer_intf.Destination)
;;

let black_hole_destination ~len ~touch_memory =
  let buf = Iobuf.create ~len in
  if touch_memory then Iobuf.zero buf;
  let module Dest = struct
    let next_buf ~ensure_capacity =
      Iobuf.reset buf;
      if ensure_capacity > Iobuf.length buf
      then failwith "Record too large for [black_hole_destination]";
      buf
    ;;

    let wrote_bytes _count = ()
    let close () = ()
  end
  in
  (module Dest : Writer_intf.Destination)
;;

(* A [Destination] which keeps buffers it gives out in a list and is able to write the
   contents of those buffers to another [Destination]. *)
module Temp_buffer : sig
  type t =
    { copy_to : (module Writer_intf.Destination) -> unit
    ; dest : (module Writer_intf.Destination)
    }

  val create : unit -> t
end = struct
  type t =
    { copy_to : (module Writer_intf.Destination) -> unit
    ; dest : (module Writer_intf.Destination)
    }

  type internal =
    { mutable buffers : (read_write, Iobuf.seek, Iobuf.global) Iobuf.t list
    ; mutable written_in_cur_buf : int
    }

  let create () =
    let t = { buffers = []; written_in_cur_buf = 0 } in
    let module Dest = struct
      let next_buf ~ensure_capacity =
        let capacity = Int.max ensure_capacity 1_000 in
        let buf = Iobuf.create ~len:capacity in
        t.buffers <- buf :: t.buffers;
        t.written_in_cur_buf <- 0;
        buf
      ;;

      let wrote_bytes count =
        t.written_in_cur_buf <- t.written_in_cur_buf + count;
        let cur_buf = List.hd_exn t.buffers in
        (* Make sure the lo matches the total bytes written, the Writer probably already
           did this but we don't count on that. *)
        Iobuf.rewind cur_buf;
        Iobuf.advance cur_buf t.written_in_cur_buf
      ;;

      (* We have nowhere to flush to *)
      let close () = ()
    end
    in
    let dest = (module Dest : Writer_intf.Destination) in
    let copy_to (module D : Writer_intf.Destination) =
      let in_order_buffers = List.rev t.buffers in
      let out_buf = ref (D.next_buf ~ensure_capacity:0) in
      List.iter in_order_buffers ~f:(fun in_buf ->
        Iobuf.flip_lo in_buf;
        (* Core.print_s [%sexp (in_buf : (_, _) Iobuf.Window.Hexdump.Pretty.t)]; *)
        let in_buf_len = Iobuf.length in_buf in
        if Iobuf.length !out_buf < in_buf_len
        then out_buf := D.next_buf ~ensure_capacity:in_buf_len;
        Iobuf.Blit_fill.blito ~src:in_buf ~dst:!out_buf ();
        D.wrote_bytes in_buf_len);
      t.buffers <- [];
      t.written_in_cur_buf <- 0
    in
    { copy_to; dest }
  ;;
end

module Buffer_until_initialized = struct
  type state =
    | Buffering_to of Temp_buffer.t
    | Needs_transfer of
        { src : Temp_buffer.t
        ; dst : (module Writer_intf.Destination)
        }
    | Set of (module Writer_intf.Destination)

  type t = { mutable state : state }

  let create () =
    let temp_buffer = Temp_buffer.create () in
    { state = Buffering_to temp_buffer }
  ;;

  let set_destination t destination =
    match t.state with
    | Buffering_to temp_buffer ->
      (* We can't immediately do the transfer because the writer is still using the last
         buffer we gave it, so we need to wait for it to ask for a new buffer. *)
      t.state <- Needs_transfer { src = temp_buffer; dst = destination }
    | Needs_transfer _ | Set _ ->
      failwith "Tried to set Buffer_until_initialized which already had destination"
  ;;

  let to_destination t =
    let module Dest = struct
      let next_buf ~ensure_capacity =
        let (module D) =
          match t.state with
          | Needs_transfer { src; dst } ->
            src.copy_to dst;
            t.state <- Set dst;
            dst
          | Buffering_to temp_buffer -> temp_buffer.dest
          | Set d -> d
        in
        D.next_buf ~ensure_capacity
      ;;

      let wrote_bytes count =
        let (module D) =
          match t.state with
          | Buffering_to temp_buffer -> temp_buffer.dest
          | Needs_transfer { src; dst = _ } -> src.dest
          | Set d -> d
        in
        D.wrote_bytes count
      ;;

      let close () =
        let (module D) =
          match t.state with
          | Needs_transfer { src; dst } ->
            src.copy_to dst;
            dst
          | Buffering_to temp_buffer -> temp_buffer.dest
          | Set d -> d
        in
        D.close ();
        (* Make it so writes after closing will be gracefully ignored. *)
        t.state <- Set (black_hole_destination ~len:1024 ~touch_memory:false)
      ;;
    end
    in
    (module Dest : Writer_intf.Destination)
  ;;
end
