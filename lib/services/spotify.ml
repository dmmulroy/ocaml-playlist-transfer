module C = Cohttp_lwt_unix
open Cohttp

type t = { access_token : string }

(* type config = { client_id : string; client_secret : string } *)
type error = SpotifyApiError of string

let base_url : Uri.t = Uri.of_string "https://api.spotify.com/v1"

let fetch_access_token ~(client_id : string) ~(client_secret : string) :
    (string, error) result Lwt.t =
  let open Lwt.Infix in
  let token_uri = Uri.of_string (Uri.to_string base_url ^ "/token") in
  Base64.encode (client_id ^ ":" ^ client_secret)
  |> Result.map (fun authorization_value ->
         Header.add (Header.init ()) "Authorization" authorization_value)
  |> function
  | Ok headers ->
      C.Client.get ~headers token_uri >>= fun (_, response) ->
      Cohttp_lwt.Body.to_string response >|= fun token -> Ok token
  | Error (`Msg err) -> Lwt.return (Error (SpotifyApiError err))

let init ~(client_id : string) ~(client_secret : string) : t Lwt.t =
  let open Lwt.Infix in
  fetch_access_token ~client_id ~client_secret >|= function
  | Ok access_token -> { access_token }
  | Error _ -> failwith "Failed to fetch access token"
