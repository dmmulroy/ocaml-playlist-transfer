type external_urls = { spotify : string } [@@deriving yojson]

type image = {
  height : int option; (* nullable *)
  url : Http.Uri.t;
  width : int option (* nullable *);
}
[@@deriving yojson]

type resource_type =
  ([ `Playlist | `Track | `User ]
  [@of_yojson
    fun json ->
      match json with
      | `String "playlist" -> Ok `Playlist
      | `String "track" -> Ok `Track
      | `String "user" -> Ok `User
      | _ -> Error "Invalid resource type"]
  [@to_yojson
    fun resource_type ->
      `String
        (match resource_type with
        | `Playlist -> "playlist"
        | `Track -> "track"
        | `User -> "user")])

type resource_reference = {
  href : Http.Uri.t option;
  (* nullable *) total : int;
}
[@@deriving yojson { strict = false }]
