module Me : sig
  val get_playlists : Client.t -> (unit, [ `Msg of string ]) result Lwt.t
  (* Spotify.Playlist.Me.get_playlists *)
end

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

val get_featured_playlists :
  Client.t ->
  ?options:get_featured_playlists_options option ->
  unit ->
  (unit, [ `Msg of string ]) result Lwt.t
(* Spotify.Playlist.get_featured_playlists *)
