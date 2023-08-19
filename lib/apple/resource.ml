type t = [ `Library_playlists | `Playlist | `Song ]

let to_string = function
  | `Library_playlists -> "library-playlists"
  | `Playlist -> "playlist"
  | `Song -> "song"

let of_string = function
  | "library-playlists" -> `Library_playlists
  | "playlist" -> `Playlist
  | "song" -> `Song
  | _ -> failwith "Invalid resource type"

let of_yojson = function
  | `String "library-playlists" -> Ok `Library_playlists
  | `String "playlist" -> Ok `Playlist
  | `String "song" -> Ok `Song
  | _ -> Error "Invalid resource type"

let to_yojson = function
  | `Library_playlists -> `String "library-playlists"
  | `Playlist -> `String "playlist"
  | `Song -> `String "song"
