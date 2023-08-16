type t [@@deriving yojson]

val get_expiration_time : t -> float
val get_grant_type : t -> [ `Authorization_code | `Client_credentials ]
val get_refresh_token : t -> string option
val get_scopes : t -> Scope.t list option
val get_token : t -> string
val is_expired : t -> bool

val make :
  ?scopes:Scope.t list ->
  ?refresh_token:string ->
  expiration_time:float ->
  grant_type:[ `Authorization_code | `Client_credentials ] ->
  token:string ->
  unit ->
  t

val to_bearer_token : t -> string
val set_expiration_time : t -> float -> t
