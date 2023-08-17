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
  type output = Get_playlists_output.t [@@deriving yojson]

  let name = "Get_playlists"

  let make_endpoint input =
    let base_endpoint =
      Http.Uri.of_string "https://api.spotify.com/v1/me/playlists"
    in
    let query_params = Get_playlists_input.to_query_params input in
    Http.Uri.add_query_params' base_endpoint query_params

  let to_http_request input =
    Lwt.return_ok
    @@ Http.Request.make ~meth:`GET ~headers:Http.Header.empty
         ~body:Http.Body.empty ~uri:(make_endpoint input) ()

  let of_http_response =
    Spotify_request.default_of_http_response ~deserialize:output_of_yojson
end)

let get_playlists = Get_playlists.request
