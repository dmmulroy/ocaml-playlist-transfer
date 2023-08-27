type apple = Apple of string
type spotify = Spotify of int

type _ playlist =
  | ApplePlaylist : apple -> apple playlist
  | SpotifyPlaylist : spotify -> spotify playlist

type _ converted_playlist =
  | AppleOfSpotify : apple playlist -> spotify converted_playlist
  | SpotifyOfApple : spotify playlist -> apple converted_playlist

let convert : type a. a playlist -> a converted_playlist = function
  | ApplePlaylist (Apple str) ->
      SpotifyOfApple (SpotifyPlaylist (Spotify (int_of_string str)))
  | SpotifyPlaylist (Spotify num) ->
      AppleOfSpotify (ApplePlaylist (Apple (string_of_int num)))

let _ =
  let ap = Apple "apple" in
  let playlist = ApplePlaylist ap in
  let converted = convert playlist in
  match converted with
  | SpotifyOfApple (SpotifyPlaylist (Spotify num)) ->
      print_endline (string_of_int num)
