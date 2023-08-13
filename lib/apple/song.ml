open Syntax
open Let
open Infix.Lwt

type t = string

module Get_song_by_id_input = struct
  type t = string
end

module Get_song_by_id_output = struct
  type nonrec t = t
end

module Get_song_by_id = Apple_request.Make_unauthenticated (struct
  type input = Get_song_by_id_input.t
  type output = Get_song_by_id_output.t

  let to_http id =
    Http.Request.make ~meth:`GET ~headers:Http.Header.empty
      ~body:Http.Body.empty
      ~uri:
        (Http.Uri.of_string @@ "https://api.music.apple.com/v1/test/songs/" ^ id)
      ()

  let of_http = function
    | _, response when Http.Response.is_success response ->
        Lwt.return_ok "song name"
    | request, response ->
        let message =
          Http.Code.reason_phrase_of_code
          @@ Http.Code.code_of_status response.status
        in
        let* json_res = Http.Body.to_yojson response.body in
        let* raw =
          match json_res with
          | Error _ ->
              Infix.Lwt.(
                Http.Body.to_string response.body >|= fun x -> `String x)
          | Ok json -> Lwt.return @@ `Json json
        in
        Lwt.return_error
        @@ Error.make ~domain:`Apple
             ~source:(`Http (response.status, Http.Request.(request.uri)))
             ~raw message
end)

let get_song_by_id = Get_song_by_id.request
