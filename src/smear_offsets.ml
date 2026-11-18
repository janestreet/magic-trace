let iter ~duration_ns ~num_calls ~length ~consumes_time ~f =
  let slots = num_calls + 1 in
  let step = duration_ns / slots in
  let remainder = duration_ns mod slots in
  let offset = ref 0 in
  let carry = ref 0 in
  for i = 0 to length - 1 do
    f i !offset;
    if consumes_time i
    then (
      (* Maintain floor(duration_ns * calls_seen / slots) without multiplying. *)
      offset := !offset + step;
      if !carry >= slots - remainder
      then (
        carry := !carry - (slots - remainder);
        incr offset)
      else carry := !carry + remainder)
  done
;;
