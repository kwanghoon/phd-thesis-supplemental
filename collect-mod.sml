signature COLLECT_MOD_PARAMS = sig
  structure Expr : IDX_TYPE_EXPR
  val on_var : string list -> Expr.var -> string list
  val on_mod_id : string list -> Expr.mod_id -> string list
end
                                 
(* collect module references *)
functor CollectModFn (Params : COLLECT_MOD_PARAMS) = struct

open Params
open Expr
open Expr.Idx
open Expr.Type
open Util
open Pattern
open Bind
       
infixr 0 $

fun acc2ref f env b =
    let
      val acc = f (!env) b
      val () = env := acc
    in
      b
    end
       
fun ref2acc f acc b =
  let
    val result = ref acc
    val b = f result b
  in
    !result
  end

fun visit_var a = acc2ref on_var a
fun visit_mod_id a = acc2ref on_mod_id a
       
structure IdxVisitor = IdxVisitorFn (structure S = Expr.Idx
                                     structure T = Expr.Idx)
open IdxVisitor

fun collect_mod_idx_visitor_vtable cast () =
  let
  in
    default_idx_visitor_vtable
      cast
      extend_noop
      (ignore_this visit_var)
      visit_noop
      visit_noop
      visit_noop
      visit_noop
  end

fun new_collect_mod_idx_visitor params = new_idx_visitor collect_mod_idx_visitor_vtable params
    
fun visit_i env b =
  let
    val visitor as (IdxVisitor vtable) = new_collect_mod_idx_visitor ()
  in
    #visit_idx vtable visitor env b
  end

fun visit_p env b =
  let
    val visitor as (IdxVisitor vtable) = new_collect_mod_idx_visitor ()
  in
    #visit_prop vtable visitor env b
  end

fun visit_s env b =
  let
    val visitor as (IdxVisitor vtable) = new_collect_mod_idx_visitor ()
  in
    #visit_sort vtable visitor env b
  end

fun on_i a = ref2acc visit_i a
fun on_p a = ref2acc visit_p a
fun on_s a = ref2acc visit_s a

fun collect_mod_i a = on_i [] a
fun collect_mod_p a = on_p [] a
fun collect_mod_s a = on_s [] a

(* fun on_ibind f acc (Bind (_, b) : ('a * 'b) ibind) = f acc b *)

(* fun collect_mod_long_id b = on_var [] b *)
  
(* local *)
(*   fun f acc b = *)
(*     case b of *)
(* 	VarI x => on_var acc x *)
(*       | IConst _ => acc *)
(*       | UnOpI (opr, i, r) => f acc i *)
(*       | BinOpI (opr, i1, i2) =>  *)
(*         let *)
(*           val acc = f acc i1 *)
(*           val acc = f acc i2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | Ite (i1, i2, i3, r) => *)
(*         let *)
(*           val acc = f acc i1 *)
(*           val acc = f acc i2 *)
(*           val acc = f acc i3 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | IAbs (b, bind, r) => *)
(*         on_ibind f acc bind *)
(*       | UVarI a => acc *)
(* in *)
(* val on_i = f *)
(* fun collect_mod_i b = f [] b *)
(* end *)

(* local *)
(*   fun f acc b = *)
(*     case b of *)
(* 	PTrueFalse _ => acc *)
(*       | Not (p, r) => f acc p *)
(*       | BinConn (opr,p1, p2) => *)
(*         let *)
(*           val acc = f acc p1 *)
(*           val acc = f acc p2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | BinPred (opr, i1, i2) =>  *)
(*         let *)
(*           val acc = on_i acc i1 *)
(*           val acc = on_i acc i2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | Quan (q, bs, bind, r) => on_ibind f acc bind *)
(* in *)
(* val on_p = f *)
(* fun collect_mod_p b = f [] b *)
(* end *)

(* local *)
(*   fun f acc b = *)
(*     case b of *)
(* 	Basic s => acc *)
(*       | Subset (b, bind, r) => on_ibind on_p acc bind *)
(*       | UVarS a => acc *)
(*       | SAbs (s, bind, r) => on_ibind f acc bind *)
(*       | SApp (s, i) => *)
(*         let *)
(*           val acc = f acc s *)
(*           val acc = on_i acc i *)
(*         in *)
(*           acc *)
(*         end *)
(* in *)
(* val on_s = f *)
(* fun collect_mod_s b = f [] b *)
(* end *)

(* open Bind *)
       
(* fun on_tbind f acc (Bind (_, b) : ('a * 'b) tbind) = f acc b *)

