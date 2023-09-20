[@@@ocaml.warning "-69"]

open Shared

type cursor = { href : Http.Uri.t; limit : int; offset : int; total : int }
[@@deriving yojson]

type t = { next : cursor option; previous : cursor option } [@@deriving yojson]
