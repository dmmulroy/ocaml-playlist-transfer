type authorization_grant = {
  client_id : string;
  redirect_uri : string;
  state : string;
  scope : string;
  show_dialog : bool;
}

type client_credentials_grant = { client_id : string; client_secret : string }
type error

type flow =
  [ `Authorization_code of authorization_grant
  | `Client_credentials of client_credentials_grant
  | `Implicit of authorization_grant ]

module Access_token : sig
  type t

  val make : string -> t
end

val get_access_token : flow -> (Access_token.t, error) result Lwt.t
