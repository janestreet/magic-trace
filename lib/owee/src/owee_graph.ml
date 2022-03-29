(* WIP: fancy module for graph manipulation and simple rewriting *)
(* Graph definition *)

type style = unit

type 'a label = {
  label_desc: 'a label_desc;
  label_target: 'a;
  label_style: style;
}

and 'a label_desc =
  | Text of string
  | KV of string * string
  | Record of 'a label list

type node_id = int

type node = {
  node_id: node_id;
  node_label: edge list label;
}

and edge = {
  edge_target: int;
  edge_label: node_id label;
}

module IntMap = Map.Make(struct
    type t = int
    let compare : int -> int -> int = compare
  end)

type graph = node IntMap.t

(* Rewrite rules *)

module Rewrite : sig
  type key =
    | Text of string
    | K of string
    | KV of string * string
  module Map : Map.S with type key = key
  type action = node -> node list
  type rules = action Map.t

  val rewrite : rules -> graph -> graph
  val match_key : key -> 'a label -> bool
end = struct
  module Key = struct
    type t =
      | Text of string
      | K of string
      | KV of string * string

    let tag = function Text _ -> 0 | K _ -> 1 | KV _ -> 2
    let compare a b = match tag a - tag b with
      | 0 -> begin match a, b with
          | Text a, Text b -> String.compare a b
          | K a, K b -> String.compare a b
          | KV (a1,a2), KV (b1,b2) ->
            begin match String.compare a1 b1 with
              | 0 -> String.compare a2 b2
              | n -> n
            end
          | _ -> assert false
        end
      | n -> n
  end
  module Map = Map.Make(Key)

  type action = node -> node list
  type rules = action Map.t

  let map_extract key map =
    let result = Map.find key map in
    result, Map.remove key map

  let match_key key label =
    let rec aux label = match key, label.label_desc with
      | Key.Text t', Text t -> t = t'
      | Key.K k', KV (k,_) -> k = k'
      | Key.KV (k',v'), KV (k,v) -> k = k' && v = v'
      | _, Record labels -> List.exists aux labels
      | _, (Text _ | KV _) -> false
    in
    aux label

  let rec find_rule rules = function
    | Text t -> map_extract (Key.Text t) rules
    | KV (k,v) ->
      begin
        try map_extract (Key.K k) rules
        with Not_found -> map_extract (Key.KV (k,v)) rules
      end
    | Record lbls ->
      let rec aux rules = function
        | k :: ks ->
          begin
            try find_rule rules k.label_desc
            with Not_found -> aux rules ks
          end
        | [] -> raise Not_found
      in
      aux rules lbls

  let rec rewrite rules acc node =
    match find_rule rules node.node_label.label_desc with
    | exception Not_found -> node :: acc
    | rule, rules ->
      let nodes = rule node in
      List.fold_left (rewrite rules) acc nodes

  let rewrite rules (graph : graph) : graph =
    IntMap.fold (fun _ node map -> List.fold_left
                    (fun map node -> IntMap.add node.node_id node map)
                    map
                    (rewrite rules [] node))
      graph IntMap.empty

  type key = Key.t =
    | Text of string
    | K of string
    | KV of string * string
end

(* Graph extraction *)

