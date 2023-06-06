module Me : sig
  val get_playlists : Client.t -> (unit, [ `Msg of string ]) result Lwt.t
  (* Spotify.Playlist.Me.get_playlists *)
end

type get_featured_playlists_request = {
  country : string;
  locale : string;
  timestamp : string;
  limit : int;
  offset : int;
}

val get_featured_playlists : Client.t -> (unit, [ `Msg of string ]) result Lwt.t
(* Spotify.Playlist.get_featured_playlists *)
