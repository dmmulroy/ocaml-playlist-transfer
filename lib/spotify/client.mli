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

type t

val get_bearer_token : t -> string
val make : Access_token.t -> t
