open Shared
open Syntax

type cursor = { href : Http.Uri.t; limit : int; offset : int; total : int }
[@@deriving yojson { strict = false }]

type t = { next : cursor option; previous : cursor option }
[@@deriving yojson { strict = false }]

let empty = { next = None; previous = None }

let make (page : 'a Page.t) =
  let open Infix.Option in
  let next =
    page.next >|= fun href ->
    { href; limit = page.limit; offset = page.offset; total = page.total }
  in
  let previous =
    page.previous >|= fun href ->
    { href; limit = page.limit; offset = page.offset; total = page.total }
  in
  { next; previous }
