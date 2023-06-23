type t = { resource_type : Resource.t; id : string }

let to_string t =
  Printf.sprintf "spotify:%s:%s" (Resource.to_string t.resource_type) t.id

let of_string str =
  match String.split_on_char ':' str with
  | [ _; resource_type; id ] ->
      { resource_type = Resource.of_string resource_type; id }
  | _ -> failwith @@ "Invalid Spotify URI: " ^ str

let to_yojson t = `String (to_string t)

let of_yojson = function
  | `String str -> Ok (of_string str)
  | _ -> Error "Invalid Spotify URI"
