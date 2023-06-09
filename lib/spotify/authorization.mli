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
type error = [ `No_refresh_token | `Invalid_grant_type ]

val error_to_string : error -> string

val request_access_token :
  [ `Authorization_code of authorization_code_grant
  | `Client_credentials of client_credentials_grant ] ->
  (Access_token.t, [ error | Spotify_request.error | Common.error ]) result
  Promise.t

val refresh_access_token :
  client:Client.t ->
  (Access_token.t, [ error | Spotify_request.error | Common.error ]) result
  Promise.t
