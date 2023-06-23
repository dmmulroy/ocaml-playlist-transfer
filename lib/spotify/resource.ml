type t =
  [ `Artist
  | `Album
  | `Episode
  | `Follower
  | `Playlist
  | `Show
  | `Track
  | `User ]

let of_string = function
  | "artist" -> `Artist
  | "album" -> `Album
  | "episode" -> `Episode
  | "follower" -> `Follower
  | "playlist" -> `Playlist
  | "show" -> `Show
  | "track" -> `Track
  | "user" -> `User
  | _ -> failwith "Invalid resource type"

let to_string = function
  | `Artist -> "artist"
  | `Album -> "album"
  | `Episode -> "episode"
  | `Follower -> "follower"
  | `Playlist -> "playlist"
  | `Show -> "show"
  | `Track -> "track"
  | `User -> "user"
  | #t -> .

let of_yojson = function
  | `String "artist" -> Ok `Artist
  | `String "album" -> Ok `Album
  | `String "episode" -> Ok `Episode
  | `String "follower" -> Ok `Follower
  | `String "playlist" -> Ok `Playlist
  | `String "show" -> Ok `Show
  | `String "track" -> Ok `Track
  | `String "user" -> Ok `User
  | _ -> Error "Invalid resource type"

let to_yojson = function
  | `Artist -> `String "artist"
  | `Album -> `String "album"
  | `Episode -> `String "episode"
  | `Follower -> `String "follower"
  | `Playlist -> `String "playlist"
  | `Show -> `String "show"
  | `Track -> `String "track"
  | `User -> `String "user"
  | #t -> .

type reference = { resource_type : t; href : Http.Uri.t option; total : int }
[@@deriving yojson]

type uri = { resource_type : t; id : string } [@@deriving yojson]

let uri_to_string uri =
  Printf.sprintf "spotify:%s:%s" (to_string uri.resource_type) uri.id

let uri_of_string str =
  match String.split_on_char ':' str with
  | [ _; resource_type; id ] -> { resource_type = of_string resource_type; id }
  | _ -> failwith @@ "Invalid Spotify URI: " ^ str

let uri_to_yojson uri = `String (uri_to_string uri)

let uri_of_yojson = function
  | `String str -> Ok (uri_of_string str)
  | _ -> Error "Invalid Spotify URI"
