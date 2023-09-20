[@@@ocaml.warning "-69"]

type 'a t = {
  href : Http.Uri.t;
  items : 'a list;
  limit : int;
  next : Http.Uri.t option;
  offset : int;
  previous : Http.Uri.t option;
  total : int;
}
[@@deriving yojson]

type page_info = { href : Http.Uri.t; limit : int; offset : int; total : int }
type page = { next : page_info option; previous : page_info option }
