type get_playlists_options = { limit : int option; offset : int option }

module GetCurrentUserPlaylistsInput = struct
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

module GetCurrentUserPlaylistsOutput = struct
  type t = Simple_playlist.t Page.t [@@deriving yojson]
end

module GetCurrentUsersPlaylists = Spotify_request.Make (struct
  type input = GetCurrentUserPlaylistsInput.t
  type options = unit
  type output = GetCurrentUserPlaylistsOutput.t
  type error = [ `Msg of string ]

  let query_params_of_request_options = function
    | Some options ->
        List.filter_map
          (fun (key, value) -> Option.map (fun value -> (key, value)) value)
          [
            ("limit", Option.map string_of_int options.limit);
            ("offset", Option.map string_of_int options.offset);
          ]
    | _ -> []

  let make_endpoint input =
    let base_endpoint =
      Http.Uri.of_string "https://api.spotify.com/v1/me/playlists"
    in
    let query_params = GetCurrentUserPlaylistsInput.to_query_params input in
    Http.Uri.add_query_params' base_endpoint query_params

  let to_http ?options:_ input =
    (`GET, Http.Header.empty, make_endpoint input, Http.Body.empty)

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match GetCurrentUserPlaylistsOutput.of_yojson json with
        | Ok response -> Lwt.return_ok response
        | Error err -> Lwt.return_error (`Msg err))
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
end)

let get_playlists = GetCurrentUsersPlaylists.request
