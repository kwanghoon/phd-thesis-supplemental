structure Elaborate = struct
structure S = Ast
structure E = NamefulExpr
open S
open E
open Bind
       
infixr 0 $

exception Error of region * string

local

  fun runError m _ =
      OK (m ())
      handle
      Error e => Failed e

  val un_ops = [ToReal, Log2, Ceil, Floor, B2n, Neg]
  val un_op_names = zip (un_ops, map str_idx_un_op un_ops)
  fun is_un_op (opr, i1) =
      case (opr, i1) of
          (TimeApp, S.VarI (NONE, (x, r1))) => find_by_snd_eq op= x un_op_names
        | _ => NONE

  fun is_ite i =
      case i of
          S.BinOpI (IApp, S.BinOpI (IApp, S.BinOpI (TimeApp, S.VarI (NONE, (x, _)), i1, _), i2, _), i3, _) =>
          if x = "ite" then SOME (i1, i2, i3)
          else NONE
        | _ => NONE
                 
  fun to_long_id (m, x) =
    case m of
        NONE => ID x
      | SOME m => QID (m, x)
        
  fun elab_i i =
      case i of
	  S.VarI (id as (m, (x, r))) =>
          (case m of
               NONE =>
	       if x = "true" then
		 TrueI r
	       else if x = "false" then
		 FalseI r
               else if x = "admit" then
                 AdmitI r
               else if x = "_" then
                 UVarI ((), r)
	       else
		 VarI (to_long_id id, [])
             | SOME _ => VarI (to_long_id id, [])
          )
	| S.ConstIN n =>
	  ConstIN n
	| S.ConstIT (x, r) =>
          let
            infixr 0 !!
            val x = TimeType.fromString x !! (fn () => raise Error (r, sprintf "Wrong time literal: $" [x]))
          in
	    ConstIT (x, r)
          end
        (* | S.UnOpI (opr, i, r) => UnOpI (opr, elab_i i, r) *)
        | S.DivI (i1, n2, _) => DivI (elab_i i1, n2)
	| S.BinOpI (opr, i1, i2, r) =>
          (case is_un_op (opr, i1) of
               SOME opr => UnOpI (opr, elab_i i2, r)
             | NONE =>
               case is_ite i of
                   SOME (i1, i2, i3) => Ite (elab_i i1, elab_i i2, elab_i i3, r)
	         | NONE =>BinOpI (opr, elab_i i1, elab_i i2)
          )
	| S.TTI r =>
	  TTI r
        | S.IAbs (names, i, r) =>
          foldr (fn (name, i) => IAbs (UVarBS (), Bind (name, i), r)) (elab_i i) names

  fun elab_p p =
      case p of
	  ConstP (name, r) =>
	  if name = "True" then
	    True r
	  else if name = "False" then
	    False r
	  else raise Error (r, sprintf "Unrecognized proposition: $" [name])
        | S.Not (p, r) => Not (elab_p p, r)
	| S.BinConn (opr, p1, p2, _) => BinConn (opr, elab_p p1, elab_p p2)
	| S.BinPred (opr, i1, i2, _) => BinPred (opr, elab_i i1, elab_i i2)

  fun TimeFun n =
    if n <= 0 then Base Time
    else BSArrow (Base Nat, TimeFun (n-1))

  fun elab_b b =
      case b of
          S.Base (name, r) =>
	  if name = "Time" then
	    (Base Time, r)
	  else if name = "Nat" then
	    (Base Nat, r)
	  else if name = "Bool" then
	    (Base BoolSort, r)
	  else if name = "Unit" then
	    (Base UnitSort, r)
          else if name = "_" then
            (UVarBS (), r)
	  else raise Error (r, sprintf "Unrecognized base sort: $" [name])

  fun elab_s s =
      case s of
	  S.Basic b =>
          (case elab_b b of
               (UVarBS (), r) => UVarS ((), r)
             | b => Basic b
          )
	| S.Subset (b, name, p, r) => Subset (elab_b b, Bind (name, elab_p p), r)
        | S.BigOSort (name, b, i, r) =>
          let
            fun SortBigO (bs, i, r) =
              let
                val name = "__f"
              in
                Subset (bs, Bind ((name, r), BinPred (BigO, VarI (ID (name, r), []), i)), r)
              end
          in
            if name = "BigO" then
              SortBigO (elab_b b, elab_i i, r)
            else
              raise Error (r, sprintf "Unrecognized sort: $" [name])
          end

  fun get_is t =
      case t of 
	  AppTI (t, i, _) =>
	  let val (t, is) = get_is t in
	    (t, is @ [i])
	  end
	| _ => (t, [])

  fun get_ts t =
      case t of 
	  AppTT (t, t2, _) =>
	  let val (t, ts) = get_ts t in
	    (t, ts @ [t2])
	  end
	| _ => (t, [])

  fun is_var_app_ts t = 
      let val (t, ts) = get_ts t in
	case t of
	    S.VarT x => SOME (x, ts)
	  | _ => NONE
      end

  fun elab_mt t =
      case t of
	  S.VarT (id as (m, (x, r))) =>
          let
            fun def () = AppV (to_long_id id, [], [], r)
          in
            case m of
                NONE =>
                if x = "unit" then
                  Unit r
                else if x = "int" then
                  BaseType (Int, r)
                else if x = "_" then
                  UVar ((), r)
                else
                  def ()
              | SOME _ => def ()
          end
	| S.Arrow (t1, d, t2, _) => Arrow (elab_mt t1, elab_i d, elab_mt t2)
	| S.Prod (t1, t2, _) => Prod (elab_mt t1, elab_mt t2)
	| S.Quan (quan, binds, t, r) =>
	  let fun f ((x, s, _), t) =
		case quan of
		    S.Forall => UniI (elab_s s, Bind (x, t), r)
	  in
	    foldr f (elab_mt t) binds
	  end
	| S.AppTT (t1, t2, r) =>
	  (case is_var_app_ts t1 of
	       SOME (x, ts) => AppV (to_long_id x, map elab_mt (ts @ [t2]), [], r)
	     | NONE => raise Error (r, "Head of type-type application must be a variable"))
	| S.AppTI (t, i, r) =>
	  let val (t, is) = get_is t 
	      val is = is @ [i]
	  in
	    case is_var_app_ts t of
		SOME (x, ts) => AppV (to_long_id x, map elab_mt ts, map elab_i is, r)
	      | NONE => raise Error (r, "The form of type-index application can only be [Variable Types Indices]")
	  end

  fun elab_return return = mapPair (Option.map elab_mt, Option.map elab_i) return
                                   
  fun elab_pn pn =
      case pn of
          S.ConstrP ((name, eia), inames, pn, r) =>
          if isNone (fst name) andalso not eia andalso null inames andalso isNone pn then
            VarP $ Binder $ EName (snd name)
          else
            ConstrP (Outer ((to_long_id name, ()), eia), map str2ibinder inames, default (TTP $ Outer r) $ Option.map elab_pn pn, Outer r)
        | S.TupleP (pns, r) =>
          (case pns of
               [] => TTP $ Outer r
             | pn :: pns => foldl (fn (pn2, pn1) => PairP (pn1, elab_pn pn2)) (elab_pn pn) pns)
        | S.AliasP (name, pn, r) =>
          AliasP (Binder $ EName name, elab_pn pn, Outer r)
        | S.AnnoP (pn, t, r) =>
          AnnoP (elab_pn pn, Outer $ elab_mt t)
  (*                                                              
    and copy_anno (t, d) =
        let
          fun loop e =
              case e of
                  S.Case (e, (t', d'), es, r) =>
                  let
                    fun copy a b = case a of
                                       NONE => b
                                     | SOME _ => a
                  in
                    S.Case (e, (copy t' t, copy d' d), es, r)
                  end
                | S.Let (decls, e, r) => S.Let (decls, loop e, r)
                | _ => e
        in
          loop
        end
    *)

  fun partitionSum f ls = mapPair (rev, rev) $ foldl (fn (x, (acc1, acc2)) => case f x of
                                                             inl a => (a :: acc1, acc2) |
                                                             inr b => (acc1, b :: acc2)) ([], []) ls
                
  fun elab_datatype ((name, tnames, top_sortings, sorts, constrs, r) : S.datatype_def) : mtype datatype_def * region =
      let
        val sorts = map (fst o elab_b) (map (fn (_, s, _) => s) top_sortings @ sorts)
        fun default_t2 r = foldl (fn (arg, f) => S.AppTT (f, S.VarT (NONE, (arg, r)), r)) (S.VarT (NONE, (name, r))) tnames
        fun elab_constr ((cname, binds, core, r) : S.constr_decl) : mtype constr_decl =
            let
              (* val (t1, t2) = default (S.VarT ("unit", r), SOME (default_t2 r)) core *)
              (* val t2 = default (default_t2 r) t2 *)
              val (t1, t2) =
                  case core of
                      NONE => (S.VarT (NONE, ("unit", r)), default_t2 r)
                    | SOME (t1, NONE) => (S.VarT (NONE, ("unit", r)), t1)
                    | SOME (t1, SOME t2) => (t1, t2)
              fun f (name, sort, r) = (name, elab_s sort)
              val binds = map f (map (fn (name, b, r) => (name, S.Basic b, r)) top_sortings @ binds)
              val t2_orig = t2
              val (t2, is) = get_is t2
              val (t2, ts) = get_ts t2
              val () = if case t2 of S.VarT (NONE, (x, _)) => x = name | _ => false then
                         ()
                       else
                         raise Error (S.get_region_t t2, sprintf "Result type of constructor must be $ (did you use -> when you should you --> ?)" [name])
              val () = if length ts = length tnames then () else raise Error (S.get_region_t t2_orig, "Must have type arguments " ^ join " " tnames)
              fun f (t, tname) =
                  let
                    val targ_mismatch = "This type argument must be " ^ tname
                  in
                    case t of
                        S.VarT (NONE, (x, r)) => if x = tname then () else raise Error (r, targ_mismatch)
                      | _ => raise Error (S.get_region_t t, targ_mismatch)
                  end
              val () = app f (zip (ts, tnames))
            in
              (cname, fold_binds (binds, (elab_mt t1, map elab_i is)), r)
            end
        val dt = Bind ((name, dummy), fold_binds (map (attach_snd ()) $ map (attach_snd dummy) tnames, (sorts, map elab_constr constrs)))
      in
        (dt, r)
      end
        
  fun elab e =
      case e of
	  S.Var (id as (m, (x, r)), eia) =>
          let
            fun def () = EVar (to_long_id id, eia)
          in
            case m of
                NONE =>
                if x = "never" andalso eia = false then
                  ENever (elab_mt (S.VarT (NONE, ("_", r))), r)
                else if x = "builtin" andalso eia = false then
                  EBuiltin (elab_mt (S.VarT (NONE, ("_", r))), r)
                else
                  def ()
              | SOME _ => def ()
          end
	| S.Tuple (es, r) =>
	  (case es of
	       [] => ETT r
	     | e :: es => foldl (fn (e2, e1) => EPair (e1, elab e2)) (elab e) es)
	| S.Abs (binds, (t, d), e, r) =>
	  let 
            fun f (b, e) =
		case b of
		    Typing pn => EAbs $ Unbound.Bind (elab_pn pn, e)
		  | BindSort (name, s, _) => EAbsI (BindAnno ((IName name, elab_s s), e), r)
            val e = elab e
            val e = case d of SOME d => EAscTime (e, elab_i d) | _ => e
            val e = case t of SOME t => EAsc (e, elab_mt t) | _ => e
	  in
	    foldr f e binds
	  end
	| S.App (e1, e2, r) =>
	  let 
	    fun default () = EApp (elab e1, elab e2)
	  in
	    case e1 of
		S.Var ((m, (x, _)), false) =>
                (case m of
                     NONE =>
		     if x = "fst" then EFst (elab e2, r)
		     else if x = "snd" then ESnd (elab e2, r)
		     else default ()
                   | SOME _ => default ()
                )
	      | _ => default ()
	  end
	| S.AppI (e, i, _) =>
	  EAppI (elab e, elab_i i)
	| S.Case (e, return, rules, r) =>
	  let
            (* val rules = map (mapSnd (copy_anno return)) rules *)
	  in
	    ECase (elab e, elab_return return, map (fn (pn, e) => Unbound.Bind (elab_pn pn, elab e)) rules, r)
	  end
	| S.Asc (e, t, _) =>
	  EAsc (elab e, elab_mt t)
	| S.AscTime (e, i, _) =>
	  EAscTime (elab e, elab_i i)
	| S.Let (return, decs, e, r) =>
          ELet (elab_return return, Unbound.Bind (Teles $ map elab_decl decs, elab e), r)
	| S.Const n => EConstInt n
	| S.ConstNat n => EConstNat n
        | S.BinOp (opr, e1, e2, _) => EBinOp (opr, elab e1, elab e2)

  and elab_decl decl =
      case decl of
	  S.Val (tnames, pn, e, r) =>
          let
            val pn = elab_pn pn
          in
            case pn of
                VarP name =>
                DVal (name, Outer $ Unbound.Bind (map (Binder o TName) tnames, elab e), Outer r)
              | _ =>
                if null tnames then
                  DValPtrn (pn, Outer $ elab e, Outer r)
                else
                  raise Error (r, "compound pattern can't be generalized, so can't have explicit type variables")
          end
	| S.Rec (tnames, name, binds, (t, d), e, r) =>
          let
            fun f bind =
                case bind of
		    Typing pn => TypingST (elab_pn pn)
		  | BindSort (nm, s, _) => SortingST (Binder $ IName nm, Outer $ elab_s s)
            val binds = map f binds
            (* if the function body is a [case] without annotations, copy the return clause from the function signature to the [case] *)
            (* val e = copy_anno (t, d) e *)
            val t = default (UVar ((), r)) (Option.map elab_mt t)
            val d = default (UVarI ((), r)) (Option.map elab_i d)
            val e = elab e
          in
	    DRec (Binder $ EName name, Inner $ Unbound.Bind ((map (Binder o TName) tnames, Rebind $ Teles binds), ((t, d), e)), Outer r)
          end
        | S.IdxDef ((name, r), s, i) =>
          let
            val s = default (UVarS ((), r)) $ Option.map elab_s s
          in
            DIdxDef (Binder $ IName (name, r), Outer $ SOME s, Outer $ elab_i i)
          end
        | S.AbsIdx2 ((name, r), s, i) =>
          let
            val s = default (UVarS ((), r)) $ Option.map elab_s s
          in
            DAbsIdx2 (Binder $ IName (name, r), Outer s, Outer $ elab_i i)
          end
        | S.AbsIdx ((name, r1), s, i, decls, r) =>
          let
            val s = default (UVarS ((), r1)) $ Option.map elab_s s
            val i = case i of
                        SOME i => elab_i i
                      | NONE => UVarI ((), r1)
          in
            DAbsIdx ((Binder $ IName (name, r1), Outer s, Outer i), Rebind $ Teles $ map elab_decl decls, Outer r)
          end
        | S.Datatype a =>
          let
            val (dt, r) = elab_datatype a
          in
            DTypeDef (Binder $ TName $ fst $ unBind dt, Outer $ TDatatype (dt, r))
          end
        | S.TypeDef (name, t) => DTypeDef (Binder $ TName name, Outer $ elab_mt t)
        | S.Open name => DOpen (Outer name, NONE)

  fun elab_spec spec =
      case spec of
          S.SpecVal (name, tnames, t, r) => SpecVal (name, foldr (fn (tname, t) => Uni (Bind (tname, t), combine_region (snd tname) r)) (Mono $ elab_mt t) tnames)
        | S.SpecIdx (name, sort) => SpecIdx (name, elab_s sort)
        | S.SpecType (tnames, sorts, r) =>
          (case tnames of
               [] => raise Error (r, "Type declaration must have a name")
             | name :: tnames => SpecType (name, (length tnames, map (fst o elab_b) sorts))
          )
        | S.SpecTypeDef (name, ty) => SpecTypeDef (name, elab_mt ty)
        | S.SpecDatatype a =>
          let
            val (dt, r) = elab_datatype a
          in
            SpecTypeDef (fst $ unBind dt, TDatatype (dt, r))
          end

  fun elab_sig sg =
      case sg of
          S.SigComponents (specs, r) => (map elab_spec specs, r)

  fun elab_mod m =
      case m of
          S.ModComponents (comps, r) => ModComponents (map elab_decl comps, r)
        | S.ModSeal (m, sg) => ModSeal (elab_mod m, elab_sig sg)
        | S.ModTransparentAsc (m, sg) => ModTransparentAsc (elab_mod m, elab_sig sg)
                                                                         
  fun elab_top_bind bind =
      case bind of
          S.TopModBind (name, m) => (name, TopModBind (elab_mod m))
        | S.TopFunctorBind (name, (arg_name, arg), body) => (name, TopFunctorBind ((arg_name, elab_sig arg), elab_mod body))
        | S.TopFunctorApp (name, f, arg) => (name, TopFunctorApp (f, arg))
                                                          
  fun elab_prog prog = map elab_top_bind prog
                           
in
val elaborate = elab
fun elaborate_opt e = runError (fn () => elab e) ()
val elaborate_decl = elab_decl
fun elaborate_decl_opt d = runError (fn () => elab_decl d) ()
val elaborate_prog = elab_prog
                       
end

end
