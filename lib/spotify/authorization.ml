let authorize_uri = Http.Uri.of_string "https://accounts.spotify.com/authorize"

let make_authorization_url ~client_id ~redirect_uri ?scopes
    ?(show_dialog = true) ~state () =
  let query_params =
    [
      ("client_id", client_id);
      ("response_type", "code");
      ("redirect_uri", Http.Uri.to_string redirect_uri);
      ("state", state);
      ("show_dialog", string_of_bool show_dialog);
    ]
  in
  let scope =
    Option.map
      (fun scope_list ->
        String.concat " " @@ List.map Scope.to_string scope_list)
      scopes
  in
  Http.Uri.with_query' authorize_uri
    (query_params
    @ match scope with Some scope -> [ ("scope", scope) ] | None -> [])

type authorization_code_grant = {
  client_id : string;
  client_secret : string;
  redirect_uri : Http.Uri.t;
  code : string;
}

type authorization_code_grant_response = {
  access_token : string;
  expires_in : float;
  scope : string;
  token_type : string;
  refresh_token : string;
}
[@@deriving yojson]

type client_credentials_grant = { client_id : string; client_secret : string }

type error =
  [ `Request_error of Http.Code.status_code * string
  | `Json_parse_error
  | `No_refresh_token
  | `Invalid_refresh_token ]

type client_credentials_grant_response = {
  access_token : string;
  expires_in : float;
  token_type : string;
}
[@@deriving yojson]

let authorize_uri = Http.Uri.of_string "https://accounts.spotify.com/authorize"

module RequestAccessToken = struct
  type input =
    [ `Authorization_code of authorization_code_grant
    | `Client_credentials of client_credentials_grant ]

  type options = unit
  type output = Access_token.t
  type nonrec error = error

  let make_headers grant =
    let client_id, client_secret =
      match grant with
      | `Authorization_code
          ({ client_id; client_secret; _ } : authorization_code_grant)
      | `Client_credentials { client_id; client_secret } ->
          (client_id, client_secret)
    in
    Http.Header.of_list
      [
        ("Content-Type", "application/x-www-form-urlencoded");
        ( "Authorization",
          "Basic " ^ Base64.encode_string (client_id ^ ":" ^ client_secret) );
      ]

  let endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

  let response_of_yojson json =
    match authorization_code_grant_response_of_yojson json with
    | Ok res -> Ok (`Authorization_code res)
    | Error _ -> (
        match client_credentials_grant_response_of_yojson json with
        | Ok res -> Ok (`Client_credentials res)
        | Error _ -> Error `Json_parse_error)

  let to_http ?options input =
    match options with
    | _ -> (
        match input with
        | `Authorization_code (grant : authorization_code_grant) ->
            ( `POST,
              make_headers (`Authorization_code grant),
              endpoint,
              Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
                [
                  ("code", [ grant.code ]);
                  ("redirect_uri", [ Http.Uri.to_string grant.redirect_uri ]);
                  ("grant_type", [ "authorization_code" ]);
                ] )
        | `Client_credentials (grant : client_credentials_grant) ->
            ( `POST,
              make_headers (`Client_credentials grant),
              endpoint,
              Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
                [ ("grant_type", [ "client_credentials" ]) ] ))

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match response_of_yojson json with
        | Ok (`Authorization_code _res) -> Lwt.return_ok ()
        | Ok (`Client_credentials _res) -> Lwt.return_ok ()
        | Error err -> Lwt.return_error err)
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        print_endline @@ json;
        let status_code = Http.Response.status res in
        Lwt.return_error (`Request_error (status_code, json))
end

(* let request_access_token = *)
(*   RequestAccessToken.unauthenticated_request ~options:() *)

module RefreshAccessToken = struct
  type input = Access_token.t
  type options = unit
  type output = Access_token.t
  type nonrec error = error

  let endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

  let to_http ?_options access_token =
    let _client_id, _client_secret =
      Access_token.get_client_credentials access_token
    in
    ()
end
