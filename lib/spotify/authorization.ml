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

  let to_bearer_token t = "Bearer " ^ t.token
end

type authorization_parameters = {
  client_id : string;
  client_secret : string;
  redirect_uri : Http.Uri.t;
  state : string;
  scopes : Scope.t list option;
  show_dialog : bool;
}

type authorization_code_grant = {
  client_id : string;
  client_secret : string;
  redirect_uri : Http.Uri.t;
  code : string;
}

type client_credentials_grant = { client_id : string; client_secret : string }

type grant =
  [ `Authorization_code of authorization_code_grant
  | `Client_credentials of client_credentials_grant ]

type authorization_response = { access_token : string; expires_in : float }
[@@deriving yojson { strict = false }]

type error =
  [ `Request_error of Http.Code.status_code * string | `Json_parse_error ]

let token_endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

let fetch_with_client_credentials_grant credentials =
  let body =
    Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
      [ ("grant_type", [ "client_credentials" ]) ]
  in
  let headers =
    Http.Header.of_list
      [
        ( "Authorization",
          "Basic "
          ^ Base64.encode_string
              (credentials.client_id ^ ":" ^ credentials.client_secret) );
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

let fetch_with_authorization_code_grant authorization_code_grant =
  let body =
    Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
      [
        ("code", [ authorization_code_grant.code ]);
        ( "redirect_uri",
          [ Http.Uri.to_string authorization_code_grant.redirect_uri ] );
        ("grant_type", [ "authorization_code" ]);
      ]
  in
  let headers =
    Http.Header.of_list
      [
        ( "Authorization",
          "Basic "
          ^ Base64.encode_string
              (authorization_code_grant.client_id ^ ":"
             ^ authorization_code_grant.client_secret) );
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

let fetch_access_token = function
  | `Authorization_code grant -> fetch_with_authorization_code_grant grant
  | `Client_credentials grant -> fetch_with_client_credentials_grant grant

let authorize_uri = Http.Uri.of_string "https://accounts.spotify.com/authorize"

let make_authorization_url (params : authorization_parameters) =
  let query_params =
    [
      ("client_id", params.client_id);
      ("response_type", "code");
      ("redirect_uri", Http.Uri.to_string params.redirect_uri);
      ("state", params.state);
      ("show_dialog", string_of_bool params.show_dialog);
    ]
  in
  let scope =
    Option.map
      (fun scope_list ->
        String.concat " " @@ List.map Scope.to_string scope_list)
      params.scopes
  in
  Http.Uri.with_query' authorize_uri
    (query_params
    @ match scope with Some scope -> [ ("scope", scope) ] | None -> [])
