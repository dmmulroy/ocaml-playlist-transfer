[@@@ocaml.warning "-69-32"]

type t = { client_id : string; client_secret : string; redirect_uri : Uri.t }
[@@deriving show]

let default_redirect_uri = Uri.of_string "http://localhost:3939/spotify"

let make ~client_id ~client_secret ?(redirect_uri = default_redirect_uri) () : t
    =
  { client_id; client_secret; redirect_uri }

let set_client_id t client_id = { t with client_id }
let set_client_secret t client_secret = { t with client_secret }
let set_redirect_uri t redirect_uri = { t with redirect_uri }
