[@@@ocaml.warning "-32"]

open Shared
open Syntax

module Resource = struct
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

  let of_yojson_narrowed ~(narrow : t -> ([< t ], string) result) json =
    Infix.Result.(of_yojson json >>= narrow)

  let to_yojson resource = `String (to_string resource)

  let of_string_list resources =
    List.filter_map
      (fun resource -> Result.to_option @@ of_string resource)
      resources

  let to_string_list resources = List.map to_string resources
end

module Artwork = struct
  type t = {
    bg_color : string option; [@key "bgColor"] [@default None]
    height : int option; [@default None]
    width : int option; [@default None]
    text_color1 : string option; [@key "textColor1"] [@default None]
    text_color2 : string option; [@key "textColor2"] [@default None]
    text_color3 : string option; [@key "textColor3"] [@default None]
    text_color4 : string option; [@key "textColor4"] [@default None]
    url : string;
  }
  [@@deriving yojson]
end

module Content_rating = struct
  type t = [ `Clean | `Explicit ] [@@deriving yojson]

  let content_rating_to_string = function
    | `Clean -> "clean"
    | `Explicit -> "explicit"

  let content_rating_of_string = function
    | "clean" -> Ok `Clean
    | "explicit" -> Ok `Explicit
    | _ -> Error "Invalid content rating"

  let content_rating_to_yojson content_rating =
    `String (content_rating_to_string content_rating)

  let content_rating_of_yojson = function
    | `String s -> content_rating_of_string s
    | _ -> Error "Invalid content rating"
end

module Description = struct
  type t = { standard : string; short : string option [@default None] }
  [@@deriving yojson]
end

module Play_params = struct
  type kind = [ `Playlist | `Song ]

  let kind_to_string = function `Playlist -> "playlist" | `Song -> "song"

  let kind_of_string = function
    | "playlist" -> Ok `Playlist
    | "song" -> Ok `Song
    | _ -> Error "Invalid kind"

  let kind_to_yojson kind = `String (kind_to_string kind)

  let kind_of_yojson = function
    | `String s -> kind_of_string s
    | _ -> Error "Invalid kind"

  type t = {
    catalog_id : string option; [@default None] [@key "catalogId"]
    global_id : string option; [@default None] [@key "globalId"]
    id : string;
    is_library : bool option; [@key "isLibrary"] [@default None]
    kind : kind;
    reporting : bool option; [@default None]
    reporting_id : string option; [@default None] [@key "reportingId"]
    version_hash : string option; [@default None] [@key "versionHash"]
  }
  [@@deriving yojson]
end

module rec Relationship : sig
  type catalog =
    [ `Catalog_playlist of Playlist.t Page.t | `Catalog_song of Song.t Page.t ]
  [@@deriving yojson]

  type tracks =
    [ `Library_song of Library_song.t Page.t
    | `Library_music_video of Library_music_video.t Page.t ]
  [@@deriving yojson]

  type t = { catalog : catalog option; tracks : tracks option }
  [@@deriving yojson]
end = struct
  type catalog =
    [ `Catalog_playlist of Playlist.t Page.t | `Catalog_song of Song.t Page.t ]
  [@@deriving yojson]

  let catalog_of_yojson_opt json =
    match Page.of_yojson Song.of_yojson json with
    | Ok page -> Ok (Option.some (`Catalog_song page))
    | Error _ -> (
        match Page.of_yojson Playlist.of_yojson json with
        | Ok page -> Ok (Option.some (`Catalog_playlist page))
        | Error _ -> Error "Invalid catalog")

  type tracks =
    [ `Library_song of Library_song.t Page.t
    | `Library_music_video of Library_music_video.t Page.t ]
  [@@deriving yojson]

  let tracks_of_yojson_opt json =
    match Page.of_yojson Library_song.of_yojson json with
    | Ok page -> Ok (Option.some (`Library_song page))
    | Error _ -> (
        match Page.of_yojson Library_music_video.of_yojson json with
        | Ok page -> Ok (Option.some (`Library_music_video page))
        | Error _ -> Error "Invalid catalog")

  type t = {
    catalog : catalog option; [@default None] [@of_yojson catalog_of_yojson_opt]
    tracks : tracks option; [@default None] [@of_yojson tracks_of_yojson_opt]
  }
  [@@deriving yojson]
end

and Song : sig
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Artwork.t;
    content_rating : Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    isrc : string option;
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson { strict = false }]

  val narrow_resource_type : [> `Songs ] -> ([ `Songs ], string) result

  (* TODO: Type relationships *)
  type t = {
    attributes : attributes;
    (* relationships : unit; *)
    id : string;
    resource_type : [ `Songs ];
        [@key "type"]
        [@to_yojson Resource.to_yojson]
        [@of_yojson Resource.of_yojson_narrowed ~narrow:narrow_resource_type]
    href : string;
  }
  [@@deriving yojson { strict = false }]
end = struct
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Artwork.t;
    content_rating : Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    isrc : string option;
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson { strict = false }]

  let narrow_resource_type = function
    | `Songs as resource -> Ok (resource :> [ `Songs ])
    | _ -> Error "fail" (* TODO: Create Internal Error + Map to Apple Error *)

  (* TODO: Type relationships *)
  type t = {
    attributes : attributes;
    (* relationships : unit; *)
    id : string;
    resource_type : [ `Songs ]; [@key "type"]
        (* [@to_yojson Resource.to_yojson]
           [@of_yojson Resource.of_yojson_narrowed ~narrow:narrow_resource_type] *)
    href : string;
  }
  [@@deriving yojson { strict = false }]
end

and Playlist : sig
  type playlist_type =
    [ `Editoral | `External | `Personal_mix | `Replay | `User_shared ]
  [@@deriving yojson]

  val playlist_type_to_string : playlist_type -> string
  val playlist_type_of_string : string -> (playlist_type, string) result

  type attributes = {
    artwork : Artwork.t option; [@default None]
    curator_name : string; [@key "curatorName"]
    is_chart : bool; [@key "isChart"]
    description : Description.t option; [@default None]
    last_modified_date : string option;
        [@key "lastModifiedDate"] [@default None]
    name : string;
    playlist_type : playlist_type; [@key "playlistType"]
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    track_types : Resource.t list option; [@key "trackTypes"] [@default None]
    url : Http.Uri.t;
  }
  [@@deriving yojson]

  (* TODO: relationships & views *)
  type t = {
    id : string;
    href : string;
    resource_type : Resource.t; [@key "type"]
    attributes : attributes;
        (* realationships : unit option; [@default None] *)
        (* views : unit option; [@default None] *)
  }
  [@@deriving yojson { strict = false }]
end = struct
  type playlist_type =
    [ `Editoral | `External | `Personal_mix | `Replay | `User_shared ]
  [@@deriving yojson]

  let playlist_type_to_string = function
    | `Editoral -> "editorial"
    | `External -> "external"
    | `Personal_mix -> "personal-mix"
    | `Replay -> "replay"
    | `User_shared -> "user-shared"
    | #playlist_type -> .

  let playlist_type_of_string = function
    | "editorial" -> Ok `Editoral
    | "external" -> Ok `External
    | "personal-mix" -> Ok `Personal_mix
    | "replay" -> Ok `Replay
    | "user-shared" -> Ok `User_shared
    | _ -> Error "Invalid playlist type"

  let playlist_type_of_string = function
    | "editorial" -> Ok `Editoral
    | "external" -> Ok `External
    | "personal-mix" -> Ok `Personal_mix
    | "replay" -> Ok `Replay
    | "user-shared" -> Ok `User_shared
    | _ -> Error "Invalid playlist type"

  let playlist_type_to_yojson playlist_type =
    `String (playlist_type_to_string playlist_type)

  let playlist_type_of_yojson = function
    | `String playlist_type -> playlist_type_of_string playlist_type
    | _ -> Error "Invalid playlist type"

  type attributes = {
    artwork : Artwork.t option; [@default None]
    curator_name : string; [@key "curatorName"]
    is_chart : bool; [@key "isChart"]
    description : Description.t option; [@default None]
    last_modified_date : string option;
        [@key "lastModifiedDate"] [@default None]
    name : string;
    playlist_type : playlist_type; [@key "playlistType"]
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    track_types : Resource.t list option; [@key "trackTypes"] [@default None]
    url : Http.Uri.t;
  }
  [@@deriving yojson]

  (* TODO: relationships & views *)
  type t = {
    id : string;
    href : string;
    resource_type : Resource.t; [@key "type"]
    attributes : attributes;
        (* realationships : unit option; [@default None] *)
        (* views : unit option; [@default None] *)
  }
  [@@deriving yojson { strict = false }]
end

and Library_song : sig
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Artwork.t;
    content_rating : Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson { strict = false }]

  type t = {
    attributes : attributes;
    relationships : Relationship.t option; [@default None]
    id : string;
    resource_type : Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson { strict = false }]
end = struct
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Artwork.t;
    content_rating : Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson { strict = false }]

  type t = {
    attributes : attributes;
    relationships : Relationship.t option; [@default None]
    id : string;
    resource_type : Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson { strict = false }]
