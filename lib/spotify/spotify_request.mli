open Async

module type S = sig
  type input
  type options
  type output
  type error

  val to_http :
    ?options:options ->
    input ->
    Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http :
    Http.Response.t * Http.Body.t -> (output, error) result Promise.t
end

module Make (M : S) : sig
  val request :
    client:Client.t ->
    ?options:M.options ->
    M.input ->
    (M.output, M.error) result Promise.t

  val unauthenticated_request :
    ?options:M.options -> M.input -> (M.output, M.error) result Promise.t
end
