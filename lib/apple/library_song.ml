[@@@ocaml.warning "-21"]

(* open Shared *)
(* open Syntax *)

type content_rating = [ `Clean | `Explicit ] [@@deriving yojson]

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

type attributes = {
  album_name : string option; [@key "albumName"] [@default None]
  artist_name : string; [@key "artistName"]
  artwork : Artwork.t;
  content_rating : content_rating option; [@key "contentRating"] [@default None]
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
