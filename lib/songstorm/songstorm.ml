[@@@ocaml.warning "-27-26"]

open Shared
open Syntax
open Let
module Client = Client
module Error = Shared.Error

type platform = Apple | Spotify

type transfer_report = {
  id : string;
  name : string;
  url : Uri.t;
  source : platform;
  destination : platform;
  transferred_track_count : int;
  skipped_track_ids : string list;
  timestamp : Ptime.t;
}

let make = Client.make
let make_apple_client = Auth.make_apple_client
let make_spotify_client = Auth.make_spotify_client

let transfer_from_apple_to_spotify ~(client : Client.t) playlist_id =
  let+ apple_playlist =
    Apple.Library_playlist.get_by_id ~client:client.apple_client playlist_id
  in
  failwith "not implemented"

(* https://api.music.apple.com *)
let transfer_from_spotify_to_apple ~(client : Client.t) playlist_id =
  let+ { data = spotify_playlist } =
    Spotify.Playlist.get_by_id ~client:client.spotify_client playlist_id
  in
  let+ spotify_tracks =
    Utils.Spotify.fetch_all_spotify_playlist_tracks
      ~client:client.spotify_client playlist_id
  in
  let spotify_playlist' =
    {
      spotify_playlist with
      tracks = { spotify_playlist.tracks with items = spotify_tracks };
    }
  in
  let+ songstorm_playlist, skipped_spotify_tracks =
    Transfer.Playlist.of_spotify ~client:client.spotify_client spotify_playlist'
  in
  let+ apple_playlist =
    Transfer.to_apple ~client:client.apple_client songstorm_playlist
  in
  (* TODO: Start here on Thursday w/ fetching + paginating over all tracks for a count*)
  let transferred_track_count =
    match apple_playlist.relationships with 
    | Some { tracks = Some { data = tracks } } -> List.length tracks
  Lwt.return_ok
    {
      id = apple_playlist.id;
      name = apple_playlist.attributes.name;
      url =
        Uri.(
          of_string "https://api.music.apple.com"
          |> Fun.flip Uri.with_path apple_playlist.href);
      source = Spotify;
      destination = Apple;
      transferred_track_count =
        List.length songstorm_playlist.Transfer.Playlist.tracks;

    }

let transfer ~client ~source ~destination playlist_id =
  match (source, destination) with
  | Spotify, Apple -> transfer_from_spotify_to_apple ~client playlist_id
  | Apple, Spotify -> transfer_from_apple_to_spotify ~client playlist_id
  | Apple, Apple -> failwith "not implemented"
  | Spotify, Spotify -> failwith "not implemented"
