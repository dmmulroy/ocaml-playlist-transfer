open Shared
open Syntax
open Let

module Spotify = struct
  let fetch_all_spotify_playlist_tracks ~client playlist_id =
    let open Spotify.Spotify_rest_client.Pagination in
    let+ response = Spotify.Playlist.get_tracks_by_id ~client playlist_id in
    let fetch_all_tracks ~client tracks pagination =
      let rec aux acc = function
        | None -> Lwt.return_ok acc
        | Some _ ->
            let+ { data; pagination } =
              Spotify.Playlist.get_tracks_by_id ~client playlist_id
            in
            aux (List.append data acc) pagination.next
      in
      aux tracks pagination.next
    in
    fetch_all_tracks ~client response.data response.pagination
end

module Apple = struct
  let fetch_all_apple_playlist_tracks ~client playlist_id =
    let open Apple.Apple_rest_client.Pagination in
    let+ response =
      Apple.Library_playlist.get_relationship_by_name ~client ~playlist_id
        ~relationship:`Tracks ()
    in
    let fetch_all_tracks ~client tracks pagination =
      let rec aux acc = function
        | None -> Lwt.return_ok acc
        | Some _ ->
            let+ { data; pagination } =
              Apple.Library_playlist.get_relationship_by_name ~client
                ~playlist_id ~relationship:`Tracks ()
            in
            aux (List.append data acc) pagination.next
      in
      aux tracks pagination.next
    failwith ""
end