fun on_list f acc b = foldl (fn (b, acc) => f acc b) acc b
                            
(* fun on_pair (f, g) acc (a, b) = *)
(*   let *)
(*     val acc = f acc a *)
(*     val acc = g acc b *)
(*   in *)
(*     acc *)
(*   end *)
  
structure TypeVisitor = TypeVisitorFn (structure S = Expr.Type
                                     structure T = Expr.Type)
open TypeVisitor

fun collect_mod_type_visitor_vtable cast () =
  let
  in
    default_type_visitor_vtable
      cast
      extend_noop
      extend_noop
      (ignore_this visit_var)
      visit_noop
      (ignore_this visit_i)
      (ignore_this visit_s)
      visit_noop
      visit_noop
  end

fun new_collect_mod_type_visitor params = new_type_visitor collect_mod_type_visitor_vtable params
    
fun visit_mt env b =
  let
    val visitor as (TypeVisitor vtable) = new_collect_mod_type_visitor ()
  in
    #visit_mtype vtable visitor env b
  end

fun visit_t env b =
  let
    val visitor as (TypeVisitor vtable) = new_collect_mod_type_visitor ()
  in
    #visit_ty vtable visitor env b
  end

fun visit_constr env b =
  let
    val visitor as (TypeVisitor vtable) = new_collect_mod_type_visitor ()
  in
    #visit_constr_info vtable visitor env b
  end

fun on_mt a = ref2acc visit_mt a
fun on_t a = ref2acc visit_t a
fun on_constr a = ref2acc visit_constr a

fun collect_mod_mt a = on_mt [] a
fun collect_mod_t a = on_t [] a
fun collect_mod_constr a = on_constr [] a
                           
(* fun on_mt acc b = *)
(*   let *)
(*     val f = on_mt *)
(*   in *)
(*     case b of *)
(* 	Arrow (t1, i, t2) => *)
(*         let *)
(*           val acc = f acc t1 *)
(*           val acc = on_i acc i *)
(*           val acc = f acc t2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | TyNat (i, _) => on_i acc i *)
(*       | TyArray (t, i) => *)
(*         let *)
(*           val acc = f acc t *)
(*           val acc = on_i acc i *)
(*         in *)
(*           acc *)
(*         end *)
(*       | Unit _ => acc *)
(*       | Prod (t1, t2) => *)
(*         let *)
(*           val acc = f acc t1 *)
(*           val acc = f acc t2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | UniI (s, bind, _) => *)
(*         let *)
(*           val acc = on_s acc s *)
(*           val acc = on_ibind f acc bind *)
(*         in *)
(*           acc *)
(*         end *)
(*       | MtVar x => on_var acc x *)
(*       | MtApp (t1, t2) => *)
(*         let *)
(*           val acc = f acc t1 *)
(*           val acc = f acc t2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | MtAbs (k, bind, _) => on_tbind f acc bind *)
(*       | MtAppI (t, i) => *)
(*         let *)
(*           val acc = f acc t *)
(*           val acc = on_i acc i *)
(*         in *)
(*           acc *)
(*         end *)
(*       | MtAbsI (b, bind, r) => on_ibind f acc bind *)
(*       | BaseType _ => acc *)
(*       | UVar _ => acc *)
(*       | TDatatype (dt, r) => on_datatype acc dt *)
(*   end *)
    
(* and on_constr_core acc ibinds = *)
(*   let *)
(*     val (ns, (t, is)) = unfold_binds ibinds *)
(*     val acc = on_list on_s acc $ map snd ns *)
(*     val acc = on_mt acc t *)
(*     val acc = on_list on_i acc is *)
(*   in *)
(*     acc *)
(*   end *)
    
(* and on_datatype acc (Bind (_, tbinds)) = *)
(*     let *)
(*       val (_, (_, constr_decls)) = unfold_binds tbinds *)
(*       fun on_constr_decl acc (name, core, r) = on_constr_core acc core *)
(*       val acc = on_list on_constr_decl acc constr_decls *)
(*     in *)
(*       acc *)
(*     end *)
    
(* fun collect_mod_mt b = on_mt [] b *)
(* fun collect_mod_constr_core b = on_constr_core [] b *)
    
(* local *)
(*   fun f acc b = *)
(*     case b of *)
(* 	Mono t => on_mt acc t *)
(*       | Uni (bind, r) => on_tbind f acc bind *)
(* in *)
(* val on_t = f *)
(* fun collect_mod_t b = f [] b *)
(* end *)

