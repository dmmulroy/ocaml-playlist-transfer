(* open Shared *)

type t = {
  id :
    [ `Apple_library_id of string
    | `Apple_catalog_id of string
    | `Spotify_uri of string ];
  isrc : string;
  name : string;
}
[@@deriving make]

(* let of_apple_catalog_song (track : Apple.Song.t) = *)
(*   { *)
(*     album = track.attributes.album_name; *)
(*     artist = `Individual track.attributes.artist_name; *)
(*     id = `Apple_catalog_id track.id; *)
(*     name = track.attributes.name; *)
(*     isrc = track.attributes.isrc; *)
(*   } *)
(**)
(* let of_apple_library_song (track : Apple.Library_song.t) = *)
(*   { *)
(*     album = track.attributes.album_name; *)
(*     artist = `Individual track.attributes.artist_name; *)
(*     id = `Apple_catalog_id track.id; *)
(*     name = track.attributes.name; *)
(*     isrc = None; *)
(*   } *)
(**)
(* let of_apple_library_music_video (track : Apple.Library_music_video.t) = *)
(*   { *)
(*     album = track.attributes.album_name; *)
(*     artist = `Individual track.attributes.artist_name; *)
(*     id = `Apple_library_id track.id; *)
(*     name = track.attributes.name; *)
(*     isrc = None; *)
(*   } *)
(**)
(* let of_apple = function *)
(*   | `Catalog_song song -> of_apple_catalog_song song *)
(*   | `Library_song song -> of_apple_library_song song *)
(*   | `Library_music_video video -> of_apple_library_music_video video *)
(**)
(* let of_spotify (track : Spotify.Track.t) = *)
(*   { *)
(*     album = Some track.album.name; *)
(*     artist = *)
(*       `Collaboration *)
(*         (List.map *)
(*            (fun (artist : Spotify.Simple_artist.t) -> artist.name) *)
(*            track.artists); *)
(*     id = `Spotify_uri track.uri; *)
(*     name = track.name; *)
(*     isrc = track.external_ids.isrc; *)
(*   } *)
