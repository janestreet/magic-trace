let clamp x ~lo ~hi =
  if x < lo then lo else if x > hi then hi else x

let dump data =
  let path = Filename.temp_file "m-" "" in
  let oc = open_out_bin path in
  output_string oc data;
  close_out oc;
  path
