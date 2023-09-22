type cursor
type t = { next : cursor option; previous : cursor option } [@@deriving yojson]

val make : 'a Page.t -> t
