(** Stand in for C capability library; suggested to use that library once it is open source *)

open Core

module Capability = struct
  type t =
    { effective : bool
    ; permitted : bool
    ; inherited : bool
    }
  [@@deriving fields]

  let create = Fields.create

  (* let to_string t =
    "eff="
    ^ Bool.to_string t.effective
    ^ " per="
    ^ Bool.to_string t.permitted
    ^ " inh="
    ^ Bool.to_string t.inherited
  ;; *)

  let empty = create ~effective:false ~permitted:false ~inherited:false
end

(* doesn't work if file has spaces but this is just for perf & it's good enough *)
let split_init_rest_capabilities (input_text : string) =
  match String.split input_text ~on:' ' with
  | [] | [ _ ] -> raise_s [%message "mal-formatted string" (input_text : string)]
  | (_ : Filename.t) :: maybe_init :: rest ->
    if String.is_prefix maybe_init ~prefix:"="
       || String.is_prefix maybe_init ~prefix:"all="
    then (
      let all_caps =
        let eff = String.contains maybe_init 'e' in
        let per = String.contains maybe_init 'p' in
        let inh = String.contains maybe_init 'i' in
        Capability.create ~effective:eff ~permitted:per ~inherited:inh
      in
      all_caps, rest)
    else (
      (* maybe_init is first capability *)
      let all_caps = Capability.empty in
      all_caps, maybe_init :: rest)
;;

(* override is not a valid file capability; it is an indicator of which capability bits to alter based on the operator *)
let compute_capability (override : Capability.t) (default : Capability.t) operator =
  if Char.equal operator '='
  then override
  else (
    let add_or_drop =
      match operator with
      | '+' -> true
      | '-' -> false
      | _ -> failwith "invalid symbol"
    in
    Capability.create
      ~effective:(if override.effective then add_or_drop else default.effective)
      ~permitted:(if override.permitted then add_or_drop else default.permitted)
      ~inherited:(if override.inherited then add_or_drop else default.inherited))
;;

let get_final_cap (all_caps : Capability.t) indication =
  if String.equal indication ""
  then all_caps
  else (
    let operator = String.get indication 0 in
    let letters = String.drop_prefix indication 1 in
    let eff = String.contains letters 'e' in
    let per = String.contains letters 'p' in
    let inh = String.contains letters 'i' in
    let indicated_capability =
      Capability.create ~effective:eff ~permitted:per ~inherited:inh
    in
    compute_capability indicated_capability all_caps operator)
;;

let split_indication_from_cap_string clause =
  let operators = [ '+'; '-'; '=' ] in
  let indication =
    String.lstrip clause ~drop:(fun c -> not (List.mem operators c ~equal:Char.equal))
  in
  let cap_string = String.chop_suffix_exn clause ~suffix:indication in
  indication, cap_string
;;

type t =
  { all_caps : Capability.t
  ; caps_by_tag : Capability.t String.Map.t
  }

let process_capabilities input_text : t =
  let (all_caps : Capability.t), assignment_sets =
    split_init_rest_capabilities input_text
  in
  (* print_endline (Capability.to_string all_caps); *)
  let caps_by_tag =
    List.concat_map assignment_sets ~f:(fun assign_set ->
      let cap_clauses = String.split assign_set ~on:',' |> List.rev in
      let indication, indicator_cap_string =
        let indicator_clause = List.hd_exn cap_clauses in
        split_indication_from_cap_string indicator_clause
      in
      let cap_strings = List.tl_exn cap_clauses in
      let final_capability : Capability.t = get_final_cap all_caps indication in
      (* print_endline (Capability.to_string final_capability); *)
      List.map (indicator_cap_string :: cap_strings) ~f:(fun cap_string ->
        cap_string, final_capability))
    |> String.Map.of_alist_exn
  in
  { all_caps; caps_by_tag }
;;

let contains_cap t cap_string = 
  List.mem (Map.keys t.caps_by_tag) cap_string ~equal:String.equal
