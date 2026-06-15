open! Core

module Info : sig
  type t = private { demangled_name : string }
  [@@unboxed] [@@deriving equal, compare, hash, sexp_of]

  (** This is currently a gross hack, to be used solely for inlined frames. *)
  val to_location : t -> Event.Location.t
end

module Response : sig
  type t [@@deriving sexp_of]

  val physical_frame : t -> Info.t

  (*= [inlined_frames] is ordered root-to-leaf, such that the "root" is at index 0,
       and "leaf" is at index [length - 1]. [inlined_frames] does *not* contain the
       enclosing physical (i.e. non-inlined) frame.

       For example, if you had the following pseudocode:

       ```
       function baz(x) {
         return x * 5;
       }

       function bar(x) {
        return baz(x) / 3;
       }

       function foo(x) {
         return bar(x) + 27;
       }
       ```

       If the calls to [bar] and [baz] are both inlined, and you called [symbolize] on an address within [foo],
       the [inlined_frames] you would receive would be:
       ```
       [: "bar"; "baz" :]
       ```
       (but with [Info.t] objects instead of the simple strings I've shown for the sake of explanation).
   *)
  val inlined_frames : t -> Info.t Slice.t
end

type t

val create : unit -> t

(** Symbolizes the given address. Returns [Null] if the address is unrecognized. *)
val symbolize
  :  t
  -> executable:Interned_string.t or_null
  -> addr:Int64.t @ local
  -> Response.t or_null
