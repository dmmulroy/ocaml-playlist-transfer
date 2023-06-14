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

let of_yojson = function
  | `String str -> Ok (of_string str)
  | _ -> Error "Invalid resource type"

let to_yojson resource_type = `String (to_string resource_type)

type _ resource_type_specifier =
  | Episode : [ `Episode ] resource_type_specifier
  | Playlist : [ `Playlist ] resource_type_specifier
  | Track : [ `Track ] resource_type_specifier
  | User : [ `User ] resource_type_specifier

let make_resource_to_yojson :
    type a. a resource_type_specifier -> a -> Yojson.Safe.t =
 fun resource_type resource ->
  match (resource_type, resource) with
  | Episode, `Episode -> `String "episode"
  | Playlist, `Playlist -> `String "playlist"
  | Track, `Track -> `String "track"
  | User, `User -> `String "user"

let make_resource_of_yojson :
    type a. a resource_type_specifier -> Yojson.Safe.t -> (a, string) result =
 fun resource_type json ->
  match (resource_type, json) with
  | Episode, `String "episode" -> Ok `Episode
  | Playlist, `String "playlist" -> Ok `Playlist
  | Track, `String "track" -> Ok `Track
  | User, `String "user" -> Ok `User
  | _, _ -> Error "Invalid resource type"

let episode_of_yojson = make_resource_of_yojson Episode
let episode_to_yojson = make_resource_to_yojson Episode
let playlist_of_yojson = make_resource_of_yojson Playlist
let playlist_to_yojson = make_resource_to_yojson Playlist
let track_of_yojson = make_resource_of_yojson Track
let track_to_yojson = make_resource_to_yojson Track
let user_of_yojson = make_resource_of_yojson User
let user_to_yojson = make_resource_to_yojson User

(* let resource_of_yojson resource resource_of_yojson json = *)
(*   match Yojson.Safe.Util.member "items" json with *)
(*   | exception Yojson.Safe.Util.Type_error _ -> ( *)
(*       match resource_of_yojson json with *)
(*       | Error _ -> Error "Resource response is missing required fields" *)
(*       | Ok data -> Ok (resource data)) *)
(*   | _ -> ( *)
(*       match Paginated_response.of_yojson resource_of_yojson json with *)
(*       | Error _ -> Error "Resource response is missing required fields" *)
(*       | Ok data -> Ok (resource data)) *)
