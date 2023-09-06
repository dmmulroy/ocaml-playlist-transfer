type t = {
  album : string option;
  artist : [ `Individual of string | `Collaboration of string list ];
  (* This will be the track uri for Spotify and the track id for Apple *)
  id : string;
  name : string;
}

let of_apple = function
  | `Library_song (track : Apple.Library_song.t) ->
      {
        album = track.attributes.album_name;
        artist = `Individual track.attributes.artist_name;
        id = track.id;
        name = track.attributes.name;
      }
  | `Library_music_video (track : Apple.Library_music_video.t) ->
      {
        album = track.attributes.album_name;
        artist = `Individual track.attributes.artist_name;
        id = track.id;
        name = track.attributes.name;
      }

let of_spotify (track : Spotify.Track.t) =
  {
    album = Some track.album.name;
    artist =
      `Collaboration
        (List.map
           (fun (artist : Spotify.Simple_artist.t) -> artist.name)
           track.artists);
    id = track.uri;
    name = track.name;
  }
