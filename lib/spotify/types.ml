open Shared

(* TODO Wednesday: Move the Common module into this module *)

module Artist = struct
  type t = {
    external_urls : Common.external_urls;
    followers : Resource.reference;
    genres : string list;
    href : Http.Uri.t;
    id : string;
    images : Common.image list;
    name : string;
    popularity : int;
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_artist = struct
  type t = {
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    name : string;
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_track = struct
  type t = {
    artists : Simple_artist.t list;
    available_markets : string list;
    disc_number : int;
    duration_ms : int;
    explicit : bool;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    is_local : bool;
    is_playable : bool option;
    linked_from : Common.linked_track option;
    name : string;
    preview_url : string option;
    resource_type : Resource.t; [@key "type"]
    restrictions : Common.restriction list option;
    track_number : int;
    uri : string;
  }
  [@@deriving yojson]
end

module Album = struct
  type album_type = [ `Album | `Single | `Compilation ]
  type album_group = [ album_type | `Appears_on ]

  let album_type_of_yojson = function
    | `String "album" -> Ok `Album
    | `String "single" -> Ok `Single
    | `String "compilation" -> Ok `Compilation
    | _ -> Error "Invalid album album_type"

  let album_type_to_yojson = function
    | `Album -> `String "album"
    | `Single -> `String "single"
    | `Compilation -> `String "compilation"
    | #album_type -> .

  let album_group_of_yojson = function
    | `String "appears_on" -> Ok `Appears_on
    | json -> album_type_of_yojson json

  let album_group_to_yojson = function
    | `Appears_on -> `String "appears_on"
    | #album_type as group -> album_type_to_yojson group
    | #album_group -> .

  type t = {
    album_group : album_group option; [@default None]
    album_type : album_type;
    artists : Artist.t list;
    available_markets : string list;
    copyrights : Common.copyright list;
    external_urls : Common.external_urls;
    genres : string list;
    href : Http.Uri.t;
    id : string;
    images : Common.image list;
    label : string;
    name : string;
    popularity : int;
    release_date : string;
    release_date_precision : Common.release_date_precision;
    resource_type : Resource.t; [@key "type"]
    restrictions : Common.restriction list option; [@default None]
    total_tracks : int;
    tracks : Simple_track.t list;
    uri : string;
  }
  [@@deriving yojson]
end

module Episode = struct
  type resume_point = { fully_played : bool; resume_position_ms : int }
  [@@deriving yojson]

  type t = {
    audio_preview_url : Http.Uri.t option; [@default None]
    description : string option; [@default None]
    duration_ms : int;
    explicit : bool;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    html_description : string option; [@default None]
    id : string;
    images : Common.image list option; [@default None]
    is_externally_hosted : bool option; [@default None]
    is_playable : bool;
    languages : string list option; [@default None]
    name : string;
    release_date : string option; [@default None]
    release_date_precision : string option; [@default None]
    resource_type : Resource.t; [@key "type"]
    restrictions : Common.restriction option; [@default None]
    resume_point : resume_point option; [@default None]
    uri : string;
  }
  [@@deriving yojson]
end

module Private_user = struct
  type explicit_content = { filter_enabled : bool; filter_locked : bool }
  [@@deriving yojson]

  type product = [ `Premium | `Free | `Open ]

  let product_of_yojson = function
    | `String "premium" -> Ok `Premium
    | `String "free" -> Ok `Free
    | `String "open" -> Ok `Open
    | _ -> Error "Invalid product"

  let product_to_yojson = function
    | `Premium -> `String "premium"
    | `Free -> `String "free"
    | `Open -> `String "open"

  type t = {
    country : string;
    email : string;
    explicit_content : explicit_content option; [@default None]
    product : product;
    display_name : string option; [@default None]
    external_urls : Common.external_urls;
    followers : Resource.reference option; [@default None]
    href : Http.Uri.t;
    id : string;
    image : Common.image list option; [@default None]
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_album = struct
  type t = {
    album_group : Album.album_group option; [@default None]
    album_type : Album.album_type;
    artists : Simple_artist.t list;
    available_markets : string list;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    images : Common.image list;
    is_playable : bool option; [@default None]
    name : string;
    release_date : string option; [@default None]
    release_date_precision : Common.release_date_precision option;
        [@default None]
    restrictions : Common.restriction option; [@default None]
    total_tracks : int;
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_episode = struct
  type t = {
    audio_preview_url : Http.Uri.t;
    description : string;
    duration_ms : int;
    explicit : bool;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    html_description : string;
    id : string;
    images : Common.image list;
    is_externally_hosted : bool;
    is_playable : bool;
    languages : string list;
    name : string;
    release_date : string;
    release_date_precision : string;
    resource_type : Resource.t; [@key "type"]
    restrictions : Common.restriction option; [@default None]
    resume_point : Episode.resume_point;
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_show = struct
  type t = {
    available_markets : string list;
    copyrights : Common.copyright list;
    description : string;
    explicit : bool;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    html_description : string;
    id : string;
    images : Common.image list;
    is_externally_hosted : bool;
    languages : string list;
    media_type : string;
    name : string;
    publisher : string;
    resource_type : Resource.t; [@key "type"]
    total_episodes : int;
    uri : string;
  }
  [@@deriving yojson]
end

module User = struct
  type t = {
    display_name : string option; [@default None]
    external_urls : Common.external_urls;
    followers : Resource.reference option; [@default None]
    href : Http.Uri.t;
    id : string;
    image : Common.image list option; [@default None]
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson { strict = false }]
end

module Simple_playlist = struct
  type t = {
    collaborative : bool;
    description : string option;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    images : Common.image list;
    name : string;
    owner : User.t;
    public : bool option;
    resource_type : Resource.t; [@key "type"]
    snapshot_id : string;
    tracks : Resource.reference;
    uri : string;
  }
  [@@deriving yojson]
end

module Show = struct
  type t = {
    available_markets : string list;
    copyrights : Common.copyright list;
    description : string;
    episodes : Simple_episode.t list;
    explicit : bool;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    html_description : string;
    id : string;
    images : Common.image list;
    is_externally_hosted : bool;
    languages : string list;
    media_type : string;
    name : string;
    publisher : string;
    resource_type : Resource.t; [@key "type"]
    total_episodes : int;
    uri : string;
  }
  [@@deriving yojson]
end

module Track = struct
  type t = {
    (* album : Simple_album.t; *)
    (* artists : Simple_artist.t list; *)
    available_markets : string list;
    disc_number : int;
    duration_ms : int;
    episode : bool option; [@default None]
    explicit : bool;
    external_ids : Common.external_ids;
    external_urls : Common.external_urls;
    href : Http.Uri.t;
    id : string;
    is_local : bool;
    is_playable : bool option; [@default None]
    (* linked_from : Common.linked_track option; [@default None] *)
    name : string;
    popularity : int;
    preview_url : string option; [@default None]
    resource_type : Resource.t; [@key "type"]
    (* restrictions : Common.restriction list option; [@default None] *)
    track : bool option; [@default None]
    track_number : int;
    uri : string;
  }
  [@@deriving yojson { strict = false }]
end

module Playlist = struct
  type video_thumbnail = { url : Http.Uri.t option } [@@deriving yojson]

  type playlist_track = {
    added_at : string;
    added_by : User.t;
    is_local : bool;
    primary_color : string option; [@default None]
    track : Track.t;
    video_thumbnail : video_thumbnail option; [@default None]
  }
  [@@deriving yojson { strict = false }]

  type t = {
    collaborative : bool;
    description : string option; [@default None]
    external_urls : Common.external_urls;
    followers : Resource.reference;
    href : Http.Uri.t;
    id : string;
    images : Common.image list;
    name : string;
    owner : User.t;
    primary_color : string option; [@default None]
    public : bool option; [@default None]
    resource_type : Resource.t; [@key "type"]
    snapshot_id : string;
    tracks : playlist_track Page.t;
    uri : string;
  }
  [@@deriving yojson { strict = false }]
end
