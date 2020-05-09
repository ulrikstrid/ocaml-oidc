type key = string;

type claim =
  | Essential(key)
  | NonEssential(key);

type t('a, 'b) = {
  id_token: list(claim),
  userinfo: list(claim),
};

let get_essential = value => {
  Yojson.Basic.Util.(
    to_option(v => member("essential", v) |> to_bool, value)
  );
};

let from_json = json => {
  Yojson.Basic.{
    id_token:
      json
      |> Util.member("id_token")
      |> Util.to_option(Util.to_assoc)
      |> CCOpt.map_or(
           ~default=[],
           CCList.map(((key, value)) =>
             switch (get_essential(value)) {
             | Some(true) => Essential(key)
             | _ => NonEssential(key)
             }
           ),
         ),
    userinfo:
      json
      |> Util.member("userinfo")
      |> Util.to_option(Util.to_assoc)
      |> CCOpt.map_or(
           ~default=[],
           CCList.map(((key, value)) =>
             switch (get_essential(value)) {
             | Some(true) => Essential(key)
             | _ => NonEssential(key)
             }
           ),
         ),
  };
};

let from_string = str => Yojson.Basic.from_string(str) |> from_json;
