type t = { resource_type : Resource.t; href : Http.Uri.t option; total : int }
[@@deriving yojson]
