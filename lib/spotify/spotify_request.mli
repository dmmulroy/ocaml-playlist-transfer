open Async
module Api_request = Http.Api_request

module Make (M : Api_request.S) : sig
  val request :
    client:Client.t -> M.input -> (M.output, M.error) result Promise.t
end

module Make_unauthenticated (M : Api_request.S) : sig
  val request : M.input -> (M.output, M.error) result Promise.t
end
