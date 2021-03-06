(* Utilities for MicroTiML specialized to Expr *)

structure MicroTiMLUtilTiML = struct

open Expr
open MicroTiMLLongId
open MicroTiMLUtil

infixr 0 $
       
infix 9 %@
infix 8 %^
infix 7 %*
infix 6 %+ 
infix 4 %<=
infix 4 %<
infix 4 %>=
infix 4 %>
infix 4 %=
infixr 3 /\
infixr 2 \/
infixr 1 -->
infix 1 <->

infix 8 %**
fun a %** b = IBinOp (IBExpN (), a, b)
                   
val unTAbsT = unBindAnnoName
                
fun whnf ctx t =
    case t of
        TAppT (t1, t2) =>
        let
          val t1 = whnf ctx t1
        in
          case t1 of
              TAbsT data =>
              let
                val (_, (_, t1)) = unTAbsT data
              in
                whnf ctx $ subst0_t_t t2 t1
              end
            | _ => TAppT (t1, t2)
        end
      | TAppI (t, i) =>
        let
          val t = whnf ctx t
        in
          case t of
              TAbsI data =>
              let
                val (_, (_, t)) = unTAbsT data
              in
                whnf ctx $ subst0_i_t i t
              end
            | _ => TAppI (t, i)
        end
      | TVar x => TVar x (* todo: look up type aliasing in ctx *)
      | _ => t

fun TQuanI0 (q, bind) =
  let
    val (s, t) = unBindAnno bind
  in
    TQuanI (q, BindAnno (s, (TN0 dummy, t)))
  end
    
fun TExists bind = TQuan (Exists (), TN0 dummy, bind)
                         
fun TExistsI bind = TQuanI0 (Exists (), bind)
fun TExistsI_Many (ctx, t) = foldr (TExistsI o BindAnno) t ctx
                                         
fun MakeTExistsI (name, s, t) = MakeTQuanI (Exists (), s, name, TN0 dummy, t)
fun make_exists name s = TExistsI $ IBindAnno (((name, dummy), s), TUnit)
                             
fun TSumbool (s1, s2) =
  let
    val name = "__p"
  in
    TSum (make_exists name s1, make_exists name s2)
  end
                  
fun TForallI0 bind = TQuanI0 (Forall (), bind)
fun TForallIs (binds, b) = foldr (TForallI0 o IBindAnno) b binds
                                           
fun MakeSubset (name, s, p) = SSubset ((s, dummy), Bind.Bind ((name, dummy), p), dummy)
local
  fun IV n = IVar (ID (n, dummy), [])
in
fun TSomeNat_packed () = TExistsI $ IBindAnno ((("__VC", dummy), MakeSubset ("__VC", BSUnit, PTrue dummy)), TNat $ IV 1)
fun TSomeNat_packed2 () = TExistsI $ IBindAnno ((("n", dummy), MakeSubset ("n", BSNat, IV 0 %< INat (2, dummy) %** INat (256, dummy))), TSomeNat_packed ())
fun TSomeNat () = TRec $ TBindAnno ((("some_nat", dummy), KType ()), TSomeNat_packed2 ())
end
           
val Itrue = ITrue dummy
val Ifalse = IFalse dummy
                 
val INat = fn c => INat (c, dummy)
val ITime = fn c => ITime (c, dummy)
fun IBool c = IConst (ICBool c, dummy)
                     
fun TiBoolConst b = TiBool $ IBool b
                           
val SState = SBasic (BSBase (BSSState ()), dummy)
                                
fun assert_TArrow t =
  case t of
      TArrow a => a
    | _ => raise assert_fail $ "assert_TArrow; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TState t =
  case t of
      TState a => a
    | _ => raise assert_fail $ "assert_TState; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TPtr t =
  case t of
      TPtr a => a
    | _ => raise assert_fail $ "assert_TPtr; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TNatCell t =
  case t of
      TNatCell a => a
    | _ => raise assert_fail $ "assert_TNatCell; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TNat t =
  case t of
      TNat a => a
    | _ => raise assert_fail $ "assert_TNat failed; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TNat_m t err =
  case t of
      TNat a => a
    | _ => err $ "assert_TNat failed; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TiBool t =
  case t of
      TiBool a => a
    | _ => raise assert_fail $ "assert_TiBool failed; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TiBool_m t err =
  case t of
      TiBool a => a
    | _ => err $ "assert_TiBool failed; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
(* fun assert_fst_true p = *)
(*   case p of *)
(*       (true, a) => a *)
(*     | _ => raise Impossible "assert_fst_true" *)
(* fun assert_fst_false p = *)
(*   case p of *)
(*       (false, a) => a *)
(*     | _ => raise Impossible "assert_fst_false" *)
fun assert_TTuple t =
  case t of
      TTuple a => a
    | _ => raise assert_fail $ "assert_TTuple failed; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TRecord t =
  case t of
      TRecord a => a
    | _ => raise assert_fail $ "assert_TRecord failed; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TBool t =
  case t of
      TConst (TCTiML (BTBool ())) => ()
    | _ => raise assert_fail "assert_TBool"
