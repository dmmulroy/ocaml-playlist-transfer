type error =
  [ `Expired
  | `Private_key_error of string
  | `Token_signing_error of string
  | `Unsupported_kty
  | `Validation_error of string ]

val error_to_string : error -> string

module Jwt : sig
  type t

  val is_expired : t -> bool

  val make :
    ?expiration:int ->
    private_pem:string ->
    key_id:string ->
    team_id:string ->
    unit ->
    ( t,
      [ `Private_key_error of string
      | `Token_signing_error of string
      | `Unsupported_kty ] )
    result

  val to_bearer_token : t -> string
  val to_string : t -> string

  val validate :
    t ->
    (t, [ `Expired | `Invalid_signature | `Validation_error of string ]) result
end

module Test_authorization_input : sig
  type t = Jwt.t
end

module Test_authorization_output : sig
  type t = unit
end

val test_authorization :
  Test_authorization_input.t ->
  (Test_authorization_output.t, [ `Http_error of int * string ]) result Lwt.t
