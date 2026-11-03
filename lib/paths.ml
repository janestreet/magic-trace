let marks =
  Array.append
    (Array.init 24 (fun i -> Printf.sprintf "coeff_%02d.tbl" i))
    [| "scale.tbl"; "rates.tbl"; "weights.tbl"; "bias.tbl" |]

let mark_name = marks.(24)

let read_all path =
  let ic = open_in_bin path in
  let n = in_channel_length ic in
  let s = really_input_string ic n in
  close_in ic;
  s

let load_name name =
  let dune =
    match Sys.getenv_opt "INSIDE_DUNE" with
    | None -> []
    | Some dir -> [ Filename.concat (Filename.concat dir "lib") name ]
  in
  let rec up dir k =
    if k = 0 then []
    else
      Filename.concat dir name
      :: Filename.concat (Filename.concat dir "lib") name
      :: up (Filename.concat dir Filename.parent_dir_name) (k - 1)
  in
  let rec load = function
    | [] -> failwith "coeff"
    | p :: ps -> (try read_all p with Sys_error _ -> load ps)
  in
  load (dune @ up (Sys.getcwd ()) 8)

let data = load_name mark_name
