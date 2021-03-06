(* Continuation-Passing-Style (CPS) Conversion *)

structure CPS = struct

open Expr
open CostUtil
open MicroTiMLCosts
open MicroTiMLFreeEVars
open CompilerUtil
open MicroTiMLLongId
open MicroTiMLLocallyNameless
open MicroTiMLUtil
open MicroTiML
structure S = MicroTiML

infixr 0 $

infix 9 %@
infix 8 %^
infix 7 %*
infix 6 %+ 
infix 6 %++ 
infix 4 %<=
infix 4 %>=
infix 4 %=
infixr 3 /\
infixr 2 \/
infixr 1 -->
infix 1 <->

fun a %++ b = IUnion (a, b)
  
fun IV x = IVar (make_Free_i x, [])
                
val STime = STime dummy
val SNat = SNat dummy
val SBool = SBool dummy
val SUnit = SUnit dummy

val T0 = T0 dummy
val T1 = T1 dummy
val N0 = N0 dummy
val N1 = N1 dummy
val TN0 = TN0 dummy

fun unBindAnno2 data =
  let
    val ((name, anno), t) = unBindAnno data
    val name = Name2str name
  in
    ((name, anno), t)
  end

fun unBindSimp2 bind = mapFst Name2str $ unBindSimp bind
            
fun TForallIClose0 (x, t) = TForallI0 $ close0_i_t_anno (x, t)
fun TForallICloseMany (xs, b) = foldr TForallIClose0 b xs
fun TForallTimeClose0 ((x, name), t) = TForallIClose0 ((x, name, STime), t)
fun EAbsIClose (x, e) = EAbsI $ close0_i_e_anno (x, e)
fun EAbsICloseMany (xs, b) = foldr EAbsIClose b xs
fun EAbsTimeClose ((x, name), e) = EAbsIClose ((x, name, STime), e)
fun ELetConstrClose ((x, name), e1, e2) = MakeELetConstr (e1, (name, dummy), close0_c_e x e2)
fun EAppIPair (e, (i, j)) = EAppIs (e, [i, j])
  
fun Eid t = EAbs (IEmptyState, EBindAnno ((("x", dummy), t), EVar $ Bound 0), NONE)
fun EHaltFun b t_arg t_result = EAbs (IEmptyState, EBindAnno ((("x", dummy), t_arg), EHalt (b, EVar $ Bound 0, t_result)), NONE)

infix 0 %:
infix 0 |>
infix 0 |#

(* fun free_evars_expr_visitor_vtable cast (excluded, output) = *)
(*   let *)
(*     fun visit_var this env var = *)
(*       let *)
(*         val () = *)
(*             case var of *)
(*                 QID (_, (x, _)) => *)
(*                 if ISet.member (excluded, x) then () *)
(*                 else output x *)
(*               | _ => () *)
(*       in *)
(*         var *)
(*       end *)
(*   in *)
(*     default_expr_visitor_vtable *)
(*       cast *)
(*       extend_noop *)
(*       extend_noop *)
(*       extend_noop *)
(*       extend_noop *)
(*       visit_var *)
(*       visit_noop *)
(*       visit_noop *)
(*       visit_noop *)
(*       visit_noop *)
(*   end *)

(* fun new_free_evars_expr_visitor params = new_expr_visitor free_evars_expr_visitor_vtable params *)

(* fun free_evars_fn excluded output b = *)
(*   let *)
(*     val visitor as (ExprVisitor vtable) = new_free_evars_expr_visitor (excluded, output) *)
(*   in *)
(*     #visit_expr vtable visitor () b *)
(*   end *)

(* fun free_vars_0 f b = *)
(*   let *)
(*     val r = ref ISet.empty *)
(*     fun output item = unop_ref (fn s => ISet.add (s, item)) r *)
(*     val _ = f output b *)
(*   in *)
(*     !r *)
(*   end *)

(* fun free_evars excluded a = free_vars_0 (free_evars_fn excluded) a *)
        
(* smart EApp that converts topmost beta-redex to ELet and creates aliases for e1 and e2 *)
(* pre: e1 and e2 must be value *)
fun EApp_alias_fun_arg (e1, e2) =
    case e1 of
        EAbs (st, bind, _) =>
        let
          val (t_x, (name_x, e_body)) = unBindAnnoName bind
          val e = MakeELet (e2 (* %: t_x *), name_x, e_body)
        in
          e
        end
      | _ =>
        let
          val e = EApp (EVar $ ID (1, dummy), EVar $ ID (0, dummy))
          val e = MakeELet (shift01_e_e e2, ("x2", dummy), e)
          val e = MakeELet (e1, ("x1", dummy), e)
        in
          e
        end
(* smart EApp that converts topmost beta-redex to ELet and creates aliases for e2 (not e1) *)
(* used for CPS of EApp and EAppI/T when the function part shouldn't be aliased because that may create a EAppI/T not followed by EApp, which CC can't handle *)
(* pre: e2 must be value *)
fun EApp_alias_arg (e1, e2) =
    case e1 of
        EAbs (st, bind, _) =>
        let
          val (t_x, (name_x, e_body)) = unBindAnnoName bind
          val e = MakeELet (e2 (* %: t_x *), name_x, e_body)
        in
          e
        end
      | _ =>
        let
          (* val () = assert_b "EApp_alias_arg" $ is_value e2 *)
          val e = MakeELet (e2, ("x", dummy), EApp (shift01_e_e e1, EVar $ ID (0, dummy)))
        in
          e
        end
        
infixr 0 %%
fun a %% b = EApp (a, b)
infixr 0 %$
fun a %$ b = EApp_alias_arg (a, b)
infixr 0 $$
fun a $$ b = EApp_alias_fun_arg (a, b)
                  
(* fun assert_and_reduce_beta e = *)
(*   case e of *)
(*       EBinOp (EBApp, EAbs bind, e2) => *)
(*       let *)
(*         val (_, e1) = unBindAnno bind *)
(*       in *)
(*         subst0_e_e e2 e1 *)
(*       end *)
(*     | _ => raise assert_fail "assert_and_reduce_beta" *)

fun assert_and_reduce_letxx e =
    let
      fun error () = raise assert_fail $ "assert_and_reduce_letxx: " ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (NONE, NONE) ([], [], [], []) e)
    in
      case e of
          ELet (e1, bind) =>
          let
            val (name_x, e2) = unBindSimpName bind
            val () = case e2 of
                         EVar (ID (x, _)) =>
                         if x = 0 then () else error ()
                       | _ => error ()
          in
            e1
          end
        | _ => error ()
    end

val whnf = fn t => whnf ([], []) t
                       
infix 6 %%+
        
(* infix 6 %%- *)
(* fun IMinus (a, b) = IBinOp (IBMinus (), a, b) *)
(* fun a %%- b = binop_pair IMinus (a, b) *)

fun blowup_time (i, j) = i %+ j
fun blowup_space (i, j) = i %+ j
fun blowup_time_space (i, j) = i %%+ j
fun blowup_time_space_t j = j
fun blowup_time_space_i j = j

fun open0_i_2i a i = unop_pair (open0_i_i a) i
fun open0_i_2it a (i, t) = (open0_i_2i a i, open0_i_t a t)
                              
