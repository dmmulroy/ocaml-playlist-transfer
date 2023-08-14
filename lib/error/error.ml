type t = {
  cause : t option;
  domain : [ `Apple | `Spotify ];
  source :
    [ `Auth
    | `Http of Http.Code.status_code * Http.Uri.t
    | `Serialization of [ `Json of Yojson.Safe.t | `Raw of string ]
    | `Source of string ];
  message : string;
  timestamp : Ptime.t;
}
[@@deriving show]

let make ?cause ~domain ~source message =
  { cause; domain; source; message; timestamp = Ptime_clock.now () }

let to_string = show
