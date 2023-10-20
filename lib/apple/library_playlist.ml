open Shared
open Syntax
open Let

module Create_input = struct
  type track = {
    id : string;
    resource_type :
      [ `Library_songs | `Library_music_videos | `Music_videos | `Songs ];
        [@key "type"] [@to_yojson Types.Resource.to_yojson]
  }
  [@@deriving to_yojson]

  type parent = {
    id : string;
    resource_type : [ `Library_playlist_folders ];
        [@key "type"] [@to_yojson Types.Resource.to_yojson]
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

module Create = struct
  let name = "Create"

  type input = Create_input.t
  type response = { data : Types.Playlist.t list } [@@deriving yojson]
  type output = response [@@deriving yojson]

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    let open Infix.Result in
    let input_json = Create_input.to_yojson input in
    let| body =
      input_json |> Http.Body.of_yojson
      >|? Apple_error.make ~source:(`Serialization (`Json input_json))
    in
    Lwt.return_ok @@ Http.Request.make ~meth:`POST ~uri:endpoint ~body ()

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end

let create ~(client : Client.t) (input : Create.input) =
  let module Request = Apple_rest_client.Make (Create) in
  Request.request ~client input

module Get_all = struct
  let name = "Get_all"

  type input = unit
  type output = Types.Playlist.t Page.t [@@deriving yojson]

  let endpoint =
    Http.Uri.of_string "https://api.music.apple.com/v1/me/library/playlists"

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:endpoint input

  let of_http_response =
    Apple_rest_client.handle_response ~deserialize:output_of_yojson
end

let get_all ~client () =
  let module Request = Apple_rest_client.Make (Get_all) in
  Request.request ~client ()

module Get_by_id = struct
  let name = "Get_by_id"

  type input = {
    id : string;
    extended_attributes : [ `Track_types ] option;
    relationships : [ `Tracks | `Catalog ] list option;
  }
  [@@deriving make]

  type output = { data : Types.Library_playlist.t list } [@@deriving yojson]

  let input_to_query_params input =
    [
      ( "include",
        input.relationships
        |> Option.map Relationship.requests_to_string_list
        |> Option.map (String.concat ",") );
      ( "extend",
        input.extended_attributes
        |> Option.map (function `Track_types -> "trackTypes") );
    ]
    |> List.filter_map (fun (key, value) ->
           value |> Option.map (fun value -> (key, value)))

  let make_endpoint input =
    let base_endpoint =
      Http.Uri.of_string
      @@ Fmt.str "https://api.music.apple.com/v1/me/library/playlists/%s"
           input.id
    in
    input |> input_to_query_params |> Http.Uri.add_query_params' base_endpoint

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response http_response =
    http_response
    |> Apple_rest_client.handle_response ~deserialize:output_of_yojson
end

let get_by_id ~client ?extended_attributes ?relationships id =
  let module Request = Apple_rest_client.Make (Get_by_id) in
  Get_by_id.make_input ?extended_attributes ?relationships ~id ()
  |> Request.request ~client
  |> Lwt_result.map Apple_rest_client.Response.make

module Get_relationship_by_name = struct
  let name = "Get_relationship_by_name"

  type input = {
    playlist_id : string;
    relationship : Relationship.request;
    relationships : [ `Catalog | `Tracks ] list option;
  }

  let make_input ?(relationships = []) ~playlist_id ~relationship () =
    { playlist_id; relationship; relationships = Some relationships }

  type output = Types.Library_song.t Page.t [@@deriving yojson]

  let input_to_query_params input =
    let include_query_param =
      input.relationships
      |> Option.map Relationship.requests_to_string_list
      |> Option.value ~default:[] |> String.concat ","
    in
    [ ("include", include_query_param) ]

  let make_endpoint input =
    let query_params = input_to_query_params input in
    let base_uri =
      Http.Uri.of_string
      @@ Fmt.str "https://api.music.apple.com/v1/me/library/playlists/%s/%s"
           input.playlist_id
           (Relationship.request_to_string input.relationship)
    in
    Http.Uri.add_query_params' base_uri query_params

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response http_response =
    http_response
    |> Apple_rest_client.handle_response ~deserialize:output_of_yojson
end

let get_relationship_by_name ~client ~playlist_id ~relationship ?relationships
    () =
  let module Request = Apple_rest_client.Make (Get_relationship_by_name) in
  let input =
    Get_relationship_by_name.make_input ~playlist_id ~relationship
      ?relationships ()
  in
  Request.request ~client input
