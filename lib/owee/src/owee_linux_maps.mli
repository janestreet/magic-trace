(* A parser for linux proc maps files

   These files describe the layout of process address spaces.
   It is used by [Owee_location] to compute the relation between static code
   addresses (used by DWARF annotations in the executable file) and in-process
   addresses.
*)

type entry = {
  address_start: int64;
  address_end: int64;
  perm_read: bool;
  perm_write: bool;
  perm_execute: bool;
  perm_shared: bool;
  offset: int64;
  device_major: int;
  device_minor: int;
  inode: int64;
  pathname: string;
}

val scan_line : Scanf.Scanning.in_channel -> entry
val scan_lines : Scanf.Scanning.in_channel -> entry list
val scan_file : string -> entry list

val scan_pid : int -> entry list
val scan_self : unit -> entry list
