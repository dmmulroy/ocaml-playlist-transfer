module Jwt : sig
  type t

  val is_expired : t -> bool

  val make :
    ?expiration:int ->
    private_pem:string ->
    key_id:string ->
    team_id:string ->
    unit ->
    (t, Error.t) result

  val to_bearer_token : t -> string
  val to_string : t -> string
  val validate : t -> (t, Error.t) result
end

module Test_auth_input : sig
  type t = Jwt.t
end

module Test_auth_output : sig
  type t = unit
end

val test_auth : Test_auth_input.t -> (Test_auth_output.t, Error.t) result Lwt.t
