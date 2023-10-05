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

module Create_output = struct
  type t = { data : Types.Playlist.t list } [@@deriving yojson]
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
  type t = Types.Playlist.t Page.t [@@deriving yojson]
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

  let make ?extended_attributes ?relationships id =
    Apple_rest_client.Request.make { id; extended_attributes; relationships }

  let extended_attributes_to_string = function `Track_types -> "trackTypes"

  let to_query_params input =
    let open Infix.Option in
    List.filter_map
      (fun (key, value) -> value >|= fun value -> (key, value))
      [
        ( "include",
          input.relationships >|= Relationship.requests_to_string_list
          >|= String.concat "," );
        ("extend", input.extended_attributes >|= extended_attributes_to_string);
      ]
end

module Get_by_id_output = struct
  type t = { data : Types.Playlist.t list } [@@deriving yojson]
end

module Get_by_id = Apple_rest_client.Make (struct
  type input = Get_by_id_input.t Apple_rest_client.Request.t
  type output = Get_by_id_output.t Apple_rest_client.Response.t

  let name = "Get_by_id"

  let make_endpoint (request : input) =
    let base_endpoint =
      Http.Uri.of_string
      @@ Fmt.str "https://api.music.apple.com/v1/me/library/playlists/%s"
           request.input.id
    in
    Http.Uri.add_query_params' base_endpoint
    @@ Get_by_id_input.to_query_params request.input

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response http_response =
    Infix.Lwt_result.(
      Apple_rest_client.handle_response ~deserialize:Get_by_id_output.of_yojson
        http_response
      >|= Apple_rest_client.Response.make)
end)

let get_by_id = Get_by_id.request

module Get_relationship_by_name_input = struct
  type t = {
    playlist_id : string;
    relationship : Relationship.request;
    relationships : [ `Catalog | `Tracks ] list option;
  }

  let test () = "Piq is going to write OCaml for the rest of his life"

  let to_query_params input =
    let include_query_param =
      input.relationships
      |> Option.map Relationship.requests_to_string_list
      |> Option.value ~default:[] |> String.concat ","
    in
    [ ("include", include_query_param) ]

  let make ?(relationships = []) ~playlist_id
      ~(relationship : [< Relationship.request ]) () =
    Apple_rest_client.Request.make
      { playlist_id; relationship; relationships = Some relationships }
end

module Get_relationship_by_name_output = struct
  type t = Types.Library_song.t Page.t [@@deriving yojson]
end

module Get_relationship_by_name = Apple_rest_client.Make (struct
  type input = Get_relationship_by_name_input.t Apple_rest_client.Request.t
  type output = Get_relationship_by_name_output.t Apple_rest_client.Response.t

  let name = "Get_relationship_by_name"

  let make_endpoint (request : input) =
    let query_params =
      Get_relationship_by_name_input.to_query_params request.input
    in
    let base_uri =
      Http.Uri.of_string
      @@ Fmt.str "https://api.music.apple.com/v1/me/library/playlists/%s/%s"
           request.input.playlist_id
           (Relationship.request_to_string request.input.relationship)
    in
    let endpoint = Http.Uri.add_query_params' base_uri query_params in
    endpoint

  let to_http_request input =
    Lwt.return_ok @@ Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http_response http_response =
    Infix.Lwt_result.(
      Apple_rest_client.handle_response
        ~deserialize:Get_relationship_by_name_output.of_yojson http_response
      >|= Apple_rest_client.Response.make)
end)

let get_relationship_by_name = Get_relationship_by_name.request