(* fun collect_mod_constr (family, tbinds) = *)
(*   let *)
(*     val (_, ibinds) = unfold_binds tbinds *)
(*   in *)
(*     collect_mod_constr_core ibinds *)
(*   end *)
                          
(* fun on_option f acc a = *)
(*   case a of *)
(*       SOME a => f acc a *)
(*     | NONE => acc *)

(* fun on_snd f acc (a, b) = f acc b *)
  
structure ExprVisitor = ExprVisitorFn (structure S = Expr
                                     structure T = Expr)
open ExprVisitor

fun collect_mod_expr_visitor_vtable cast () =
  let
  in
    default_expr_visitor_vtable
      cast
      extend_noop
      extend_noop
      extend_noop
      extend_noop
      (ignore_this visit_var)
      (ignore_this visit_var)
      (ignore_this visit_mod_id)
      (ignore_this visit_i)
      (ignore_this visit_s)
      (ignore_this visit_mt)
      (ignore_this visit_t)
      visit_noop
      visit_noop
  end

fun new_collect_mod_expr_visitor params = new_expr_visitor collect_mod_expr_visitor_vtable params
    
fun visit_e env b =
  let
    val visitor as (ExprVisitor vtable) = new_collect_mod_expr_visitor ()
  in
    #visit_expr vtable visitor env b
  end

fun visit_decl env b =
  let
    val visitor = new_collect_mod_expr_visitor ()
  in
    visit_decl_acc visitor (b, env)
  end

fun on_e a = ref2acc visit_e a
fun on_decl a = ref2acc visit_decl a

fun collect_mod_e a = on_e [] a
fun collect_mod_decl a = on_decl [] a
                           
(* fun on_return x = on_pair (on_option on_mt, on_option on_i) x *)
                      
(* local *)
(*   fun f acc b = *)
(*     case b of *)
(* 	ConstrP (Outer ((x, _), eia), inames, pn, r) => *)
(*         let *)
(*           val acc = on_var acc x *)
(*           val acc = f acc pn *)
(*         in *)
(*           acc *)
(*         end *)
(*       | VarP name => acc *)
(*       | PairP (pn1, pn2) => *)
(*         let *)
(*           val acc = f acc pn1 *)
(*           val acc = f acc pn2 *)
(*         in *)
(*           acc *)
(*         end *)
(*       | TTP r => acc *)
(*       | AliasP (name, pn, r) => f acc pn *)
(*       | AnnoP (pn, Outer t) => *)
(*         let *)
(*           val acc = f acc pn *)
(*           val acc = on_mt acc t *)
(*         in *)
(*           acc *)
(*         end *)
(* in *)
(* val on_ptrn = f *)
(* fun collect_mod_ptrn b = f [] b *)
(* end *)

(* local *)
(*   fun f acc b = *)
(*       case b of *)
(* 	  EVar (x, _) => collect_mod_long_id x @ acc *)
(* 	| EConst c => acc *)
(* 	| EUnOp (opr, e, r) => f acc e *)
(* 	| EBinOp (opr, e1, e2) => *)
(*           let *)
(*             val acc = f acc e1 *)
(*             val acc = f acc e2 *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| ETriOp (opr, e1, e2, e3) => *)
(*           let *)
(*             val acc = f acc e1 *)
(*             val acc = f acc e2 *)
(*             val acc = f acc e3 *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| EEI (opr, e, i) => *)
(*           let *)
(*             val acc = f acc e *)
(*             val acc = on_i acc i *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| EET (opr, e, t) => *)
(*           let *)
(*             val acc = f acc e *)
(*             val acc = on_mt acc t *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| ET (opr, t, r) => on_mt acc t *)
(* 	| EAbs bind => *)
(*           let *)
(*             val (pn, e) = Unbound.unBind bind *)
(*             val acc = on_ptrn acc pn *)
(*             val acc = f acc e *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| EAbsI (bind, r) => *)
(*           let *)
(*             val ((name, s), e) = unBindAnno bind *)
(*             val acc = on_s acc s *)
(*             val acc = f acc e *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| EAppConstr ((x, ie), ts, is, e, ot) => *)
(*           let *)
(*             val acc = on_var acc x *)
(*             val acc = on_list on_mt acc ts *)
(*             val acc = on_list on_i acc is *)
(*             val acc = f acc e *)
(*             val acc = on_option (on_snd on_mt) acc ot *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| ECase (e, return, rules, r) => *)
(*           let *)
(*             val acc = f acc e *)
(*             val acc = on_return acc return *)
(*             val on_rule = on_pair (on_ptrn, f) *)
(*             val acc = on_list (on_rule) acc $ map Unbound.unBind rules *)
(*           in *)
(*             acc *)
(*           end *)
(* 	| ELet (return, bind, r) => *)
(*           let *)
(*             val (decls, e) = Unbound.unBind bind *)
(*             val decls = unTeles decls *)
(*             val acc = on_return acc return *)
(*             val acc = on_list on_decl acc decls *)
(*             val acc = f acc e *)
(*           in *)
(*             acc *)
(*           end *)

