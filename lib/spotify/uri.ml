type t = { resource_type : Resource.t; id : string } [@@deriving yojson]

let to_string uri =
  Printf.sprintf "spotify:%s:%s" (Resource.to_string uri.resource_type) uri.id

let of_string str =
  match String.split_on_char ':' str with
  | [ _; resource_type; id ] ->
      { resource_type = Resource.of_string resource_type; id }
  | _ -> failwith @@ "Invalid Spotify URI: " ^ str

let to_yojson uri = `String (to_string uri)

let of_yojson = function
  | `String str -> Ok (of_string str)
  | _ -> Error "Invalid Spotify URI"
