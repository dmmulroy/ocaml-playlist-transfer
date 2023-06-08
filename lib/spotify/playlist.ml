module Me = struct
  let get_playlists _client = Lwt.return_ok ()
end

type external_urls = { spotify : string } [@@deriving yojson]
type followers = { total : int } [@@deriving yojson]
type image = { height : int; url : Http.Uri.t; width : int } [@@deriving yojson]

(* TODO: Move to User module *)
type owner = {
  external_urls : external_urls;
  followers : followers;
  href : string;
  id : string;
  spotify_type : [ `User ];
  uri : string;
  display_name : string option; (* nullable *)
}
[@@deriving yojson]

type tracks_reference = { href : Http.Uri.t; total : int } [@@deriving yojson]

type t = {
  collaborative : bool;
  description : string option; (* nullable *)
  external_urls : external_urls;
  followers : followers;
  href : string;
  id : string;
  images : image list;
  name : string;
  owner : owner;
  public : bool;
  snapshot_id : string;
  tracks : tracks_reference;
  uri : string;
  spotify_type : [ `Playlist ];
}
[@@deriving yojson]

(* TODO: Move this out and make it resusable *)
type 'a paginated = {
  href : Http.Uri.t;
  items : 'a list;
  limit : int;
  next : Http.Uri.t option;
  offset : int;
  previous : Http.Uri.t option;
  total : int;
}
[@@deriving yojson]

type get_featured_playlists_response = {
  message : string;
  playlists : t paginated;
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
      | Ok paginated -> Lwt.return_ok paginated
      | Error err -> Lwt.return_error (`Msg err)
      (* TODO: Figure out what's wrong here  *))
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Msg (Http.Code.string_of_status status_code ^ json))