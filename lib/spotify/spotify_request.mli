module type S = sig
  type input
  type output

  val to_http : input -> Http.Request.t

  val of_http :
    Http.Request.t * Http.Response.t -> (output, Error.t) Lwt_result.t
end

module Make (M : S) : sig
  val request : client:Client.t -> M.input -> (M.output, Error.t) Lwt_result.t
end

module Make_unauthenticated (M : S) : sig
  val request : M.input -> (M.output, Error.t) Lwt_result.t
end
