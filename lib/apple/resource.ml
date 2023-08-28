type t =
  ([ `Libray_music_videos
   | `Libray_songs
   | `Library_playlists
   | `Playlist
   | `Song ]
  [@deriving yojson])

let to_string = function
  | `Library_playlists -> "library-playlists"
  | `Libray_songs -> "library-songs"
  | `Libray_music_videos -> "library-music-videos"
  | `Playlist -> "playlist"
  | `Song -> "song"
  | #t -> .

let of_string = function
  | "library-playlists" -> Ok `Library_playlists
  | "library-songs" -> Ok `Libray_songs
  | "library-music-videos" -> Ok `Libray_music_videos
  | "playlist" -> Ok `Playlist
  | "song" -> Ok `Song
  | _ -> Error "Invalid resource type"

let of_yojson = function
  | `String "library-playlists" -> Ok `Library_playlists
  | `String "library-songs" -> Ok `Libray_songs
  | `String "library-music-videos" -> Ok `Libray_music_videos
  | `String "playlist" -> Ok `Playlist
  | `String "song" -> Ok `Song
  | _ -> Error "Invalid resource type"

let to_yojson = function
  | `Library_playlists -> `String "library-playlists"
  | `Libray_songs -> `String "library-songs"
  | `Libray_music_videos -> `String "library-music-videos"
  | `Playlist -> `String "playlist"
  | `Song -> `String "song"
  | #t -> .
