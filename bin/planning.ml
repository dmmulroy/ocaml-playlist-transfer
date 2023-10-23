type transfer_report = {
  id : string;
  name : string;
  url : Uri.t;
  source : [ `Spotify | `Apple ];
  target : [ `Spotify | `Apple ];
  transferred_track_count : int;
  skipped_track_ids : string list;
  timestamp : Ptime.t;
}

(*
  Ways to authenticate

  Spotify:
    - Supply client_id, client_secret, and scopes to perform oauth flow
    - Supply client_id, client_secret, and access_token/refresh_token 
    - Supply access_token (refresh will be disabled as refreshing requires 
      client_id & client_secret)


  Apple:
    - Supply private_key, apple key id, team id, and peforms developer_token creation,
      and music_user_token creation via music kit oauth flow
    - Supply private_key and developer_token to perform oauth flow via music kit
    - Supply private_key, developer_token, music_user_token
    - Supply developer_token and music_user_token (refresh will be disabled as 
      refreshing requires private_key)
    


  type spotify_strategy =
    | OAuth of {
        client_id : string;
        client_secret : string;
        scopes : string list;
      }
    | Access_token of string
    | Refreshable_access_token of {
        client_id : string;
        client_secret : string;
        access_token : string;
        refresh_token : string;
      }

  type music_kit = 
    Full of {
      private_key : string;
      key_id : string;
      team_id : string;
    }
    | Developer_token of {
        private_key : string;
        developer_token : string;
      }

  type apple_strategy = 
    | Music_kit of music_kit 
    | Tokens of {
        developer_token : string;
        music_user_token : string;
      }
    | Refreshable_tokens of {
        private_key : string;
        developer_token : string;
        music_user_token : string;
      }

 *)

(* let main () =
   let client = Tool.Client.make ()
   let+ spotify_client  = Tool.make_spotify_client ~client_id ~client_secret ~scopes in
   let+ apple_client  = Tool.make_apple_client ~private_key ~client_secret ~scopes in
   let client = Tool.Client.make ~spotify_client ~apple_client ()
   let+ report = Tool.transfer ~client ~source:Spotify ~target:Apple playlist_id *)
