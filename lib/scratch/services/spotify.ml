open Cohttp
module C = Cohttp_lwt_unix

type access_token = { token : string; [@key "access_token"] expires_in : int }
[@@deriving yojson { strict = false }]

type t = { access_token : access_token }
type 'a spotify_result = ('a, [ `SpotifyApiError of string ]) result Lwt.t

let base_url = Uri.of_string "https://accounts.spotify.com/api"

let append_uri_path (uri : Uri.t) (path : string) =
  Uri.with_path uri (Uri.path uri ^ path)

let make_client_credentials ~(client_id : string) ~(client_secret : string) =
  Base64.encode (client_id ^ ":" ^ client_secret)

let make_headers client_credentials =
  Header.add_list (Header.init ())
    [
      ("Authorization", "Basic " ^ client_credentials);
      ("Content-Type", "application/x-www-form-urlencoded");
    ]

let fetch_access_token ~(client_id : string) ~(client_secret : string) :
    (access_token, [ `SpotifyApiError of string ]) result Lwt.t =
  let token_uri = append_uri_path base_url "/token" in
  let body =
    Cohttp_lwt.Body.of_form ~scheme:"application/x-www-form-urlencoded"
      [ ("grant_type", [ "client_credentials" ]) ]
  in
  let headers =
    Result.map make_headers @@ make_client_credentials ~client_id ~client_secret
  in
  match headers with
  | Ok headers -> (
      let%lwt _response, body = C.Client.post ~headers ~body token_uri in
      let%lwt json = Cohttp_lwt.Body.to_string body in
      match access_token_of_yojson @@ Yojson.Safe.from_string json with
      | Ok access_token -> Lwt.return @@ Ok access_token
      | Error err ->
          Lwt.return_error (`SpotifyApiError ("Error parsing json: " ^ err)))
  | Error (`Msg err) -> Lwt.return_error (`SpotifyApiError err)

let init ~(client_id : string) ~(client_secret : string) =
  let%lwt access_token = fetch_access_token ~client_id ~client_secret in
  match access_token with
  | Ok access_token -> Lwt.return @@ Ok { access_token }
  | Error err -> Lwt.return_error err

let to_string t = t.access_token.token
