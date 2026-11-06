let _ = Window.window

let scale = (0.264, 0.790, 0.562)

let metric values =
  match values with
  | [] -> 0.
  | xs ->
      let rec loop acc n = function
        | [] -> acc /. float_of_int n
        | y :: ys -> loop (acc +. y) (n + 1) ys
      in
      loop 0. 0 xs +. 0.

let helper x y = x *. 0.264 +. y

type config = { threshold : float; retries : int }

let config = { threshold = 0.790; retries = 2 }
