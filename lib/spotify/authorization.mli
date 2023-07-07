module Access_token : sig
  type t

  val get_expiration_time : t -> float
  val get_refresh_token : t -> string option
  val get_scopes : t -> Scope.t list option
  val get_token : t -> string
  val is_expired : t -> bool

  val make :
    ?scopes:Scope.t list ->
    ?refresh_token:string ->
    expiration_time:float ->
    token:string ->
    unit ->
    t

  val to_bearer_token : t -> string
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

type error =
  [ `Request_error of Http.Code.status_code * string | `Json_parse_error ]

val fetch_access_token : grant -> (Access_token.t, error) result Lwt.t
val make_authorization_url : authorization_parameters -> Http.Uri.t
