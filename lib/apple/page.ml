type meta = { total : int } [@@deriving yojson]
type next = string option [@@deriving yojson]

type 'a t = { data : 'a list; meta : meta; next : next [@default None] }
[@@deriving yojson]

(* TODO: Add fns to work with the next type for paging *)
