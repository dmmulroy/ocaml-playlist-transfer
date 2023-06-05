module Access_token : sig
  type t

  val is_expired : t -> bool

  val make :
    token:string ->
    expiration_time:float ->
    ?refresh_token:string option ->
    unit ->
    t

  val show : t -> string
end

type authorization_grant = {
  client_id : string;
  redirect_uri : string;
  state : string;
  scope : string;
  show_dialog : bool;
}

type error =
  [ `Request_error of Http.Code.status_code * string | `Json_parse_error ]

val fetch_access_token :
  client_id:string ->
  client_secret:string ->
  (Access_token.t, error) result Lwt.t

val make_authorization_url : authorization_grant -> Uri.t
