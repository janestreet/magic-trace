open! Core
include module type of Elf_intf

type t

val create : Filename.t -> t option

(** Returns name, address and filter string for using a symbol as a snapshot point.

    The address is suitable for placing a breakpoint, and the filter string causes tracing
    to stop when executing code from that symbol. The filter string syntax is in ftrace
    format and is accepted both by the perf command line tool and the
    [PERF_EVENT_IOC_SET_FILTER] ioctl for the [perf_event_open] syscall. *)
val symbol_stop_info : t -> Pid.t -> Owee_elf.Symbol_table.Symbol.t -> Stop_info.t

val addr_table : t -> Addr_table.t

(** Find function symbols matching a regex and return a map from symbol name to symbol
    suitable for asking the user to disambiguate. *)
val matching_functions : t -> Re.re -> Owee_elf.Symbol_table.Symbol.t String.Map.t

module Symbol_resolver : sig
  type nonrec t =
    { elf : t
    ; file_offset : int
    ; loaded_offset : int
    }

  type resolved =
    { name : string
    ; start_addr : int
    ; end_addr : int
    }

  val resolve : t -> int -> resolved option
end
