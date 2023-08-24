include Rest_client.Make (struct
  type client = Client.t

  module Error = Spotify_error

  let request_headers_of_client client =
    [ ("Authorization", Client.get_bearer_token client) ]
end)
