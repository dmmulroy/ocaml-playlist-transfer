type playlist =
  [ `Apple of Apple.Library_playlist.t | `Spotify of Spotify.Playlist.t ]

type _ converted_playlist =
  | Apple : Apple.Library_playlist.t -> Spotify.Playlist.t converted_playlist
  | Spotify : Spotify.Playlist.t -> Apple.Library_playlist.t converted_playlist