(* CPS conversion on types *)
fun cps_ty_visitor_vtable cast () =
  let
    val vtable =
        default_ty_visitor_vtable
          cast
          extend_noop
          extend_noop
          visit_noop
          visit_noop
          visit_noop
          visit_noop
    fun visit_ty this env t =
      let
        (* val () = println $ "cps_t() on: " ^ (ExportPP.pp_t_to_string $ ExportPP.export_t ([], []) t) *)
        fun cps_t t = #visit_ty (cast this) this env t
        (* [[ \\a. i --> t ]] = \\a. \\j F. {F, ({F, [[t]]} --j--> void)} -- blowup_time_t(i, j) --> void *)
        fun cps_Forall (i, t) =
          let
            val t = cps_t t
            val j1 = fresh_ivar ()
            val j2 = fresh_ivar ()
            val F = fresh_ivar ()
            val j = (IV j1, IV j2)
            val t = TArrow ((IV F, t), j, Void)
            val t = TArrow ((IV F, t), i %%+ j, Void)
            val t = TForallICloseMany ([(j1, "j1", STime), (j2, "j2", SNat), (F, "F", SState)], t)
          in
            t
          end
        (* val t = whnf t *)
        val t =                                         
            case whnf t of
                TArrow ((st1, t1), i, (st2, t2)) =>
                (* [[ {st1, t1} --i--> {st2, t2} ]] = \\j F. {st1+F, [[t1]]*(st2+F, {[[t2]]} --j--> void)} -- blowup_time(i, j) --> void *)
                let
                  val t1 = cps_t t1
                  val t2 = cps_t t2
                  val j1 = fresh_ivar ()
                  val j2 = fresh_ivar ()
                  val F = fresh_ivar ()
                  val j = (IV j1, IV j2)
                  val t = TProd (t1, TArrow ((st2 %++ IV F, t2), j, Void))
                  val t = TArrow ((st1 %++ IV F, t), blowup_time_space (i, j), Void)
                in
                  TForallICloseMany ([(j1, "j1", STime), (j2, "j2", SNat), (F, "F", SState)], t)
                end
              | TQuan (Forall (), i, bind) =>
                let
                  val ((name_a, kd_a), t) = unBindAnno2 bind
                  val a = fresh_tvar ()
                  val t = open0_t_t a t
                  val t = cps_Forall (i, t)
                in
                  TForall (TN0, close0_t_t_anno ((a, name_a, kd_a), t))
                end
              | TQuanI (Forall (), bind) =>
                let
                  val ((name_a, s_a), t) = unBindAnno2 bind
                  val a = fresh_ivar ()
                  val t = open0_i_2it a t
                  val t = cps_Forall t
                in
                  TForallI0 $ close0_i_t_anno ((a, name_a, s_a), t)
                end
              | TQuan (Exists ex, _, bind) => 
                let
                  val ((name_alpha, kd_alpha), t) = unBindAnno2 bind
                  val alpha = fresh_tvar ()
                  val t = open0_t_t alpha t
                  val t = cps_t t
                  val t = close0_t_t_anno ((alpha, name_alpha, kd_alpha), t)
                in
                  TExists t
                end
              | TQuanI (Exists ex, bind) => 
                let
                  val ((name_a, s_a), (_, t)) = unBindAnno2 bind
                  val a = fresh_ivar ()
                  val t = open0_i_t a t
                  val t = cps_t t
                  val t = close0_i_t_anno ((a, name_a, s_a), t)
                in
                  TExistsI t
                end
              | TRec bind => 
                let
                  val ((name_alpha, kd_alpha), t) = unBindAnno2 bind
                  val alpha = fresh_tvar ()
                  val t = open0_t_t alpha t
                  val t = cps_t t
                  val t = close0_t_t_anno ((alpha, name_alpha, kd_alpha), t)
                in
                  TRec t
                end
              | TAbsT bind => 
                let
                  val ((name_alpha, kd_alpha), t) = unBindAnno2 bind
                  val alpha = fresh_tvar ()
                  val t = open0_t_t alpha t
                  val t = cps_t t
                  val t = close0_t_t_anno ((alpha, name_alpha, kd_alpha), t)
                in
                  TAbsT t
                end
              | TAbsI bind => 
                let
                  val ((name_a, s_a), t) = unBindAnno2 bind
                  val a = fresh_ivar ()
                  val t = open0_i_t a t
                  val t = cps_t t
                  val t = close0_i_t_anno ((a, name_a, s_a), t)
                in
                  TAbsI t
                end
              | _ => #visit_ty vtable this env t (* call super *)
        (* val () = println $ "cps_t() result: " ^ (ExportPP.pp_t_to_string $ ExportPP.export_t ([], []) t) *)
      in
        t
      end
    val vtable = override_visit_ty vtable visit_ty
  in
    vtable
  end

fun new_cps_ty_visitor a = new_ty_visitor cps_ty_visitor_vtable a
    
fun cps_t t =
  let
    val visitor as (TyVisitor vtable) = new_cps_ty_visitor ()
  in
    #visit_ty vtable visitor () t
  end

infix 6 %%+

infix 6 @%--
fun a @%-- b = ISet.difference (a, ISetU.fromList b)
        
val N : nat -> idx = INat
val T : TimeType.time -> idx = ITime
                
fun IToReal' i = IToReal (i, dummy)
fun to_real n = IToReal' $ N n
fun TN n = (to_real n, N0)

