signature IDX_TYPE = sig
  structure Idx : IDX
  structure Type : TYPE
  sharing type Type.var = Idx.var
  sharing type Type.idx = Idx.idx
  sharing type Type.sort = Idx.sort
end

signature HAS_EQUAL = sig
  type var
  type name
  include UVAR_I
  include UVAR_T
  val eq_var : var * var -> bool
  val eq_name : name * name -> bool
  val eq_uvar_bs : 'bsort uvar_bs * 'bsort uvar_bs -> bool
  val eq_uvar_i : ('bsort, 'idx) uvar_i * ('bsort, 'idx) uvar_i -> bool
  val eq_uvar_s : ('bsort, 'sort) uvar_s * ('bsort, 'sort) uvar_s -> bool
  val eq_uvar_mt : ('sort, 'kind, 'mtype) uvar_mt * ('sort, 'kind, 'mtype) uvar_mt -> bool
end
                        
functor EqualFn (structure IdxType : IDX_TYPE where type Idx.base_sort = BaseSorts.base_sort
                                                and type Type.base_type = BaseTypes.base_type
                 structure HasEqual : HAS_EQUAL
                 sharing type IdxType.Type.bsort = IdxType.Idx.bsort
                 sharing type HasEqual.var = IdxType.Idx.var
                 sharing type HasEqual.name = IdxType.Type.name
                 sharing type HasEqual.uvar_bs = IdxType.Idx.uvar_bs
                 sharing type HasEqual.uvar_i = IdxType.Idx.uvar_i
                 sharing type HasEqual.uvar_s = IdxType.Idx.uvar_s
                 sharing type HasEqual.uvar_mt = IdxType.Type.uvar_mt
                 val str_raw_mt : IdxType.Type.mtype -> string
                ) = struct

open HasEqual
open IdxType
open Idx
open Type
open Operators
open Util
open BaseTypes
open Bind

infixr 0 $
       
