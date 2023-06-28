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

type restriction_reason = [ `Market | `Product | `Explicit ] [@@deriving yojson]

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
