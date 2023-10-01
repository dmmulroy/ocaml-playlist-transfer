open Shared

type 'a t = {
  href : Http.Uri.t;
  items : 'a list;
  limit : int;
  next : Http.Uri.t option;
  offset : int;
  previous : Http.Uri.t option;
  total : int;
}
[@@deriving yojson { strict = false }]

module Test = struct
  let empty =
    {
      href = Http.Uri.of_string "";
      items = [];
      limit = 0;
      next = None;
      offset = 0;
      previous = None;
      total = 0;
    }
end

let empty =
  {
    href = Http.Uri.of_string "";
    items = [];
    limit = 0;
    next = None;
    offset = 0;
    previous = None;
    total = 0;
  }
