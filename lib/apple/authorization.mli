module Jwt : sig
  type t

  val is_expired : t -> bool

  val make :
    ?expiration:float ->
    private_pem:string ->
    key_id:string ->
    team_id:string ->
    unit ->
    (t, [ `Msg of string | `Unsupported_kty ]) result

  val to_string : t -> string

  val validate :
    t -> (t, [ `Expired | `Invalid_signature | `Msg of string ]) result
end
