type t = {
  added_at : string;
  added_by : User.t;
  is_local : bool; (* track : Track.t; *)
}
[@@deriving yojson]
