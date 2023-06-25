type t

val get_bearer_token : t -> string
val make : Authorization.Access_token.t -> t
