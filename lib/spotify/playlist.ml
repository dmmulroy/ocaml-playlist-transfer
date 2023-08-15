open Syntax
open Let

type playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option; [@default None]
  track : Track.t;
  video_thumbnail : video_thumbnail option; [@default None]
}
[@@deriving yojson]

and video_thumbnail = { url : Http.Uri.t option } [@@deriving yojson]

type t = {
  collaborative : bool;
  description : string option; [@default None]
  external_urls : Common.external_urls;
  followers : Resource.reference;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  owner : User.t;
  primary_color : string option; [@default None]
  public : bool option; [@default None]
  resource_type : Resource.t; [@key "type"]
  snapshot_id : string;
  tracks : playlist_track Page.t;
  uri : string;
}
[@@deriving yojson]

module Create_input = struct
  type t = {
    collaborative : bool option;
    description : string option;
    name : string;
    public : bool option;
    user_id : string;
  }
  [@@deriving yojson]

  let make ?collaborative ?description ?public ~name ~user_id () =
    { collaborative; description; name; public; user_id }
end

module Create_output = struct
  type nonrec t = t
end

module CreatePlaylist = Spotify_request.Make (struct
  type input = Create_input.t
  type output = Create_output.t

  let make_endpoint (user_id : string) =
    Http.Uri.of_string @@ "https://api.spotify.com/v1/users/" ^ user_id
    ^ "/playlists"

  let to_http input =
    let body_res = Http.Body.of_yojson @@ Create_input.to_yojson input in
    match body_res with
    | Ok body ->
        Http.Request.make ~meth:`POST ~body
          ~uri:(make_endpoint input.user_id)
          ()
    | Error (`Msg err) ->
        failwith err (* TODO: Update to_http to return a result *)

  let of_http = function
    | _, response when Http.Response.is_success response -> (
        let open Infix.Lwt_result in
        let+ json =
          Http.Response.body response |> Http.Body.to_yojson
          >|?* fun (`Msg msg) ->
          let* json_str = Http.Body.to_string @@ Http.Response.body response in
          let source = `Serialization (`Raw json_str) in
          Lwt.return @@ Error.make ~domain:`Spotify ~source msg
        in
        match of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error msg ->
            Lwt.return_error
            @@ Error.make ~domain:`Spotify
                 ~source:(`Serialization (`Json json))
                 msg)
    | request, response ->
        let response_status = Http.Response.status response in
        let request_uri = Http.Request.uri request in
        let message = Http.Code.reason_phrase_of_status_code response_status in
        Lwt.return_error
        @@ Error.make ~domain:`Spotify
             ~source:(`Http (response_status, request_uri))
             message
end)

let create = CreatePlaylist.request

module Get_featured_input = struct
  type t = {
    country : string option;
    locale : string option;
    timestamp : string option;
    limit : int option;
    offset : int option;
  }

  let make ?country ?locale ?timestamp ?limit ?offset () =
    { country; locale; timestamp; limit; offset }

  let to_query_params { country; locale; timestamp; limit; offset } =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("country", country);
        ("locale", locale);
        ("timestamp", timestamp);
        ("limit", Option.map string_of_int limit);
        ("offset", Option.map string_of_int offset);
      ]
end

module Get_featured_output = struct
  type t = { message : string; playlists : Simple_playlist.t Page.t }
  [@@deriving yojson]
end

module Get_featured = Spotify_request.Make (struct
  type input = Get_featured_input.t
  type output = Get_featured_output.t

  let base_endpoint =
    Http.Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"

  let make_endpoint input =
    Http.Uri.add_query_params' base_endpoint
    @@ Get_featured_input.to_query_params input

  let to_http input = Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http = function
    | _, response when Http.Response.is_success response -> (
        let open Infix.Lwt_result in
        let+ json =
          Http.Response.body response |> Http.Body.to_yojson
          >|?* fun (`Msg msg) ->
          let* json_str = Http.Body.to_string @@ Http.Response.body response in
          let source = `Serialization (`Raw json_str) in
          Lwt.return @@ Error.make ~domain:`Spotify ~source msg
        in
        match Get_featured_output.of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error msg ->
            Lwt.return_error
            @@ Error.make ~domain:`Spotify
                 ~source:(`Serialization (`Json json))
                 msg)
    | request, response ->
        let response_status = Http.Response.status response in
        let request_uri = Http.Request.uri request in
        let message = Http.Code.reason_phrase_of_status_code response_status in
        Lwt.return_error
        @@ Error.make ~domain:`Spotify
             ~source:(`Http (response_status, request_uri))
             message
end)

let get_featured = Get_featured.request

module Get_by_id_input = struct
  type t = {
    id : string;
    additional_types : [ `Track | `Episode ] list option;
    fields : string option;
    market : string option;
  }

  let to_query_params { additional_types; fields; market; _ } =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("fields", fields);
        ("market", market);
        ( "additional_types",
          Option.map
            (fun additional_types' ->
              String.concat "," @@ List.map Resource.to_string additional_types')
            additional_types );
      ]

  let make ?additional_types ?fields ?market ~id () =
    { id; additional_types; fields; market }
end

module Get_by_id_output = struct
  type nonrec t = t
end

module Get_playlist_by_id = Spotify_request.Make (struct
  type input = Get_by_id_input.t
  type output = Get_by_id_output.t

  let make_endpoint (input : input) =
    let base_endpoint =
      Http.Uri.of_string @@ "https://api.spotify.com/v1/playlists/" ^ input.id
    in
    Http.Uri.add_query_params' base_endpoint
    @@ Get_by_id_input.to_query_params input

  let to_http input = Http.Request.make ~meth:`GET ~uri:(make_endpoint input) ()

  let of_http = function
    | _, response when Http.Response.is_success response -> (
        let open Infix.Lwt_result in
        let+ json =
          Http.Response.body response |> Http.Body.to_yojson
          >|?* fun (`Msg msg) ->
          let* json_str = Http.Body.to_string @@ Http.Response.body response in
          let source = `Serialization (`Raw json_str) in
          Lwt.return @@ Error.make ~domain:`Spotify ~source msg
        in
        match of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error msg ->
            Lwt.return_error
            @@ Error.make ~domain:`Spotify
                 ~source:(`Serialization (`Json json))
                 msg)
    | request, response ->
        let response_status = Http.Response.status response in
        let request_uri = Http.Request.uri request in
        let message = Http.Code.reason_phrase_of_status_code response_status in
        Lwt.return_error
        @@ Error.make ~domain:`Spotify
             ~source:(`Http (response_status, request_uri))
             message
end)

(* TODO: Figure out way to wrap request errors with Source errors *)
let get_by_id = Get_playlist_by_id.request
