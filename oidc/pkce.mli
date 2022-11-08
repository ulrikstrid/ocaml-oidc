(**
 * Copyright 2022 Ulrik Strid. All rights reserved.
 * Use of this source code is governed by a BSD-style
 * license that can be found in the LICENSE file.
 *)

type verifier

(** https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)
type challenge

type challenge_transformation = [ `S256 | `Plain ]

(** https://www.rfc-editor.org/rfc/rfc7636#section-4.1 *)
val make_code_verifier : unit -> verifier

val verifier_of_string : string -> verifier

(** Will always be a S256 challenge
  https://www.rfc-editor.org/rfc/rfc7636#section-4.2 *)
val make_code_challenge : verifier -> challenge 

val challenge_of_string : transformation:challenge_transformation -> string -> challenge

(** https://www.rfc-editor.org/rfc/rfc7636#section-4.3 *)
val challenge_to_code_challenge_and_method : challenge -> string * string

(** https://www.rfc-editor.org/rfc/rfc7636#section-4.6 *)
val verify : verifier -> challenge -> bool