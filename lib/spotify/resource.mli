type t =
  [ `Artist
  | `Album
  | `Episode
  | `Follower
  | `Playlist
  | `Show
  | `Track
  | `User ]
[@@deriving yojson]

val of_string : string -> t
val to_string : t -> string
