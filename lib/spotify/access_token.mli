type t [@@deriving yojson]

val get_expiration_time : t -> int option
val get_grant_type : t -> [ `Authorization_code | `Client_credentials ] option
val get_refresh_token : t -> string option
val get_scopes : t -> Scope.t list option
val of_string : string -> t
val to_string : t -> string
val is_expired : t -> bool option

val make :
  ?scopes:Scope.t list ->
  ?refresh_token:string ->
  expiration_time:int ->
  grant_type:[ `Authorization_code | `Client_credentials ] ->
  token:string ->
  unit ->
  t

val set_expiration_time : t -> int -> t
