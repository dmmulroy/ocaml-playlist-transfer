type attributes = {
  album_name : string; [@key "albumName"]
  artist_name : string; [@key "artistName"]
  artist_url : string; [@key "artistUrl"]
  artwork : Artwork.t; [@key "artwork"]
  content_rating : string; [@key "contentRating"]
  duration_in_millis : int; [@key "durationInMillis"]
  (* editorial_notes : EditorialNotes.t; [@key "editorialNotes"] *)
  genre_names : string list; [@key "genreNames"]
  has_4k : bool; [@key "has4K"]
  has_hdr : bool; [@key "hasHDR"]
  isrc : string; [@key "isrc"]
  name : string; [@key "name"]
  (* play_params : PlayParameters.t; [@key "playParams"] *)
  (* previews : Preview.t list; [@key "previews"] *)
  release_date : string; [@key "releaseDate"]
  track_number : int; [@key "trackNumber"]
  url : string; [@key "url"]
  video_sub_type : string; [@key "videoSubType"]
  work_id : string; [@key "workId"]
  work_name : string; [@key "workName"]
}
[@@deriving yojson { strict = false }]
(* TODO: Finish implementing types *)

type t = {
  attributes : attributes;
  id : string;
  resource_type : Resource.t;
  href : string;
}
[@@deriving yojson]
