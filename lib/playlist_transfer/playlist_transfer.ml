type _ x = Int : int -> string x | String : string -> int x

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

type _ int_or_string = Int : int int_or_string | String : string int_or_string

let get_value : type a. a int_or_string -> a = function
  | Int -> Random.int 101
  | String -> string_of_int (Random.int 101)

let value = get_value Int (* Some Random Int between 0 and 100  *)
let value = get_value String (* Some Random String *)

type _ int_or_string =
  | Int : int -> int int_or_string
  | String : string -> string int_or_string

let double : type a. a int_or_string -> a = function
  | Int i -> i * 2
  | String s -> s ^ s

let value = double (Int 2) (* 4 *)
let value = double (String "hello") (* "hellohello" *)

type _ int_or_string =
  | Int : int -> string int_or_string
  | String : string -> int int_or_string

let transform : type a. a int_or_string -> a = function
  | Int i -> string_of_int i
  | String s -> int_of_string s

let value = transform (Int 2) (* "2" *)
let value = transform (String "2") (* 2 *)
