include Rest_client.Make (struct
  type api_client = Client.t

  module Error = Spotify_error

  let headers_of_api_client client =
    [ ("Authorization", Client.get_bearer_token client) ]
end)
