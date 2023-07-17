type get_playlists_options = { limit : int option; offset : int option }

val get_playlists :
  client:Client.t ->
  ?options:get_playlists_options ->
  unit ->
  (Simple_playlist.t Page.t, [ `Msg of string ]) result Lwt.t

module GetCurrentUserPlaylistsInput : sig
  type t = { limit : int option; offset : int option } [@@deriving show, yojson]

  val make : ?limit:int -> ?offset:int -> unit -> t
end

module GetCurrentUserPlaylistsOutput : sig
  type t = Simple_playlist.t Page.t [@@deriving yojson]
end
