open Shared
open Syntax
open Let

module Internal_error = struct
  type t =
    [ `Invalid_grant_type | `No_refresh_token | `Unhandled_error of string ]

  let to_string = function
    | `Invalid_grant_type -> "Invalid grant type"
    | `No_refresh_token -> "No refresh token"
    | `Unhandled_error str -> "An unhandled error occurred: " ^ str
    | #t -> .
    | _ -> "An unhandled error occurred"

  let to_error ?(map_msg = fun str -> `Unhandled_error str) ?(source = `Auth)
      err =
    (match err with `Msg str -> map_msg str | _ as err' -> err')
    |> to_string |> Spotify_error.make ~source
end

type authorization_code_grant = {
  client_id : string;
  client_secret : string;
  redirect_uri : Http.Uri.t;
  code : string;
}

let make_authorization_code_grant ~client_id ~client_secret ~redirect_uri ~code
    =
  { client_id; client_secret; redirect_uri; code }

type client_credentials_grant = { client_id : string; client_secret : string }

let make_client_credentials_grant ~client_id ~client_secret =
  { client_id; client_secret }

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
  scopes
  |> Option.map (fun scope_list ->
         List.map Scope.to_string scope_list |> String.concat " ")
  |> Option.fold ~none:[] ~some:(fun scope -> [ ("scope", scope) ])
  |> List.append query_params
  |> Http.Uri.with_query' authorize_uri

type client_credentials_grant_response = {
  access_token : string;
  expires_in : int;
  token_type : string;
}
[@@deriving yojson]

type authorization_code_grant_response = {
  access_token : string;
  expires_in : int;
  scope : string;
  token_type : string;
  refresh_token : string;
}
[@@deriving yojson]

let make_headers ~client_id ~client_secret =
  Http.Header.of_list
    [
      ("Content-Type", "application/x-www-form-urlencoded");
      ( "Authorization",
        "Basic " ^ Base64.encode_string (client_id ^ ":" ^ client_secret) );
    ]

module Request_access_token = struct
  let name = "Request_access_token"

  type input =
    [ `Authorization_code of authorization_code_grant
    | `Client_credentials of client_credentials_grant ]

  type output = Access_token.t [@@deriving yojson]

  let endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

  let response_of_yojson json =
    let@ response =
      match authorization_code_grant_response_of_yojson json with
      | Ok res -> Ok (`Authorization_code res)
      | Error _ -> (
          match client_credentials_grant_response_of_yojson json with
          | Ok res -> Ok (`Client_credentials res)
          | Error msg -> Error msg)
    in
    let access_token =
      match response with
      | `Authorization_code grant ->
          Access_token.make ~token:grant.access_token
            ~expiration_time:((Unix.time () |> Int.of_float) + grant.expires_in)
            ~grant_type:`Authorization_code ~refresh_token:grant.refresh_token
            ~scopes:
              (Scope.of_string_list @@ String.split_on_char ' ' grant.scope)
            ()
      | `Client_credentials grant ->
          Access_token.make ~token:grant.access_token
            ~expiration_time:((Unix.time () |> Int.of_float) + grant.expires_in)
            ~grant_type:`Client_credentials ()
    in
    Ok access_token

  let to_http_request = function
    | `Authorization_code (grant : authorization_code_grant) ->
        Lwt.return_ok
        @@ Http.Request.make ~meth:`POST
             ~headers:
               (make_headers ~client_id:grant.client_id
                  ~client_secret:grant.client_secret)
             ~body:
               (Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
                  [
                    ("code", [ grant.code ]);
                    ("redirect_uri", [ Http.Uri.to_string grant.redirect_uri ]);
                    ("grant_type", [ "authorization_code" ]);
                  ])
             ~uri:endpoint ()
    | `Client_credentials (grant : client_credentials_grant) ->
        Lwt.return_ok
        @@ Http.Request.make ~meth:`POST
             ~headers:
               (make_headers ~client_id:grant.client_id
                  ~client_secret:grant.client_secret)
             ~body:
               (Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
                  [ ("grant_type", [ "client_credentials" ]) ])
             ~uri:endpoint ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:response_of_yojson
end

let request_access_token grant =
  let module Request =
    Spotify_rest_client.Make_unauthenticated (Request_access_token) in
  Request.request grant |> Lwt_result.map Spotify_rest_client.Response.make

module Refresh_access_token = struct
  let name = "Refresh_access_token"

  type input = {
    client_id : string;
    client_secret : string;
    refresh_token : string;
  }

  type output = {
    access_token : string;
    expires_in : int;
    scope : string;
    token_type : string;
  }
  [@@deriving yojson]

  let endpoint = Http.Uri.of_string "https://accounts.spotify.com/api/token"

  let to_http_request { client_id; client_secret; refresh_token } =
    Lwt.return_ok
    @@ Http.Request.make ~meth:`POST
         ~headers:(make_headers ~client_id ~client_secret)
         ~body:
           (Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
              [
                ("grant_type", [ "refresh_token" ]);
                ("refresh_token", [ refresh_token ]);
              ])
         ~uri:endpoint ()

  let of_http_response =
    Spotify_rest_client.handle_response ~deserialize:output_of_yojson
end

let refresh_access_token ~client ~client_id ~client_secret =
  let module Request =
    Spotify_rest_client.Make_unauthenticated (Refresh_access_token) in
  let access_token = Client.get_access_token client in
  if Access_token.get_grant_type access_token <> `Authorization_code then
    Lwt.return_error @@ Internal_error.to_error `Invalid_grant_type
  else
    let refresh_token = Access_token.get_refresh_token access_token in
    match refresh_token with
    | None -> Lwt.return_error @@ Internal_error.to_error `No_refresh_token
    | Some refresh_token ->
        let open Infix.Lwt_result in
        let+ { expires_in; _ } =
          Request.request { client_id; client_secret; refresh_token }
          >|? fun err ->
          Spotify_error.make ~cause:err ~source:`Auth
            "Error refreshing access token"
        in
        let refreshed_access_token =
          Access_token.set_expiration_time access_token
            ((Unix.time () |> Int.of_float) + expires_in)
        in
        Lwt.return_ok refreshed_access_token
        |> Lwt_result.map Spotify_rest_client.Response.make
