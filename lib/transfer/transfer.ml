open Shared
open Syntax
open Let

(* TODO: Only expose of_apple and of_spotify via .mli *)
module Playlist = struct
  include Playlist

  type t = Playlist.t

  let of_apple = Playlist.of_apple
  let of_spotify = Playlist.of_spotify
end

module Track = Track

(* TODO: Do a comparison of input isrcs vs meta.filters.isrc to track skipped tracks *)
let to_apple ~(client : Apple.Client.t) (playlist : Playlist.t) =
  let isrcs =
    playlist.tracks
    |> Option.map @@ List.map (fun (track : Track.t) -> track.isrc)
    |> Option.value ~default:[]
  in
  let+ { data = { meta; _ }; _ } = Apple.Song.get_many_by_isrcs ~client isrcs in
  let tracks =
    let open Apple.Song.Get_many_by_isrcs in
    List.fold_left
      (fun acc (isrc, list) ->
        List.fold_left
          (fun acc' track ->
            match List.mem_assq isrc acc' with
            | true -> acc'
            | false -> (isrc, track.id) :: acc')
          acc list)
      [] meta.filters.isrc
    |> List.map
         (fun (_, catalog_id) : Apple.Library_playlist.Create_input.track ->
           { id = catalog_id; resource_type = `Songs })
  in
  let+ { data } =
    Apple.Library_playlist.create ~client ~name:playlist.name
      ~description:playlist.description ~tracks ()
  in
  let| playlist =
    Extended.List.hd_opt data
    |> Option.to_result
         ~none:
           (Error.make ~domain:`Transfer ~source:(`Source "Transfer.to_apple")
              "Apple Music did not return a playlist")
  in
  Lwt.return_ok playlist
