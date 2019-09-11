(* Copyright (c) 2016-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree. *)

open Core
open Ast
module SharedMemory = Memory

type index = {
  function_keys: Reference.t Hash_set.t Reference.Table.t;
  class_keys: Identifier.t Hash_set.t Reference.Table.t;
  alias_keys: Identifier.t Hash_set.t Reference.Table.t;
  global_keys: Reference.t Hash_set.t Reference.Table.t;
  dependent_keys: Reference.t Hash_set.t Reference.Table.t;
}

type t = {
  index: index;
  dependents: Reference.Set.t Reference.Table.t;
}

module type Handler = sig
  val add_function_key : qualifier:Reference.t -> Reference.t -> unit

  val add_alias_key : qualifier:Reference.t -> Identifier.t -> unit

  val add_global_key : qualifier:Reference.t -> Reference.t -> unit

  val add_dependent_key : qualifier:Reference.t -> Reference.t -> unit

  val add_dependent : qualifier:Reference.t -> Reference.t -> unit

  val dependents : Reference.t -> Reference.Set.Tree.t option

  val get_function_keys : qualifier:Reference.t -> Reference.t list

  val get_alias_keys : qualifier:Reference.t -> Identifier.t list

  val get_global_keys : qualifier:Reference.t -> Reference.t list

  val get_dependent_keys : qualifier:Reference.t -> Reference.t list

  val clear_keys_batch : Reference.t list -> unit

  val normalize : Reference.t list -> unit
end

val create : unit -> t

val copy : t -> t

val handler : t -> (module Handler)

val transitive_of_list
  :  get_dependencies:(Reference.t -> Reference.Set.Tree.t option) ->
  modules:Reference.t list ->
  Reference.Set.t

val of_list
  :  get_dependencies:(Reference.t -> Reference.Set.Tree.t option) ->
  modules:Reference.t list ->
  Reference.Set.t

val to_dot
  :  get_dependencies:(Reference.t -> Reference.Set.Tree.t option) ->
  qualifier:Reference.t ->
  string

module Callgraph : sig
  type dispatch =
    | Dynamic
    | Static

  and callee =
    | Function of Reference.t
    | Method of {
        class_name: Reference.t;
        direct_target: Reference.t;
        dispatch: dispatch;
      }
  [@@deriving compare, eq, show]

  type callee_with_locations = {
    callee: callee;
    locations: Location.Reference.t list;
  }

  val callee_to_yojson : ?locations:Location.Instantiated.t list -> callee -> Yojson.Safe.t

  include Hashable with type t := callee

  module CalleeValue : SharedMemory.ValueType with type t = callee_with_locations list

  module SharedMemory :
    Memory.WithCache.S
      with type t = CalleeValue.t
       and type key = SharedMemoryKeys.ReferenceKey.t
       and type key_out = SharedMemoryKeys.ReferenceKey.out
       and module KeySet = Caml.Set.Make(SharedMemoryKeys.ReferenceKey)
       and module KeyMap = MyMap.Make(SharedMemoryKeys.ReferenceKey)

  val set : caller:Reference.t -> callees:callee_with_locations list -> unit

  val get : caller:Reference.t -> callee_with_locations list
end
