open Shared

module Get_playlists = struct
  let name = "Get_playlists"

  type input = { limit : int option; offset : int option } [@@deriving yojson]
  type output = Types.Simple_playlist.t Page.t [@@deriving yojson]

  let input_to_query_params input =
    List.filter_map
      (fun (key, value) -> Option.map (fun value -> (key, value)) value)
      [
        ("limit", Option.map string_of_int input.limit);
        ("offset", Option.map string_of_int input.offset);
      ]

  let make_endpoint input =
    let base_endpoint =
      Http.Uri.of_string "https://api.spotify.com/v1/me/playlists"
    in
    let query_params = input_to_query_params input in
    Http.Uri.add_query_params' base_endpoint query_params

  let to_http_request input =
    Lwt.return_ok
    @@ Http.Request.make ~meth:`GET ~headers:Http.Header.empty
         ~body:Http.Body.empty ~uri:(make_endpoint input) ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

(* TODO: Handle pagination *)
let get_playlists ~client ?limit ?offset () =
  let module Request = Spotify_rest_client.Make (Get_playlists) in
  Request.request ~client { limit; offset }
  |> Lwt_result.map Spotify_rest_client.Response.make
