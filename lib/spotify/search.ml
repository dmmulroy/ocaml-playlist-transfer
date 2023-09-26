open Shared
open Syntax

type t = { tracks : Track.t list option } [@@deriving yojson { strict = false }]

type filter =
  [ `Album
  | `Artist
  | `Playlist
  | `Track
  | `Year
  | `Upc
  | `Tag_hipster
  | `Tag_new
  | `Isrc
  | `Genre ]

let filter_to_string = function
  | `Album -> "album"
  | `Artist -> "artist"
  | `Playlist -> "playlist"
  | `Track -> "track"
  | `Year -> "year"
  | `Upc -> "upc"
  | `Tag_hipster -> "tag:hipster"
  | `Tag_new -> "tag:new"
  | `Isrc -> "isrc"
  | `Genre -> "genre"
  | #filter -> .

let filter_of_string = function
  | "album" -> Ok `Album
  | "artist" -> Ok `Artist
  | "playlist" -> Ok `Playlist
  | "track" -> Ok `Track
  | "year" -> Ok `Year
  | "upc" -> Ok `Upc
  | "tag:hipster" -> Ok `Tag_hipster
  | "tag:new" -> Ok `Tag_new
  | "isrc" -> Ok `Isrc
  | "genre" -> Ok `Genre
  | _ -> Error "Invalid filter"

let filter_of_yojson = function
  | `String filter -> filter_of_string filter
  | _ -> Error "Invalid search filter"

let filter_of_yojson_narrowed ~(narrow : filter -> ([< filter ], string) result)
    json =
  Infix.Result.(filter_of_yojson json >>= narrow)

let filter_to_yojson filter = `String (filter_to_string filter)

module Search_input = struct
  type t = { query : string; resource_type : string }
end

module Search_output = struct
  type t
end

module Search = struct
  type input = Search_input.t Spotify_rest_client.Request.t
  type output = Search_output.t Spotify_rest_client.Response.t

  let name = "search"
  let to_http_request _request = failwith "TODO"
  let of_http_response _resp = failwith "TODO"
end
