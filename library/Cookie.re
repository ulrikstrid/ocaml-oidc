/** example:
 *  __cfduid=d90aa986407a12a7a981f1cccf8cb663a1564556010;
 *  expires=Thu, 30-Jul-20 06:53:30 GMT;
 *  path=/;
 *  domain=.strid.dev;
 *  HttpOnly;
 *  Secure
 */

type expiration = [
  | /** Instructs the user agent to discard the cookie
  unconditionally when the user agent terminates. */
    `Session
  | /** The value of the Max-Age attribute is delta-seconds,
    the lifetime of the cookie in seconds, a decimal
    non-negative integer. */
    `Max_age(
      int64,
    )
];

type cookie = (string, string);

type t = {
  cookie,
  expiration,
  domain: option(string),
  path: option(string),
  secure: bool,
  http_only: bool,
};

let get_cookie = ((_, cookie_header)) => {
  let cookie_parts = CCString.split(~by="; ", cookie_header);
  let secure =
    CCList.find_opt(p => p == "Secure", cookie_parts) |> CCOpt.is_some;
  let http_only =
    CCList.find_opt(p => p == "HttpOnly", cookie_parts) |> CCOpt.is_some;

  let domain =
    CCList.find_map(
      p =>
        CCString.split(~by="=", p)
        |> (
          x =>
            switch (x) {
            | ["domain", domain] => Some(domain)
            | _ => None
            }
        ),
      cookie_parts,
    );

  let path =
    CCList.find_map(
      p =>
        CCString.split(~by="=", p)
        |> (
          x =>
            switch (x) {
            | ["path", path] => Some(path)
            | _ => None
            }
        ),
      cookie_parts,
    );

  let cookie =
    CCList.get_at_idx(0, cookie_parts)
    |> CCOpt.map(CCString.split(~by="="))
    |> CCOpt.flat_map(a =>
         switch (a) {
         | [key, value] => Some((key, value))
         | _ => None
         }
       )
    |> CCOpt.get_or(~default=("key", "value"));

  {cookie, expiration: `Session, domain, path, secure, http_only};
};

let get_set_cookie_headers: list(('a, 'a)) => list(('a, 'a)) =
  CCList.filter(header => {fst(header) == "Set-Cookie"});

let to_cookie_header: list(t) => (string, string) =
  cookies => {
    (
      "Cookie",
      CCList.map(c => {fst(c.cookie) ++ "=" ++ snd(c.cookie)}, cookies)
      |> CCString.concat("; "),
    );
  };
