open Shared

include Rest_client.Make (struct
  type api_client = Client.t

  module Error = Apple_error

  let headers_of_api_client client =
    Http.Header.of_list
      [
        ("Authorization", Fmt.str "Bearer %s" @@ Client.get_bearer_token client);
        ("Music-User-Token", Client.music_user_token client);
      ]
end)
