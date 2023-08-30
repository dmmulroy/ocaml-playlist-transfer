type meta = { total : int } [@@deriving yojson]

type 'a t = {
  data : 'a list;
  meta : meta;
  next : string option; [@default None]
}
[@@deriving yojson]

module Relationship = struct
  type 'a t = {
    href : string option; [@default None]
    data : 'a list;
    next : string option; [@default None]
  }
  [@@deriving yojson]
end
