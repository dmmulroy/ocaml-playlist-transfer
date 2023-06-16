type t = { resource_type : Resource_type.t; id : string }

let of_string str =
  match String.split_on_char ':' str with
  | [ _; resource_type; id ] ->
      { resource_type = Resource_type.of_string resource_type; id }
  | _ -> failwith @@ "Invalid Spotify URI" ^ str

let to_string t =
  Printf.sprintf "spotify:%s:%s" (Resource_type.to_string t.resource_type) t.id

let of_yojson = function
  | `String str -> Ok (of_string str)
  | _ -> Error "Invalid Spotify URI"

let to_yojson t = `String (to_string t)
