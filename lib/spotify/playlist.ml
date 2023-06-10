module Me = struct
  let get_playlists _client = Lwt.return_ok ()
end

type external_urls = { spotify : string } [@@deriving yojson]

type followers = { href : Http.Uri.t option; (* nullable *) total : int }
[@@deriving yojson]

type image = {
  height : int option; (* nullable *)
  url : Http.Uri.t;
  width : int option (* nullable *);
}
[@@deriving yojson]

(* TODO: Move to User module *)
type owner = {
  external_urls : external_urls;
  followers : followers option; (* nullable *) [@default None]
  href : string;
  id : string;
  spotify_type : [ `User ];
      [@key "type"]
      [@of_yojson
        fun json ->
          match json with
          | `String "user" -> Ok `User
          | _ -> failwith "Error parsing spotify type"]
  uri : string;
  display_name : string option; (* nullable *)
}
[@@deriving yojson]

type tracks_reference = { href : Http.Uri.t; total : int } [@@deriving yojson]

type t = {
  collaborative : bool;
  description : string option; (* nullable *)
  external_urls : external_urls;
  href : string;
  id : string;
  images : image list;
  name : string;
  owner : owner;
  public : bool option;
  snapshot_id : string;
  tracks : tracks_reference;
  uri : string;
  spotify_type : [ `Playlist ];
      [@key "type"]
      [@of_yojson
        fun json ->
          match json with
          | `String "playlist" -> Ok `Playlist
          | _ -> failwith "Error parsing spotify type"]
}
[@@deriving yojson { strict = false }]

type get_featured_playlists_response = {
  message : string;
  playlists : t Paginated_response.t;
}
[@@deriving yojson]

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

let query_params_of_request_options = function
  | `Get_featured_playlists -> (
      function
      | None -> []
      | Some options ->
          List.filter_map
            (fun (key, value) -> Option.map (fun value -> (key, value)) value)
            [
              ("country", options.country);
              ("locale", options.locale);
              ("timestamp", options.timestamp);
              ("limit", Option.map string_of_int options.limit);
              ("offset", Option.map string_of_int options.offset);
            ])

let get_featured_playlists (client : Client.t) ?(options = None) () =
  let base_endpoint =
    Uri.of_string "https://api.spotify.com/v1/browse/featured-playlists"
  in
  let headers =
    Http.Header.of_list [ ("Authorization", Client.get_bearer_token client) ]
  in
  let query_params =
    query_params_of_request_options `Get_featured_playlists options
  in
  let endpoint = Uri.add_query_params' base_endpoint query_params in
  match%lwt Http.Client.get ~headers endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_yojson body in
      match get_featured_playlists_response_of_yojson json with
      | Ok response ->
          Lwt.return_ok @@ Paginated_response.get_items response.playlists
      | Error err -> Lwt.return_error (`Msg err))
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))
