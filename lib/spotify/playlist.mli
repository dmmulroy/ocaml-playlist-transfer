type tracks_reference = { href : Uri.t; total : int }

type t = {
  collaborative : bool;
  description : string option; (* nullable *)
  external_urls : Common.external_urls;
  href : string;
  id : string;
  images : Common.image list;
  name : string;
  owner : User.t;
  public : bool option;
  snapshot_id : string;
  tracks : tracks_reference;
  uri : string;
  spotify_type : [ `Playlist ];
}

type get_current_users_playlists_options = {
  limit : int option;
  offset : int option;
}

module Me : sig
  type get_current_users_playlists_response = t Paginated_response.t

  (* Spotify.Playlist.Me.get_playlists *)
  val get_playlists :
    Client.t ->
    ?options:get_current_users_playlists_options option ->
    unit ->
    (t list, [ `Msg of string ]) result Lwt.t
end

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

(* Spotify.Playlist.get_featured_playlists *)
val get_featured_playlists :
  Client.t ->
  ?options:get_featured_playlists_options option ->
  unit ->
  (t list, [ `Msg of string ]) result Lwt.t
