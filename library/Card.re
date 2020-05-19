open Tyxml;

let createElement = (~title, ~children, ()) =>
  <div className="max-w-sm rounded overflow-hidden shadow-lg bg-white">
    <div className="px-6 py-4">
      <div className="font-bold text-xl mb-2"> {Html.txt(title)} </div>
    </div>
    <div className="px-6 py-4"> ...children </div>
  </div>;
