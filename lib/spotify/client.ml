type t = {
  access_token : Access_token.t;
  client_id : string;
  client_secret : string;
}

let get_access_token { access_token; _ } = access_token
let get_bearer_token { access_token; _ } = Access_token.get_token access_token

let get_client_credentials { client_id; client_secret; _ } =
  (client_id, client_secret)

let make ~access_token ~client_id ~client_secret =
  { access_token; client_id; client_secret }

let set_access_token t access_token = { t with access_token }
