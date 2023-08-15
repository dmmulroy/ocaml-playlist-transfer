module Get_playlists_input : sig
  type t = { limit : int option; offset : int option } [@@deriving show, yojson]

  val make : ?limit:int -> ?offset:int -> unit -> t
end

module Get_playlists_output : sig
  type t = Simple_playlist.t Page.t [@@deriving yojson]
end

val get_playlists :
  client:Client.t ->
  Get_playlists_input.t ->
  (Get_playlists_output.t, Error.t) Lwt_result.t
