type t

val get_access_token : t -> Access_token.t
val get_bearer_token : t -> string

val make :
  access_token:[ `Access_token of Access_token.t | `String of string ] -> t

val set_access_token : t -> string -> t
