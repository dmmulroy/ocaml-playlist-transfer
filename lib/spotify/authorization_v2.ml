module Access_token = struct
  type t = {
    token : string; [@key "access_token"]
    expiration_time : float;
    refresh_token : string option;
  }
  [@@deriving yojson { strict = false }]

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

type client_credentials_grant = { client_id : string; client_secret : string }
type error = unit

type flow =
  [ `Authorization_code of authorization_grant
  | `Client_credentials of client_credentials_grant
  | `Implicit of authorization_grant ]

let token_endpoint = Uri.of_string "https://accounts.spotify.com/api/token"

let client_credentials_flow client_credentials :
    (Access_token.t, error) result Lwt.t =
  let body =
    Http.Body.of_form ~scheme:"application/x-www-form-urlencoded"
      [ ("grant_type", [ "client_credentials" ]) ]
  in
  let headers =
    Http.Header.of_list
      [
        ( "Authorization",
          Base64.encode_string
            (client_credentials.client_id ^ ":"
           ^ client_credentials.client_secret) );
        ("Content-Type", "application/x-www-form-urlencoded");
      ]
  in
  match%lwt Http.Client.post ~headers ~body token_endpoint with
  | res, body
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res -> (
      let%lwt json = Http.Body.to_string body in
      match Access_token.of_yojson @@ Yojson.Safe.from_string json with
      | Ok access_token -> Lwt.return_ok access_token
      | Error _ -> Lwt.return_error ())
  | _ -> Lwt.return_error ()

let fetch_access_token = function
  | `Authorization_code _ ->
      Lwt.return_ok @@ Access_token.make ~token:"TODO" ~expiration_time:0.0 ()
  | `Client_credentials grant -> client_credentials_flow grant
  | `Implicit _ ->
      Lwt.return_ok @@ Access_token.make ~token:"TODO" ~expiration_time:0.0 ()

let authorize_endpoint = Uri.of_string "https://accounts.spotify.com/authorize"

let make_authorization_url (authorization_grant : authorization_grant) =
  Uri.with_query' authorize_endpoint
    [
      ("client_id", authorization_grant.client_id);
      ("response_type", "code");
      ("redirect_uri", authorization_grant.redirect_uri);
      ("state", authorization_grant.state);
      ("scope", authorization_grant.scope);
      ("show_dialog", string_of_bool authorization_grant.show_dialog);
    ]
