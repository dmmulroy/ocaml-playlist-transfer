include Rest_client.Make (struct
  type client = Client.t

  module Error_handler = Error.Apple

  let request_headers_of_client client =
    [
      ("Authorization", Client.get_bearer_token client);
      ("Music-User-Token", Client.music_user_token client);
    ]
end)
