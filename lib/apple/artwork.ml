type t = {
  bg_color : string option; [@key "bgColor"] [@default None]
  height : int;
  width : int;
  text_color1 : string option; [@key "textColor1"] [@default None]
  text_color2 : string option; [@key "textColor2"] [@default None]
  text_color3 : string option; [@key "textColor3"] [@default None]
  text_color4 : string option; [@key "textColor4"] [@default None]
  url : string;
}
[@@deriving yojson]
