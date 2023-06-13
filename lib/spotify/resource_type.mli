type t = [ `Episode | `Playlist | `Track | `User ] [@@deriving yojson]
type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]

val playlist_of_yojson : Yojson.Safe.t -> ([ `Playlist ], string) result
val episode_of_yojson : Yojson.Safe.t -> ([ `Episode ], string) result
val episode_to_yojson : [ `Episode ] -> Yojson.Safe.t
val playlist_to_yojson : [ `Playlist ] -> Yojson.Safe.t
val track_of_yojson : Yojson.Safe.t -> ([ `Track ], string) result
val track_to_yojson : [ `Track ] -> Yojson.Safe.t
val user_of_yojson : Yojson.Safe.t -> ([ `User ], string) result
val user_to_yojson : [ `User ] -> Yojson.Safe.t
val of_string : string -> t
val to_string : [< t ] -> string
