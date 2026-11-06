type t = { enabled : bool }

let make ?(enabled = true) () = { enabled }

let enabled t = t.enabled
