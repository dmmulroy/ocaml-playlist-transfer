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

type reference = { resource_type : t; href : Http.Uri.t option; total : int }
[@@deriving yojson]

type uri [@@deriving yojson]

val uri_of_string : string -> uri
val uri_to_string : uri -> string