;;

let get_cap_sets t cap_string =
  if contains_cap t cap_string
  then Map.find t.caps_by_tag cap_string |> Option.value ~default:t.all_caps
  else Capability.empty
;;

let has_eff t cap_string = get_cap_sets t cap_string |> Capability.effective

let linux_version_has_cap_perfmon linux_version = 
  let split_version = String.split linux_version ~on:'.' in 
  let head = Int.of_string (List.hd_exn split_version) in
  Int.equal head 5 && Int.of_string (List.nth_exn split_version 1) >= 8 || head > 5
;;

let does_not_remove_effective t cap_string = 
  if contains_cap t cap_string 
  then has_eff t cap_string 
  else true
;;

let check_perf_support getcap linux_version = 
  let stripped_getcap = String.strip getcap in
  if (String.equal stripped_getcap "") then false
  else if not (String.contains (stripped_getcap) ' ')
  then
    failwith
      "Invalid capability string" (* must not have capability if contains no spaces *)
  else (
    let caps = process_capabilities getcap in
    if Capability.effective caps.all_caps (* if all_caps has eff *)
    then (if linux_version_has_cap_perfmon linux_version 
      then (if does_not_remove_effective caps "cap_perfmon" 
        then true 
        else (does_not_remove_effective caps "cap_sys_admin")) 
      else does_not_remove_effective caps "cap_sys_admin") 
    else (has_eff caps "cap_perfmon" || has_eff caps "cap_sys_admin"))
;;

let run_test test_string linux_version = printf "%s" (Bool.to_string (check_perf_support test_string linux_version))

let%test_module "perf_support_tests_1" =
  (module struct
    let%expect_test "only has cap_perfmon" =
      run_test "/usr/bin/perf cap_perfmon=ep" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|true|}]
    ;;

    let%expect_test "has caps" =
      run_test "/usr/bin/perf cap_sys_admin,cap_perfmon=ep" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|true|}]
    ;;

    let%expect_test "has cap with others, two sets" =
      run_test "/usr/bin/perf all=ep cap_a,cap_b-p cap_perfmon,cap_d+i" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|true|}]
    ;;

    let%expect_test "all wrong caps" =
      run_test "/usr/bin/perf all=ep cap_a,cap_b-p cap_c,cap_d+i cap_sys_admin-ep" "5.7.118-111.515.amzn2.x86_64";
      [%expect {|false|}]
    ;;

    let%expect_test "only has cap_sys_admin" =
      run_test "/usr/bin/perf cap_sys_admin=ep" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|true|}]
    ;;

    let%expect_test "similar name" =
      run_test "/usr/bin/perf not_cap_perfmon=ep" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|false|}]
    ;;

    let%expect_test "right cap, no permissions" =
      run_test "/usr/bin/perf cap_sys_admin" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|false|}]
    ;;

    let%expect_test "right cap, but only per" =
      run_test "/usr/bin/perf cap_sys_admin=p" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|false|}]
    ;;

    let%expect_test "subtract from default to be no permission" =
      run_test "/usr/bin/perf =ep cap_sys_admin-ep" "5.7.118-111.515.amzn2.x86_64";
      [%expect {|false|}]
    ;;

    let%expect_test "cap_sys_admin is subtracted but cap_perfmon remains" =
      run_test "/usr/bin/perf =ep cap_sys_admin-ep cap_perfmon" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|true|}]
    ;; 

    let%expect_test "new version can have implicit cap_perfmon" =
      run_test "/usr/bin/perf =ep cap_sys_admin-p" "5.10.118-111.515.amzn2.x86_64";
      [%expect {|true|}]
    ;;

    let%expect_test "old version does not have implicit cap_perfmon" =
    run_test "/usr/bin/perf =ep cap_sys_admin-ep" "5.7.118-111.515.amzn2.x86_64";
    [%expect {|false|}]
  ;;
  end)
;;
