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
let get_name t = Option.map (fun a -> a.name) t.attributes
let get_album_name t = Option.map (fun a -> a.album_name) t.attributes
let get_artist_name t = Option.map (fun a -> a.artist_name) t.attributes
let get_duration_ms t = Option.map (fun a -> a.duration_ms) t.attributes
let get_genre_names t = Option.map (fun a -> a.genre_names) t.attributes
let get_track_number t = Option.map (fun a -> a.track_number) t.attributes
let get_release_date t = Option.map (fun a -> a.release_date) t.attributes
