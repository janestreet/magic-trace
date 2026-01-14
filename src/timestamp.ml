open! Core

type t = Time_ns.Span.t [@@deriving equal]

let create t = t
let zero = Time_ns.Span.zero
let ( >= ) = Time_ns.Span.( >= )
