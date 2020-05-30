open Tyxml;

let auth_route = Routes.(s("auth") / str /? nil);

let createElement = (~providers, ()) => {
  let buttons =
    List.map(
      ((name, buttonContent)) => {
        let href = Routes.sprintf(auth_route, name);
        <Button.Link href> {Html.txt(buttonContent)} </Button.Link>;
      },
      providers,
    );

  [
    <p className="text-md mb-1 pb-2 border-b-2 border-gray-500 text-center">
      "Login alternatives"
    </p>,
    ...buttons,
  ];
};
