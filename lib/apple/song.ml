[@@@ocaml.warning "-69"]

type song_attributes = {
  name : string;
  album_name : string option;
  artist_name : string;
  artwork : Common.artwork;
  content_rating : [ `Clean | `Explicit ] option;
  disc_number : int option;
  duration_ms : int;
  genre_names : string list;
  has_lyrics : bool;
  release_date : string option;
  track_number : int option;
}

type t = {
  id : string;
  song_type : [ `Library ];
  href : string;
  attributes : song_attributes option;
}

let get_id t = t.id
let get_name t = match t.attributes with Some a -> Some a.name | None -> None

let get_album_name t =
  match t.attributes with Some a -> a.album_name | None -> None

let get_artist_name t =
  match t.attributes with Some a -> Some a.artist_name | None -> None

let get_duration_ms t =
  match t.attributes with Some a -> Some a.duration_ms | None -> None

let get_genre_names t =
  match t.attributes with Some a -> Some a.genre_names | None -> None

let get_track_number t =
  match t.attributes with Some a -> a.track_number | None -> None

let get_release_date t =
  match t.attributes with Some a -> a.release_date | None -> None
