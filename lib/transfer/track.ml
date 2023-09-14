type t = {
  album : string option;
  artist : [ `Individual of string | `Collaboration of string list ];
  (* This will be the track uri for Spotify and the catalog id for Apple *)
  id :
    [ `Apple_library_id of string
    | `Apple_catalog_id of string
    | `Spotify_uri of string ];
  isrc : string option;
  name : string;
}

let of_apple_catalog_song (track : Apple.Song.t) =
  {
    album = track.attributes.album_name;
    artist = `Individual track.attributes.artist_name;
    id = `Apple_catalog_id track.id;
    name = track.attributes.name;
    isrc = Some track.attributes.isrc;
  }

let of_apple_library_song (track : Apple.Library_song.t) =
  {
    album = track.attributes.album_name;
    artist = `Individual track.attributes.artist_name;
    id = `Apple_catalog_id track.id;
    name = track.attributes.name;
    isrc = None;
  }

let of_apple = function
  | `Catalog song -> of_apple_catalog_song song
  | `Library song -> of_apple_library_song song

let of_apple_library_music_video (track : Apple.Library_music_video.t) =
  {
    album = track.attributes.album_name;
    artist = `Individual track.attributes.artist_name;
    id = `Apple_library_id track.id;
    name = track.attributes.name;
    isrc = None;
  }

let of_spotify (track : Spotify.Track.t) =
  {
    album = Some track.album.name;
    artist =
      `Collaboration
        (List.map
           (fun (artist : Spotify.Simple_artist.t) -> artist.name)
           track.artists);
    id = `Spotify_uri track.uri;
    name = track.name;
    isrc = track.external_ids.isrc;
  }
