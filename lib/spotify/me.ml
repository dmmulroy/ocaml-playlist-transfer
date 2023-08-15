open Syntax
open Let

module Get_playlists_input = struct
  type t = { limit : int option; offset : int option } [@@deriving show, yojson]

  let make ?limit ?offset () = { limit; offset }

  let to_query_params t =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("limit", Option.map string_of_int t.limit);
        ("offset", Option.map string_of_int t.offset);
      ]
end

module Get_playlists_output = struct
  type t = Simple_playlist.t Page.t [@@deriving yojson]
end

module Get_playlists = Spotify_request.Make (struct
  type input = Get_playlists_input.t
  type output = Get_playlists_output.t

  let make_endpoint input =
    let base_endpoint =
      Http.Uri.of_string "https://api.spotify.com/v1/me/playlists"
    in
    let query_params = Get_playlists_input.to_query_params input in
    Http.Uri.add_query_params' base_endpoint query_params

  let to_http input =
    Http.Request.make ~meth:`GET ~headers:Http.Header.empty
      ~body:Http.Body.empty ~uri:(make_endpoint input) ()

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
        match Get_playlists_output.of_yojson json with
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

let get_playlists = Get_playlists.request
