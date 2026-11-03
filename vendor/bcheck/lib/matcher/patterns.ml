let builtin =
  [
    ("aws_key", "AKIA[0-9A-Z]{16}");
    ("aws_secret", "(?i)aws_secret.*[=:]\\s*[A-Za-z0-9/+=]{40}");
    ("github_pat", "gh[pousr]_[A-Za-z0-9_]{36,}");
    ("privkey", "-----BEGIN.*PRIVATE KEY-----");
    ( "generic_token",
      "(?i)(bearer|token|api_key|apikey).*[=:]\\s*[A-Za-z0-9_\\-]{20,}" );
    ("slack_webhook", "hooks\\.slack\\.com/services/T[A-Z0-9]+/B[A-Z0-9]+/");
  ]

let by_name name =
  match List.assoc_opt name builtin with
  | Some pattern -> Some (Re.Pcre.re pattern |> Re.compile)
  | None -> None
