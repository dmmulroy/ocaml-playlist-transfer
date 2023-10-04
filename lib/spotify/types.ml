open Shared

module Copyright = struct
  type t = [ `C of string | `P of string ] [@@deriving yojson]

  let of_yojson = function
    | `Assoc [ ("text", `String s); ("type", `String "C") ] -> Ok (`C s)
    | `Assoc [ ("text", `String s); ("type", `String "P") ] -> Ok (`P s)
    | _ -> Error "Invalid copyright"

  let to_yojson = function
    | `C s -> `Assoc [ ("text", `String s); ("type", `String "C") ]
    | `P s -> `Assoc [ ("text", `String s); ("type", `String "P") ]
end

module External = struct
  type ids = {
    ean : string option; [@default None]
    isrc : string option; [@default None]
    spotify : string option; [@default None]
    upc : string option; [@default None]
  }
  [@@deriving yojson]

  type urls = { spotify : string } [@@deriving yojson]
end

module Image = struct
  type t = { height : int option; url : Http.Uri.t; width : int option }
  [@@deriving yojson]
end

module Reference = struct
  type t = { href : Http.Uri.t option; total : int } [@@deriving yojson]
end

module Release_date_precision = struct
  type t = [ `Year | `Month | `Day ] [@@deriving yojson]

  let of_yojson = function
    | `String "year" -> Ok `Year
    | `String "month" -> Ok `Month
    | `String "day" -> Ok `Day
    | _ -> Error "Invalid album release_date_precision"

  let to_yojson = function
    | `Year -> `String "year"
    | `Month -> `String "month"
    | `Day -> `String "day"
end

module Restriction = struct
  type restriction_reason = [ `Market | `Product | `Explicit ]
  [@@deriving yojson]

  let restriction_reason_of_yojson = function
    | `String "market" -> Ok `Market
    | `String "product" -> Ok `Product
    | `String "explicit" -> Ok `Explicit
    | _ -> Error "Invalid album restrictions_reason"

  let restriction_reason_to_yojson = function
    | `Market -> `String "market"
    | `Product -> `String "product"
    | `Explicit -> `String "explicit"
    | #restriction_reason -> .

  type t = { reason : restriction_reason } [@@deriving yojson]
end

module Linked_track = struct
  type t = {
    external_urls : External.urls;
    href : Http.Uri.t;
    id : string;
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson]
end

module Artist = struct
  type t = {
    external_urls : External.urls;
    followers : Resource.reference;
    genres : string list;
    href : Http.Uri.t;
    id : string;
    images : Image.t list;
    name : string;
    popularity : int;
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_artist = struct
  type t = {
    external_urls : External.urls;
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
    external_urls : External.urls;
    href : Http.Uri.t;
    id : string;
    is_local : bool;
    is_playable : bool option;
    linked_from : Linked_track.t option;
    name : string;
    preview_url : string option;
    resource_type : Resource.t; [@key "type"]
    restrictions : Restriction.t list option;
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
    copyrights : Copyright.t list;
    external_urls : External.urls;
    genres : string list;
    href : Http.Uri.t;
    id : string;
    images : Image.t list;
    label : string;
    name : string;
    popularity : int;
    release_date : string;
    release_date_precision : Release_date_precision.t;
    resource_type : Resource.t; [@key "type"]
    restrictions : Restriction.t list option; [@default None]
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
    external_urls : External.urls;
    href : Http.Uri.t;
    html_description : string option; [@default None]
    id : string;
    images : Image.t list option; [@default None]
    is_externally_hosted : bool option; [@default None]
    is_playable : bool;
    languages : string list option; [@default None]
    name : string;
    release_date : string option; [@default None]
    release_date_precision : string option; [@default None]
    resource_type : Resource.t; [@key "type"]
    restrictions : Restriction.t option; [@default None]
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
    external_urls : External.urls;
    followers : Resource.reference option; [@default None]
    href : Http.Uri.t;
    id : string;
    image : Image.t list option; [@default None]
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
    external_urls : External.urls;
    href : Http.Uri.t;
    id : string;
    images : Image.t list;
    is_playable : bool option; [@default None]
    name : string;
    release_date : string option; [@default None]
    release_date_precision : Release_date_precision.t option; [@default None]
    restrictions : Restriction.t option; [@default None]
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
    external_urls : External.urls;
    href : Http.Uri.t;
    html_description : string;
    id : string;
    images : Image.t list;
    is_externally_hosted : bool;
    is_playable : bool;
    languages : string list;
    name : string;
    release_date : string;
    release_date_precision : string;
    resource_type : Resource.t; [@key "type"]
    restrictions : Restriction.t option; [@default None]
    resume_point : Episode.resume_point;
    uri : string;
  }
  [@@deriving yojson]
end

module Simple_show = struct
  type t = {
    available_markets : string list;
    copyrights : Copyright.t list;
    description : string;
    explicit : bool;
    external_urls : External.urls;
    href : Http.Uri.t;
    html_description : string;
    id : string;
    images : Image.t list;
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
    external_urls : External.urls;
    followers : Resource.reference option; [@default None]
    href : Http.Uri.t;
    id : string;
    image : Image.t list option; [@default None]
    resource_type : Resource.t; [@key "type"]
    uri : string;
  }
  [@@deriving yojson { strict = false }]
end

module Simple_playlist = struct
  type t = {
    collaborative : bool;
    description : string option;
    external_urls : External.urls;
    href : Http.Uri.t;
    id : string;
    images : Image.t list;
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
    copyrights : Copyright.t list;
    description : string;
    episodes : Simple_episode.t list;
    explicit : bool;
    external_urls : External.urls;
    href : Http.Uri.t;
    html_description : string;
    id : string;
    images : Image.t list;
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
    external_ids : External.ids;
    external_urls : External.urls;
    href : Http.Uri.t;
    id : string;
    is_local : bool;
    is_playable : bool option; [@default None]
    (* linked_from : Linked_track.t option; [@default None] *)
    name : string;
    popularity : int;
    preview_url : string option; [@default None]
    resource_type : Resource.t; [@key "type"]
    (* restrictions : Restriction.t list option; [@default None] *)
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
    external_urls : External.urls;
    followers : Resource.reference;
    href : Http.Uri.t;
    id : string;
    images : Image.t list;
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
