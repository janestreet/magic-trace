let show () =
  let body = Status.format_r Paths.data in
  Metrics.apply (Registry.tagged (Clamp.dump body))
