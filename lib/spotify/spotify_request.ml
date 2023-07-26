open Async
module Api_request = Http.Api_request

module Make (M : Api_request.S) = struct
  let request ~(client : Client.t) (input : M.input) :
      (M.output, M.error) result Promise.t =
    let method', headers', endpoint, body = M.to_http input in
    let headers =
      Http.Header.add_list_unless_exists headers'
        [
          ("Authorization", Client.get_bearer_token client);
          ("Content-Type", "application/json");
        ]
    in
    let%lwt response = Api_request.execute ~headers ~body ~endpoint ~method' in
    M.of_http response
end

module Make_unauthenticated (M : Api_request.S) = struct
  let request (input : M.input) : (M.output, M.error) result Promise.t =
    let method', headers', endpoint, body = M.to_http input in
    let headers =
      Http.Header.add_unless_exists headers' "Content-Type" "application/json"
    in
    let%lwt response = Api_request.execute ~headers ~body ~endpoint ~method' in
    M.of_http response
end
