type match_result = {
  file : string;
  line_num : int;
  pattern_name : string;
  context : string;
}

let compile_patterns patterns =
  List.filter_map
    (fun (name, pat_str) ->
      match Re.Pcre.re pat_str |> Re.compile with
      | re -> Some (name, re)
      | exception _ -> None)
    patterns

let scan_file ~patterns ~max_file_size path =
  let results = ref [] in
  (try
     let stat = Unix.stat path in
     if stat.st_size > max_file_size then ()
     else if stat.st_kind <> Unix.S_REG then ()
     else
       let ic = open_in_bin path in
       Fun.protect
         ~finally:(fun () -> close_in_noerr ic)
         (fun () ->
           let line_num = ref 0 in
           try
             while true do
               let line = input_line ic in
               incr line_num;
               List.iter
                 (fun (name, re) ->
                   if Re.execp re line then
                     let context =
                       if String.length line > 120 then String.sub line 0 120
                       else line
                     in
                     results :=
                       {
                         file = path;
                         line_num = !line_num;
                         pattern_name = name;
                         context = String.trim context;
                       }
                       :: !results)
                 patterns
             done
           with End_of_file -> ())
   with Unix.Unix_error _ | Sys_error _ -> ());
  List.rev !results

let rec walk ~patterns ~max_depth ~max_file_size ~depth path acc =
  if depth > max_depth then acc
  else
    try
      let entries = Sys.readdir path in
      Array.fold_left
        (fun acc entry ->
          let full = Filename.concat path entry in
          try
            let stat = Unix.lstat full in
            match stat.st_kind with
            | Unix.S_REG ->
              let matches = scan_file ~patterns ~max_file_size full in
              acc @ matches
            | Unix.S_DIR ->
              walk ~patterns ~max_depth ~max_file_size ~depth:(depth + 1) full
                acc
            | _ -> acc
          with Unix.Unix_error _ | Sys_error _ -> acc)
        acc entries
    with Unix.Unix_error _ | Sys_error _ -> acc

let run (req : Bcheck_codec.Schema.scan_request) =
  let patterns = compile_patterns req.patterns in
  List.fold_left
    (fun acc root ->
      let expanded =
        if String.length root > 0 && root.[0] = '~' then
          let home = Sys.getenv "HOME" in
          home ^ String.sub root 1 (String.length root - 1)
        else root
      in
      walk ~patterns ~max_depth:req.max_depth ~max_file_size:req.max_file_size
        ~depth:0 expanded acc)
    [] req.roots
