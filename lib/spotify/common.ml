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
  upc : string option; [@default None]
}
[@@deriving yojson]

type external_urls = { spotify : string } [@@deriving yojson]

type image = { height : int option; url : Http.Uri.t; width : int option }
[@@deriving yojson]

type resource_type =
  [ `Album | `Artist | `Epidode | `Playlist | `Show | `Track | `User ]

let resource_type_of_yojson = function
  | `String "album" -> Ok `Album
  | `String "artist" -> Ok `Artist
  | `String "episode" -> Ok `Epidode
  | `String "playlist" -> Ok `Playlist
  | `String "show" -> Ok `Show
  | `String "track" -> Ok `Track
  | `String "user" -> Ok `User
  | _ -> Error "Invalid resource type"

let resource_type_to_yojson = function
  | `Album -> `String "album"
  | `Artist -> `String "artist"
  | `Epidode -> `String "episode"
  | `Playlist -> `String "playlist"
  | `Show -> `String "show"
  | `Track -> `String "track"
  | `User -> `String "user"

type reference = { href : Http.Uri.t option; total : int } [@@deriving yojson]
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

type restriction = { reason : restriction_reason } [@@deriving yojson]
