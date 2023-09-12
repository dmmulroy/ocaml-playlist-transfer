type meta = { total : int } [@@deriving yojson]

type 'a t = {
  data : 'a list;
  href : string option; [@default None]
  meta : meta option; [@default None]
  next : string option; [@default None]
}
[@@deriving yojson]

(* TODO: Add fns to work with the next type for paging *)
