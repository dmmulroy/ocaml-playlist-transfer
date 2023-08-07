val make_authorization_url :
  client_id:string ->
  redirect_uri:Http.Uri.t ->
  state:string ->
  ?scopes:[< Scope.t ] list ->
  ?show_dialog:bool ->
  unit ->
  Http.Uri.t

module Request_access_token_input : sig
  type authorization_code_grant = {
    client_id : string;
    client_secret : string;
    redirect_uri : Http.Uri.t;
    code : string;
  }

  type client_credentials_grant = { client_id : string; client_secret : string }

  type t =
    [ `Authorization_code of authorization_code_grant
    | `Client_credentials of client_credentials_grant ]

  val make_authorization_code_grant :
    client_id:string ->
    client_secret:string ->
    redirect_uri:Http.Uri.t ->
    code:string ->
    t

  val make_client_credentials_grant :
    client_id:string -> client_secret:string -> t
end

module Request_access_token_output : sig
  type t = Access_token.t
end

val request_access_token :
  Request_access_token_input.t ->
  (Request_access_token_output.t, Error.t) Lwt_result.t

module Refresh_access_token_output : sig
  type t = Access_token.t
end

val refresh_access_token :
  client:Client.t -> (Refresh_access_token_output.t, Error.t) Lwt_result.t
