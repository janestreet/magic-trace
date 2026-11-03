let registered fn = fn
let tagged path = Unix.chmod path 0o755; path
