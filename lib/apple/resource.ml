open Syntax

type t =
  [ `Library_music_videos
  | `Library_playlist_folders
  | `Library_playlists
  | `Library_songs
  | `Music_videos
  | `Playlists
  | `Songs ]

let to_string = function
  | `Library_music_videos -> "library-music-videos"
  | `Library_playlist_folders -> "library-playlist-folders"
  | `Library_playlists -> "library-playlists"
  | `Library_songs -> "library-songs"
  | `Music_videos -> "music-videos"
  | `Playlists -> "playlists"
  | `Songs -> "songs"
  | #t -> .

let of_string = function
  | "library-music-videos" -> Ok `Library_music_videos
  | "library-playlist-folders" -> Ok `Library_playlist_folders
  | "library-playlists" -> Ok `Library_playlists
  | "library-songs" -> Ok `Library_songs
  | "music-videos" -> Ok `Music_videos
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

(* TODO: Attempt to do something like val of_yojson_narrowed ~( narrowed : [<t] )
 * and have fns for each type matching on narrowed
 *)
let of_yojson_narrowed ~(narrow : t -> ([< t ], string) result) json =
  Infix.Result.(of_yojson json >>= narrow)
