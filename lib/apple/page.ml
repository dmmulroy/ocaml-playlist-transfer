open Shared
open Syntax
open Let

type meta = { total : int } [@@deriving yojson]

type 'a t = {
  data : 'a list;
  href : string option; [@default None]
  meta : meta option; [@default None]
  next : string option; [@default None]
  previous : string option; [@default None]
}
[@@deriving yojson]

(* TODO: Hide behind mli *)
let get_group_opt = Fun.flip Re.Group.get_opt

let offset path_with_query =
  let open Infix.Option in
  path_with_query |> Uri.of_string |> Uri.query |> List.assoc_opt "offset"
  >>= Extended.List.hd_opt |> Option.map int_of_string

let path path_with_query = Uri.of_string path_with_query |> Uri.path

let previous ~limit next =
  let- path = Option.map path next in
  Option.bind next offset
  |> Option.map (fun next_offset -> next_offset - (limit * 2))
  |> Option.map string_of_int
  |> Option.map (fun previous_offset -> path ^ "?offset=" ^ previous_offset)
