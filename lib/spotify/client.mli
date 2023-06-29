type t

val get_bearer_token : t -> string
val make : Authorization.Access_token.t -> t

(*
  Client API: 
  Spotify.Playlist.get_by_id ~client:client ~id:"123" ()
  
  in Playlist.ml:
  module GetPlaylistById : SpotifyRequest struct ... end
  let get_by_id = Client.execute_request GetPlaylistById

  or MakeExecutor functor option:

  module GetPlaylistById : SpotifyRequest struct ... end
  module GetPlaylistByIdExecutor = MakeExecutor(GetPlaylistById)
  let get_by_id =GetPlaylistByIdExecutor.execute 

*)

module HttpRequest : sig
  type t = method' * headers * endpoint * body

  and method' =
    [ `GET
    | `POST
    | `PUT
    | `DELETE
    | `HEAD
    | `CONNECT
    | `OPTIONS
    | `TRACE
    | `PATCH ]

  and headers = (string * string) list
  and endpoint = Uri.t
  and body = string option

  (* val method_to_string : [< method_ ] -> string *)
  (* val method_of_string : string -> method_ *)
end

module HttpResponse : sig
  type t
end

module type SpotifyRequest = sig
  type input
  type output
  type error

  val to_http : input -> HttpRequest.t
  val of_http : HttpResponse.t -> (output, error) result
end

type ('input, 'output, 'error) request =
  (module SpotifyRequest
     with type input = 'input
      and type output = 'output
      and type error = 'error)

type 'a promise = 'a Lwt.t

val execute_request :
  ('input, 'output, 'error) request ->
  t ->
  'input ->
  ('output, 'error) result promise

(* module GetPlaylistByid : sig *)
(*   type input = string *)
(*   type output = string *)
(*   type error = string *)
(***)
(*   val to_http : input -> Http.HttpRequest.t *)
(*   val of_http : Http.HttpResponse.t -> (output, error) result *)
(***)
(*   include *)
(*     SpotifyRequest *)
(*       with type input := input *)
(*        and type output := output *)
(*        and type error := error *)
(* end *)
