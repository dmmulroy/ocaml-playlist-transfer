open Syntax

type t = { description : string; name : string; tracks : Track.t list option }

let add_track playlist track =
  let converted_track =
    match track with
    | `Apple track' -> Track.of_apple track'
    | `Spotify track' -> Track.of_spotify track'
  in
  let tracks =
    match playlist.tracks with
    | None -> Some [ converted_track ]
    | Some tracks -> Some (converted_track :: tracks)
  in
  { playlist with tracks }

let of_apple (playlist : Apple.Library_playlist.t) =
  let name = playlist.attributes.name in
  let description =
    Option.fold ~none:playlist.attributes.name
      ~some:(fun (description : Apple.Description.t) -> description.standard)
      playlist.attributes.description
  in
  let tracks =
    Infix.Option.(
      Apple.Library_playlist.tracks playlist >|= List.map Track.of_apple)
  in
  { description; name; tracks }

let of_spotify (playlist : Spotify.Playlist.t) =
  let name = playlist.name in
  let description = Option.value ~default:playlist.name playlist.description in
  let tracks =
    Option.some
    @@ List.map
         (fun (playlist_track : Spotify.Playlist.playlist_track) ->
           Track.of_spotify playlist_track.track)
         playlist.tracks.items
  in
  { description; name; tracks }