end

and Library_music_video : sig
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Artwork.t;
    content_rating : Content_rating.t option;
        [@key "contentRating"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson]

  type t = {
    attributes : attributes;
    id : string;
    resource_type : Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson]
end = struct
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Artwork.t;
    content_rating : Content_rating.t option;
        [@key "contentRating"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson]

  type t = {
    attributes : attributes;
    id : string;
    resource_type : Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson]
end

(* module Playlist = struct
     type playlist_type =
       [ `Editoral | `External | `Personal_mix | `Replay | `User_shared ]
     [@@deriving yojson]

     let playlist_type_to_string = function
       | `Editoral -> "editorial"
       | `External -> "external"
       | `Personal_mix -> "personal-mix"
       | `Replay -> "replay"
       | `User_shared -> "user-shared"
       | #playlist_type -> .

     let playlist_type_of_string = function
       | "editorial" -> Ok `Editoral
       | "external" -> Ok `External
       | "personal-mix" -> Ok `Personal_mix
       | "replay" -> Ok `Replay
       | "user-shared" -> Ok `User_shared
       | _ -> Error "Invalid playlist type"

     let playlist_type_to_yojson playlist_type =
       `String (playlist_type_to_string playlist_type)

     let playlist_type_of_yojson = function
       | `String playlist_type -> playlist_type_of_string playlist_type
       | _ -> Error "Invalid playlist type"

     type attributes = {
       artwork : Artwork.t option; [@default None]
       curator_name : string; [@key "curatorName"]
       is_chart : bool; [@key "isChart"]
       description : Description.t option; [@default None]
       last_modified_date : string option;
           [@key "lastModifiedDate"] [@default None]
       name : string;
       playlist_type : playlist_type; [@key "playlistType"]
       play_params : Play_params.t option; [@key "playParams"] [@default None]
       track_types : Resource.t list option; [@key "trackTypes"] [@default None]
       url : Http.Uri.t;
     }
     [@@deriving yojson]

     (* TODO: relationships & views *)
     type t = {
       id : string;
       href : string;
       resource_type : Resource.t; [@key "type"]
       attributes : attributes;
           (* realationships : unit option; [@default None] *)
           (* views : unit option; [@default None] *)
     }
     [@@deriving yojson { strict = false }]
   end *)

(* module Song = struct
     type attributes = {
       album_name : string option; [@key "albumName"] [@default None]
       artist_name : string; [@key "artistName"]
       artwork : Artwork.t;
       content_rating : Content_rating.t option;
           [@key "contentRating"] [@default None]
       disc_number : int option; [@key "discNumber"] [@default None]
       duration_in_millis : int; [@key "durationInMillis"]
       genre_names : string list; [@key "genreNames"]
       has_credits : bool; [@key "hasCredits"]
       has_lyrics : bool; [@key "hasLyrics"]
       isrc : string option;
       name : string;
       play_params : Play_params.t option; [@key "playParams"] [@default None]
       release_date : string option; [@key "releaseDate"] [@default None]
       track_number : int option; [@key "trackNumber"] [@default None]
     }
     [@@deriving yojson { strict = false }]

     let narrow_resource_type = function
       | `Songs as resource -> Ok (resource :> [ `Songs ])
       | _ -> Error "fail" (* TODO: Create Internal Error + Map to Apple Error *)

     (* TODO: Type relationships *)
     type t = {
       attributes : attributes;
       (* relationships : unit; *)
       id : string;
       resource_type : [ `Songs ];
           [@key "type"]
           [@to_yojson Resource.to_yojson]
           [@of_yojson Resource.of_yojson_narrowed ~narrow:narrow_resource_type]
       href : string;
     }
     [@@deriving yojson { strict = false }]
   end
*)

(* module Library_music_video = struct
     type attributes = {
       album_name : string option; [@key "albumName"] [@default None]
       artist_name : string; [@key "artistName"]
       artwork : Artwork.t;
       content_rating : [ `Clean | `Explicit ] option;
           [@key "contentRating"] [@default None]
       duration_in_millis : int; [@key "durationInMillis"]
       genre_names : string list; [@key "genreNames"]
       name : string;
       play_params : Play_params.t option; [@key "playParams"] [@default None]
       release_date : string option; [@key "releaseDate"] [@default None]
       track_number : int option; [@key "trackNumber"] [@default None]
     }
     [@@deriving yojson]

     type t = {
       attributes : attributes;
       id : string;
       resource_type : Resource.t; [@key "type"]
       href : string;
     }
     [@@deriving yojson]
   end

   module Library_song = struct
     type attributes = {
       album_name : string option; [@key "albumName"] [@default None]
       artist_name : string; [@key "artistName"]
       artwork : Artwork.t;
       content_rating : Content_rating.t option;
           [@key "contentRating"] [@default None]
       disc_number : int option; [@key "discNumber"] [@default None]
       duration_in_millis : int; [@key "durationInMillis"]
       genre_names : string list; [@key "genreNames"]
       has_credits : bool; [@key "hasCredits"]
       has_lyrics : bool; [@key "hasLyrics"]
       name : string;
       play_params : Play_params.t option; [@key "playParams"] [@default None]
       release_date : string option; [@key "releaseDate"] [@default None]
       track_number : int option; [@key "trackNumber"] [@default None]
     }
     [@@deriving yojson { strict = false }]

     let catalog_of_yojson json =
       match Page.of_yojson Song.of_yojson json with
       | Ok page -> Ok (Option.some (`Catalog_song page))
       | Error _ -> (
           match Page.of_yojson Playlist.of_yojson json with
           | Ok page -> Ok (Option.some (`Catalog_playlist page))
           | Error _ -> Error "Invalid catalog")

     type t = {
       attributes : attributes;
       relationships : relationships option; [@default None]
       id : string;
       resource_type : Resource.t; [@key "type"]
       href : string;
     }
     [@@deriving yojson { strict = false }]

     and relationships = {
       catalog :
         [ `Catalog_playlist of Playlist.t Page.t | `Catalog_song of Song.t Page.t ]
         option;
           [@of_yojson catalog_of_yojson]
       tracks :
         [ `Library_song of t | `Library_music_video of Library_music_video.t ]
         Page.t
         option;
           [@default None]
     }
     [@@deriving yojson { strict = false }]

     (* let relationships_to_yojson relationships =
        let open Infix.Option in
        let catalog =
          relationships.catalog >|= fun catalog ->
          match catalog with
          | `Catalog_playlist playlist -> Page.to_yojson Playlist.to_yojson playlist
          | `Catalog_song song -> Page.to_yojson Song.to_yojson song
        in
        let tracks =
          relationships.tracks
          >|= Page.to_yojson (function
                | `Library_song song -> to_yojson song
                | `Library_music_video video -> Library_music_video.to_yojson video)
        in
        `Assoc
          (List.filter_map
             (fun (key, value) -> value >|= fun value -> (key, value))
             [ ("catalog", catalog); ("tracks", tracks) ]) *)

     let relationships_of_yojson _json =
       (* let open Yojson.Safe.Util in *)
       (* let catalog =
            try
              member "catalog" json
              |> Page.of_yojson Playlist.of_yojson
              |> Result.map (fun playlist -> `Catalog_playlist playlist)
              |> Extended.Result.ok_or_else (fun _ ->
                     Page.of_yojson Song.of_yojson json
                     |> Result.map (fun song -> `Catalog_song song))
              |> Result.to_option
            with Type_error _ -> None
          in *)
       print_endline "HERE!!";
       (* let catalog =
            try
              member "catalog" json
              |> Page.of_yojson Song.of_yojson
              |> Result.map (fun song -> `Catalog_song song)
              |> Result.to_option
            with Type_error _ -> None
          in *)
       print_endline "HERE@@";
       (* let tracks =
            try
              member "tracks" json
              |> Page.of_yojson (fun track_json ->
                     let open Infix.Result in
                     match
                       member "type" track_json |> to_string |> Resource.of_string
                     with
                     | Ok `Library_songs ->
                         of_yojson track_json >|= fun song -> `Library_song song
                     | Ok `Library_music_videos ->
                         Library_music_video.of_yojson track_json >|= fun video ->
                         `Library_music_video video
                     | _ -> Error "Invalid track type")
              |> Result.to_option
            with Type_error _ -> None
          in *)
       Ok { catalog = None; tracks = None }
   end *)

