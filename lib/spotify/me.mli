type get_playlists_options = { limit : int option; offset : int option }

val get_playlists :
  client:Client.t ->
  ?options:get_playlists_options ->
  unit ->
  (Simple_playlist.t Page.t, [ `Msg of string ]) result Lwt.t
