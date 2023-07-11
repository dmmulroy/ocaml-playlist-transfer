open Async

val make_authorization_url :
  client_id:string ->
  redirect_uri:Http.Uri.t ->
  state:string ->
  ?scopes:[< Scope.t ] list ->
  ?show_dialog:bool ->
  unit ->
  Http.Uri.t

type authorization_code_grant = {
  client_id : string;
  client_secret : string;
  redirect_uri : Http.Uri.t;
  code : string;
}

type client_credentials_grant = { client_id : string; client_secret : string }

type error =
  [ `Request_error of
    Http.Code.status_code
    * string (* TODO: Move to spotify_request.ml or error.ml *)
  | `Json_parse_error (* TODO: Move to common.ml or error.ml*)
  | `No_refresh_token
  | `Invalid_refresh_token ]

val request_access_token :
  [ `Authorization_code of authorization_code_grant
  | `Client_credentials of client_credentials_grant ] ->
  (Access_token.t, error) result Promise.t

(* val refresh_access_token : *)
(*   client:Client.t -> *)
(*   ?options:unit -> *)
(*   unit -> *)
(*   (Access_token.t, [< `No_refresh_token | `Invalid_refresh_token ]) result *)
(*   Promise.t *)