fun eq_option eq (a, a') =
  case (a, a') of
      (SOME v, SOME v') => eq (v, v')
    | (NONE, NONE) => true
    | _ => false

fun eq_bs bs bs' =
  case bs of
      Base b =>
      (case bs' of Base b' => b = b' | _ => false)
    | BSArrow (s1, s2) =>
      (case bs' of
           BSArrow (s1', s2') => eq_bs s1 s1' andalso eq_bs s2 s2'
         | _ => false
      )
    | UVarBS u => (case bs' of UVarBS u' => eq_uvar_bs (u, u') | _ => false)

fun eq_idx_const c c' =
  case c of
      ICBool b => (case c' of ICBool b' => b = b' | _ => false)
    | ICTT => (case c' of ICTT => true | _ => false)
    | ICAdmit => raise Impossible "can't compare index ICAdmit"
    | ICNat n => (case c' of ICNat n' => n = n' | _ => false)
    | ICTime x => (case c' of ICTime x' => TimeType.time_eq (x, x') | _ => false)
    
fun eq_i i i' =
  let
    fun loop i i' =
      case i of
          VarI (x, _) => (case i' of VarI (x', _) => eq_var (x, x') | _ => false)
        | IConst (c, _) => (case i' of IConst (c', _) => eq_idx_const c c' | _ => false)
        | UnOpI (opr, i, _) => (case i' of UnOpI (opr', i', _) => opr = opr' andalso loop i i' | _ => false)
        | BinOpI (opr, i1, i2) => (case i' of BinOpI (opr', i1', i2') => opr = opr' andalso loop i1 i1' andalso loop i2 i2' | _ => false)
        | Ite (i1, i2, i3, _) => (case i' of Ite (i1', i2', i3', _) => loop i1 i1' andalso loop i2 i2' andalso loop i3 i3' | _ => false)
        | IAbs (b, Bind (_, i), _) => (case i' of IAbs (b', Bind (_, i'), _) => eq_bs b b' andalso loop i i'
                                                | _ => false)
        | UVarI (u, _) => (case i' of UVarI (u', _) => eq_uvar_i (u, u') | _ => false)
  in
    loop i i'
  end

fun eq_quan q q' =
  case q of
      Forall => (case q' of Forall => true | Exists _ => false)
    | Exists _ => (case q' of Forall => false | Exists _ => true)
                    
fun eq_p p p' =
  case p of
      PTrueFalse (b, _) => (case p' of PTrueFalse (b', _) => b = b' | _ => false)
    | BinConn (opr, p1, p2) => (case p' of BinConn (opr', p1', p2') => opr = opr' andalso eq_p p1 p1' andalso eq_p p2 p2' | _ => false)
    | BinPred (opr, i1, i2) => (case p' of BinPred (opr', i1', i2') => opr = opr' andalso eq_i i1 i1' andalso eq_i i2 i2' | _ => false)
    | Not (p, _) => (case p' of Not (p', _) => eq_p p p' | _ => false)
    | Quan (q, bs, Bind (_, p), _) => (case p' of Quan (q', bs', Bind (_, p'), _) => eq_quan q q' andalso eq_bs bs bs' andalso eq_p p p' | _ => false)

fun eq_s s s' =
  case s of
      Basic (b, _) =>
      (case s' of
           Basic (b', _) => eq_bs b b'
         | _ => false
      )
    | Subset ((b, _), Bind (_, p), _) =>
      (case s' of
           Subset ((b', _), Bind (_, p'), _) => eq_bs b b' andalso eq_p p p'
         | _ => false
      )
    | UVarS (x, _) =>
      (case s' of
           UVarS (x', _) => eq_uvar_s (x, x')
         | _ => false
      )
    | SAbs (s1, Bind (_, s), _) =>
      (case s' of
           SAbs (s1', Bind (_, s'), _) => eq_bs s1 s1' andalso eq_s s s'
         | _ => false
      )
    | SApp (s, i) =>
      (case s' of
           SApp (s', i') => eq_s s s' andalso eq_i i i'
         | _ => false
      )
                                                             
fun eq_ls eq (ls1, ls2) = length ls1 = length ls2 andalso List.all eq $ zip (ls1, ls2)
                                                              
fun eq_k ((n, sorts) : kind) (n', sorts') =
  n = n' andalso eq_ls (uncurry eq_bs) (sorts, sorts')
  
fun eq_mt t t' = 
    case t of
	Arrow (t1, i, t2) =>
        (case t' of
	     Arrow (t1', i', t2') => eq_mt t1 t1' andalso eq_i i i' andalso eq_mt t2 t2'
           | _ => false
        )
      | TyNat (i, r) =>
        (case t' of
             TyNat (i', _) => eq_i i i'
           | _ => false
        )
      | TiBool (i, r) =>
        (case t' of
             TiBool (i', _) => eq_i i i'
           | _ => false
        )
      | TyArray (t, i) =>
        (case t' of
             TyArray (t', i') => eq_mt t t' andalso eq_i i i'
           | _ => false
        )
      | Unit r =>
        (case t' of
             Unit _ => true
           | _ => false
        )
      | Prod (t1, t2) =>
        (case t' of
             Prod (t1', t2') => eq_mt t1 t1' andalso eq_mt t2 t2'
           | _ => false
        )
      | UniI (s, Bind (_, t), r) =>
        (case t' of
             UniI (s', Bind (_, t'), _) => eq_s s s' andalso eq_mt t t'
           | _ => false
        )
      | TSumbool (s1, s2) =>
        (case t' of
             TSumbool (s1', s2') => eq_s s1 s1' andalso eq_s s2 s2'
           | _ => false
        )
      | MtVar x =>
        (case t' of
             MtVar x' => eq_var (x, x')
           | _ => false
        )
      | MtAbs (k, Bind (_, t), r) =>
        (case t' of
             MtAbs (k', Bind (_, t'), _) => eq_k k k' andalso eq_mt t t'
           | _ => false
        )
      | MtApp (t1, t2) =>
        (case t' of
             MtApp (t1', t2') => eq_mt t1 t1' andalso eq_mt t2 t2'
           | _ => false
        )
      | MtAbsI (s, Bind (_, t), r) =>
        (case t' of
             MtAbsI (s', Bind (_, t'), _) => eq_bs s s' andalso eq_mt t t'
           | _ => false
        )
      | MtAppI (t, i) =>
        (case t' of
             MtAppI (t', i') => eq_mt t t' andalso eq_i i i'
           | _ => false
        )
      | BaseType (a : base_type, r) =>
        (case t' of
             BaseType (a' : base_type, _)  => eq_base_type (a, a')
           | _ => false
        )
      | UVar (x, _) =>
        (case t' of
             UVar (x', _) => eq_uvar_mt (x, x')
           | _ => false
        )
      (* | TDatatype _ => raise Unimpl "eq_mt()/TDatatype" *)
      | TDatatype (dt, _) =>
        (case t' of
             TDatatype (dt', _) =>
             let
               open ContUtil
               fun eq_constr_decl_k ((name, core, _), (name', core', _)) return =
                 let
                   fun check b = if b then () else return false
                   (* constructor names are significant *)
                   val () = check $ eq_name (name, name')
                   val (iname_sorts, (t, is)) = unfold_binds core
                   val (iname_sorts', (t', is')) = unfold_binds core'
                   val () = check $ eq_ls (uncurry eq_s) (map snd iname_sorts, map snd iname_sorts')
                   (* val () = println $ sprintf "to compare types:\n$\n$" [str_raw_mt t, str_raw_mt t'] *)
                   val () = check $ eq_mt t t'
                   val () = check $ eq_ls (uncurry eq_i) (is, is')
                 in
                   true
                 end
               fun eq_constr_decl a = callret $ eq_constr_decl_k a
               fun eq_datatype_def_k (Bind (name, tbinds), Bind (name', tbinds')) return =
                 let
                   fun check b = if b then () else return false
                   (* the self-referencing name is significant *)
                   val () = check $ eq_name (name, name')
                   val (tname_kinds, (sorts, constr_decls)) = unfold_binds tbinds
                   val (tname_kinds', (sorts', constr_decls')) = unfold_binds tbinds'
                   val () = check $ length tname_kinds = length tname_kinds'
                   val () = check $ eq_ls (uncurry eq_bs) (sorts, sorts') 
                   val () = check $ eq_ls eq_constr_decl (constr_decls, constr_decls')
                 in
                   true
                 end
               fun eq_datatype_def a = callret $ eq_datatype_def_k a
               val ret = eq_datatype_def (dt, dt')
             in
               ret
             end
           | _ => false
        )

end