module Library_playlist = struct
  type attributes = {
    artwork : Artwork.t option; [@default None]
    can_edit : bool; [@key "canEdit"]
    date_added : string; [@key "dateAdded"]
    description : Description.t option; [@default None]
    has_catalog : bool; [@key "hasCatalog"]
    is_public : bool; [@key "isPublic"]
    last_modified_date : string; [@key "lastModifiedDate"]
    name : string;
    play_params : Play_params.t option; [@key "playParams"] [@default None]
    track_types : Resource.t list option; [@key "trackTypes"] [@default None]
  }
  [@@deriving yojson]

  type relationships = {
    catalog :
      [ `Catalog_playlist of Playlist.t Page.t | `Catalog_song of Song.t Page.t ]
      option;
        [@default None]
    tracks :
      [ `Library_song of Library_song.t
      | `Library_music_video of Library_music_video.t ]
      Page.t
      option;
        [@default None]
  }
  [@@deriving yojson]

  let relationships_to_yojson relationships =
    let open Infix.Option in
    let catalog =
      relationships.catalog >|= fun catalog ->
      match catalog with
      | `Catalog_playlist playlist -> Page.to_yojson Playlist.to_yojson playlist
      | `Catalog_song song -> Page.to_yojson Song.to_yojson song
    in
    let tracks =
      relationships.tracks
      >|= Page.to_yojson (function
            | `Library_song song -> Library_song.to_yojson song
            | `Library_music_video video -> Library_music_video.to_yojson video)
    in
    `Assoc
      (List.filter_map
         (fun (key, value) -> value >|= fun value -> (key, value))
         [ ("catalog", catalog); ("tracks", tracks) ])

  let relationships_of_yojson json =
    let open Yojson.Safe.Util in
    let catalog =
      try
        member "catalog" json
        |> Page.of_yojson Playlist.of_yojson
        |> Result.map (fun playlist -> `Catalog_playlist playlist)
        |> Extended.Result.ok_or_else (fun _ ->
               Page.of_yojson Song.of_yojson json
               |> Result.map (fun song -> `Catalog_song song))
        |> Result.to_option
      with Type_error _ -> None
    in
    let tracks =
      try
        member "tracks" json
        |> Page.of_yojson (fun track_json ->
               let open Infix.Result in
               match
                 member "type" track_json |> to_string |> Resource.of_string
               with
               | Ok `Library_songs ->
                   Library_song.of_yojson track_json >|= fun song ->
                   `Library_song song
               | Ok `Library_music_videos ->
                   Library_music_video.of_yojson track_json >|= fun video ->
                   `Library_music_video video
               | _ -> Error "Invalid track type")
        |> Result.to_option
      with Type_error _ -> None
    in
    Ok { catalog; tracks }

  type t = {
    attributes : attributes;
    href : string;
    id : string;
    relationships : relationships option; [@default None]
    resource_type : Resource.t; [@key "type"]
  }
  [@@deriving yojson]

  let tracks playlist =
    Infix.Option.(
      playlist.relationships >|= fun relationships ->
      relationships.tracks >|= fun response -> response.data)
    |> Option.join
end

(*TODO: Create Content_rating modue*)

module Music_video = struct
  type attributes = {
    album_name : string; [@key "albumName"]
    artist_name : string; [@key "artistName"]
    artist_url : string; [@key "artistUrl"]
    artwork : Artwork.t; [@key "artwork"]
    content_rating : string; [@key "contentRating"]
    duration_in_millis : int; [@key "durationInMillis"]
    (* TODO: Add EditorialNotes *)
    (* editorial_notes : EditorialNotes.t; [@key "editorialNotes"] *)
    genre_names : string list; [@key "genreNames"]
    has_4k : bool; [@key "has4K"]
    has_hdr : bool; [@key "hasHDR"]
    isrc : string; [@key "isrc"]
    name : string; [@key "name"]
    play_params : Play_params.t; [@key "playParams"]
    (* TODO: Add Preview type *)
    (* previews : Preview.t list; [@key "previews"] *)
    release_date : string; [@key "releaseDate"]
    track_number : int; [@key "trackNumber"]
    url : string; [@key "url"]
    video_sub_type : string; [@key "videoSubType"]
    work_id : string; [@key "workId"]
    work_name : string; [@key "workName"]
  }
  [@@deriving yojson { strict = false }]

  type t = {
    attributes : attributes;
    id : string;
    resource_type : Resource.t;
    href : string;
  }
  [@@deriving yojson]
end
