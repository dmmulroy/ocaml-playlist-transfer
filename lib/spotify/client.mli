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

module type SpotifyRequest = sig
  type input
  type output
  type error

  val to_http :
    input -> Http.Code.meth * Http.Header.t * Http.Uri.t * Http.Body.t

  val of_http : Http.Response.t * Http.Body.t -> (output, error) result
end

module MakeRequestExecutor (M : SpotifyRequest) : sig
  open Async

  val execute : client:t -> M.input -> (M.output, M.error) result Promise.t
end
