open Async

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

type error =
  [ `Request_error of Http.Code.status_code * string | `Json_parse_error ]

val make_authorization_url : authorization_parameters -> Http.Uri.t

(* val request_access_token : grant -> (Access_token.t, error) result Promise.t *)
val request_access_token :
  client:Client.t ->
  ?options:unit ->
  grant ->
  (Access_token.t, error) result Promise.t
