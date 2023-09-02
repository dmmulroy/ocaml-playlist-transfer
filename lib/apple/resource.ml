type t =
  [ `Libray_music_videos
  | `Libray_songs
  | `Library_playlists
  | `Playlists
  | `Songs ]

let to_string = function
  | `Library_playlists -> "library-playlists"
  | `Libray_songs -> "library-songs"
  | `Libray_music_videos -> "library-music-videos"
  | `Playlists -> "playlists"
  | `Songs -> "songs"
  | #t -> .

let of_string = function
  | "library-playlists" -> Ok `Library_playlists
  | "library-songs" -> Ok `Libray_songs
  | "library-music-videos" -> Ok `Libray_music_videos
  | "playlists" -> Ok `Playlists
  | "songs" -> Ok `Songs
  | _ -> Error "Invalid resource type"

let of_yojson = function
  | `String resource -> of_string resource
  | _ -> Error "Invalid resource type"

let to_yojson resource = `String (to_string resource)

let of_string_list resources =
  List.filter_map
    (fun resource -> Result.to_option @@ of_string resource)
    resources

let to_string_list resources = List.map to_string resources
