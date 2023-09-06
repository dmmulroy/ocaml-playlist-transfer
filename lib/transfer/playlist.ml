type t = { description : string; name : string; tracks : Track.t list option }

let of_apple (playlist : Apple.Library_playlist.t) =
  let description =
    Option.fold ~none:playlist.attributes.name
      ~some:(fun (description : Apple.Description.t) -> description.standard)
      playlist.attributes.description
  in
  { description; name = playlist.attributes.name; tracks = None }

let of_spotify (playlist : Spotify.Playlist.t) =
  let description = Option.value ~default:playlist.name playlist.description in
  { description; name = playlist.name; tracks = None }
