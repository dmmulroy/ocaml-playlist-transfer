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
    ( `GET,
      Http.Header.empty,
      Http.Uri.of_string @@ "https://api.music.apple.com/v1/test/songs/" ^ id,
      Http.Body.empty )

  let of_http = function
    | res, _ when Http.Response.is_success res -> Lwt.return_ok "song name"
    | res -> Error.of_http res >>= Lwt.return_error
end)

let get_song_by_id = Get_song_by_id.request
