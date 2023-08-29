type meta = { total : int } [@@deriving yojson]

type 'a t = {
  data : 'a list;
  meta : meta;
  next : string option; [@default None]
}
[@@deriving yojson]
