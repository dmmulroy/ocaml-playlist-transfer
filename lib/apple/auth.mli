open Shared

module Test_auth_input : sig
  type t = unit
end

module Test_auth_output : sig
  type t = unit
end

val test_auth :
  client:Client.t ->
  unit ->
  (unit Apple_rest_client.Response.t, Error.t) result Lwt.t
