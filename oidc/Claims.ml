open Utils

type key = string

type claim =
  | Essential of key
  | NonEssential of key

type ('a, 'b) t = {
  id_token : claim list;
  userinfo : claim list;
}

let get_essential value =
  Yojson.Safe.Util.(to_option (fun v -> member "essential" v |> to_bool) value)

let of_yojson json =
  Yojson.Safe.
    {
      id_token =
        json
        |> Util.member "id_token"
        |> Util.to_option Util.to_assoc
        |> ROpt.map_or ~default:[]
             (List.map (fun (key, value) ->
                  match get_essential value with
                  | Some true -> Essential key
                  | _ -> NonEssential key));
      userinfo =
        json
        |> Util.member "userinfo"
        |> Util.to_option Util.to_assoc
        |> ROpt.map_or ~default:[]
             (List.map (fun (key, value) ->
                  match get_essential value with
                  | Some true -> Essential key
                  | _ -> NonEssential key));
    }

let from_string str = Yojson.Safe.from_string str |> of_yojson
