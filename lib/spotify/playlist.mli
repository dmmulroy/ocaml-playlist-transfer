type external_urls = { spotify : string }
type followers = { total : int }
type image = { height : int; url : Uri.t; width : int }

type owner = {
  external_urls : external_urls;
  followers : followers;
  href : string;
  id : string;
  spotify_type : [ `User ];
  uri : string; (* TODO: consider making spotify_uri type/module  *)
  display_name : string option; (* nullable *)
}
(* TODO: Move to User module *)

type tracks_reference = { href : Uri.t; total : int }

type 'a paginated = {
  href : Uri.t;
  items : 'a list;
  limit : int;
  next : Uri.t option;
  offset : int;
  previous : Uri.t option;
  total : int;
}

(* TODO: Move this out and make it resusable *)
type t = {
  collaborative : bool;
  description : string option; (* nullable *)
  external_urls : external_urls;
  followers : followers;
  href : string;
  id : string;
  images : image list;
  name : string;
  owner : owner;
  public : bool;
  snapshot_id : string;
  tracks : tracks_reference;
  uri : string;
  spotify_type : [ `Playlist ];
}

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
