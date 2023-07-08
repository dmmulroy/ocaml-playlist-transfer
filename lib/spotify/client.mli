type t

val get_bearer_token : t -> string
val init : ?access_token:Access_token.t -> unit -> t
val set_access_token : t -> Access_token.t -> t
