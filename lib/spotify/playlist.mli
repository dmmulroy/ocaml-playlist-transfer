open Async

type playlist_track = {
  added_at : string;
  added_by : User.t;
  is_local : bool;
  primary_color : string option;
  track : Track.t;
  video_thumbnail : video_thumbnail option;
}
[@@deriving yojson]

and video_thumbnail = { url : Http.Uri.t option } [@@deriving yojson]

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

type get_featured_playlists_options = {
  country : string option;
  locale : string option;
  timestamp : string option;
  limit : int option;
  offset : int option;
}

type create_playlist_input = {
  collaborative : bool option;
  description : string option;
  name : string;
  public : bool option;
  user_id : string;
}

(* Spotify.Playlist.create*)
val create :
  client:Client.t ->
  ?options:unit ->
  create_playlist_input ->
  (t, [ `Msg of string ]) result Promise.t

module Get_by_id_input : sig
  type t = {
    id : string;
    additional_types : [ `Track | `Episode ] option;
    fields : string option;
    market : string option;
  }

  val make :
    ?additional_types:[ `Track | `Episode ] list ->
    ?fields:string ->
    ?market:string ->
    string ->
    t
end

module Get_by_id_output : sig
  type nonrec t = t
end

(* Spotify.Playlist.get_by_id *)
val get_by_id :
  client:Client.t ->
  Get_by_id_input.t ->
  (Get_by_id_output.t, [ `Msg of string ]) result Promise.t

type get_featured_response = {
  message : string;
  playlists : Simple_playlist.t Page.t;
}
[@@deriving yojson]

(* Spotify.Playlist.get_featured  *)
val get_featured :
  client:Client.t ->
  ?options:get_featured_playlists_options ->
  unit ->
  (get_featured_response, [ `Msg of string ]) result Promise.t
