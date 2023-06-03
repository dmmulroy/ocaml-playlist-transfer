module Access_token = struct
  type t = string

  let make x : t = x
end

type authorization_grant = {
  client_id : string;
  redirect_uri : string;
  state : string;
  scope : string;
  show_dialog : bool;
}

type client_credentials_grant = { client_id : string; client_secret : string }
type error = unit

type flow =
  [ `Authorization_code of authorization_grant
  | `Client_credentials of client_credentials_grant
  | `Implicit of authorization_grant ]

let base_uri = Uri.of_string "https://accounts.spotify.com/api/token"

let client_credentials_flow client_credentials :
    (Access_token.t, error) result Lwt.t =
  let body = Http.Body.of_form [ ("grant_type", [ "client_credentials" ]) ] in
  let headers =
    Http.Header.of_list
      [
        ( "Authorization",
          Base64.encode_string
            (client_credentials.client_id ^ ":"
           ^ client_credentials.client_secret) );
        ("Content-Type", "application/x-www-form-urlencoded");
      ]
  in
  match%lwt Http.Client.post ~headers ~body base_uri with
  | res, _
    when Http.Code.is_success @@ Http.Code.code_of_status
         @@ Http.Response.status res ->
      Lwt.return_ok @@ Access_token.make "TODO"
  | _ -> Lwt.return_error ()

let get_access_token = function
  | `Authorization_code grant -> Lwt.return_ok @@ Access_token.make grant.state
  | `Client_credentials grant -> client_credentials_flow grant
  | `Implicit grant -> Lwt.return_ok @@ Access_token.make grant.scope
