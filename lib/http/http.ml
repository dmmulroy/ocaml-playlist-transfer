include Cohttp
include Cohttp_lwt
include Cohttp_lwt_unix

let uri_to_yojson uri = `String (Uri.to_string uri)

let uri_of_yojson = function
  | `String s -> Ok (Uri.of_string s)
  | _ -> Error "Error parsing Uri.t with yojson"

let uri_option_to_yojson = function
  | None -> `Null
  | Some uri -> uri_to_yojson uri

let uri_option_of_yojson = function
  | `Null -> Ok None
  | json -> (
      match uri_of_yojson json with
      | Ok uri -> Ok (Some uri)
      | Error _ -> Error "Error parsing Uri.t option with yojson")
