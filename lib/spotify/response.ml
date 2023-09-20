type 'a t = { data : 'a; pagination : Pagination.t option } [@@deriving yojson]

(*
  Option B
  val get_by_id : client:Client.t -> ?page:Page.t -> Input.t -> ({ t; page }, Error.t) result Lwt.t
  let+ {data; pagination} = Spotify.Playlist.get_by_id ~client input
  let+ {data; pagination} = Spotify.Playlist.get_by_id ~client ?(page:pagination.next) input
  let+ {data; pagination} = Spotify.Playlist.get_by_id ~client ?(page:pagination.previous) input
 *)
