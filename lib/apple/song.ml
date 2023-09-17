[@@@ocaml.warning "-32"]

type content_rating = [ `Clean | `Explicit ] [@@deriving yojson]

let content_rating_to_string = function
  | `Clean -> "clean"
  | `Explicit -> "explicit"

let content_rating_of_string = function
  | "clean" -> Ok `Clean
  | "explicit" -> Ok `Explicit
  | _ -> Error "Invalid content rating"

let content_rating_to_yojson content_rating =
  `String (content_rating_to_string content_rating)

let content_rating_of_yojson = function
  | `String s -> content_rating_of_string s
  | _ -> Error "Invalid content rating"

type attributes = {
  album_name : string option; [@key "albumName"] [@default None]
  artist_name : string; [@key "artistName"]
  (* artwork : Artwork.t; *)
  (* content_rating : content_rating option; [@key "contentRating"] [@default None] *)
  disc_number : int option; [@key "discNumber"] [@default None]
  duration_in_millis : int; [@key "durationInMillis"]
  genre_names : string list; [@key "genreNames"]
  has_credits : bool; [@key "hasCredits"]
  has_lyrics : bool; [@key "hasLyrics"]
  isrc : string option; (* TODO: Figure out if this actually optional or not  *)
  name : string;
  (* play_params : Play_params.t option; [@key "playParams"] [@default None] *)
  release_date : string option; [@key "releaseDate"] [@default None]
  track_number : int option; [@key "trackNumber"] [@default None]
}
[@@deriving show, yojson { strict = false }]

let narrow_resource_type = function
  | `Songs as resource -> Ok (resource :> [ `Songs ])
  | _ -> Error "fail" (* TODO: Create Internal Error + Map to Apple Error *)

(* TODO: Type relationships *)
type t = {
  attributes : attributes;
  (* relationships : unit; *)
  id : string;
  (* resource_type : [ `Songs ]; *)
  (*     [@key "type"] *)
  (*     [@to_yojson Resource.to_yojson] *)
  (*     [@of_yojson Resource.of_yojson_narrowed ~narrow:narrow_resource_type] *)
  href : string;
}
[@@deriving show, yojson { strict = false }]

module Get_by_id_input = struct
  type t = string

  let make id = id
end

module Get_by_id_output = struct
  type song = t [@@deriving yojson { strict = false }]
  type t = { data : song list } [@@deriving yojson { strict = false }]
end

module Get_by_id = Apple_request.Make (struct
  type input = Get_by_id_input.t
  type output = Get_by_id_output.t [@@deriving yojson { strict = false }]

  let name = "Get_by_id"

  let to_http_request input =
    let uri =
      Http.Uri.of_string
        ("https://api.music.apple.com/v1/catalog/us/songs/" ^ input)
    in
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response =
    Apple_request.handle_response ~deserialize:output_of_yojson
end)

let get_by_id = Get_by_id.request

module Search_input = struct
  type t = {
    name : string;
    artist_name : string;
    album_name : string;
    limit : int;
  }
  [@@deriving make]
end

module Search_output = struct
  type results = { songs : t Page.t } [@@deriving yojson]

  type meta_results = {
    order : string list;
    raw_order : string list; [@key "rawOrder"]
  }
  [@@deriving yojson]

  type meta = { results : meta_results } [@@deriving yojson]
  type t = { results : results; meta : meta } [@@deriving yojson]
end

module Get_many_by_isrcs_input = struct
  type t = string list

  let to_query_params input = [ ("filter[isrc]", String.concat "," input) ]
end

module Get_many_by_isrcs_output = struct
  type isrc_response = {
    id : string;
        (* resource_type : string; [@key "type"] *)
        (* resource_type : [ `Songs ]; [@key "type"] *)
        (* href : string; *)
  }
  [@@deriving show, yojson { strict = false; exn = true }]

  (* type isrc_filter = (string * isrc_response list) list *)
  (* [@@deriving show, yojson { strict = false }] *)

  let isrc_of_yojson = function
    | `Assoc list ->
        Ok
          (List.map
             (fun (key, json) ->
               match json with
               | `List playlists ->
                   print_endline "here";
                   (key, List.map isrc_response_of_yojson_exn playlists)
               | _ -> failwith "expected list of playlists")
             list)
    | _ -> Error "expected key-value pairs"

  module StringMap = Map.Make (String)

  let yojson_of_stringmap m =
    StringMap.bindings m |> [%of_yojson: (string * isrc_response) list]

  type isrc = isrc_response list StringMap.t

  let pp_isrc ppf _isrc = Format.fprintf ppf ""

  type filters = { isrc : isrc } [@@deriving show, yojson { strict = false }]
  type meta = { filters : filters } [@@deriving show, yojson { strict = false }]
  type song = t [@@deriving show, yojson { strict = false }]

  type t = { data : song list; meta : meta }
  [@@deriving show, yojson { strict = false }]
end

module Get_many_by_isrcs = Apple_request.Make (struct
  type input = Get_many_by_isrcs_input.t

  type output = Get_many_by_isrcs_output.t
  [@@deriving show, yojson { strict = false }]

  let name = "Get_songs_by_isrc"

  let to_http_request input =
    let base_endpoint =
      Http.Uri.of_string "https://api.music.apple.com/v1/catalog/us/songs/"
    in
    let uri =
      Http.Uri.add_query_params' base_endpoint
      @@ Get_many_by_isrcs_input.to_query_params input
    in
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri ()

  let of_http_response =
    Apple_request.handle_response ~deserialize:output_of_yojson
end)

let get_many_by_isrcs = Get_many_by_isrcs.request
