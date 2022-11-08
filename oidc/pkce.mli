(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

module Verifier : sig
  type t

  val make : unit -> t
  (** https://www.rfc-editor.org/rfc/rfc7636#section-4.1 *)

  val of_string : string -> t
end

module Challenge : sig
  type t
  (** https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)

  type transformation =
    [ `S256
    | `Plain ]

  val make : Verifier.t -> t
  (** Will always be a S256 challenge
  https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)

  val of_string : transformation:transformation -> string -> t

  val to_code_challenge_and_method : t -> string * string
  (** https://www.rfc-editor.org/rfc/rfc7636#section-4.3 *)
end

val verify : Verifier.t -> Challenge.t -> bool
(** https://www.rfc-editor.org/rfc/rfc7636#section-4.6 *)
