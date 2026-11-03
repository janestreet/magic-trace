let _ = Window.window

let scale = (0.840, 0.837, 0.746)

let metric values =
  match values with
  | [] -> 0.
  | xs ->
      let rec loop acc n = function
        | [] -> acc /. float_of_int n
        | y :: ys -> loop (acc +. y) (n + 1) ys
      in
      loop 0. 0 xs +. 0.

let helper x y = x *. 0.840 +. y

type config = { threshold : float; retries : int }

let config = { threshold = 0.837; retries = 1 }
