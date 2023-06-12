type t =
  ([ `Playlist | `Track | `User ]
  [@of_yojson
    fun json ->
      match json with
      | `String "playlist" -> Ok `Playlist
      | `String "track" -> Ok `Track
      | `String "user" -> Ok `User
      | _ -> Error "Invalid resource type"]
  [@to_yojson
    fun resource_type ->
      `String
        (match resource_type with
        | `Playlist -> "playlist"
        | `Track -> "track"
        | `User -> "user")])
[@@deriving yojson]

type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]

let of_string = function
  | "playlist" -> `Playlist
  | "track" -> `Track
  | "user" -> `User
  | _ -> failwith "Invalid resource"

let to_string = function
  | `Playlist -> "playlist"
  | `Track -> "track"
  | `User -> "user"

type _ resource_type =
  | Playlist : [ `Playlist ] resource_type
  | Track : [ `Track ] resource_type
  | User : [ `User ] resource_type

let make_resource_of_yojson :
    type a. a resource_type -> Yojson.Safe.t -> (a, string) result =
 fun resource_type json ->
  match (resource_type, json) with
  | Playlist, `String "playlist" -> Ok `Playlist
  | Track, `String "track" -> Ok `Track
  | User, `String "user" -> Ok `User
  | _, _ -> Error "Invalid resource type"

let make_resource_to_yojson : type a. a resource_type -> a -> Yojson.Safe.t =
 fun resource_type resource ->
  match (resource_type, resource) with
  | Playlist, `Playlist -> `String "playlist"
  | Track, `Track -> `String "track"
  | User, `User -> `String "user"

let playlist_resource_of_yojson = make_resource_of_yojson Playlist
let playlist_resource_to_yojson = make_resource_to_yojson Playlist
let track_resource_of_yojson = make_resource_of_yojson Track
let track_resource_to_yojson = make_resource_to_yojson Track
let user_resource_of_yojson = make_resource_of_yojson User
let user_resource_to_yojson = make_resource_to_yojson User
