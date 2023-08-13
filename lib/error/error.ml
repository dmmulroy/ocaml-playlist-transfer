open Syntax
open Let

type t = {
  cause : t option;
  domain : [ `Apple | `Spotify | `None ];
  source :
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Json
    | `None
    | `Source of string ];
  message : string;
  raw : [ `Json of Yojson.Safe.t | `None | `Raw of string ];
  timestamp : Ptime.t;
}
[@@deriving show]

let make ?cause ?(raw = `None) ~domain ~source message =
  { cause; domain; source; message; raw; timestamp = Ptime_clock.now () }

let of_http ?cause ~domain
    ((request, response) : Http.Request.t * Http.Response.t) =
  let message =
    Http.Code.reason_phrase_of_code @@ Http.Code.code_of_status response.status
  in
  let* json_res = Http.Body.to_yojson response.body in
  let* raw =
    match json_res with
    | Error _ ->
        Infix.Lwt.(Http.Body.to_string response.body >|= fun x -> `Raw x)
    | Ok json -> Lwt.return @@ `Json json
  in
  Lwt.return
  @@ make ?cause ~domain
       ~source:(`Http (response.status, request.uri))
       ~raw message

let to_string = show
