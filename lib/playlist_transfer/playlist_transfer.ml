type apple = Apple
type spotify = Spotify

type _ playlist =
  | ApplePlaylist : apple playlist
  | SpotifyPlaylist : spotify playlist

type _ converted_playlist =
  | AppleOfSpotify : apple playlist -> spotify converted_playlist
  | SpotifyOfApple : spotify playlist -> apple converted_playlist

let convert : type a. a playlist -> a converted_playlist = function
  | ApplePlaylist -> SpotifyOfApple SpotifyPlaylist
  | SpotifyPlaylist -> AppleOfSpotify ApplePlaylist
