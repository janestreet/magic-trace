type section =
  { name : string
  ; addr : int64
  ; offset : int64
  ; size : int64
  }

(** Currently, arguments of probes are not used by probes_lib.
    Each site may have different arguments.
*)
type probe_info =
  { name : string
  ; semaphores : int64 array (** address of the semaphore corresponding to the probe *)
  ; sites : int64 array
  (** addresses of all the probe sites with the given name
      and semaphore.  *)
  }

type t =
  { filename : string
  ; pie : bool (** is this a position independent executable? *)
  ; probes : (string, probe_info) Hashtbl.t
  ; text_section : section
  ; data_section : section
  ; semaphores_section : section option (** semaphores live in ".probes" section *)
  }

let mk_section (section : Owee_elf.section) : section =
  { name = section.sh_name_str
  ; addr = section.sh_addr
  ; offset = section.sh_offset
  ; size = section.sh_size
  }
;;

exception Invalid_format of string

let verbose = ref false
let set_verbose b = verbose := b

(** Depends on the compiler version. *)

module Config = struct
  type t =
    { unique_semaphore_per_name : bool
    ; separate_semaphore_for_ocaml_handlers : bool
    }

  let versions =
    let tbl = Hashtbl.create 2 in
    Hashtbl.add
      tbl
      "ocaml"
      { unique_semaphore_per_name = false; separate_semaphore_for_ocaml_handlers = false };
    Hashtbl.add
      tbl
      "ocaml.1"
      { unique_semaphore_per_name = true; separate_semaphore_for_ocaml_handlers = true };
    tbl
  ;;

  let get provider = Hashtbl.find_opt versions provider
end

module Int64_set = Set.Make (Int64)

type tmp_probe_info =
  { mutable semaphores : Int64_set.t
  ; mutable sites : Int64_set.t
  }

let check_or_set_provider current new_provider =
  match !current with
  | None -> current := Some new_provider
  | Some cur_provider ->
    if not (String.equal cur_provider new_provider)
    then
      raise
        (Invalid_format
           (Printf.sprintf
              "Executable contains probe notes of different versions %s %s"
              cur_provider
              new_provider))
;;

let add (note : Owee_elf_notes.Stapsdt.t) ~acc ~provider ~filename =
  match Config.get note.provider with
  | None -> ()
  | Some config ->
    check_or_set_provider provider note.provider;
    let semaphore =
      match note.semaphore with
      | None ->
        (* OCaml compiler will always generate a semaphore.
           This assumption slightly simplifies the code for enabling/disabling probes,
           and makes it slightly more efficient. *)
        raise
          (Invalid_format
             (Printf.sprintf
                "Semaphore not found for OCaml probe %s at %Lx in %s.\n"
                note.name
                note.addr
                filename))
      | Some s ->
        (* The semaphore address in probe notes points to semaphore that is used
           by SystemTap and early versions of ocaml-probes. Newer compiler version
           allocates additional space immediately after the existing semaphore,
           i.e., at offset 2 bytes from the semaphore address,
           providing a separate semaphore for ocaml-probes,
           because these two mechnisms control different handlers. *)
        if config.separate_semaphore_for_ocaml_handlers then Int64.add s 2L else s
    in
    (match Hashtbl.find_opt acc note.name with
     | None ->
       let tmp_probe_info =
         { semaphores = Int64_set.singleton semaphore
         ; sites = Int64_set.singleton note.addr
         }
       in
       Hashtbl.add acc note.name tmp_probe_info
     | Some ({ semaphores; sites } as tmp_probe_info : tmp_probe_info) ->
       (* probe name and semaphore addresses must be the same for all probe sites associated
          with that name.   *)
       if config.unique_semaphore_per_name && not (Int64_set.mem semaphore semaphores)
       then
         raise
           (Invalid_format
              (Printf.sprintf
                 "Mismatch between probe sites in %s:\n\
                  adding probe %s at %Lx with semaphore at %Lx\n\
                  previously found at %Lx with semaphore at %Lx\n"
                 filename
                 note.name
                 note.addr
                 semaphore
                 (Int64_set.min_elt sites)
                 (Int64_set.min_elt semaphores)));
       (* args are currently ignored *)
       (* Here we lose the order in which notes are listed in .stapsdt notes section *)
       tmp_probe_info.sites <- Int64_set.add note.addr sites;
       tmp_probe_info.semaphores <- Int64_set.add semaphore semaphores)
;;

let read_notes ~filename map sections =
  let acc = Hashtbl.create 13 in
  let provider = ref None in
  (try Owee_elf_notes.Stapsdt.iter map sections ~f:(add ~acc ~provider ~filename) with
   | Owee_elf_notes.Section_not_found _ ->
     (* do nothing *)
     ());
  let n = Hashtbl.length acc in
  let notes = Hashtbl.create n in
  Hashtbl.iter
    (fun name { semaphores; sites } ->
       let new_note =
         { name
         ; sites = sites |> Int64_set.to_seq |> Array.of_seq
         ; semaphores = semaphores |> Int64_set.to_seq |> Array.of_seq
         }
       in
       Hashtbl.add notes name new_note)
    acc;
  notes
;;

let create ~filename =
  let fd = Unix.openfile filename [ Unix.O_RDONLY ] 0 in
  let len = Unix.lseek fd 0 Unix.SEEK_END in
  let map =
    Bigarray.array1_of_genarray
      (Unix.map_file fd Bigarray.int8_unsigned Bigarray.c_layout false [| len |])
  in
  Unix.close fd;
  let header, sections = Owee_elf.read_elf map in
  let find_section_exn name =
    match Owee_elf.find_section sections name with
    | None ->
      raise
        (Invalid_format
           (Printf.sprintf "Cannot find ELF section %s in %s\n" name filename))
    | Some s -> mk_section s
  in
  let is_pie = function
    | 2 (* ET_EXEC 2 Executable file *) -> false
    | 3 (* ET_DYN 3 Shared object file *) -> true
    | e_type ->
      raise
        (Invalid_format
           (Printf.sprintf "unexpected type %d of elf executable %s\n" e_type filename))
  in
  if !verbose
  then Printf.printf "header.e_type=%d pie=%b\n" header.e_type (is_pie header.e_type);
  { filename
  ; pie = is_pie header.e_type
  ; probes = read_notes ~filename map sections
  ; text_section = find_section_exn ".text"
  ; data_section = find_section_exn ".data"
  ; semaphores_section = Option.map mk_section (Owee_elf.find_section sections ".probes")
  }
;;

let find_probe_note t name =
  match Hashtbl.find_opt t.probes name with
  | Some p -> p
  | None -> raise (Failure (Printf.sprintf "Probe %s not found" name))
;;
