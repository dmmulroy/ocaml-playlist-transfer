include Rest_client.Make (struct
  type api_client = Client.t

  module Error = Spotify_error

  let headers_of_api_client client =
    Http.Header.of_list
      [
        ("Authorization", Fmt.str "Bearer %s" @@ Client.get_bearer_token client);
      ]
end)
