open Shared

type t

val is_expired : t -> bool

val make :
  ?expiration:int ->
  private_pem:string ->
  key_id:string ->
  team_id:string ->
  unit ->
  (t, Error.t) result

val of_string : private_pem:string -> string -> (t, Error.t) result
val unsafe_of_string : string -> (t, Error.t) result
val to_string : t -> string
val validate : t -> (t, Error.t) result
