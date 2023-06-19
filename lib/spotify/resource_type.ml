type t = [ `Album | `Episode | `Playlist | `Track | `User ] [@@deriving yojson]
type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]

let of_string = function
  | "album" -> `Album
  | "episode" -> `Episode
  | "playlist" -> `Playlist
  | "track" -> `Track
  | "user" -> `User
  | str -> failwith @@ "Invalid resource type: " ^ str

let to_string = function
  | `Album -> "album"
  | `Episode -> "episode"
  | `Playlist -> "playlist"
  | `Track -> "track"
  | `User -> "user"
  | #t -> .

let of_yojson = function
  | `String str -> Ok (of_string str)
  | _ -> Error "Invalid resource type"

let to_yojson resource_type = `String (to_string resource_type)

type _ resource_type_specifier =
  | Album : [ `Album ] resource_type_specifier
  | Episode : [ `Episode ] resource_type_specifier
  | Playlist : [ `Playlist ] resource_type_specifier
  | Track : [ `Track ] resource_type_specifier
  | User : [ `User ] resource_type_specifier

let make_resource_to_yojson :
    type a. a resource_type_specifier -> a -> Yojson.Safe.t =
 fun resource_type resource ->
  match (resource_type, resource) with
  | Album, `Album -> `String "album"
  | Episode, `Episode -> `String "episode"
  | Playlist, `Playlist -> `String "playlist"
  | Track, `Track -> `String "track"
  | User, `User -> `String "user"

let make_resource_of_yojson :
    type a. a resource_type_specifier -> Yojson.Safe.t -> (a, string) result =
 fun resource_type json ->
  match (resource_type, json) with
  | Album, `String "album" -> Ok `Album
  | Episode, `String "episode" -> Ok `Episode
  | Playlist, `String "playlist" -> Ok `Playlist
  | Track, `String "track" -> Ok `Track
  | User, `String "user" -> Ok `User
  | _, _ -> Error "Invalid resource type"

let album_of_yojson = make_resource_of_yojson Album
let album_to_yojson = make_resource_to_yojson Album
let episode_of_yojson = make_resource_of_yojson Episode
let episode_to_yojson = make_resource_to_yojson Episode
let playlist_of_yojson = make_resource_of_yojson Playlist
let playlist_to_yojson = make_resource_to_yojson Playlist
let track_of_yojson = make_resource_of_yojson Track
let track_to_yojson = make_resource_to_yojson Track
let user_of_yojson = make_resource_of_yojson User
let user_to_yojson = make_resource_to_yojson User
