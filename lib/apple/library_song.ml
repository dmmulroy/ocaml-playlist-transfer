type attributes = {
  album_name : string option; [@key "albumName"] [@default None]
  artist_name : string option; [@key "artistName"] [@default None]
  (* artwork : Artwork.t; *)
  content_rating : string option; [@key "contentRating"] [@default None]
  disc_number : int option; [@key "discNumber"] [@default None]
  duration_in_millis : int; [@key "durationInMillis"]
  genre_names : string list; [@key "genreNames"]
  has_lyrics : bool; [@key "hasLyrics"]
  name : string;
  play_params : Play_params.t; [@key "playParams"]
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
