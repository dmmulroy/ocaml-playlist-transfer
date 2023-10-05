type t

(*
  Current State:

  let request = Apple.Library_playlist.Get_by_id_input.make playlist_id in
  let+ { data; _ } =
    Apple.Library_playlist.get_by_id ~client:apple_client request
  in

  Future State:

  let request = Apple.Library_playlist.Get_by_id.make_request ... in 
  let response = Apple.Library_playlist.Get_by_id.execute ~client request
 *)
(* module type Request_S = sig
     include Api_request.Config.S

     (* client:C.api_client ->
        M.input ->
        (M.output, Error.t) Lwt_result.t *)
     (* Think about how we could pagination here *)
     val execute : client:'api_client -> input -> (output, Error.t) Lwt_result.t
     val execute_unauthenticated : input -> (output, Error.t) Lwt_result.t
     val make_request : 'a -> input
   end *)
