type t
type authorization_code = (string, [ `Msg of string ]) result Lwt.t

val make : Config.t -> t
val authorization_code_grant : t -> authorization_code
