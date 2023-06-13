type t = [ `Episode | `Playlist | `Track | `User ] [@@deriving yojson]
type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]

val playlist_resource_of_yojson :
  Yojson.Safe.t -> ([ `Playlist ], string) result

val episode_resource_of_yojson : Yojson.Safe.t -> ([ `Episode ], string) result
val episode_resource_to_yojson : [ `Episode ] -> Yojson.Safe.t
val playlist_resource_to_yojson : [ `Playlist ] -> Yojson.Safe.t
val track_resource_of_yojson : Yojson.Safe.t -> ([ `Track ], string) result
val track_resource_to_yojson : [ `Track ] -> Yojson.Safe.t
val user_resource_of_yojson : Yojson.Safe.t -> ([ `User ], string) result
val user_resource_to_yojson : [ `User ] -> Yojson.Safe.t
val of_string : string -> t
val to_string : [< t ] -> string
