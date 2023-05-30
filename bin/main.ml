(* open Services *)

(* let () = *)
(*   let client_id = Sys.getenv "SPOTIFY_CLIENT_ID" in *)
(*   let client_secret = Sys.getenv "SPOTIFY_CLIENT_SECRET" in *)
(*   let init_result = Lwt_main.run @@ Spotify.init ~client_id ~client_secret in *)
(*   let spotify = *)
(*     match init_result with *)
(*     | Ok spotify -> spotify *)
(*     | Error (`SpotifyApiError err) -> failwith err *)
(*   in *)
(*   let () = print_string @@ Spotify.to_string spotify in *)
(*   let _ = Unix.system "open https://github.com/dmmulroy/tsc.nvim" in *)
(*   () *)

let () =
  let config = Spotify.Config.make ~client_id:"id" ~client_secret:"secret" () in
  let _ = print_endline @@ Spotify.Config.show config in
  ()
