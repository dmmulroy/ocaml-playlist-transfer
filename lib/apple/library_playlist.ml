open Shared
open Syntax
open Let

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
  catalog : Playlist.t Relationship.response option; [@default None]
  tracks :
    [ `Library_song of Library_song.t
    | `Library_music_video of Library_music_video.t ]
    Relationship.response
    option;
      [@default None]
}
[@@deriving yojson]

let relationships_to_yojson relationships =
  let open Infix.Option in
  let catalog =
    relationships.catalog >|= Relationship.response_to_yojson Playlist.to_yojson
  in
  let tracks =
    relationships.tracks
    >|= Relationship.response_to_yojson (function
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
      |> Relationship.response_of_yojson Playlist.of_yojson
      |> Result.to_option
    with Type_error _ -> None
  in
  let tracks =
    try
      member "tracks" json
      |> Relationship.response_of_yojson (fun track_json ->
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

module Create_input = struct
  type track = {
    id : string;
    resource_type :
      [ `Library_songs | `Library_music_videos | `Music_videos | `Songs ];
        [@key "type"] [@to_yojson Resource.to_yojson]
  }
  [@@deriving to_yojson]

  type parent = {
    id : string;
    resource_type : [ `Library_playlist_folders ];
        [@key "type"] [@to_yojson Resource.to_yojson]
  }
  [@@deriving to_yojson]

  type 'a data = { data : 'a list } [@@deriving to_yojson]

  type relationships = {
    tracks : track data option;
    parent : parent data option;
  }
  [@@deriving to_yojson]

  let relationships_to_yojson relationships =
    let open Infix.Option in
    let tracks = relationships.tracks >|= data_to_yojson track_to_yojson in
    let parent = relationships.parent >|= data_to_yojson parent_to_yojson in
    `Assoc
      (List.filter_map
         (fun (key, value) -> value >|= fun value -> (key, value))
         [ ("tracks", tracks); ("parent", parent) ])

  type attributes = { description : string option; name : string }
  [@@deriving to_yojson]

  let attributes_to_yojson attributes =
    let open Infix.Option in
    let description =
      attributes.description >|= fun description -> `String description
    in
    let name = Option.some (`String attributes.name) in
    `Assoc
      (List.filter_map
         (fun (key, value) -> value >|= fun value -> (key, value))
         [ ("description", description); ("name", name) ])

  type t = { attributes : attributes; relationships : relationships option }
  [@@deriving to_yojson]

  let make ?description ?parent_playlist_folder ?tracks ~name () =
    let open Infix.Option in
    let attributes = { description; name } in
    let relationships =
      let tracks = tracks >|= fun tracks' -> { data = tracks' } in
      let parent =
        parent_playlist_folder >|= fun parent -> { data = [ parent ] }
      in
      match (tracks, parent) with
      | None, None -> None
      | _, _ -> Some { tracks; parent }
    in
    { attributes; relationships }
end

module Create_output = struct
  type playlist = t [@@deriving yojson]
  type t = { data : playlist list } [@@deriving yojson]
end

module Create = Apple_rest_client.Make (struct
  type input = Create_input.t
  type output = Create_output.t [@@deriving yojson]

  let name = "Create"

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    let open Infix.Result in
    let input_json = Create_input.to_yojson input in
    let| body =
      Http.Body.of_yojson input_json >|? fun str ->
      Apple_error.make ~source:(`Serialization (`Json input_json)) str
    in
    Lwt.return_ok @@ Http.Request.make ~meth:`POST ~uri:endpoint ~body ()

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end)

let create = Create.request

module Get_all_input = struct
  type t = unit
end

module Get_all_output = struct
  type playlist = t [@@deriving yojson]
  type t = playlist Page.t [@@deriving yojson]
end

module Get_all = Apple_rest_client.Make (struct
  type input = Get_all_input.t
  type output = Get_all_output.t [@@deriving yojson]

  let name = "Get_all"

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:endpoint input

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end)

let get_all = Get_all.request

module Get_by_id_input = struct
  type t = {
    id : string;
    extended_attributes : [ `Track_types ] option;
    relationships : [ `Tracks | `Catalog ] list option;
  }
  [@@deriving make]

  let extended_attributes_to_string = function `Track_types -> "trackTypes"

  let to_query_params input =
    let open Infix.Option in
    List.filter_map
      (fun (key, value) -> value >|= fun value -> (key, value))
      [
        ( "include",
          input.relationships >|= Relationship.to_string_list
          >|= String.concat "," );
        ("extend", input.extended_attributes >|= extended_attributes_to_string);
      ]
end

module Get_by_id_output = struct
  type playlist = t [@@deriving yojson]
  type t = { data : playlist list } [@@deriving yojson]
end

module Get_by_id = Apple_rest_client.Make (struct
  type input = Get_by_id_input.t
  type output = Get_by_id_output.t [@@deriving yojson]

  let name = "Get_by_id"

  let make_endpoint (input : input) =
    let base_endpoint =
      Http.Uri.of_string
      @@ Fmt.str "https://api.music.apple.com/v1/me/library/playlists/%s"
           input.id
    in
    Http.Uri.add_query_params' base_endpoint
    @@ Get_by_id_input.to_query_params input

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end)

let get_by_id = Get_by_id.request
