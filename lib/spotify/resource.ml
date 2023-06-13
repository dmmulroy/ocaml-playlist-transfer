type t = [ `Episode | `Playlist | `Track | `User ] [@@deriving yojson]
type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]

let of_string = function
  | "episode" -> `Episode
  | "playlist" -> `Playlist
  | "track" -> `Track
  | "user" -> `User
  | _ -> failwith "Invalid resource type"

let to_string = function
  | `Episode -> "episode"
  | `Playlist -> "playlist"
  | `Track -> "track"
  | `User -> "user"
  | #t -> .

let of_yojson json =
  match json with
  | `String str -> Ok (of_string str)
  | _ -> Error "Invalid resource type"

let to_yojson resource_type = `String (to_string resource_type)

type _ resource_type_specifier =
  | Episode : [ `Episode ] resource_type_specifier
  | Playlist : [ `Playlist ] resource_type_specifier
  | Track : [ `Track ] resource_type_specifier
  | User : [ `User ] resource_type_specifier

let make_resource_of_yojson :
    type a. a resource_type_specifier -> Yojson.Safe.t -> (a, string) result =
 fun resource_type json ->
  match (resource_type, json) with
  | Episode, `String "episode" -> Ok `Episode
  | Playlist, `String "playlist" -> Ok `Playlist
  | Track, `String "track" -> Ok `Track
  | User, `String "user" -> Ok `User
  | _, _ -> Error "Invalid resource type"

let make_resource_to_yojson :
    type a. a resource_type_specifier -> a -> Yojson.Safe.t =
 fun resource_type resource ->
  match (resource_type, resource) with
  | Episode, `Episode -> `String "episode"
  | Playlist, `Playlist -> `String "playlist"
  | Track, `Track -> `String "track"
  | User, `User -> `String "user"

let episode_resource_of_yojson = make_resource_of_yojson Episode
let episode_resource_to_yojson = make_resource_to_yojson Episode
let playlist_resource_of_yojson = make_resource_of_yojson Playlist
let playlist_resource_to_yojson = make_resource_to_yojson Playlist
let track_resource_of_yojson = make_resource_of_yojson Track
let track_resource_to_yojson = make_resource_to_yojson Track
let user_resource_of_yojson = make_resource_of_yojson User
let user_resource_to_yojson = make_resource_to_yojson User
