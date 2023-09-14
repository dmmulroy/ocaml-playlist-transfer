type t = {
  album : string option;
  artist : [ `Individual of string | `Collaboration of string list ];
  (* This will be the track uri for Spotify and the track id for Apple *)
  id : [ `Apple of string | `Spotify of string ];
  isrc : string;
  name : string;
}

let of_apple = function
  | `Library_song (track : Apple.Song.t) ->
      {
        album = track.attributes.album_name;
        artist = `Individual track.attributes.artist_name;
        id = `Apple track.id;
        name = track.attributes.name;
        isrc = track.attributes.isrc;
      }
  | `Library_music_video (track : Apple.Music_video.t) ->
      {
        album = Some track.attributes.album_name;
        artist = `Individual track.attributes.artist_name;
        id = `Apple track.id;
        name = track.attributes.name;
        isrc = track.attributes.isrc;
      }

let of_spotify (track : Spotify.Track.t) =
  {
    album = Some track.album.name;
    artist =
      `Collaboration
        (List.map
           (fun (artist : Spotify.Simple_artist.t) -> artist.name)
           track.artists);
    id = `Spotify track.uri;
    name = track.name;
    isrc = Option.get track.external_ids.isrc;
    (* TODO: Don't use Option.get *)
  }
