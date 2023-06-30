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
  and method' = [ `GET | `POST ]
  and headers = Http.Header.t
  and endpoint = Uri.t
  and body = Http.Body.t

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

type 'a promise = 'a Lwt.t

module MakeRequestExecutor (M : SpotifyRequest) : sig
  val execute : client:t -> M.input -> (M.output, M.error) result promise
end
