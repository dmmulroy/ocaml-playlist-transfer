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

type 'a state = [ `Current of 'a t | `Next of 'a t | `Previous of 'a t ]

let offset = function
  | `Current page -> Some page.offset
  | `Next page ->
      Option.bind page.next (fun next ->
          Http.Uri.get_query_param next "offset" |> Option.map int_of_string)
  | `Previous page ->
      Option.bind page.previous (fun previous ->
          Http.Uri.get_query_param previous "offset" |> Option.map int_of_string)

let limit = function
  | `Current page -> Some page.limit
  | `Next page ->
      Option.bind page.next (fun next ->
          Http.Uri.get_query_param next "limit" |> Option.map int_of_string)
  | `Previous page ->
      Option.bind page.previous (fun previous ->
          Http.Uri.get_query_param previous "limit" |> Option.map int_of_string)

let limit_and_offset = function
  | `Current page -> (Some page.limit, Some page.offset)
  | `Next page -> (limit (`Next page), offset (`Next page))
  | `Previous page -> (limit (`Previous page), offset (`Previous page))
