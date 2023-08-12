open Syntax
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
        Error.of_http ~domain:`Apple (request, response) >>= Lwt.return_error
end)

let get_song_by_id = Get_song_by_id.request
