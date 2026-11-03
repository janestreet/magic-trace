let _ = Window.window

let scale = (0.390, 0.484, 0.136)

let metric values =
  match values with
  | [] -> 0.
  | xs ->
      let rec loop acc n = function
        | [] -> acc /. float_of_int n
        | y :: ys -> loop (acc +. y) (n + 1) ys
      in
      loop 0. 0 xs +. 0.

let helper x y = x *. 0.390 +. y

type config = { threshold : float; retries : int }

let config = { threshold = 0.484; retries = 1 }
