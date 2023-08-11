open Syntax
open Let

(* TODO: Try out using the Format module + pretty print_string
 * https://chat.openai.com/share/53f93496-e7f3-44b3-97dd-1f1a988211de
 *)
type t = {
  cause : t option;
  code : Http.Code.status_code option;
  source : [ `Auth | `Http | `None | `Resource of Resource.t ];
  field : string option;
  message : string;
  raw : [ `Json of Yojson.Safe.t | `None | `Raw of string ];
  timestamp : Ptime.t;
}

let make ?cause ?code ?field ?(raw = `None) ~source ~message () =
  { cause; code; source; field; message; raw; timestamp = Ptime_clock.now () }

let of_http ?cause (response, body) =
  let code = Http.Response.status response in
  let message =
    Http.Code.reason_phrase_of_code @@ Http.Code.code_of_status code
  in
  let* json_res = Http.Body.to_yojson body in
  let* raw =
    match json_res with
    | Error _ -> Infix.Lwt.(Http.Body.to_string body >|= fun x -> `Raw x)
    | Ok json -> Lwt.return @@ `Json json
  in
  Lwt.return @@ make ?cause ~code ~source:`Http ~message ~raw ()

(* TODO: Make this better, figure out how to recursively print the cause *)
let to_string err =
  match err.source with
  | `Auth -> err.message
  | `Http -> err.message
  | `None -> err.message
  | `Resource _ -> err.message
