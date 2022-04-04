open! Core

type t =
  | Single_thread of Pid.t
  | Thread_group of Pid.t
