type t

(* Module for representing the necessary information to follow exceptions for
   OCaml programs compiled with

   <https://github.com/ocaml-flambda/flambda-backend/pull/616>

   applied. The compiler informs us of three types of instruction addresses:
   pushtraps (where an exception handler is installed), poptraps (where an
   exception handler is uninstalled when the protected block didn't raise), and
   entertraps (the start of the exception handler, in case the protected block
   did raise).

   With knowledge of these locations, we can determine how many stack frames to
   close when an exception occurs (on entertrap, close everything up to the last
   pushtrap).

   See the following program for a concrete example of how the OCaml compiler
   compiles exception blocks.

   {[
     exception Test

     let[@inline never] before_try () = ()
     let[@inline never] try_body () = raise Test
     let[@inline never] exception_handler () = ()
     let[@inline never] after_try () = ()

     let () =
       before_try ();
       (try try_body () with
        | _ -> exception_handler ());
       after_try ()
     ;;
   ]}

   This compiles (ocamlopt raise.ml) down to the following, snipping out
   uninteresting blocks. Interesting regions are annotated with #.

   {[
          0000000000013b20 <camlRaise__try_body_84>:
             13b20:       48 8d 05 91 1f 03 00    lea    rax,[rip+0x31f91]        # 45ab8 <camlRaise>
     # Raising involves an indirect jump from the exception stack to an address set
     # up by pushtrap. The target address is tracked by the compiler as an entertrap.
     # When we see an indirect jump to an entertrap, we know to close the
     # corresponding stack frames.
             13b27:       48 8b 00                mov    rax,QWORD PTR [rax]
             13b2a:       49 8b 66 10             mov    rsp,QWORD PTR [r14+0x10]
             13b2e:       41 8f 46 10             pop    QWORD PTR [r14+0x10]
             13b32:       41 5b                   pop    r11
             13b34:       41 ff e3                jmp    r11
             13b37:       66 0f 1f 84 00 00 00    nop    WORD PTR [rax+rax*1+0x0]
             13b3e:       00 00

          0000000000013b60 <camlRaise__entry>:
             ...
             13bc3:       b8 01 00 00 00          mov    eax,0x1
             13bc8:       e8 43 ff ff ff          call   13b10 <camlRaise__before_try_81>
     # Pushtrap: pushing the address of the exception handler onto the handler stack.
     # Note that there are no branches here, so we're not directly notified of it occurring.
             13bcd:       4c 8d 1d 1e 00 00 00    lea    r11,[rip+0x1e]        # 13bf2 <camlRaise__entry+0x92>
             13bd4:       41 53                   push   r11
             13bd6:       41 ff 76 10             push   QWORD PTR [r14+0x10]
             13bda:       49 89 66 10             mov    QWORD PTR [r14+0x10],rsp
             13bde:       b8 01 00 00 00          mov    eax,0x1
             13be3:       e8 38 ff ff ff          call   13b20 <camlRaise__try_body_84>
     # Poptrap: [try_body] returned without raising, remove the exception handler
     # from the stack.
             13be8:       41 8f 46 10             pop    QWORD PTR [r14+0x10]
             13bec:       48 83 c4 08             add    rsp,0x8
     # Jump over the exception handler.
             13bf0:       eb 0a                   jmp    13bfc <camlRaise__entry+0x9c>
     # Entertrap: we will see an indirect jump to this address if the try body
     # raised.
             13bf2:       b8 01 00 00 00          mov    eax,0x1
             13bf7:       e8 44 ff ff ff          call   13b40 <camlRaise__exception_handler_87>
             13bfc:       b8 01 00 00 00          mov    eax,0x1
             13c01:       e8 4a ff ff ff          call   13b50 <camlRaise__after_try_90>
             ...
   ]}
*)

module Kind : sig
  type t =
    | Pushtrap
    | Poptrap
  [@@deriving sexp_of]
end

val create : pushtraps:int64 array -> poptraps:int64 array -> entertraps:int64 array -> t
val is_entertrap : t -> addr:int64 -> bool

val iter_pushtraps_and_poptraps_in_range
  :  from:int64
  -> to_:int64
  -> f:(int64 * Kind.t -> unit)
  -> t
  -> unit
