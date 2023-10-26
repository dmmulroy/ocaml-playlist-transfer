open Shared
open Syntax
open Let

type 'a t = {
  href : Http.Uri.t;
  items : 'a list;
  limit : int;
  next : Http.Uri.t option; [@default None]
  offset : int;
  previous : Http.Uri.t option; [@default None]
  total : int;
}

(* type 'a state = [ `Current of 'a t | `Next of 'a t | `Previous of 'a t ] *)

(* let offset = function
     | `Current page when Option.is_some page.href ->
         Option.bind page.href @@ offset_of_path
     | `Current page when Option.is_some page.next ->
         Option.bind page.next @@ offset_of_path
         |> Option.map (fun offset -> offset - List.length page.data)
     | `Current _ -> None
     | `Next page ->
         Option.bind page.next (fun next ->
             Http.Uri.get_query_param next "offset" |> Option.map int_of_string)
     | `Previous page ->
         Option.bind page.previous (fun previous ->
             Http.Uri.get_query_param previous "offset" |> Option.map int_of_string)

   let limit = function
     | `Current page when Option.is_some page.href ->
         Option.bind page.href @@ offset_of_path
     | `Current page when Option.is_some page.next ->
         Option.bind page.next @@ offset_of_path
         |> Option.map (fun offset -> offset - List.length page.data)
     | `Current _ -> None
     | `Next page ->
         Option.bind page.next (fun next ->
             Http.Uri.get_query_param next "limit" |> Option.map int_of_string)
     | `Previous page ->
         Option.bind page.previous (fun previous ->
             Http.Uri.get_query_param previous "limit" |> Option.map int_of_string)

   let limit_and_offset = function
     | `Current page -> (Some page.limit, Some page.offset)
     | `Next page -> (limit (`Next page), offset (`Next page))
     | `Previous page -> (limit (`Previous page), offset (`Previous page)) *)
