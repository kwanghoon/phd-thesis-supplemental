structure UVar = struct

open Util

infixr 0 $
       
datatype ('a, 'b) uvar = 
         Fresh of 'a
         | Refined of 'b

type uvar_name = int

type ('a, 'b) uvar_ref = (('a, 'b) uvar) ref
                             
fun is_fresh x =
  case !x of
      Fresh _ => true
    | Refined _ => false
                        
(* uvar for bsort *)                  
type 'bsort uvar_bs = (uvar_name, 'bsort) uvar_ref

(* uvar for index *)                  
type ('bsort, 'idx) uvar_i = (uvar_name * (string * 'bsort) list(*context*) * 'bsort(*result*), 'idx) uvar_ref

(* uvar for sort *)                  
type ('bsort, 'sort) uvar_s = (uvar_name * (string * 'bsort) list(*context*), 'sort) uvar_ref

(* uvar for (mono-)type *)                  
type ('bsort, 'kind, 'mtype) uvar_mt = (uvar_name * ((string * 'bsort) list(*index context*) * (string * 'kind) list(*type context*)), 'mtype) uvar_ref

(* mapping will break sharing of uvars *)
fun new_ref f r = ref $ f (!r)
                      
fun map_uvar_bs f_bs x =
  flip new_ref x $
       (fn u => case u of
                    Fresh name => Fresh name
                  | Refined b => Refined $ f_bs b
       )

fun map_uvar_i (f_bs, f_i) x =
  flip new_ref x $
       (fn u => case u of
                    Fresh (name, ctx, b) => Fresh (name, map (mapSnd f_bs) ctx, f_bs b)
                  | Refined i => Refined $ f_i i
       )

fun map_uvar_s (f_bs, f_s) x =
  flip new_ref x $
       (fn u => case u of
                    Fresh (name, ctx) => Fresh (name, map (mapSnd f_bs) ctx)
                  | Refined s => Refined $ f_s s
       )

fun map_uvar_mt (f_bs, f_k, f_mt) x =
  flip new_ref x $
       (fn u => case u of
                    Fresh (name, (sctx, kctx)) => Fresh (name, (map (mapSnd f_bs) sctx, map (mapSnd f_k) kctx))
                  | Refined t => Refined $ f_mt t
       )

fun refine (x : ('a, 'b) uvar_ref) (v : 'b) = 
  case !x of
      Refined _ => raise Impossible "refine(): should only refine Fresh uvar"
    | Fresh _ =>
      x := Refined v

fun str_uvar n = "?" ^ str_int n

fun str_uinfo_bs n = str_uvar n
fun str_uinfo_i str_bs (n, ctx, b) = str_uvar n
fun str_uinfo_s (n, ctx) = str_uvar n
fun str_uinfo_mt _ (n, ctx) = str_uvar n
                                         
(* fun str_uinfo_i str_bs (n, ctx, b) = sprintf "$[$$]" [str_uvar n, join_suffix " => " $ map (str_bs o snd) $ rev ctx, str_bs b] *)
(* fun str_uinfo_mt (str_s, str_k) (n, (sctx, kctx)) = sprintf "$[$$$]" [str_uvar n, join_suffix " => " $ map (fn (name, s) => sprintf "$:$" [name, str_s s]) $ rev sctx, join_suffix " => " $ map (str_k o snd) $ rev kctx, "*"] *)
                                         
fun str_uvar_bs str_bs (u : 'bsort uvar_bs) =
  case !u of
      Refined bs => str_bs bs
    | Fresh info => str_uinfo_bs info
                                 
fun str_uvar_i (str_bs, str_i) (u : ('bsort, 'idx) uvar_i) =
  case !u of
      Refined i => str_i i
    | Fresh info => str_uinfo_i str_bs info

fun str_uvar_s str_s (u : ('bsort, 'sort) uvar_s) =
  case !u of
      Refined s => str_s s
    | Fresh info => str_uinfo_s info

fun str_uvar_mt (str_s, str_k, str_mt) (u : ('sort, 'kind, 'mtype) uvar_mt) =
  case !u of
      Refined t => str_mt t
    | Fresh info => str_uinfo_mt (str_s, str_k) info
                            
fun pp_uvar_mt (str_s, str_k, pp_t, str) (u : ('sort, 'kind, 'mtype) uvar_mt) =
  case !u of
      Refined t => pp_t t
    | Fresh info => str $ str_uinfo_mt (str_s, str_k) info
                            
val eq_uvar_bs = op=
val eq_uvar_i = op=
val eq_uvar_s = op=
val eq_uvar_mt = op=
                                                                                        
fun get_uvar_info x =
  case !x of
      Fresh info => SOME info
    | Refined _ => NONE
                       
end
