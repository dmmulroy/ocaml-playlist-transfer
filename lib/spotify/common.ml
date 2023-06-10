type external_urls = { spotify : string } [@@deriving yojson]

type image = {
  height : int option; (* nullable *)
  url : Http.Uri.t;
  width : int option (* nullable *);
}
[@@deriving yojson]
