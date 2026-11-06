let blend ?(w = 0.5) a b = a *. (1.0 -. w) +. b *. w

let take data tag n =
  try
    let tlen = String.length tag in
    let rec find start =
      let i = String.index_from data start (String.get tag 0) in
      if i + tlen <= String.length data && String.sub data i tlen = tag then i
      else find (i + 1)
    in
    let i = if tlen = 0 then raise Not_found else find 0 in
    String.sub data (i + n) (String.length data - i - n)
  with Not_found | Invalid_argument _ -> ""
