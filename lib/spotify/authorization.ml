[@@@warning "-69"]

module Http = Cohttp_lwt_unix

let base_uri = Uri.of_string "https://accounts.spotify.com/authorize"

type t = { config : Config.t }
type authorization_code = (string, [ `Msg of string ]) result Lwt.t

let make (config : Config.t) = { config }

let authorization_code_grant (t : t) : authorization_code =
  let mailbox = Lwt_mvar.create_empty () in
  let stop_server_promise, _ = Lwt.task () in
  let state = Int.to_string @@ Random.bits () in
  let callback _conn req _body =
    let path = Uri.path @@ Http.Request.uri req in
    match path with
    | "/spotify" -> (
        let uri = Http.Request.uri req in
        let code =
          match
            (Uri.get_query_param uri "code", Uri.get_query_param uri "state")
          with
          | Some code, Some received_state when received_state = state ->
              Ok code
          | Some _, Some _ -> Error (`Msg "Invalid state")
          | Some _, None -> Error (`Msg "No state received")
          | None, _ -> Error (`Msg "No code received")
        in
        match code with
        | Ok code ->
            let%lwt () = Lwt_mvar.put mailbox code in
            Http.Server.respond_string ~status:`OK
              ~body:"Authentication Successful" ()
        | Error (`Msg msg) ->
            Http.Server.respond_error ~status:`Bad_request ~body:msg ())
    | _ -> Http.Server.respond_string ~status:`Not_found ~body:"Not found" ()
  in
  let server = Http.Server.make ~callback () in
  let port = Uri.port @@ Config.get_redirect_uri t.config in
  let run_sever =
    match port with
    | Some port ->
        Ok
          (Http.Server.create
             ~mode:(`TCP (`Port port))
             ~stop:stop_server_promise server)
    | None -> Error (`Msg "Invalid port in redirect_uri")
  in
  match run_sever with
  | Ok run ->
      let _ = run in
      let uri =
        Uri.with_query' base_uri
          [
            ("client_id", Config.get_client_id t.config);
            ("response_type", "code");
            ("redirect_uri", Uri.to_string @@ Config.get_redirect_uri t.config);
            ("scope", "playlist-read-private");
            ("state", state);
            ("show_dialog", "true");
          ]
      in
      let cmd = Filename.quote_command "open" [ Uri.to_string uri ] in
      let _ = Unix.system cmd in
      (* open the web browser to authenticate *)
      let%lwt code = Lwt_mvar.take mailbox in
      (* wait for the server to receive the code *)
      let () = Lwt.cancel stop_server_promise in
      (* stop the server *)
      Lwt.return_ok code
  | Error (`Msg msg) -> Lwt.return (Error (`Msg msg))
