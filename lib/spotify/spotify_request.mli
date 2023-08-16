module type S = sig
  type input
  type output [@@deriving of_yojson]

  val name : string
  val to_http_request : input -> Http.Request.t
  val of_http_response : Http.Response.t -> (output, Error.t) Lwt_result.t
end

module Make (M : S) : sig
  val request : client:Client.t -> M.input -> (M.output, Error.t) Lwt_result.t
end

module Make_unauthenticated (M : S) : sig
  val request : M.input -> (M.output, Error.t) Lwt_result.t
end

val default_of_http_response :
  deserialize:(Yojson.Safe.t -> ('a, string) result) ->
  Http.Response.t ->
  ('a, Error.t) Lwt_result.t
