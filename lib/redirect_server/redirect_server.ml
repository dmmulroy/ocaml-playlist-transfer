open Shared
open Syntax
open Let

type t = {
  mailbox : string Lwt_mvar.t;
  redirect_uri : Http.Uri.t;
  state : string;
  stop_server_promise : unit Lwt.t;
}

let make ~redirect_uri ~state =
  let stop_server_promise, _ = Lwt.task () in
  {
    mailbox = Lwt_mvar.create_empty ();
    redirect_uri;
    state;
    stop_server_promise;
  }

let handler ~state ~mailbox _conn req _body =
  let request_uri = Http.Cohttp_request.uri req in
  let path = Http.Uri.path request_uri in
  match path with
  | "/spotify" -> (
      let code =
        match
          ( Http.Uri.get_query_param request_uri "code",
            Http.Uri.get_query_param request_uri "state" )
        with
        | Some code, Some received_state when received_state = state -> Ok code
        | Some _, Some _ -> Error (`Msg "Invalid state")
        | Some _, None -> Error (`Msg "No state received")
        | None, _ -> Error (`Msg "No code received")
      in
      match code with
      | Ok code when Lwt_mvar.is_empty mailbox ->
          let* () = Lwt_mvar.put mailbox code in
          Http.Server.respond_string ~status:`OK
            ~body:"Authentication Successful" ()
      | Ok _ ->
          Http.Server.respond_string ~status:`OK
            ~body:"Authentication Successful" ()
      | Error (`Msg msg) ->
          Http.Server.respond_error ~status:`Bad_request ~body:msg ())
  | _ -> Http.Server.respond_string ~status:`Not_found ~body:"Not found" ()

let run t () =
  let callback = handler ~state:t.state ~mailbox:t.mailbox in
  let server = Http.Server.make ~callback () in
  let port = Http.Uri.port t.redirect_uri in
  let run_sever =
    match port with
    | Some port ->
        Ok
          (Http.Server.create
             ~mode:(`TCP (`Port port))
             ~stop:t.stop_server_promise server)
    | None -> Error (`Msg "Invalid port in redirect_uri")
  in
  match run_sever with
  | Ok run ->
      let _ = run in
      Lwt.return_ok ()
  | Error (`Msg msg) -> Lwt.return_error (`Msg msg)

let get_code t =
  let* code = Lwt_mvar.take t.mailbox in
  let () = Lwt.cancel t.stop_server_promise in
  Lwt.return code
