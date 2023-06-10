type external_urls = { spotify : string }
type followers = { href : Uri.t option; (* nullable *) total : int }

type image = {
  height : int option; (* nullable *)
  url : Uri.t;
  width : int option (* nullable *);
}

(* TODO: Move to User module *)
type owner = {
  external_urls : external_urls;
  followers : followers option; (* nullable *)
  href : string;
  id : string;
  spotify_type : [ `User ];
  uri : string; (* TODO: consider making spotify_uri type/module  *)
  display_name : string option; (* nullable *)
}

type tracks_reference = { href : Uri.t; total : int }

(* TODO: Move this out and make it resusable *)
type t = {
  collaborative : bool;
  description : string option; (* nullable *)
  external_urls : external_urls;
  href : string;
  id : string;
  images : image list;
  name : string;
  owner : owner;
  public : bool option;
  snapshot_id : string;
  tracks : tracks_reference;
  uri : string;
  spotify_type : [ `Playlist ];
}

module Me : sig
  (* Spotify.Playlist.Me.get_playlists *)
  val get_playlists : Client.t -> (unit, [ `Msg of string ]) result Lwt.t
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
(* TODO: return t paginated *)
