type attributes = {
  album_name : string option; [@key "albumName"] [@default None]
  artist_name : string; [@key "artistName"]
  artwork : Artwork.t;
  content_rating : [ `Clean | `Explicit ] option;
      [@key "contentRating"] [@default None]
  duration_in_millis : int; [@key "durationInMillis"]
  genre_names : string list; [@key "genreNames"]
  name : string;
  play_params : Play_params.t option; [@key "playParams"] [@default None]
  release_date : string option; [@key "releaseDate"] [@default None]
  track_number : int option; [@key "trackNumber"] [@default None]
}
[@@deriving yojson]

type t = {
  attributes : attributes;
  id : string;
  resource_type : Resource.t; [@key "type"]
  href : string;
}
[@@deriving yojson]
