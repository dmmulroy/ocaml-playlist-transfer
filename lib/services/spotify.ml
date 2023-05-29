open Cohttp
module C = Cohttp_lwt_unix

type t = { access_token : string }
type error = SpotifyApiError of string

let base_url : Uri.t = Uri.of_string "https://accounts.spotify.com/api"

let fetch_access_token ~(client_id : string) ~(client_secret : string) :
    (string, error) result Lwt.t =
  let open Lwt.Infix in
  let token_uri = Uri.of_string (Uri.to_string base_url ^ "/token") in
  let body =
    Cohttp_lwt.Body.of_form ~scheme:"application/x-www-form-urlencoded"
      [ ("grant_type", [ "client_credentials" ]) ]
  in
  Base64.encode (client_id ^ ":" ^ client_secret)
  |> Result.map (fun authorization_value ->
         Header.add_list (Header.init ())
           [
             ("Authorization", "Basic " ^ authorization_value);
             ("Content-Type", "application/x-www-form-urlencoded");
           ])
  |> function
  | Ok headers ->
      C.Client.post ~headers ~body token_uri >>= fun (_, response) ->
      Cohttp_lwt.Body.to_string response >|= fun token -> Ok token
  | Error (`Msg err) -> Lwt.return (Error (SpotifyApiError err))

let init ~(client_id : string) ~(client_secret : string) : t Lwt.t =
  let open Lwt.Infix in
  fetch_access_token ~client_id ~client_secret >|= function
  | Ok access_token -> { access_token }
  | Error _ -> failwith "Failed to fetch access token"
