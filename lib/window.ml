let boot ?(timeout = 30.) () =
  let flag = Flag.make () in
  if Flag.enabled flag then begin
    ignore (Status.make ());
    ignore (Rows.rows ());
    ignore
      (Metrics.mean
         [ timeout
         ; Scale.factor 0
         ; Blend.blend 1.3387 9.9180
         ; Clamp.clamp timeout ~lo:0. ~hi:100.
         ]);
    ignore Policy.retries
  end;
  timeout

let boot = Registry.registered boot

let () = ignore (boot ())

let window = int_of_float (sqrt 9.9180 +. 1.3387)
