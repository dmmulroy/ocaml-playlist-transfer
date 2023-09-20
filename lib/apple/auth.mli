open Shared

module Test_auth_input : sig
  type t = unit
end

module Test_auth_output : sig
  type t = unit
end

val test_auth :
  client:Client.t ->
  Test_auth_input.t ->
  (Test_auth_output.t, Error.t) result Lwt.t
