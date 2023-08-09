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

module Create_input : sig
  type t = {
    collaborative : bool option;
    description : string option;
    name : string;
    public : bool option;
    user_id : string;
  }

  val make :
    ?collaborative:bool ->
    ?description:string ->
    ?public:bool ->
    name:string ->
    user_id:string ->
    unit ->
    t
end

module Create_output : sig
  type nonrec t = t
end

(* Spotify.Playlist.create*)
val create :
  client:Client.t ->
  Create_input.t ->
  ( Create_output.t,
    [ `Http_error of int * string | `Json_parse_error of string ] )
  Lwt_result.t

module Get_by_id_input : sig
  type t = {
    id : string;
    additional_types : [ `Track | `Episode ] list option;
    fields : string option;
    market : string option;
  }

  val make :
    ?additional_types:[ `Track | `Episode ] list ->
    ?fields:string ->
    ?market:string ->
    id:string ->
    unit ->
    t
end

module Get_by_id_output : sig
  type nonrec t = t
end

(* Spotify.Playlist.get_by_id *)
val get_by_id :
  client:Client.t ->
  Get_by_id_input.t ->
  ( Get_by_id_output.t,
    [ `Http_error of int * string | `Json_parse_error of string ] )
  Lwt_result.t

module Get_featured_input : sig
  type t = {
    country : string option;
    locale : string option;
    timestamp : string option;
    limit : int option;
    offset : int option;
  }

  val make :
    ?country:string ->
    ?locale:string ->
    ?timestamp:string ->
    ?limit:int ->
    ?offset:int ->
    unit ->
    t
end

module Get_featured_output : sig
  type t = { message : string; playlists : Simple_playlist.t Page.t }
  [@@deriving yojson]
end

(* Spotify.Playlist.get_featured  *)
val get_featured :
  client:Client.t ->
  Get_featured_input.t ->
  ( Get_featured_output.t,
    [ `Http_error of int * string | `Json_parse_error of string ] )
  Lwt_result.t
