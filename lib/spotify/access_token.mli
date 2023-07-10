type t

val get_client_credentials : t -> string * string
val get_expiration_time : t -> float
val get_refresh_token : t -> string option
val get_scopes : t -> Scope.t list option
val get_token : t -> string
val is_expired : t -> bool

val make :
  ?scopes:Scope.t list ->
  ?refresh_token:string ->
  client_id:string ->
  client_secret:string ->
  expiration_time:float ->
  token:string ->
  unit ->
  t

val to_bearer_token : t -> string
