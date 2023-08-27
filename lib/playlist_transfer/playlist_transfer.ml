type _ playlist =
  | Apple : Apple.Library_playlist.t -> Apple.Library_playlist.t playlist
  | Spotify : Spotify.Playlist.t -> Spotify.Playlist.t playlist

type _ converted_playlist =
  | AppleOfSpotify :
      Apple.Library_playlist.t playlist
      -> Spotify.Playlist.t converted_playlist
  | SpotifyOfApple :
      Spotify.Playlist.t playlist
      -> Apple.Library_playlist.t converted_playlist

let convert_apple_to_spotify (_playlist : Apple.Library_playlist.t) :
    Spotify.Playlist.t =
  failwith "TODO"

let convert_spotify_to_apple (_playlist : Spotify.Playlist.t) :
    Apple.Library_playlist.t =
  failwith "TODO"

let make_apple_playlist () : Apple.Library_playlist.t playlist = failwith "TODO"
let make_spotify_playlist () : Spotify.Playlist.t playlist = failwith "TODO"

let convert : type a. a playlist -> a converted_playlist = function
  | Apple playlist ->
      SpotifyOfApple (Spotify (convert_apple_to_spotify playlist))
  | Spotify playlist ->
      AppleOfSpotify (Apple (convert_spotify_to_apple playlist))

let get_spotify_playlist = function
  | SpotifyOfApple (Spotify playlist) -> playlist

let get_apple_playlist = function AppleOfSpotify (Apple playlist) -> playlist

let spotify_playlist =
  let apple_playlist = make_apple_playlist () in
  convert apple_playlist |> get_spotify_playlist

let apple_playlist =
  let spotify_playlist = make_spotify_playlist () in
  convert spotify_playlist |> get_apple_playlist
