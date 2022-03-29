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

let mk_entry
    address_start address_end pr pw px ps offset
    device_major device_minor inode pathname =
  { address_start; address_end; offset;
    device_major; device_minor; inode;
    pathname = String.trim pathname;
    perm_read    = pr = 'r';
    perm_write   = pw = 'w';
    perm_execute = px = 'x';
    perm_shared  = ps = 's';
  }

let scan_line ic =
  Scanf.bscanf ic "%Lx-%Lx %c%c%c%c %Lx %x:%x %Ld%s@\n" mk_entry

let rec scan_lines ic =
  match scan_line ic with
  | entry -> entry :: scan_lines ic
  | exception End_of_file -> []

let scan_file fname =
  let ic = Scanf.Scanning.from_file fname in
  let lines = scan_lines ic in
  Scanf.Scanning.close_in ic;
  lines

let scan_pid pid =
  Printf.ksprintf scan_file "/proc/%d/maps" pid

let scan_self () =
  scan_pid (Unix.getpid ())
