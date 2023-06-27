type copyright = [ `C of string | `P of string ] [@@deriving yojson]

let copyright_of_yojson = function
  | `Assoc [ ("text", `String s); ("type", `String "C") ] -> Ok (`C s)
  | `Assoc [ ("text", `String s); ("type", `String "P") ] -> Ok (`P s)
  | _ -> Error "Invalid copyright"

let copyright_to_yojson = function
  | `C s -> `Assoc [ ("text", `String s); ("type", `String "C") ]
  | `P s -> `Assoc [ ("text", `String s); ("type", `String "P") ]

type external_ids = {
  ean : string option; [@default None]
  isrc : string option; [@default None]
  spotify : string option; [@default None]
  upc : string option; [@default None]
}
[@@deriving yojson]

type external_urls = { spotify : string } [@@deriving yojson]

type image = { height : int option; url : Http.Uri.t; width : int option }
[@@deriving yojson]

type linked_track = {
  external_urls : external_urls;
  href : Http.Uri.t;
  id : string;
  resource_type : Resource.t; [@key "type"]
  uri : string;
}
[@@deriving yojson]

type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]
type release_date_precision = [ `Year | `Month | `Day ] [@@deriving yojson]

let release_date_precision_of_yojson = function
  | `String "year" -> Ok `Year
  | `String "month" -> Ok `Month
  | `String "day" -> Ok `Day
  | _ -> Error "Invalid album release_date_precision"

let release_date_precision_to_yojson = function
  | `Year -> `String "year"
  | `Month -> `String "month"
  | `Day -> `String "day"

type restriction_reason = [ `Market | `Product | `Explicit ]

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

type restriction = { reason : restriction_reason } [@@deriving yojson]

type _ resource_type =
  | Artist : [ `Artist ] resource_type
  | Album : [ `Album ] resource_type
  | Episode : [ `Episode ] resource_type
  | Playlist : [ `Playlist ] resource_type
  | Show : [ `Show ] resource_type
  | Track : [ `Track ] resource_type
  | User : [ `User ] resource_type

let resource_type_of_yojson = function
  | `String "artist" -> Ok `Artist
  | `String "album" -> Ok `Album
  | `String "episode" -> Ok `Episode
  | `String "playlist" -> Ok `Playlist
  | `String "show" -> Ok `Show
  | `String "track" -> Ok `Track
  | `String "user" -> Ok `User
  | _ -> Error "Invalid resource type"

let resource_type_to_yojson : type a. a resource_type -> Yojson.Safe.t =
  function
  | Artist -> `String "artist"
  | Album -> `String "album"
  | Episode -> `String "episode"
  | Playlist -> `String "playlist"
  | Show -> `String "show"
  | Track -> `String "track"
  | User -> `String "user"

let make_resource_type_of_yojson :
    type a. a resource_type -> Yojson.Safe.t -> (a, string) result = function
  | Artist -> (
      function `String "artist" -> Ok `Artist | _ -> Error "Expected 'artist'")
  | Album -> (
      function `String "album" -> Ok `Album | _ -> Error "Expected 'album'")
  | Episode -> (
      function
      | `String "episode" -> Ok `Episode | _ -> Error "Expected 'episode'")
  | Playlist -> (
      function
      | `String "playlist" -> Ok `Playlist | _ -> Error "Expected 'playlist'")
  | Show -> (
      function `String "show" -> Ok `Show | _ -> Error "Expected 'show'")
  | Track -> (
      function `String "track" -> Ok `Track | _ -> Error "Expected 'track'")
  | User -> (
      function `String "user" -> Ok `User | _ -> Error "Expected 'user'")

let make_resource_type_to_yojson : type a. a resource_type -> a -> Yojson.Safe.t
    = function
  | Artist -> ( function `Artist -> `String "artist")
  | Album -> ( function `Album -> `String "album")
  | Episode -> ( function `Episode -> `String "episode")
  | Playlist -> ( function `Playlist -> `String "playlist")
  | Show -> ( function `Show -> `String "show")
  | Track -> ( function `Track -> `String "track")
  | User -> ( function `User -> `String "user")
