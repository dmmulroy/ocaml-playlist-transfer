type t = [ `Playlist | `Song ]

let to_string = function `Playlist -> "playlist" | `Song -> "song"

let of_string = function
  | "playlist" -> `Playlist
  | "song" -> `Song
  | _ -> failwith "Invalid resource type"

let of_yojson = function
  | `String "playlist" -> Ok `Playlist
  | `String "song" -> Ok `Song
  | _ -> Error "Invalid resource type"

let to_yojson = function
  | `Playlist -> `String "playlist"
  | `Song -> `String "song"
