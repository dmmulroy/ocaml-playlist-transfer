type resource_type =
  [ `Artist
  | `Album
  | `Episode
  | `Follower
  | `Playlist
  | `Show
  | `Track
  | `User ]
[@@deriving yojson]

type 'a t = 'a constraint 'a = [< resource_type ] [@@deriving yojson]

val of_string : string -> resource_type t
val to_string : resource_type t -> string

type 'a reference = {
  resource_type : 'a;
  href : Http.Uri.t option;
  total : int;
}
  constraint 'a = [< resource_type ]
[@@deriving yojson]

type 'a uri = {
  resource_type : 'a;
  id : string;
}
  constraint 'a = [< resource_type ]
[@@deriving yojson]

val uri_of_string : string -> resource_type uri
val uri_to_string : resource_type uri -> string
