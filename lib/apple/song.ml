[@@@ocaml.warning "-32"]

type t = string
type error = [ `Song_not_found ]

let error_to_string = function `Song_not_found -> "Song not found"

module Get_song_by_id_input = struct
  type t = string
end

module Get_song_by_id_output = struct
  type nonrec t = t
end

module Get_song_by_id = Apple_request.Make_unauthenticated (struct
  type input = Get_song_by_id_input.t
  type output = Get_song_by_id_output.t
  type nonrec error = [ `Http_error of int * string | error ]

  let to_http id =
    ( `GET,
      Http.Header.empty,
      Http.Uri.of_string @@ "https://api.music.apple.com/v1/test/songs/" ^ id,
      Http.Body.empty )

  let of_http = function
    | res, _ when Http.Response.is_success res -> Lwt.return_ok "song name"
    | res, body ->
        let%lwt json = Http.Body.to_string body in
        let status_code = Http.Response.status res in
        Lwt.return_error
          (`Http_error (Http.Code.code_of_status status_code, json))
end)

let get_song_by_id = Get_song_by_id.request
