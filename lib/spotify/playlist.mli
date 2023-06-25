type t = {
  collaborative : bool;
  description : string option;
  external_urls : Common.external_urls;
  followers : Resource.reference;
  href : Http.Uri.t;
  id : string;
  images : Common.image list;
  name : string;
  owner : User.t;
  primary_color : string option;
  public : bool option;
  resource_type : Resource.t;
  snapshot_id : string;
  tracks : playlist_track Page.t;
  uri : string;
}
[@@deriving yojson]

and playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option; [@default None]
  track : Track.t;
}
[@@deriving yojson]

type create_options = {
  public : bool option;
  collaborative : bool option;
  description : string option;
}

type get_by_id_options = {
  fields : string option;
  market : string option;
  additional_types : [ `Track | `Episode ] option;
}

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

type get_current_users_playlists_options = {
  limit : int option;
  offset : int option;
}

(* Spotify.Playlist.create*)
val create :
  client:Client.t ->
  user_id:string ->
  name:string ->
  ?options:create_options option ->
  unit ->
  (t, [ `Msg of string ]) result Lwt.t

(* Spotify.Playlist.get_by_id *)
val get_by_id :
  client:Client.t ->
  string ->
  ?options:get_by_id_options option ->
  unit ->
  (t, [ `Msg of string ]) result Lwt.t

type get_featured_response = {
  message : string;
  playlists : Simple_playlist.t Page.t;
}
[@@deriving yojson]

(* Spotify.Playlist.get_featured  *)
val get_featured :
  client:Client.t ->
  ?options:get_featured_playlists_options option ->
  unit ->
  (get_featured_response, [ `Msg of string ]) result Lwt.t

module Me : sig
  (* Spotify.Playlist.Me.get_playlists *)
  val get_all :
    client:Client.t ->
    ?options:get_current_users_playlists_options option ->
    unit ->
    (Simple_playlist.t Page.t, [ `Msg of string ]) result Lwt.t
end
