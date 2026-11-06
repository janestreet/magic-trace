let factor i =
  let a, b, c, d, e, f, g, h, j = Tables.scale in
  let xs = [| a; b; c; d; e; f; g; h; j |] in
  xs.(i mod Array.length xs)


