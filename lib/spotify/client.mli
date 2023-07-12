type t

val get_access_token : t -> Access_token.t
val get_bearer_token : t -> string
val get_client_credentials : t -> string * string

val make :
  access_token:Access_token.t -> client_id:string -> client_secret:string -> t

val set_access_token : t -> Access_token.t -> t
