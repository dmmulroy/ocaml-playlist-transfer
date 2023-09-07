open Syntax
open Let
module Track = Track
module Playlist = Playlist

(* 
 * Transfer.to_spotify track
 * Transfer.to_apple track
 * TODO: Figure out how to deal w/ rate + page limits
 *)

module Internal_error = struct
  type t = [ `Empty_apple_response | `Unhandled_error of string ]

  let to_string = function
    | `Empty_apple_response ->
        "The `data` list returned from `Apple.Library_playlist.create` was \
         empty"
    | `Unhandled_error str -> "An unhandled error occurred: " ^ str
    | #t -> .
    | _ -> "An unhandled error occurred"

  let to_error ?(map_msg = fun str -> `Unhandled_error str)
      ?(source = `Source "Transfer") err =
    let message =
      (match err with `Msg str -> map_msg str | _ as err' -> err')
      |> to_string
    in
    Transfer_error.make ~source message
end

(* val to_apple : t -> Apple.Library_playlist.t Lwt_result.t *)
(*
 * For each track in playlist.tracks
 *   if track.id is of Apple
 *   then map track to Apple.Library_playlist.Create_input.track
 *   else search Apple Music for the track using Apple.Song.search
 * 
 * TODO: 
 * - Run search results in parallel
 * - Handle not_found/processed results gracefully
 * 
 *)
let to_apple ~(client : Apple.Client.t) (playlist : Playlist.t) =
  let create_input =
    Apple.Library_playlist.Create_input.make ~description:playlist.description
      ~name:playlist.name ()
  in
  let+ _apple_playlist =
    Infix.Lwt_result.(
      Apple.Library_playlist.create ~client create_input >>= fun { data } ->
      try Lwt.return_ok (List.hd data)
      with Failure _ ->
        Lwt.return_error @@ Internal_error.to_error `Empty_apple_response)
  in
  Lwt.return_ok ()

let to_spotify _track = ()
