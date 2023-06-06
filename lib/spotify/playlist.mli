type t

module Me : sig
  val get_playlists : Client.t -> (t, [ `Msg of string ]) result Lwt.t
  (* Spotify.Playlist.Me.get_playlists *)
end

val get_featured_playlists : Client.t -> (t, [ `Msg of string ]) result Lwt.t
(* Spotify.Playlist.get_featured_playlists *)