fun assert_TForallI t =
  case t of
      TQuanI (Forall (), bind) =>
      let
        val ((name, s), (i, t)) = unBindAnno bind
      in
        (name, s, i, t)
      end
    | _ => raise assert_fail $ "assert_TForallI; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TForall t =
  case t of
      TQuan (Forall (), i, bind) =>
      let
        val ((name, k), t) = unBindAnno bind
      in
        (name, k, i, t)
      end
    | _ => raise assert_fail $ "assert_TForall; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TExistsI t =
  case t of
      TQuanI (Exists _, bind) =>
      let
        val ((name, s), (_, t)) = unBindAnno bind
      in
        (name, s, t)
      end
    | _ => raise assert_fail $ "assert_TExistsI; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TExists t =
  case t of
      TQuan (Exists _, i, bind) =>
      let
        val ((name, k), t) = unBindAnno bind
      in
        (name, k, t)
      end
    | _ => raise assert_fail $ "assert_TExists; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
fun assert_TSum t =
  case t of
      TBinOp (TBSum (), t1, t2) => (t1, t2)
    | _ => raise assert_fail "assert_TSum"
                                                          
fun assert_EAbs e =
  case e of
      EAbs (st, bind, spec) => (st, unBindAnnoName bind, spec)
    | _ => raise assert_fail "assert_EAbs"
fun assert_EAnnoLiveVars e =
  case e of
      EUnOp (EUTiML (EUAnno (EALiveVars n)), e) => (e, n)
    | _ => raise assert_fail "assert_EAnnoLiveVars"
fun assert_EAnnoFreeEVars e =
  case e of
      EUnOp (EUTiML (EUAnno (EAFreeEVars n)), e) => (e, n)
    | _ => raise assert_fail "assert_EAnnoFreeEVars"
                 
infix 6 @++
fun m @++ m' = StMapU.union m m'
                            
infix 6 @%++
val op@%++ = ISet.union
         
infix  9 @!!
fun m @!! k = StMapU.must_find m k
                               
fun decompose_state i =
  let
    val is = collect_IUnion i
    val (vars_info, maps) = partitionSum
                              (fn i =>
                                  case i of
                                      IVar (ID (n, _), ls) => inl (n, ls)
                                    | IState m => inr m
                                    | _ => raise Impossible $ "decompose_state: wrong idx: " ^ (ExportPP.str_i $ ExportPP.export_i [] i)
                              ) is
    val m = foldl (fn (m, acc) => acc @++ m) StMap.empty maps
    val vars = ISetU.to_set $ map fst vars_info
    val vars_info = IMapU.fromList vars_info
  in
    (vars, vars_info, m)
  end
    
fun compose_state (vars, vars_info, m) =
  combine_IUnion (IState m) $ map (fn n => IVar (ID (n, dummy), IMapU.must_find vars_info n)) $ ISetU.to_list vars
                 
fun IUnion_simp (i1, i2) =
  let
    val (vars1, vars_info1, map1) = decompose_state i1
    val (vars2, vars_info2, map2) = decompose_state i2
  in
    compose_state (vars1 @%++ vars2, IMapU.union vars_info1 vars_info2, map1 @++ map2)
  end
    
fun idx_st_must_find i k =
  let
    val (_, _, m) = decompose_state i
  in
    m @!! k
  end
fun idx_st_add i p = IUnion_simp (i, IState (StMapU.single p))
                                 
infix  9 @%!!
fun a @%!! b = idx_st_must_find a b

infix  6 @%+
fun a @%+ b = idx_st_add a b
                                
type mtiml_ty = (Expr.var, basic_sort, idx, sort) ty
type mtiml_expr = (Expr.var, idx, sort, basic_sort kind, mtiml_ty) expr

fun subst0_i_2i v b = unop_pair (subst0_i_i v) b
                                
fun is_rec_body e =
  case e of
      EUnOp (EUTiML (EUAnno (EABodyOfRecur ())), e) => (true, e)
    | _ => (false, e)
             
fun is_TApp_TRec t =
  let
    val (t, args) = collect_TAppIT t
  in
    case t of
        TRec data => SOME (unBindAnnoName data, args)
      | _ => NONE
  end

fun try_unfold t =
  case is_TApp_TRec t of
      SOME ((k, (_, t1)), args) => whnf ([], []) $ TAppITs (subst0_t_t t t1) args
    | NONE => t

fun is_wordsize_ty t =
  case whnf ([], []) $ snd $ collect_TExistsIT $ try_unfold t of
      TNat _ => true
    | TiBool _ => true
    | TConst c =>
      (case c of
           TCUnit () => true
         | TCEmpty () => true
         | TCTiML c =>
           case c of
               BTInt () => true
             | BTBool () => true
             | BTByte () => true
      )
    | _ => false

fun assert_wordsize_ty t =
  if is_wordsize_ty t then ()
  else raise Impossible "not a base storage type"

fun assert_TTuple t =
  case t of
      TTuple a => a
    | _ => raise assert_fail $ "assert_TTuple; got: " ^ (ExportPP.pp_t_to_string NONE $ ExportPP.export_t NONE ([], []) t)
                                                          
end
