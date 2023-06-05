[@@@warning "-69"]

module Access_token = struct
  type t = {
    token : string;
    expiration_time : float;
    refresh_token : string option;
  }
  [@@deriving show]

  let is_expired t = Unix.time () > t.expiration_time

  let make ~token ~expiration_time ?(refresh_token = None) () =
    { token; expiration_time; refresh_token }
end

type authorization_grant = {
  client_id : string;
  redirect_uri : string;
  state : string;
  scope : string;
  show_dialog : bool;
}

type authorization_response = { access_token : string; expires_in : float }
[@@deriving yojson { strict = false }]

type error =
  [ `Request_error of Http.Code.status_code * string | `Json_parse_error ]

let token_endpoint = Uri.of_string "https://accounts.spotify.com/api/token"

let fetch_access_token ~client_id ~client_secret =
  let body =
    Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
      [ ("grant_type", [ "client_credentials" ]) ]
  in
  let headers =
    Http.Header.of_list
      [
        ( "Authorization",
          "Basic " ^ Base64.encode_string (client_id ^ ":" ^ client_secret) );
        ("Content-Type", "application/x-www-form-urlencoded");
      ]
  in
  match%lwt Http.Client.post ~headers ~body token_endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_string body in
      match
        authorization_response_of_yojson @@ Yojson.Safe.from_string json
      with
      | Ok res ->
          let at =
            Access_token.make ~token:res.access_token
              ~expiration_time:(Unix.time () +. res.expires_in)
              ()
          in
          Lwt.return_ok at
      | Error _ -> Lwt.return_error `Json_parse_error)
  | res, body ->
      let%lwt json = Http.Body.to_string body in
      let status_code = Http.Response.status res in
      Lwt.return_error (`Request_error (status_code, json))

let authorize_uri = Uri.of_string "https://accounts.spotify.com/authorize"

let make_authorization_url authorization_grant =
  Uri.with_query' authorize_uri
    [
      ("client_id", authorization_grant.client_id);
      ("response_type", "code");
      ("redirect_uri", authorization_grant.redirect_uri);
      ("state", authorization_grant.state);
      ("scope", authorization_grant.scope);
      ("show_dialog", string_of_bool authorization_grant.show_dialog);
    ]
