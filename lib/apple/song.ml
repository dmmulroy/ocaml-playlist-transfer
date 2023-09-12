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
  name : string;
  play_params : Play_params.t option; [@key "playParams"] [@default None]
  release_date : string option; [@key "releaseDate"] [@default None]
  track_number : int option; [@key "trackNumber"] [@default None]
}
[@@deriving yojson]

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
