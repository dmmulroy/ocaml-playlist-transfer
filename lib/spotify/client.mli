type t

val get_bearer_token : t -> string
val get_client_credentials : t -> string * string
val make : Access_token.t -> t
val set_access_token : t -> Access_token.t -> t
