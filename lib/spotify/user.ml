type followers = { href : Http.Uri.t option; (* nullable *) total : int }
[@@deriving yojson]

type t = {
  external_urls : Common.external_urls;
  followers : followers option; (* nullable *) [@default None]
  href : string;
  id : string;
  spotify_type : [ `User ];
      [@key "type"]
      [@of_yojson
        fun json ->
          match json with
          | `String "user" -> Ok `User
          | _ -> failwith "Error parsing spotify type"]
  uri : string;
  display_name : string option; (* nullable *)
}
[@@deriving yojson]
