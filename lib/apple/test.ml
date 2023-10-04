[@@@ocaml.warning "-32-33"]

open Shared
open Syntax

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
    artwork : Types.Artwork.t;
    content_rating : Types.Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    isrc : string option;
    name : string;
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
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
    artwork : Types.Artwork.t;
    content_rating : Types.Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    isrc : string option;
    name : string;
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
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
    artwork : Types.Artwork.t option; [@default None]
    curator_name : string; [@key "curatorName"]
    is_chart : bool; [@key "isChart"]
    description : Types.Description.t option; [@default None]
    last_modified_date : string option;
        [@key "lastModifiedDate"] [@default None]
    name : string;
    playlist_type : playlist_type; [@key "playlistType"]
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
    track_types : Types.Resource.t list option;
        [@key "trackTypes"] [@default None]
    url : Http.Uri.t;
  }
  [@@deriving yojson]

  (* TODO: relationships & views *)
  type t = {
    id : string;
    href : string;
    resource_type : Types.Resource.t; [@key "type"]
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
    artwork : Types.Artwork.t option; [@default None]
    curator_name : string; [@key "curatorName"]
    is_chart : bool; [@key "isChart"]
    description : Types.Description.t option; [@default None]
    last_modified_date : string option;
        [@key "lastModifiedDate"] [@default None]
    name : string;
    playlist_type : playlist_type; [@key "playlistType"]
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
    track_types : Types.Resource.t list option;
        [@key "trackTypes"] [@default None]
    url : Http.Uri.t;
  }
  [@@deriving yojson]

  (* TODO: relationships & views *)
  type t = {
    id : string;
    href : string;
    resource_type : Types.Resource.t; [@key "type"]
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
    artwork : Types.Artwork.t;
    content_rating : Types.Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    name : string;
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson { strict = false }]

  type t = {
    attributes : attributes;
    (* relationships : relationships option; [@default None] *)
    id : string;
    resource_type : Types.Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson { strict = false }]
end = struct
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Types.Artwork.t;
    content_rating : Types.Content_rating.t option;
        [@key "contentRating"] [@default None]
    disc_number : int option; [@key "discNumber"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    has_credits : bool; [@key "hasCredits"]
    has_lyrics : bool; [@key "hasLyrics"]
    name : string;
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson { strict = false }]

  type t = {
    attributes : attributes;
    (* relationships : relationships option; [@default None] *)
    id : string;
    resource_type : Types.Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson { strict = false }]
end

and Library_music_video : sig
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Types.Artwork.t;
    content_rating : Types.Content_rating.t option;
        [@key "contentRating"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    name : string;
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson]

  type t = {
    attributes : attributes;
    id : string;
    resource_type : Types.Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson]
end = struct
  type attributes = {
    album_name : string option; [@key "albumName"] [@default None]
    artist_name : string; [@key "artistName"]
    artwork : Types.Artwork.t;
    content_rating : Types.Content_rating.t option;
        [@key "contentRating"] [@default None]
    duration_in_millis : int; [@key "durationInMillis"]
    genre_names : string list; [@key "genreNames"]
    name : string;
    play_params : Types.Play_params.t option;
        [@key "playParams"] [@default None]
    release_date : string option; [@key "releaseDate"] [@default None]
    track_number : int option; [@key "trackNumber"] [@default None]
  }
  [@@deriving yojson]

  type t = {
    attributes : attributes;
    id : string;
    resource_type : Types.Resource.t; [@key "type"]
    href : string;
  }
  [@@deriving yojson]
end
