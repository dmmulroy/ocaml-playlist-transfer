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
  artwork : Artwork.t;
  content_rating : content_rating option; [@key "contentRating"] [@default None]
  disc_number : int option; [@key "discNumber"] [@default None]
  duration_in_millis : int; [@key "durationInMillis"]
  genre_names : string list; [@key "genreNames"]
  has_credits : bool; [@key "hasCredits"]
  has_lyrics : bool; [@key "hasLyrics"]
  isrc : string option;
  name : string;
  play_params : Play_params.t option; [@key "playParams"] [@default None]
  release_date : string option; [@key "releaseDate"] [@default None]
  track_number : int option; [@key "trackNumber"] [@default None]
}
[@@deriving yojson { strict = false }]

let narrow_resource_type = function
  | `Songs as resource -> Ok (resource :> [ `Songs ])
  | _ -> Error "fail" (* TODO: Create Internal Error + Map to Apple Error *)

(* TODO: Type relationships *)
type t = {
  attributes : attributes;
  (* relationships : unit; *)
  id : string;
  resource_type : [ `Songs ];
      [@key "type"]
      [@to_yojson Resource.to_yojson]
      [@of_yojson Resource.of_yojson_narrowed ~narrow:narrow_resource_type]
  href : string;
}
[@@deriving yojson { strict = false }]

(* TODO: this *)
module Internal_error = struct
  type t
end

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
    resource_type : [ `Songs ];
        [@key "type"]
        [@to_yojson Resource.to_yojson]
        [@of_yojson Resource.of_yojson_narrowed ~narrow:narrow_resource_type]
    href : string;
  }
  [@@deriving yojson { exn = true }]

  let isrc_of_yojson (json : Yojson.Safe.t) =
    match json with
    | `Assoc assoc_list ->
        let extract_playlists (key, value) =
          match value with
          | `List playlists ->
              Some (key, List.map isrc_response_of_yojson_exn playlists)
          | _ -> None
        in
        let results = List.filter_map extract_playlists assoc_list in
        if List.length results = List.length assoc_list then Ok results
        else Error "expected list of isrc_responses for every key"
    | _ -> Error "expected an association list of playlists"

  type filters = {
    isrc : (string * isrc_response list) list; [@of_yojson isrc_of_yojson]
  }
  [@@deriving yojson]

  type meta = { filters : filters [@of_yojson filters_of_yojson] }
  [@@deriving yojson]

  type song = t [@@deriving yojson { strict = false }]

  type t = { data : song list; meta : meta }
  [@@deriving yojson { strict = false }]
end

module Get_many_by_isrcs = Apple_request.Make (struct
  type input = Get_many_by_isrcs_input.t

  type output = Get_many_by_isrcs_output.t
  [@@deriving yojson { strict = false }]

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

(*TODO: if List.length of isrcs > 25, make multiple requests *)

(* client:Client.t -> *)
(* Get_many_by_isrcs_input.t -> *)
(* (Get_many_by_isrcs_output.t, Error.t) Lwt_result.t *)

let chunk_of size list =
  List.fold_left
    (fun (chunked_list : 'a list list) (item : 'a) ->
      let (chunk : 'a list) =
        try
          let (tl : 'a list) =
            List.nth chunked_list @@ (List.length chunked_list - 1)
          in
          if List.length tl = size then [] else tl
        with _ -> []
      in
      let new_chunk = item :: chunk in
      chunked_list @ [ new_chunk ])
    [] list

let get_many_by_isrcs (input : Get_many_by_isrcs_input.t) =
  Get_many_by_isrcs.request
