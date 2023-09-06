type t = {
  album : string option;
  artist : [ `Individual of string | `Collaboration of string list ];
  (* This will be the track uri for Spotify and the track id for Apple *)
  id : string;
  name : string;
}

let of_apple (song : Apple.Library_song.t) =
  {
    album = song.attributes.album_name;
    artist = `Individual song.attributes.artist_name;
    id = song.id;
    name = song.attributes.name;
  }

let of_spotify (track : Spotify.Track.t) =
  {
    album = Some track.album.name;
    artist =
      `Collaboration
        (List.map
           (fun (artist : Spotify.Simple_artist.t) -> artist.name)
           track.artists);
    id = track.id;
    name = track.name;
  }
