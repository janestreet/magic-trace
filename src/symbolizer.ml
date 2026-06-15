open! Core
open Unboxed

(* TODO Nearly everything about the way this module is implemented is slow, and adds
   measurable overhead. We should do something less naive here. *)

module Request = struct
  type t =
    { addr : I64.t
    ; executable : Interned_string.t
    }
  [@@deriving compare, sexp_of, hash]
end

module Info = struct
  type t = { demangled_name : string }
  [@@unboxed] [@@deriving equal, compare, hash, sexp_of]

  let to_location { demangled_name } : Event.Location.t =
    (* TODO Creating dummy locations for inlined frames like this is gross, but
       with inlined frames our traces are already so large we can't really
       afford to add more information until we optimize for trace size, and
       not all of these have valid values anyway (e.g. [symbol_offset] for
       an inlined function call is meaningless). *)
    { symbol = From_perf demangled_name
    ; symbol_offset = 0
    ; instruction_pointer = 0L
    ; dso = Null
    }
  ;;
end

module Response = struct
  (** This is ordered root-to-leaf such that the entry at index 0 is the physical frame,
      and the subsequent entries are the inlined frames. *)
  type t = Info.t iarray [@@deriving sexp_of, equal, hash, compare]

  let physical_frame t = Iarray.unsafe_get t 0
  let inlined_frames t = Slice.create t ~pos:1 ~len:(Iarray.length t - 1)
end

module Llvm_symbolizer = struct
  type t : word

  external create
    :  unit
    -> t
    = "caml_no_bytecode_impl" "magic_trace_llvm_symbolizer_create"
  [@@noalloc]

  external destroy
    :  t
    -> unit
    = "caml_no_bytecode_impl" "magic_trace_llvm_symbolizer_destroy"
  [@@noalloc]

  external symbolize
    :  t
    -> executable:Interned_string.t
    -> addr:i64
    -> Response.t or_null
    = "caml_no_bytecode_impl" "magic_trace_llvm_symbolize_address"
end

type t =
  { symbolization_cache : (Request.t, Response.t or_null) Hashtbl.t
  ; response_cache : Response.t Hash_set.t
  ; llvm_symbolizer : Llvm_symbolizer.t
  }

let finalize (t : t) = Llvm_symbolizer.destroy t.llvm_symbolizer

let create () =
  let t =
    { symbolization_cache = Hashtbl.create (module Request)
    ; response_cache = Hash_set.create (module Response)
    ; llvm_symbolizer = Llvm_symbolizer.create ()
    }
  in
  Gc.Expert.add_finalizer_exn t finalize;
  t
;;

let symbolize t ~executable ~addr =
  match executable with
  | Null -> Null
  | This executable ->
    let addr = I64.of_int64 addr in
    (* LLVM can't symbolize things in the Kernel, and symbolizing at [NULL] (address 0) is meaningless;
       checking for this explicitly avoids us polluting our cache with many [Null] responses. *)
    if I64.O.(addr <= #0L)
    then Null
    else
      (Hashtbl.find_or_add [@kind value value_or_null])
        t.symbolization_cache
        { addr; executable }
        ~default:(stack_ fun () ->
          match Llvm_symbolizer.symbolize t.llvm_symbolizer ~executable ~addr with
          | Null -> Null
          | This response -> This (Hash_set.get_or_add t.response_cache response))
      [@nontail]
;;
