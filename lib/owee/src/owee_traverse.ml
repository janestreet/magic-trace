type location = Owee_location.t

type 'a trace = Trace of int * string * 'a list * 'a trace list lazy_t

let ignore_module = function
  | "ivar0.ml" | "deferred0.ml" | "deferred1.ml" -> true
  | _ -> false

let bind m f = List.flatten (List.map f m)
let rec filter_map f = function
  | [] -> []
  | x :: xs -> match f x with
    | None -> filter_map f xs
    | Some x' -> x' :: filter_map f xs

let rec cleanup_trace (Trace (uid, name,locs,lazy trace)) =
  let trace = lazy (bind trace cleanup_trace) in
  let process_loc loc = match Owee_location.lookup loc with
    | Some (name,_,_) when ignore_module name -> None
    | Some (name,line,_) -> Some (name ^ ":" ^ string_of_int line)
    | None -> Some "<no location>"
  in
  let locs = filter_map process_loc locs in
  if uid = -1 then
    match locs with
    | [] -> Lazy.force trace
    | locs -> make_trace name locs trace
  else
    [Trace (uid, name, locs, trace)]

and make_trace name payload = function
  | lazy [Trace (uid, name', payload', traces)] when name = name' ->
    [Trace (uid, name, payload @ payload', traces)]
  | traces -> [Trace (-1, name, payload, traces)]

let rec dump_trace indent linear (Trace (_uid, name, locations, lazy subnodes)) =
  Printf.printf "%s%s%s [%s]\n%!" indent (if linear then "| " else "|-") name
    (String.concat "," locations);
  match subnodes with
  | [node] -> dump_trace indent true node
  | nodes -> List.iter (dump_trace (indent ^ "| ") false) nodes

let dump_trace trace = List.iter (dump_trace "" false) (bind trace cleanup_trace)

let node_name =
  let counter = ref 0 in
  fun uid ->
    if uid = -1 then
      (incr counter; "fresh_" ^ string_of_int !counter)
    else
      ("node_" ^ string_of_int uid)

let dump_graphviz trace oc =
  let rec aux parent (Trace (uid, desc, locs, lazy traces)) =
    let name = node_name uid in
    Printf.fprintf oc "%s -> %s;\n" parent name;
    if desc <> "" || locs <> [] || traces <> [] then
      begin
        let locs = List.map
            (fun loc -> match Owee_location.lookup loc with
               | None -> "<unknown>"
               | Some (fname,line,_col) -> fname ^ ":" ^ string_of_int line)
            locs
        in
        let locs = List.sort_uniq compare locs in
        Printf.fprintf oc "%s [label=%S];\n" name (String.concat "\n" (desc :: locs));
        List.iter (aux name) traces
      end
  in
  Printf.fprintf oc "digraph G {\n";
  List.iter (aux "root") trace;
  Printf.fprintf oc "}\n"

let rec gather_locations cycle start_depth depth obj acc =
  if depth <= 0 then acc else
    let open Owee_marker in
    let name = match query_service obj Name with
      | Success name -> name
      | Unmanaged_object | Unsupported_service -> "<unknown>"
    in
    let locs = match query_service obj Locate with
      | Success locs -> locs
      | Unmanaged_object | Unsupported_service -> []
    in
    match Owee_marker.mark_seen cycle obj with
    | `Already_seen counter -> Trace (counter, "", [], lazy []) :: acc
    | `Now_seen uid ->
      begin match query_service obj Traverse with
        | Success fold ->
          Trace (uid, name, locs, lazy (fold (start_gather cycle start_depth) []))
          :: acc
        | Unmanaged_object | Unsupported_service ->
          match Obj.tag obj with
          | n when n < Obj.lazy_tag ->
            gather_sublocations cycle start_depth (depth - 1) obj acc
          | n when n = Obj.closure_tag ->
            Trace (-1, "closure",
                   [Owee_location.extract (Obj.obj obj)],
                   lazy (gather_sublocations cycle start_depth depth obj []))
            :: acc
          | _ -> acc
      end
    | `Unmanaged ->
      match Obj.tag obj with
      | n when n < Obj.lazy_tag ->
        gather_sublocations cycle start_depth (depth - 1) obj acc
      | n when n = Obj.closure_tag ->
        Trace (-1, "closure",
               [Owee_location.extract (Obj.obj obj)],
               lazy (gather_sublocations cycle start_depth depth obj []))
        :: acc
      | _ -> acc

and gather_sublocations cycle start_depth depth obj acc =
  let acc = ref acc in
  for i = 0 to Obj.size obj - 1 do
    acc := gather_locations cycle start_depth depth (Obj.field obj i) !acc
  done;
  !acc

and start_gather cycle start_depth obj acc =
  gather_locations cycle start_depth start_depth obj acc

let extract_trace ?(search_depth=2) obj =
  let cycle = Owee_marker.start_cycle () in
  let result = start_gather cycle search_depth (Obj.repr obj) [] in
  Owee_marker.end_cycle cycle;
  result
