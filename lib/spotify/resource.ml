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
