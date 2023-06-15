type t = { resource_type : Resource_type.t; id : string }

let of_string str =
  match String.split_on_char ':' str with
  | [ _; resource_type; id ] ->
      Ok { resource_type = Resource_type.of_string resource_type; id }
  | _ -> Error (`Msg "Invalid resource string")

let to_string t =
  Printf.sprintf "spotify:%s:%s" (Resource_type.to_string t.resource_type) t.id
