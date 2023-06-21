type copyright = [ `C of string | `P of string ] [@@deriving yojson]

let copyright_of_yojson = function
  | `Assoc [ ("text", `String s); ("type", `String "C") ] -> Ok (`C s)
  | `Assoc [ ("text", `String s); ("type", `String "P") ] -> Ok (`P s)
  | _ -> Error "Invalid copyright"

let copyright_to_yojson = function
  | `C s -> `Assoc [ ("text", `String s); ("type", `String "C") ]
  | `P s -> `Assoc [ ("text", `String s); ("type", `String "P") ]

type external_id = { ean : string; isrc : string; upc : string }
[@@deriving yojson]

type external_urls = { spotify : string } [@@deriving yojson]

type image = { height : int option; url : Http.Uri.t; width : int option }
[@@deriving yojson]