(* CPS conversion on terms *)
(* pre: ... |- k : [[t_e]] --j_k-=> unit |> 0 *)
(* the 'unit' part can be relaxed if e is a value *)
fun cps (e, t_e, F : idx) (k, j_k : idx * idx) =
  let
    (* val () = println $ "CPS on\n" ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (SOME 4, SOME 4) ([], [], [], []) e) *)
    fun simp_2i a = unop_pair Simp.simp_i a
    val j_k = simp_2i j_k
    (* val () = println $ "k: " ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (SOME 4, SOME 4) ([], [], [], []) k) *)
    (* val () = println $ sprintf "j_k: $, $\n" [ToString.str_i Gctx.empty [] $ Simp.simp_i $ fst j_k, ToString.str_i Gctx.empty [] $ Simp.simp_i $ snd j_k] *)
    val cps_with_frame = cps
    fun cps (e, t_e) (k, j_k) = cps_with_frame (e, t_e, F) (k, j_k)
    fun err () = raise Impossible $ "unknown case of cps() on: " ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (NONE, NONE) ([], [], [], []) e)
    (* EApp/EAppI/EAppT/EIte/ECase explicitly creates the continuation closure, so they are responsible for adjusting j_k by the closure-unpacking overhead. *)
    fun get_cost_adjustments (n_live_vars, _) k =
      let
        val inner = (C_Abs_Inner_BeforeCC n_live_vars, M_Abs_Inner_BeforeCC n_live_vars)
        val outer = (C_Abs_BeforeCC n_live_vars, M_Abs_BeforeCC n_live_vars)
      in
        case k of
            EAbs _ => (mapPair' to_real N inner, mapPair' to_real N outer)
          | EVar _ => (TN0, TN0)
          | _ => raise Impossible "get_cost_adjustments(): neither EAbs nor EVar"
      end
    (* [[ \\a. e |> i ]](k) = k (\\a. \\j F. \c {F}. [[e]](c)) *)
    fun cps_EAbsIT (e, (i, t_e)) =
      let
        val j1 = fresh_ivar ()
        val j2 = fresh_ivar ()
        val F = fresh_ivar ()
        val c = fresh_evar ()
        val () = assert_b_m (fn () => "is_value() on " ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (NONE, NONE) ([], [], [], []) e)) $ is_value e
        val (e, n_fvars) = assert_EAnnoFreeEVars e
        val j = (IV j1, IV j2)
        val tail_app_cost = if is_tail_call e then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val (e, _) = cps_with_frame (e, t_e, IV F) (EV c, mapPair' to_real N tail_app_cost %%+ j)
        (* val e = EAscTimeSpace (e, blowup_time_space_t j) *)
        val t_e = cps_t t_e
        val t_c = cont_type ((IV F, t_e), j)
        val e = EAbs (IV F, close0_e_e_anno ((c, "c", t_c), e), NONE)
        val e = EAbsICloseMany ([(j1, "j1", STime), (j2, "j2", SNat), (F, "F", SState)], e)
        (* val () = println $ "n_fvars = " ^ str_int n_fvars *)
        (* val () = println $ "C_Abs_BeforeCC n_fvars = " ^ str_int (C_Abs_BeforeCC n_fvars) *)
      in
        (e, mapPair' to_real N (C_Abs_BeforeCC n_fvars, M_Abs_BeforeCC n_fvars))
      end
    fun main () =
  case e of
      S.EVar x =>
      (* [[ x ]](k) = k x *)
      (k $$ EVar x, TN C_EVar %%+ j_k)
    | S.EAbs (_, bind, _) =>
      (* [[ \x {pre_st}. (e |> i) {post_st} ]](k) = k (\\j F. \(x, c) {pre_st+F}. [[e]](c) |> blowup_time(i, j))
         where blowup_time(i,j) = b(i+1)+2i+1+j, [b] is blow-up factor *)
      let
        val ((name_x, _), e) = unBindAnno2 bind
        val t_e = whnf t_e
        val ((pre_st, t_x), i, (post_st, t_e)) = assert_TArrow t_e
        val x = fresh_evar ()
        val e = open0_e_e x e
        val (e, n_fvars) = assert_EAnnoFreeEVars e
        val c = fresh_evar ()
        val j1 = fresh_ivar ()
        val j2 = fresh_ivar ()
        val F = fresh_ivar ()
        val j = (IV j1, IV j2)
        val tail_app_cost = if is_tail_call e then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val (e, _) = cps_with_frame (e, t_e, IV F) (EV c, mapPair' to_real N tail_app_cost %%+ j)
        val t_e = cps_t t_e
        val t_c = cont_type ((post_st %++ IV F, t_e), j)
        val t_x = cps_t t_x
        val e = EAbsPairCloseWithAnno (pre_st %++ IV F, (x, name_x, t_x), (c, "c", t_c), e, SOME $ i %%+ j)
        val e = EAbsICloseMany ([(j1, "j1", STime), (j2, "j2", SNat), (F, "F", SState)], e)
      in
        (k $$ e, mapPair' to_real N (C_Abs_BeforeCC n_fvars, M_Abs_BeforeCC n_fvars) %%+ j_k)
      end
    | S.EAbsT bind =>
      let
        val ((name_a, kd_a), e) = unBindAnno2 bind
        val t_e = whnf t_e
        val (_, _, i, t_e) = assert_TForall t_e
        val a = fresh_tvar ()
        val e = open0_t_e a e
        val t_e = open0_t_t a t_e
        val (e, cost) = cps_EAbsIT (e, (i, t_e))
        val e = EAbsT $ close0_t_e_anno ((a, name_a, kd_a), e)
      in
        (k $$ e, cost %%+ j_k)
      end
    | S.EAbsI bind =>
      let
        val ((name_a, s_a), e) = unBindAnno2 bind
        val t_e = whnf t_e
        val (_, _, i, t_e) = assert_TForallI t_e
        val t_e = (i, t_e)
        val a = fresh_ivar ()
        val e = open0_i_e a e
        val t_e = open0_i_2it a t_e
        val (e, cost) = cps_EAbsIT (e, t_e)
        val e = EAbsI $ close0_i_e_anno ((a, name_a, s_a), e)
      in
        (k $$ e, cost %%+ j_k)
      end
    | S.EBinOp (EBApp (), e1, e2) =>
      (* [[ e1 e2 ]](k) = [[e1]] (\x1. [[e2]] (\x2. x1 {k.j} (x2, k))) *)
      let
        val (e1, st_e1) = assert_EAscState e1
        val (e1, t_e1) = assert_EAscType e1
        val (e2, n_live_vars) = assert_EAnnoLiveVars e2
        val (e2, st_e2) = assert_EAscState e2
        val t_e1 = whnf t_e1
        val ((_, t_e2), i, _) = assert_TArrow t_e1
        val x1 = fresh_evar ()
        val x2 = fresh_evar ()
        val xk = fresh_evar ()
        val (inner, outer) = get_cost_adjustments n_live_vars k
        val j_k = inner %%+ j_k
        val e = EAppIPair (EV x1, j_k) %$ EPair (EV x2, EV xk)
        val e = ELetClose ((xk, "k", k), e)
        val t_x2 = cps_t t_e2
        val e = EAbs (st_e2 %++ F, close0_e_e_anno ((x2, "x2", t_x2), e), NONE)
        val (e, i_e) = cps (e2, t_e2) (e, mapPair' to_real N (C_App_BeforeCPS, M_App_BeforeCPS) %%+ outer %%+ i %%+ j_k)
        val t_x1 = cps_t t_e1
        val e = EAbs (st_e1 %++ F, close0_e_e_anno ((x1, "x1", t_x1), e), NONE)
      in
        cps (e1, t_e1) (e, i_e)
      end
    | S.EAppT (e, t) =>
      (* [[ e[t] ]](k) = [[e]](\x. x[t]{k.j}(k)) *)
      let
        val (e, n_live_vars) = assert_EAnnoLiveVars e
        val (e, st_e) = assert_EAscState e
        val (e, t_e) = assert_EAscType e
        val t_e = whnf t_e
        val (_, _, j, _) = assert_TForall t_e
        val x = fresh_evar ()
        val (inner, outer) = get_cost_adjustments n_live_vars k
        val j_k = inner %%+ j_k
        val c = EAppIPair (EAppT (EV x, cps_t t), j_k) %$ k
        val t_x = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((x, "x", t_x), c), NONE)
      in
        cps (e, t_e) (c, mapPair' to_real N (C_App_BeforeCC, M_App_BeforeCC) %%+ outer %%+ j %%+ j_k)
      end
    | S.EAppI (e, i) =>
      (* [[ e[i] ]](k) = [[e]](\x. x[i]{k.j}(k)) *)
      let
        val (e, n_live_vars) = assert_EAnnoLiveVars e
        val (e, st_e) = assert_EAscState e
        val (e, t_e) = assert_EAscType e
        val t_e = whnf t_e
        val (_, _, j, _) = assert_TForallI t_e
        val x = fresh_evar ()
        val (inner, outer) = get_cost_adjustments n_live_vars k
        val j_k = inner %%+ j_k
        val c = EAppIPair (EAppI (EV x, i), j_k) %$ k
        val t_x = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((x, "x", t_x), c), NONE)
      in
        cps (e, t_e) (c, mapPair' to_real N (C_App_BeforeCC, M_App_BeforeCC) %%+ outer %%+ subst0_i_2i i j %%+ j_k)
      end
    | S.ETriOp (ETIte (), e, e1, e2) =>
      (* [[ if e then e1 else e2 ]](k) = [[e]](\y. if y then [[e1]](k) else [[e2]](k)) *)
      let
        val (e, st_e) = assert_EAscState e
        val t_res = t_e
        val t_e = TBool
        val t_res = cps_t t_res
        val x_k = fresh_evar ()
        val (e2, n_live_vars) = assert_EAnnoLiveVars e2
        val (inner, outer) = get_cost_adjustments n_live_vars k
        val j_k = inner %%+ j_k
        val tail_app_cost1 = if is_tail_call e1 then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val tail_app_cost2 = if is_tail_call e2 then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val (e1, i_e1) = cps (e1, t_res) (EV x_k, mapPair' to_real N tail_app_cost1 %%+ j_k)
        val (e2, i_e2) = cps (e2, t_res) (EV x_k, mapPair' to_real N tail_app_cost2 %%+ j_k)
        val y = fresh_evar ()
        val c = ETriOp (ETIte (), EV y, e1, e2)
        val c = ELetClose ((x_k, "k", k), c)
        val t_y = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((y, "y", t_y), c), NONE)
        val i_c = mapPair' to_real N (C_Ite_BeforeCodeGen, 0) %%+ outer %%+ IMaxPair (i_e1, TN C_JUMPDEST %%+ i_e2)
      in
        cps (e, t_e) (c, i_c)
      end
    | S.EIfi (e, bind1, bind2) =>
      (* [[ ifi e (x.e1) (x.e2) ]](k) = [[e]](\y. ifi y (x. [[e1]](k)) (x. [[e2]](k))) *)
      let
        val (e, st_e) = assert_EAscState e
        val (name_x_1, e1) = unBindSimp2 bind1
        val (name_x_2, e2) = unBindSimp2 bind2
        val (e2, n_live_vars) = assert_EAnnoLiveVars e2
        val x = fresh_evar ()
        val e1 = open0_e_e x e1
        val e2 = open0_e_e x e2
        val t_res = t_e
        val (e, t_e) = assert_EAscType e
        val t_res = cps_t t_res
        val x_k = fresh_evar ()
        val (inner, outer) = get_cost_adjustments n_live_vars k
        val j_k = inner %%+ j_k
        val tail_app_cost1 = if is_tail_call e1 then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val tail_app_cost2 = if is_tail_call e2 then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val (e1, i_e1) = cps (e1, t_res) (EV x_k, mapPair' to_real N tail_app_cost1 %%+ j_k)
        val (e2, i_e2) = cps (e2, t_res) (EV x_k, mapPair' to_real N tail_app_cost2 %%+ j_k)
        val y = fresh_evar ()
        val c = EIfiClose (EV y, ((x, name_x_1), e1), ((x, name_x_2), e2))
        val c = ELetClose ((x_k, "k", k), c)
        val t_y = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((y, "y", t_y), c), NONE)
        val i_c = mapPair' to_real N (C_Ifi_BeforeCodeGen, 0) %%+ outer %%+ IMaxPair (i_e1, TN C_JUMPDEST %%+ i_e2)
      in
        cps (e, t_e) (c, i_c)
      end
    | S.ECase (e, bind1, bind2) =>
      (* [[ case e (x.e1) (x.e2) ]](k) = [[e]](\y. case y (x. [[e1]](k)) (x. [[e2]](k))) *)
      let
        val (e, st_e) = assert_EAscState e
        val (name_x_1, e1) = unBindSimp2 bind1
        val (name_x_2, e2) = unBindSimp2 bind2
        val (e2, n_live_vars) = assert_EAnnoLiveVars e2
        val x = fresh_evar ()
        val e1 = open0_e_e x e1
        val e2 = open0_e_e x e2
        val t_res = t_e
        val (e, t_e) = assert_EAscType e
        val t_res = cps_t t_res
        val x_k = fresh_evar ()
        val (inner, outer) = get_cost_adjustments n_live_vars k
        val j_k = inner %%+ j_k
        val tail_app_cost1 = if is_tail_call e1 then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val tail_app_cost2 = if is_tail_call e2 then (0, 0)
                            else (C_App_BeforeCC, M_App_BeforeCC)
        val (e1, i_e1) = cps (e1, t_res) (EV x_k, mapPair' to_real N tail_app_cost1 %%+ j_k)
        val (e2, i_e2) = cps (e2, t_res) (EV x_k, mapPair' to_real N tail_app_cost2 %%+ j_k)
        val y = fresh_evar ()
        val c = ECaseClose (EV y, ((x, name_x_1), e1), ((x, name_x_2), e2))
        val c = ELetClose ((x_k, "k", k), c)
        val t_y = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((y, "y", t_y), c), NONE)
        val i_c = mapPair' to_real N (C_Case_BeforeCodeGen, 0) %%+ outer %%+ IMaxPair (i_e1, TN C_JUMPDEST %%+ i_e2)
      in
        cps (e, t_e) (c, i_c)
      end
    | S.EConst c =>
      (* [[ c ]](k) = k c *)
      (k $$ EConst c, TN C_EConst %%+ j_k)
    | S.EDispatch ls =>
      (* [[ dispatch ]](k) = k dispatch *)
      (k $$ EDispatch ls, TN C_EConst %%+ j_k)
    (* | S.EDebugLog ls => *)
    (*   (* [[ debug_log ]](k) = k debug_log *) *)
    (*   (k $$ EDebugLog ls, TN C_EConst %%+ j_k) *)
    | S.EEnv name =>
      (* [[ msg_info ]](k) = k msg_info *)
      (k $$ EEnv name, TN (C_EEnv name) %%+ j_k)
    | S.EState x =>
      (* [[ x ]](k) = k x *)
      (k $$ EState x, TN C_EState %%+ j_k)
    | S.ENever t =>
      (* [[ never ]](k) = k(never) *)
      (k $$ ENever (cps_t t), TN C_ENever %%+ j_k)
    | S.EBuiltin (name, t) =>
      (* [[ builtin ]](k) = k(builtin) *)
      (k $$ EBuiltin (name, cps_t t), TN C_EBuiltin %%+ j_k)
    | S.ERec bind =>
      (* [[ fix x.e ]](k) = k (fix x. [[e]](id)) *)
      let
        val ((name_x, _), e) = unBindAnno2 bind
        (* val () = println $ "cps() on: " ^ name_x *)
        val x = fresh_evar ()
        val e = open0_e_e x e
        val t_x = cps_t t_e
        val () = assert_b "cps/ERec/1" $ is_value e
        val (e, i_e) = cps (e, t_e) (Eid t_x, TN0) (* CPS with id is not strictly legal, since id doesn't return unit. It's OK because e should be a value. Values can be CPSed with continuations that return non-unit. *)
        val e = assert_and_reduce_letxx e
        val (e, _) = collect_EAscTypeTime e
        val () = assert_b "cps/ERec/2" $ is_value e
        val () = case snd $ collect_EAbsIT e of
                     EAbs _ => ()
                   | _ => raise Impossible "ERec: body after CPS should be EAbsITMany (EAbs (...))"
        val e = ERec $ close0_e_e_anno ((x, name_x, t_x), e)
      in
        (k $$ e, j_k %%+ i_e)
      end
    | S.EPack (t_pack, t, e) =>
      (* [[ pack <t, e> ]](k) = [[e]](\x. k (pack <t, x>)) *)
      let
        val (e, st_e) = assert_EAscState e
        val (e, t_e) = assert_EAscType e
        val x = fresh_evar ()
        val t_pack = cps_t t_pack
        val t = cps_t t
        val c = EPack (t_pack, t, EV x)
        val c = k $$ c
        val t_x = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((x, "x", t_x), c), NONE)
      in
        cps (e, t_e) (c, TN C_EPack %%+ j_k)
      end
    | S.EPackI (t_pack, i, e) =>
      (* [[ packI <i, e> ]](k) = [[e]](\x. k (packI <i, x>)) *)
      let
        val (e, st_e) = assert_EAscState e
        val (e, t_e) = assert_EAscType e
        val x = fresh_evar ()
        val t_pack = cps_t t_pack
        val c = EPackI (t_pack, i, EV x)
        val c = k $$ c
        val t_x = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((x, "x", t_x), c), NONE)
      in
        cps (e, t_e) (c, TN C_EPack %%+ j_k)
      end
    | S.EUnpack (e1, bind) =>
      (* [[ unpack e1 as <alpha, x> in e2 ]](k) = [[e1]](\x1. unpack x1 as <alpha, x> in [[e2]](k)) *)
      let
        val (e1, st_e1) = assert_EAscState e1
        val (e1, t_e1) = assert_EAscType e1
        val (name_alpha, e2) = unBindSimp2 bind
        val (name_x, e2) = unBindSimp2 e2
        val alpha = fresh_tvar ()
        val x = fresh_evar ()
        val e2 = open0_t_e alpha e2
        val e2 = open0_e_e x e2
        val x1 = fresh_evar ()
        val t_e2 = t_e
        val (c, i_c) = cps (e2, t_e2) (k, j_k)
        val c = EUnpackClose (EV x1, (alpha, name_alpha), (x, name_x), c)
        val t_x1 = cps_t t_e1
        val c = EAbs (st_e1 %++ F, close0_e_e_anno ((x1, "x1", t_x1), c), NONE)
      in
        cps (e1, t_e1) (c, TN C_EUnpack %%+ i_c)
      end
    | S.EUnpackI (e1, bind) =>
      (* [[ unpackI e1 as <a, x> in e2 ]](k) = [[e1]](\x1. unpack x1 as <a, x> in [[e2]](k)) *)
      let
        val (e1, st_e1) = assert_EAscState e1
        val (e1, t_e1) = assert_EAscType e1
        val (name_a, e2) = unBindSimp2 bind
        val (name_x, e2) = unBindSimp2 e2
        val a = fresh_ivar ()
        val x = fresh_evar ()
        val e2 = open0_i_e a e2
        val e2 = open0_e_e x e2
        val x1 = fresh_evar ()
        val t_e2 = t_e
        val (c, i_c) = cps (e2, t_e2) (k, j_k)
        val c = EUnpackIClose (EV x1, (a, name_a), (x, name_x), c)
        val t_x1 = cps_t t_e1
        val c = EAbs (st_e1 %++ F, close0_e_e_anno ((x1, "x1", t_x1), c), NONE)
      in
        cps (e1, t_e1) (c, TN C_EUnpack %%+ i_c)
      end
    | S.ETuple es =>
      let
        val ts = assert_TTuple t_e
        val ets = zip (es, ts)
        val xs_names_es = mapi (fn (i, (e, t)) => (fresh_evar (), "x" ^ str_int (i+1), assert_EAscState e, t)) ets
        val xs = map #1 xs_names_es
        val ek = k $$ ETuple (map EV xs)
        fun f ((x, name, (e, st_e), t), (ek, i_ek)) =
            let
              val t_x = cps_t t
              val ek = EAbs (st_e %++ F, close0_e_e_anno ((x, name, t_x), ek), NONE)
            in
              cps (e, t) (ek, i_ek)
            end
        val len = length es
      in
        foldr f (ek, (to_real $ C_ETuple len, N $ 32 * len) %%+ j_k) xs_names_es
      end
    | S.ERecord fields =>
      let
        val t_fields = assert_TRecord t_e
        val () = assert_b "cps/ERecord/is_same_domain()" $ SMapU.is_same_domain fields t_fields
        val fields = sort cmp_str_fst $ SMap.listItemsi fields
        val (names, es) = unzip fields
        val t_fields = sort cmp_str_fst $ SMap.listItemsi t_fields
        val (_, ts) = unzip t_fields
        val ets = zip (es, ts)
        val xs_names_es = map (fn (name, (e, t)) => (fresh_evar (), name, assert_EAscState e, t)) $ zip (names, ets)
        val xs = map #1 xs_names_es
        val ek = k $$ ERecord (SMapU.fromList $ zip (names, map EV xs))
        fun f ((x, name, (e, st_e), t), (ek, i_ek)) =
            let
              val t_x = cps_t t
              val ek = EAbs (st_e %++ F, close0_e_e_anno ((x, name, t_x), ek), NONE)
            in
              cps (e, t) (ek, i_ek)
            end
        val len = length es
      in
        foldr f (ek, (to_real $ C_ETuple len, N $ 32 * len) %%+ j_k) xs_names_es
      end
    | S.EBinOp (opr, e1, e2) =>
      (* [[ e1 o e2 ]](k) = [[e1]] (\x1. [[e2]] (\x2. k (x1 o x2))) *)
      let
        val (e1, st_e1) = assert_EAscState e1
        val (e2, st_e2) = assert_EAscState e2
        fun get_comp_types (e1, e2) t_e =
          (* case opr of *)
          (*     EBPair () => ((e1, e2), assert_TProd t_e) *)
          (*   | _ => *)
              let
                val (e1, t_e1) = assert_EAscType e1
                val (e2, t_e2) = assert_EAscType e2
              in
                ((e1, e2), (t_e1, t_e2))
              end
        val t_e = whnf t_e
        val ((e1, e2), (t_e1, t_e2)) = get_comp_types (e1, e2) t_e
        val x1 = fresh_evar ()
        val x2 = fresh_evar ()
        val t_x1 = cps_t t_e1
        val t_x2 = cps_t t_e2
        val e = k $$ EBinOp (opr, EV x1, EV x2)
        val e = EAbs (st_e2 %++ F, close0_e_e_anno ((x2, "x2", t_x2), e), NONE)
        val cost =
            case opr of
                EBPrim opr => (N $ C_EBPrim opr, N 0)
              | EBNatCmp opr => (N $ C_ENatCmp opr, N 0)
              | EBiBool opr => (N $ C_EiBool opr, N 0)
              | EBNat (EBNExp ()) =>
                let
                  val i2 = assert_TNat t_e2
                in
                  (E_nat_exp_cost i2, N 0)
                end
              | EBNat opr => (N $ C_ENat opr, N 0)
              | EBApp () => raise Impossible "cps/BinOp/App"
              | EBNew w =>
                let
                  val len = assert_TNat t_e1
                in
                  (N C_ENew_order0 %+ N (C_ENew_order1 w) %* len, len %* N w %+ N 32)
                end
              | EBIntNatExp () =>
                let
                  val i2 = assert_TNat t_e2
                in
                  (E_nat_exp_cost i2, N 0)
                end
              | EBRead w => (N $ C_ERead w, N 0)
              | EBVectorGet () => (N C_EVectorGet, N 0)
              | EBVectorPushBack () => (N C_EVectorPushBack, N 0)
              | EBMapPtr () => (N C_EMapPtr, N 0)
              | EBStorageSet () => (N C_EStorageSet, N 0)
              | EBNatCellSet () =>
                let
                  fun get_nat_cell st t1 =
                    let
                      val x = assert_TState t1 
                      infix  9 @%!!
                      val i = st @%!! x
                    in
                      (x, i)
                    end
                  val (x, old) = get_nat_cell st_e2 t_e1
                  val new = assert_TNat_m t_e2 (fn s => raise Impossible $ "cps/ENetCellSet: " ^ s)
                  val store_cost = set_cost old new
                in
                  (N C_ENatCellSet %+ store_cost, N 0)
                end
        val (e, i_e) = cps (e2, t_e2) (e, mapFst IToReal' cost %%+ j_k) 
        val e = EAbs (st_e1 %++ F, close0_e_e_anno ((x1, "x1", t_x1), e), NONE)
      in
        cps (e1, t_e1) (e, i_e)
      end
    | S.ENewArrayValues (w, t, es) =>
      let
        val t_x = cps_t t
        val xs_names_es = mapi (fn (i, e) => (fresh_evar (), "x" ^ str_int (i+1), assert_EAscState e)) es
        val xs = map (fn (x, _, _) => x) xs_names_es
        val ek = k $$ ENewArrayValues (w, t_x, map EV xs)
        fun f ((x, name, (e, st_e)), (ek, i_ek)) =
          let
            val ek = EAbs (st_e %++ F, close0_e_e_anno ((x, name, t_x), ek), NONE)
          in
            cps (e, t) (ek, i_ek)
          end
        val len = length es
      in
        foldr f (ek, (to_real $ C_ENewArrayValues w len, N $ w * len + 32) %%+ j_k) xs_names_es
      end
    | S.EHalt (b, e, _) =>
      (* [[ halt e [_] ]](k) = [[e]](\x. halt x [unit]) *)
      let
        val (e, st_e) = assert_EAscState e
        val (e, t_e) = assert_EAscType e
        val x = fresh_evar ()
        val c = (* k $$  *)EHalt (b, EV x, TUnit)
        val t_x = cps_t t_e
        val c = EAbs (st_e %++ F, close0_e_e_anno ((x, "x", t_x), c), NONE)
      in
        cps (e, t_e) (c, TN C_EHalt (* %%+ j_k *))
      end
    | S.EUnOp (EUTiML (EUAnno _), e) => cps (e, t_e) (k, j_k)
    | S.EUnOp (opr, e) =>
      (* [[ opr e ]](k) = [[e]](\x. k (opr x)) *)
      let
        val (e, st_e) = assert_EAscState e
        fun cps_EUnOp t_e f =
          let
            val x = fresh_evar ()
            val c = k $$ f x
            val t_x = cps_t t_e
            val c = EAbs (st_e %++ F, close0_e_e_anno ((x, "x", t_x), c), NONE)
            val cost =
                case opr of
                    EUInj _ => (C_EInj, M_Inj)
                  | EUFold _ => (C_EFold, 0)
                  | EUUnfold _ => (C_EUnfold, 0)
                  | EUTiML opr =>
                    (case opr of
                         EUProj _ => (C_EProj, 0)
                       | EUField _ => (C_EProj, 0)
                       | EUPtrProj _ => (C_EPtrProj, 0)
                       | EUPrim opr => (C_EUPrim opr, 0)
                       | EUArrayLen _ => (C_EArrayLen, 0)
                       | EUiBoolNeg _ => (C_EiBoolNeg, 0)
                       | EUNat2Int _ => (C_ENat2Int, 0)
                       | EUInt2Nat _ => (C_EInt2Nat, 0)
                       | EUPrintc _ => (C_EPrintc, 0)
                       | EUDebugLog _ => (C_EConst, 0)
                       | EUStorageGet _ => (C_EStorageGet, 0)
                       | EUNatCellGet _ => (C_ENatCellGet, 0)
                       | EUVectorClear _ => (C_EVectorClear, 0)
                       | EUVectorLen _ => (C_EVectorLen, 0)
                       | EUAnno _ => raise Impossible "cps()/EUnOp/EUAnno"
                    )
                  (* | EUTupleProj _ => (C_EProj, 0) *)
          in
            cps (e, t_e) (c, mapPair' to_real N cost %%+ j_k)
          end
        val (t_e, opr) = 
            case opr of
                EUInj (inj, t_other) =>
                let
                  val t_e = whnf t_e
                  val t1_t2 = assert_TSum t_e
                  val t_e = choose_inj t1_t2 inj
                  val t_other = cps_t t_other
                in
                  (t_e, EUInj (inj, t_other))
                end
              | EUFold t_fold =>
                let
                  val (e, t_e) = assert_EAscType e
                in
                  (t_e, EUFold $ cps_t t_fold)
                end
              | EUTiML (EUPrintc ()) =>
                (TByte, opr)
              (* | EUTiML EUPrint => *)
              (*   (TString, opr) *)
              (* | EUTiML EUInt2Str => *)
              (*   (TInt, opr) *)
              | EUTiML (EUInt2Nat ()) =>
                (TInt, opr)
              | _ =>
                let
                  val (e, t_e) = assert_EAscType e
                in
                  (t_e, opr)
                end
      in
        cps_EUnOp t_e (fn x => EUnOp (opr, EV x))
      end
    | S.ELet (e1, bind) =>
      (* [[ let x = e1 in e2 ]](k) = [[e1]](\x. [[e2]](k)) *)
      let
        val (e1, st_e1) = assert_EAscState e1
        val (e1, t_e1) = assert_EAscType e1
        val t_res = t_e
        val (name_x, e2) = unBindSimp2 bind
        val x = fresh_evar ()
        val e2 = open0_e_e x e2
        val (c, i_c) = cps (e2, t_res) (k, j_k)
        val t_x = cps_t t_e1
        val c = EAbs (st_e1 %++ F, close0_e_e_anno ((x, name_x, t_x), c), NONE)
      in
        cps (e1, t_e1) (c, i_c)
      end
    | S.EAscType (e, t) =>
      (* let *)
      (*   val x = fresh_evar () *)
      (*   val t = cps_t t *)
      (*   val t_x = cps_t t_e *)
      (*   val k = k $$ (EV x %: t) *)
      (*   val k = EAbs $ close0_e_e_anno ((x, "x", t_x), k) *)
      (* in *)
      (*   cps (e, t) (k, j_k) *)
      (* end *)
      cps (e, t) (k, j_k)  (* todo: may need to do more *)
    | S.EAscTime (e, i) =>
      let
        val (e, (i', j)) = cps (e, t_e) (k, j_k)
        val i = blowup_time (i, fst j_k)
      in
        (e |> i, (i, j))
      end
    | S.EAscSpace (e, i) =>
      let
        val (e, (j, i')) = cps (e, t_e) (k, j_k)
        val i = blowup_space (i, snd j_k)
      in
        (e |# i, (j, i))
      end
    | S.EAscState (e, _) =>
      cps (e, t_e) (k, j_k)
    | S.ETriOp (opr, e1, e2, e3) =>
      (* [[ opr e1 e2 e3 ]](k) = [[e1]] (\x1. [[e2]] (\x2. [[e3]] (\x3. k (opr x1 x2 x3)))) *)
      let
        val (e1, st_e1) = assert_EAscState e1
        val (e1, t_e1) = assert_EAscType e1
        val (e2, st_e2) = assert_EAscState e2
        val (e2, t_e2) = assert_EAscType e2
        val (e3, st_e3) = assert_EAscState e3
        val (e3, t_e3) = assert_EAscType e3
        val x1 = fresh_evar ()
        val x2 = fresh_evar ()
        val x3 = fresh_evar ()
        val t_x1 = cps_t t_e1
        val t_x2 = cps_t t_e2
        val t_x3 = cps_t t_e3
        val e = k $$ ETriOp (opr, EV x1, EV x2, EV x3)
        val e = EAbs (st_e1 %++ F, close0_e_e_anno ((x3, "x3", t_x3), e), NONE)
        val cost =
            case opr of
                ETWrite w => C_EWrite w
              | ETIte _ => raise Impossible "cps()/ETriOp/Ite"
              | ETVectorSet _ => C_EVectorSet
        val (e, i_e) = cps (e3, t_e3) (e, TN cost %%+ j_k)
        val e = EAbs (st_e2 %++ F, close0_e_e_anno ((x2, "x2", t_x2), e), NONE)
        val (e, i_e) = cps (e2, t_e2) (e, i_e)
        val e = EAbs (st_e3 %++ F, close0_e_e_anno ((x1, "x1", t_x1), e), NONE)
      in
        cps (e1, t_e1) (e, i_e)
      end
    (* | S.ELetConstr (e1, bind) => *)
    (*   (* [[ let constr x = e1 in e2 ]](k) = [[e1]](\y. let constr x = y in [[e2]](k)) *) *)
    (*   let *)
    (*     val (e1, t_e1) = assert_EAscType e1 *)
    (*     val t_res = t_e *)
    (*     val (name_x, e2) = unBindSimp2 bind *)
    (*     val x = fresh_cvar () *)
    (*     val e2 = open0_c_e x e2 *)
    (*     val (c, i_c) = cps (e2, t_res) (k, j_k) *)
    (*     val y = fresh_evar () *)
    (*     val c = ELetConstrClose ((x, name_x), EV y, c) *)
    (*     val t_y = cps_t t_e1 *)
    (*     val c = EAbs $ close0_e_e_anno ((y, "y", t_y), c) *)
    (*   in *)
    (*     cps (e1, t_e1) (c, i_c) *)
    (*   end *)
    | S.ELetIdx _ => err ()
    | S.ELetType _ => err ()
    | S.ELetConstr _ => err ()
    | S.EAbsConstr _ => err ()
    | S.EAppConstr _ => err ()
    | S.EVarConstr _ => err ()
    | S.EPackIs _ => err ()
    | S.EMatchSum _ => err ()
    (* | S.EMatchPair _ => err () *)
    | S.EMatchTuple _ => err ()
    | S.EMatchUnfold _ => err ()
    (* | S.EMallocPair _ => err () *)
    (* | S.EPairAssign _ => err () *)
    (* | S.EProjProtected _ => err () *)
    fun extra_msg () = "\nwhen cps-ing:\n" ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (SOME 1, SOME 5) ([], [], [], []) e)
    val ret = main ()
              handle Impossible m => raise Impossible (m ^ extra_msg ())
  in
    ret
  end

val debug_dir_name = ref (NONE : string option)
fun debug_write_file filename s =
  case !debug_dir_name of
      SOME dirname => write_file (join_dir_file' dirname filename, s)
    | NONE => ()
  
val cps = fn (e, t_e, F) => fn (k, j_k) =>
             let
               val (e, _) = MicroTiMLLiveVars.live_vars e
               val () = debug_write_file
                          "debug-before-cps-after-live-vars.tmp" $
                          ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (NONE, NONE) ToStringUtil.empty_ctx e
               val e = set_is_rec false e
               val e = set_free_evars e
               val (e, i) = cps (e, t_e, F) (k, j_k)
               val e = ExportPP.uniquefy_e ToStringUtil.empty_ctx $ MicroTiMLPostProcess.post_process e
             in
               (e, i)
             end
                        
val cps_tc_flags =
    let
      open MicroTiMLTypecheck
    in
      [Anno_EApp, Anno_EAppT, Anno_EAppI, Anno_EFold, Anno_EUnfold, Anno_EPack, Anno_EPackI, Anno_EUnpack, Anno_EUnpackI, Anno_EBPrim, Anno_ENew, Anno_ERead, Anno_ENat, Anno_ENatCmp, Anno_EProj, Anno_ECase, Anno_ELet, Anno_EWrite, Anno_EHalt,
       
Anno_ENatCellGet,
Anno_ENatCellGet_state,
Anno_ENatCellSet,
Anno_ENatCellSet_state,
Anno_EPtrProj,
Anno_EPtrProj_state,
Anno_EDebugLog,
Anno_EDebugLog_state,
                                 
       Anno_EIfi,
       Anno_EVectorSet,
       Anno_EMapPtr,
       Anno_EVectorGet,
       Anno_EVectorPushBack,
       Anno_EStorageSet,
       Anno_EUPrim,
       Anno_EArrayLen,
       Anno_ENat2Int,
       Anno_EStorageGet,
       Anno_EProj_state,
       Anno_EPrintc_state,
       Anno_EUPrim_state,
       Anno_EArrayLen_state,
       Anno_ENat2Int_state,
       Anno_EInt2Nat_state,
       Anno_EStorageGet_state,
       Anno_EInj_state,
       Anno_EFold_state,
       Anno_EUnfold_state,
       Anno_EApp_state,
       Anno_EPair_state,
       Anno_EBPrim_state,
       Anno_ENew_state,
       Anno_ERead_state,
       Anno_EMapPtr_state,
       Anno_EVectorGet_state,
       Anno_EVectorPushBack_state,
       Anno_EVectorSet_state,
       Anno_EStorageSet_state,
       Anno_ENat_state,
       Anno_ENatCmp_state,
       Anno_EWrite_state,
       Anno_ECase_state,
       Anno_EIte_state,
       Anno_EIfi_state,
       Anno_EAppT_state,
       Anno_EAppI_state,
       Anno_EPack_state,
       Anno_EPackI_state,
       Anno_EUnpack_state,
       Anno_EUnpackI_state,
       Anno_ELet_state,
       Anno_ENewArrayValues_state,
       Anno_EVectorLen,
       Anno_EVectorClear,
       Anno_EVectorLen_state,
       Anno_EVectorClear_state,
       Anno_EHalt_state
      ]
    end
                     
(* Checks the form invariants after CPS, according to the 'System F to TAL' paper. *)
      
fun check_CPSed_ty_visitor_vtable cast () =
  let
    val vtable = 
        default_ty_visitor_vtable
          cast
          extend_noop
          extend_noop
          visit_noop
          visit_noop
          visit_noop
          visit_noop
    fun visit_TQuanI this env (data as (q, _)) =
      case q of
          Forall () =>
          let
            val (binds, t) = collect_TForallIT $ TQuanI data
            val _ = assert_TArrow t
            val _ = #visit_ty (cast this) this env t
          in
            TQuanI data
          end
        | _ => #visit_TQuanI vtable this env data (* call super *)
    fun visit_TQuan this env (data as (q, _, _)) =
      case q of
          Forall () =>
          let
            val (binds, t) = collect_TForallIT $ TQuan data
            val _ = assert_TArrow t
            val _ = #visit_ty (cast this) this env t
          in
            TQuan data
          end
        | _ => #visit_TQuan vtable this env data (* call super *)
    fun visit_TArrow this env (data as ((_, t1), i, (_, t2))) =
      let
        val _ = #visit_ty (cast this) this env t1
        val () = assert_TUnit "check_CPSed_type(): result type of TArrow must be TUnit" t2
      in
        TArrow data
      end
    val vtable = override_visit_TQuanI vtable visit_TQuanI
    val vtable = override_visit_TQuan vtable visit_TQuan
    val vtable = override_visit_TArrow vtable visit_TArrow
  in
    vtable
  end

fun new_check_CPSed_ty_visitor a = new_ty_visitor check_CPSed_ty_visitor_vtable a
    
fun check_CPSed_type b =
  let
    val visitor as (TyVisitor vtable) = new_check_CPSed_ty_visitor ()
  in
    #visit_ty vtable visitor () b
  end
    
fun check_CPSed_type_expr_visitor_vtable cast () =
  default_expr_visitor_vtable
    cast
    extend_noop
    extend_noop
    extend_noop
    extend_noop
    visit_noop
    visit_noop
    visit_noop
    visit_noop
    visit_noop
    (ignore_this_env check_CPSed_type)

fun new_check_CPSed_type_expr_visitor params = new_expr_visitor check_CPSed_type_expr_visitor_vtable params

fun check_CPSed_type_e b =
  let
    val visitor as (ExprVisitor vtable) = new_check_CPSed_type_expr_visitor ()
  in
    ignore $ #visit_expr vtable visitor () b
  end

fun check_CPSed_expr e =
  let
    val loop = check_CPSed_expr
    fun err () = raise Impossible $ "check_CPSed_expr():\n" ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (NONE, NONE) ([], [], [], []) e)

  in
  case fst $ collect_EAscType e of
      ELet (e1, bind) =>
      let
        val () = check_decl e1
        val (_, e2) = unBind bind
      in
        loop e2
      end
    | EUnpack (e1, bind) =>
      let
        val () = check_value e1
        val (_, bind) = unBind bind
        val (_, e2) = unBind bind
      in
        loop e2
      end
    | EUnpackI (e1, bind) =>
      let
        val () = check_value e1
        val (_, bind) = unBind bind
        val (_, e2) = unBind bind
      in
        loop e2
      end
    | EBinOp (EBApp (), e1, e2) =>
      (check_value e1;
       check_value e2)
    | ECase (e, bind1, bind2) =>
      let
        val () = check_value e
        val (_, e1) = unBind bind1
        val (_, e2) = unBind bind2
      in
        (loop e1;
         loop e2)
      end
    | EIfi (e, bind1, bind2) =>
      let
        val () = check_value e
        val (_, e1) = unBind bind1
        val (_, e2) = unBind bind2
      in
        (loop e1;
         loop e2)
      end
    | ETriOp (ETIte (), e, e1, e2) =>
      let
        val () = check_value e
      in
        (loop e1;
         loop e2)
      end
    | EHalt (_, e, _) => check_value e
    | EAscTime (e, _) => loop e
    | EAscSpace (e, _) => loop e
    (* | EBinOp (EBPair (), _, _) => err () *)
    | ETuple _ => err ()
    | ERecord _ => err ()
    | EBinOp (EBNew _, _, _) => err ()
    | EBinOp (EBRead _, _, _) => err ()
    | EBinOp (EBPrim _, _, _) => err ()
    | EBinOp (EBiBool _, _, _) => err ()
    | EBinOp (EBNat _, _, _) => err ()
    | EBinOp (EBNatCmp _, _, _) => err ()
    | EBinOp (EBIntNatExp _, _, _) => err ()
    | EBinOp (EBVectorGet (), _, _) => err ()
    | EBinOp (EBVectorPushBack (), _, _) => err ()
    | EBinOp (EBMapPtr (), _, _) => err ()
    | EBinOp (EBStorageSet (), _, _) => err ()
    | EBinOp (EBNatCellSet (), _, _) => err ()
    | ETriOp (ETWrite _, _, _, _) => err ()
    | ETriOp (ETVectorSet (), _, _, _) => err ()
    | EVar _ => err ()
    | EConst _ => err ()
    | EDispatch _ => err () (* pretend to be an EConst *)
    (* | EDebugLog _ => err () (* pretend to be an EConst *) *)
    | EEnv _ => err ()
    | EState _ => err ()
    | EUnOp _ => err ()
    | EAbs _ => err ()
    | ERec _ => err ()
    | EAbsT _ => err ()
    | EAppT _ => err ()
    | EAbsI _ => err ()
    | EAppI _ => err ()
    | EPack _ => err ()
    | EPackI _ => err ()
    | EAscType _ => err ()
    | EAscState _ => err ()
    | ENever _ => err ()
    | EBuiltin _ => err ()
    | ENewArrayValues _ => err ()
    | ELetIdx _ => err ()
    | ELetType _ => err ()
    | ELetConstr _ => err ()
    | EAbsConstr _ => err ()
    | EAppConstr _ => err ()
    | EVarConstr _ => err ()
    | EPackIs _ => err ()
    | EMatchSum _ => err ()
    (* | EMatchPair _ => err () *)
    | EMatchTuple _ => err ()
    | EMatchUnfold _ => err ()
    (* | EMallocPair _ => err () *)
    (* | EPairAssign _ => err () *)
    (* | EProjProtected _ => err () *)
  end

and check_decl e =
    case fst $ collect_EAscType e of
        EUnOp (_, e) => check_value e
      | EBinOp (opr, e1, e2) =>
        (assert_b "check_decl/EBinOp/opr <> EBApp" $ opr <> EBApp ();
         check_value e1;
         check_value e2)
      | ETriOp (ETWrite _, e1, e2, e3) =>
        (check_value e1;
         check_value e2;
         check_value e3)
      | ENewArrayValues (_, t, es) => app check_value es
      (* | EMallocPair _ => () *)
      (* | EPairAssign (e1, _, e2) => *)
      (*   (check_value e1; *)
      (*    check_value e2) *)
      (* | EProjProtected (_, e) => check_value e *)
      | _ => check_value e
             handle Impossible msg =>
                    raise Impossible $ "check_decl():\n" ^ msg
        
and check_value e =
    let
      fun err () = raise Impossible $ "check_value():\n" ^ (ExportPP.pp_e_to_string (NONE, NONE) $ ExportPP.export (NONE, NONE) ([], [], [], []) e)

    in
  case e of
      EConst _ => ()
    | EDispatch _ => () (* pretend to be an EConst *)
    (* | EDebugLog _ => () (* pretend to be an EConst *) *)
    | EState _ => ()
    | EEnv _ => ()
    (* | EBinOp (EBPair (), e1, e2) => (check_value e1; check_value e2) *)
    | ETuple es => app check_value es
    | ERecord fields => SMap.app check_value fields
    | EUnOp (EUInj _, e) => check_value e
    | EUnOp (EUTiML opr, _) =>
      (case opr of
           EUProj _ => err ()
         | EUField _ => err ()
         | EUPtrProj _ => err ()
         | EUArrayLen () => err ()
         | EUPrim _ => err ()
         | EUiBoolNeg () => err ()
         | EUNat2Int () => err ()
         | EUInt2Nat () => err ()
         | EUPrintc () => err ()
         | EUDebugLog _ => () (* pretend to be an EConst *)
         | EUStorageGet () => err ()
         | EUNatCellGet () => err ()
         | EUVectorClear () => err ()
         | EUVectorLen () => err ()
         | EUAnno _ => check_value e
      )
    | EAbs (_, bind, _) =>
      let
        val (_, e) = unBindAnno bind
      in
        check_CPSed_expr e
      end
    | EAbsT bind => 
      let
        val (_, e) = unBindAnno bind
      in
        check_value e
      end
    | EAbsI bind => 
      let
        val (_, e) = unBindAnno bind
      in
        check_value e
      end
    | EPack (_, _, e) => check_value e
    | EPackI (_, _, e) => check_value e
    | EPackIs (_, _, e) => check_value e
    | EUnOp (EUFold _, e) => check_value e
    | EAscType (e, _) => check_value e
    | EAscState (e, _) => check_value e
    | EAppT (e, _) => check_value e
    | EAppI (e, _) => check_value e
    | ERec data =>
      let
        val (_, e) = unBindAnno data
      in
        check_value e
      end
    | EVar _ => () (* variables denote values *)
    | ENever _ => ()
    | EBuiltin _ => ()
    | EUnOp (EUUnfold (), _) => err ()
    (* | EUnOp (EUTupleProj _, _) => err () *)
    | EBinOp (EBApp (), _, _) => err ()
    | EBinOp (EBNew _, _, _) => err ()
    | EBinOp (EBRead _, _, _) => err ()
    | EBinOp (EBPrim _, _, _) => err ()
    | EBinOp (EBiBool _, _, _) => err ()
    | EBinOp (EBNat _, _, _) => err ()
    | EBinOp (EBNatCmp _, _, _) => err ()
    | EBinOp (EBIntNatExp _, _, _) => err ()
    | EBinOp (EBVectorGet (), _, _) => err ()
    | EBinOp (EBVectorPushBack (), _, _) => err ()
    | EBinOp (EBMapPtr (), _, _) => err ()
    | EBinOp (EBStorageSet (), _, _) => err ()
    | EBinOp (EBNatCellSet (), _, _) => err ()
    | ETriOp _ => err ()
    | ECase _ => err ()
    | EUnpack _ => err ()
    | EUnpackI _ => err ()
    | EAscTime _ => err ()
    | EAscSpace _ => err ()
    | ELet _ => err ()
    | ENewArrayValues _ => err ()
    | ELetIdx _ => err ()
    | ELetType _ => err ()
    | ELetConstr _ => err ()
    | EAbsConstr _ => err ()
    | EAppConstr _ => err ()
    | EVarConstr _ => err ()
    | EMatchSum _ => err ()
    (* | EMatchPair _ => err () *)
    | EMatchTuple _ => err ()
    | EMatchUnfold _ => err ()
    | EIfi _ => err ()
    | EHalt _ => err ()
    (* | EMallocPair _ => err () *)
    (* | EPairAssign _ => err () *)
    (* | EProjProtected _ => err () *)
    end

val check_CPSed_expr = fn e => (check_CPSed_type_e e; check_CPSed_expr e)
                              
structure UnitTest = struct

structure TestUtil = struct

open LongId
open Util
open MicroTiML
open MicroTiMLVisitor
open MicroTiMLLongId
open MicroTiML
       
fun fail () = OS.Process.exit OS.Process.failure
                   
end

open TestUtil

infixr 0 $
infixr 0 !!
         
fun test1 dirname =
  let
    val () = println "CPS.UnitTest started"
    val filename = join_dir_file (dirname, "cps-test1.pkg")
    val filenames = map snd $ ParseFilename.expand_pkg (fn msg => raise Impossible msg) (true, filename)
    open Parser
    val prog = concatMap parse_file filenames
    open Elaborate
    val prog = elaborate_prog prog
    open NameResolve
    val (prog, _, _) = resolve_prog empty prog
                                    
    open TypeCheck
    val () = TypeCheck.turn_on_builtin ()
    val () = println "Started TiML typechecking ..."
    val () = TypeCheck.clear_st_types ()
    val ((prog, _, _), (vcs, admits)) = typecheck_prog empty prog
    val st_types = fst $ TypeCheck.get_st_types ()
    val vcs = VCSolver.vc_solver filename vcs
    val () = if null vcs then ()
             else
               raise curry TypeCheck.Error dummy $ (* str_error "Error" filename dummy *) [sprintf "Typecheck Error: $ Unproved obligations:" [str_int $ length vcs], ""] @ (
               (* concatMap (fn vc => str_vc true filename vc @ [""]) $ map fst vcs *)
               concatMap (VCSolver.print_unsat true filename) vcs
             )
    val () = println "Finished TiML typechecking"
                     
    open MergeModules
    val decls = merge_prog prog []
    open TiML2MicroTiML
    val e = SMakeELet (Teles decls, Expr.ETT dummy)
    val () = println "Simplifying ..."
    val e = SimpExpr.simp_e [] e
    val () = println "Finished simplifying"
    val empty_ctx = ToStringUtil.empty_ctx
    (* val () = println $ str_e empty empty_ctx e *)
    (* val () = println "" *)
    val () = println "Started translating ..."
    val e = trans_e e
    val st_types = StMap.map trans_mt st_types
    val () = println "Finished translating"
    (* val () = pp_e $ export empty_ctx e *)
    (* val () = println "" *)
                     
    open MicroTiMLTypecheck
    open TestUtil
    val () = println "Started MicroTiML typechecking #1 ..."
    val ((e, t, i, st), (vcs, admits)) = typecheck (cps_tc_flags, st_types) (([], [], []), IEmptyState) e
    val () = println "Finished MicroTiML typechecking #1"
    val () = println "Type:"
    open ExportPP
    val () = pp_t NONE $ export_t NONE ([], []) t
    fun print_time_space (i, j) =
        let
          val () = println "Time:"
          val () = println $ ToString.str_i Gctx.empty [] $ simp_i i
          val () = println "Space:"
          val () = println $ ToString.str_i Gctx.empty [] $ simp_i j
        in
          ()
        end
    val () = print_time_space i
    (* val () = println $ "#VCs: " ^ str_int (length vcs) *)
    (* val () = println "VCs:" *)
    (* val () = app println $ concatMap (fn ls => ls @ [""]) $ map (str_vc false "") vcs *)
    val () = pp_e (NONE, NONE) $ export (NONE, NONE) empty_ctx e
    val () = println ""
                     
    val () = println "Started CPS conversion ..."
    open MicroTiMLUtil
    val (e, _) = cps (e, TUnit, IEmptyState) (EHaltFun true TUnit TUnit, TN0)
    (* val (e, _) = cps (e, TUnit) (Eid TUnit, T_0) *)
    val () = println "Finished CPS conversion ..."
    val () = pp_e (NONE, NONE) $ export (NONE, NONE) empty_ctx e
    val () = println ""
    val () = println "Started post-CPS form checking"
    val () = check_CPSed_expr e
    val () = println "Finished post-CPS form checking"
    val () = println "Started MicroTiML typechecking #2 ..."
    val ((e, t, i, st), (vcs, admits)) = typecheck ([], st_types) (([], [], []), IEmptyState) e
    val () = println "Finished MicroTiML typechecking #2"
    val () = println "Type:"
    val () = pp_t NONE $ export_t NONE ([], []) t
    val () = print_time_space i
    val () = println "CPS.UnitTest passed"
  in
    ((* t, e *))
  end
  handle MicroTiMLTypecheck.MTCError msg => (println $ "MTiMLTC.MTCError: " ^ substr 0 1000 msg; fail ())
       | TypeCheck.Error (_, msgs) => (app println $ "TC.Error: " :: msgs; fail ())
       | NameResolve.Error (_, msg) => (println $ "NR.Error: " ^ msg; fail ())
    
val test_suites = [
      test1
]
                            
end                  

end
