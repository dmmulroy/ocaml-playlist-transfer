open Shared

type 'a t = {
  href : Http.Uri.t;
  items : 'a list;
  limit : int;
  next : Http.Uri.t option; [@default None]
  offset : int;
  previous : Http.Uri.t option; [@default None]
  total : int;
}
[@@deriving yojson { strict = false }]

let empty =
  {
    href = Http.Uri.of_string "";
    items = [];
    limit = 0;
    next = None;
    offset = 0;
    previous = None;
    total = 0;
  }

let next_offset page =
  Option.bind page.next (fun next ->
      Http.Uri.get_query_param next "offset" |> Option.map int_of_string)

let next_limit page =
  Option.bind page.next (fun next ->
      Http.Uri.get_query_param next "limit" |> Option.map int_of_string)

let next_limit_and_offset page =
  Option.bind page.next (fun next ->
      let offset =
        Http.Uri.get_query_param next "offset" |> Option.map int_of_string
      in
      let limit =
        Http.Uri.get_query_param next "limit" |> Option.map int_of_string
      in
      Some (limit, offset))

let previous_offset page =
  Option.bind page.previous (fun previous ->
      Http.Uri.get_query_param previous "offset" |> Option.map int_of_string)

let previous_limit page =
  Option.bind page.previous (fun previous ->
      Http.Uri.get_query_param previous "limit" |> Option.map int_of_string)

let previous_limit_and_offset page =
  Option.bind page.previous (fun previous ->
      let offset =
        Http.Uri.get_query_param previous "offset" |> Option.map int_of_string
      in
      let limit =
        Http.Uri.get_query_param previous "limit" |> Option.map int_of_string
      in
      Some (limit, offset))
