open Async

type error = [ `Request_error of Http.Code.status_code * string ]

val error_to_string : error -> string

module type S = sig
  type input
  type output
  type error

  val to_http :
    input -> Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http :
    Http.Response.t * Http.Body.t -> (output, error) result Promise.t
end

module Make (M : S) : sig
  val request :
    client:Client.t -> M.input -> (M.output, M.error) result Promise.t
end

module Make_unauthenticated (M : S) : sig
  val request : M.input -> (M.output, M.error) result Promise.t
end