(*   and on_decl acc b = *)
(*       case b of *)
(*           DVal (name, Outer bind, r) => *)
(*           let *)
(*             val (tnames, e) = Unbound.unBind bind *)
(*             val pn = VarP name *)
(*             val acc = on_ptrn acc pn *)
(*             val acc = f acc e *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DValPtrn (pn, Outer e, r) => *)
(*           let  *)
(*             val acc = f acc e *)
(*             val acc = on_ptrn acc pn *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DRec (name, bind, r) => *)
(*           let *)
(*             val ((tnames, Rebind binds), ((t, i), e)) = Unbound.unBind $ unInner bind *)
(*             val binds = unTeles binds *)
(*             fun on_stbind acc b = *)
(*               case b of *)
(*                   SortingST (name, Outer s) => on_s acc s *)
(*                 | TypingST pn => on_ptrn acc pn *)
(*             val acc = on_list on_stbind acc binds *)
(*             val acc = on_mt acc t *)
(*             val acc = on_i acc i *)
(*             val acc = f acc e *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DIdxDef (name, Outer s, Outer i) => *)
(*           let  *)
(*             val acc = on_option on_s acc s *)
(*             val acc = on_i acc i *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DConstrDef (name, Outer x) => *)
(*           let  *)
(*             val acc = on_var acc x *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DAbsIdx2 (name, Outer s, Outer i) => *)
(*           let  *)
(*             val acc = on_s acc s *)
(*             val acc = on_i acc i *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DAbsIdx ((name, Outer s, Outer i), Rebind decls, r) => *)
(*           let  *)
(*             val acc = on_s acc s *)
(*             val acc = on_i acc i *)
(*             val decls = unTeles decls *)
(*             val acc = on_list on_decl acc decls *)
(*           in *)
(*             acc *)
(*           end *)
(*         | DTypeDef (name, Outer t) => on_mt acc t *)
(*         | DOpen (Outer m, _) => on_mod_id acc m *)

(* in *)
(* val on_e = f *)
(* fun collect_mod_e b = f [] b *)
(* val on_decl = on_decl *)
(* end *)

(* fun on_k acc b = on_list on_s acc $ snd b *)
(* fun collect_mod_k b = on_k [] b *)
  
local
  fun f acc b =
    case b of
        SpecVal (name, t) => on_t acc t
      | SpecIdx (name, s) => on_s acc s
      | SpecType (name, k) => acc
      | SpecTypeDef (name, t) => on_mt acc t
in
val on_spec = f
fun collect_mod_spec b = f [] b
end

fun on_sgn acc b = on_list on_spec acc $ fst b

local
  fun f acc b =
    case b of
        ModComponents (comps, r) => on_list on_decl acc comps
      | ModSeal (m, sg) =>
        let 
          val acc = f acc m
          val acc = on_sgn acc sg
        in
          acc
        end
      | ModTransparentAsc (m, sg) =>
        let 
          val acc = f acc m
          val acc = on_sgn acc sg
        in
          acc
        end
in
val on_mod = f
fun collect_mod_mod b = f [] b
end

fun on_top_bind acc b =
  case b of
      TBMod m => on_mod acc m
    | TBFunctor (((arg_name, r2), arg), m) =>
      let 
        val acc = on_sgn acc arg
        val acc2 = diff op= (on_mod [] m) [arg_name]
        val acc = acc2 @ acc
      in
        acc
      end
    | TBFunctorApp (functor_name, arg_name) =>
      on_mod_id (on_mod_id acc functor_name) arg_name
    | TBState _ => acc
    | TBPragma _ => acc

fun on_prog acc b =
  let
    fun iter (((name, r), b), acc) =
      let
        val acc = diff op= acc [name]
        val acc = on_top_bind acc b
      in
        acc
      end
    val acc2 = foldr iter [] b
    val acc = acc2 @ acc
  in
    acc
  end

fun collect_mod_prog b = on_prog [] b

end
                         
