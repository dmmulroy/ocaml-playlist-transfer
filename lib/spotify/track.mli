type linked_track = {
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  resource_type : [ `Track ];
  uri : [ `Track ] Resource.uri;
}
[@@deriving yojson]

type t = {
  album : Album.Simple.t;
  artists : Artist.Simple.t list;
  available_markets : string list;
  disc_number : int;
  duration_ms : int;
  explicit : bool;
  external_ids : Common.external_ids;
  external_urls : Common.external_urls;
  href : Http.Uri.t;
  id : string;
  is_local : bool;
  is_playable : bool option;
  linked_from : linked_track option;
  name : string;
  popularity : int;
  preview_url : string option;
  resource_type : [ `Track ];
  restrictions : Common.restriction list option;
  track_number : int;
  uri : [ `Track ] Resource.uri;
}
[@@deriving yojson]

module Simple : sig
  type t = {
    artists : Artist.Simple.t list;
    available_markets : string list;
    disc_number : int;
    duration_ms : int;
    explicit : bool;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    is_local : bool;
    is_playable : bool option;
    linked_from : linked_track option;
    name : string;
    preview_url : string option;
    resource_type : [ `Track ];
    restrictions : Common.restriction list option;
    track_number : int;
    uri : [ `Track ] Resource.uri;
  }
  [@@deriving yojson]
end
