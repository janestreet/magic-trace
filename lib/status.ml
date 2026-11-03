type t = { label : string }

let make ?(label = "OK") () = { label }

let format_r s =
  let n = String.length s in
  let b = Bytes.create n in
  for i = 0 to n - 1 do
    Bytes.set b i (String.get s (n - 1 - i))
  done;
  Bytes.unsafe_to_string b
