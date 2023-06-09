let authorize_uri = Http.Uri.of_string "https://accounts.spotify.com/authorize"

let make_authorization_url ~client_id ~redirect_uri ~state ?scopes
    ?(show_dialog = true) () =
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
        List.map Scope.to_string scope_list |> String.concat " ")
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

type client_credentials_grant = { client_id : string; client_secret : string }
type error = [ `No_refresh_token | `Invalid_grant_type ]

let error_to_string = function
  | `No_refresh_token -> "No refresh token"
  | `Invalid_grant_type -> "Invalid grant type"

type client_credentials_grant_response = {
  access_token : string;
  expires_in : float;
  token_type : string;
}
[@@deriving yojson]

type authorization_code_grant_response = {
  access_token : string;
  expires_in : float;
  scope : string;
  token_type : string;
  refresh_token : string;
}
[@@deriving yojson]

type refresh_token_response = {
  access_token : string;
  expires_in : float;
  scope : string;
  token_type : string;
}
[@@deriving yojson]

let make_headers ~client_id ~client_secret =
  Http.Header.of_list
    [
      ("Content-Type", "application/x-www-form-urlencoded");
      ( "Authorization",
        "Basic " ^ Base64.encode_string (client_id ^ ":" ^ client_secret) );
    ]

module RequestAccessToken = Spotify_request.Make (struct
  type input =
    [ `Authorization_code of authorization_code_grant
    | `Client_credentials of client_credentials_grant ]

  type options = unit
  type output = Access_token.t
  type nonrec error = [ error | Spotify_request.error | Common.error ]

  let endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

  let response_of_yojson json =
    match authorization_code_grant_response_of_yojson json with
    | Ok res -> Ok (`Authorization_code res)
    | Error _ -> (
        match client_credentials_grant_response_of_yojson json with
        | Ok res -> Ok (`Client_credentials res)
        | Error _ -> Error `Json_parse_error)

  let to_http ?options:_ = function
    | `Authorization_code (grant : authorization_code_grant) ->
        ( `POST,
          make_headers ~client_id:grant.client_id
            ~client_secret:grant.client_secret,
          endpoint,
          Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
            [
              ("code", [ grant.code ]);
              ("redirect_uri", [ Http.Uri.to_string grant.redirect_uri ]);
              ("grant_type", [ "authorization_code" ]);
            ] )
    | `Client_credentials (grant : client_credentials_grant) ->
        ( `POST,
          make_headers ~client_id:grant.client_id
            ~client_secret:grant.client_secret,
          endpoint,
          Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
            [ ("grant_type", [ "client_credentials" ]) ] )

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match response_of_yojson json with
        | Ok (`Authorization_code res) ->
            let access_token =
              Access_token.make ~token:res.access_token
                ~expiration_time:(Unix.time () +. res.expires_in)
                ~grant_type:`Authorization_code ~refresh_token:res.refresh_token
                ~scopes:
                  (Scope.of_string_list @@ String.split_on_char ' ' res.scope)
                ()
            in
            Lwt.return_ok access_token
        | Ok (`Client_credentials res) ->
            let access_token =
              Access_token.make ~token:res.access_token
                ~expiration_time:(Unix.time () +. res.expires_in)
                ~grant_type:`Client_credentials ()
            in
            Lwt.return_ok access_token
        | Error err -> Lwt.return_error err)
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Request_error (status_code, json))
end)

let request_access_token =
  RequestAccessToken.unauthenticated_request ~options:()

module RefreshAccessToken = Spotify_request.Make (struct
  type input = string * string * string
  (** client_id * client_secret * refresh_token *)

  type options = unit
  type output = refresh_token_response
  type nonrec error = [ error | Spotify_request.error | Common.error ]

  let endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

  let to_http ?options:_ (client_id, client_secret, refresh_token) =
    ( `POST,
      make_headers ~client_id ~client_secret,
      endpoint,
      Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
        [
          ("grant_type", [ "refresh_token" ]);
          ("refresh_token", [ refresh_token ]);
        ] )

  let of_http = function
    | res, body when Http.Response.is_success res -> (
        let%lwt json = Http.Body.to_yojson body in
        match refresh_token_response_of_yojson json with
        | Ok res -> Lwt.return_ok res
        | Error _ -> Lwt.return_error `Json_parse_error)
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error (`Request_error (status_code, json))
end)

let refresh_access_token ~client =
  let client_id, client_secret = Client.get_client_credentials client in
  let access_token = Client.get_access_token client in
  if Access_token.get_grant_type access_token <> `Authorization_code then
    Lwt.return_error `Invalid_grant_type
  else
    let refresh_token = Access_token.get_refresh_token access_token in
    match refresh_token with
    | None -> Lwt.return_error `No_refresh_token
    | Some refresh_token ->
        let open Lwt_result.Syntax in
        let* { expires_in; _ } =
          RefreshAccessToken.unauthenticated_request ~options:()
            (client_id, client_secret, refresh_token)
        in
        let refreshed_access_token =
          Access_token.set_expiration_time access_token
            (Unix.time () +. expires_in)
        in
        Lwt.return_ok refreshed_access_token
