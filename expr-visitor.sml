functor ExprVisitorFn (structure S : EXPR
                     structure T : EXPR
                    ) = struct

open Unbound
open Namespaces
open Binders
open Operators
open Region
open S

infixr 0 $
       
type ('this, 'env) expr_visitor_vtable =
     {
       visit_expr : 'this -> 'env -> expr -> T.expr,
       visit_EVar : 'this -> 'env -> var * bool -> T.expr,
       visit_EConst : 'this -> 'env -> expr_const * region -> T.expr,
       visit_EUnOp : 'this -> 'env -> expr_un_op * expr * region -> T.expr,
       visit_EBinOp : 'this -> 'env -> bin_op * expr * expr -> T.expr,
       visit_ETriOp : 'this -> 'env -> tri_op * expr * expr * expr -> T.expr,
       visit_EEI : 'this -> 'env -> expr_EI * expr * idx -> T.expr,
       visit_EET : 'this -> 'env -> expr_ET * expr * mtype -> T.expr,
       visit_ET : 'this -> 'env -> expr_T * mtype * region -> T.expr,
       visit_EAbs : 'this -> 'env -> (ptrn, expr) bind -> T.expr,
       visit_EAbsI : 'this -> 'env -> (sort, expr) ibind_anno * region -> T.expr,
       visit_EAppConstr : 'this -> 'env -> (var * bool) * mtype list * idx list * expr * (int * mtype) option -> T.expr,
       visit_ECase : 'this -> 'env -> expr * return * (ptrn, expr) bind list * region -> T.expr,
       visit_ELet : 'this -> 'env -> return * (decl tele, expr) bind * region -> T.expr,
       visit_EAsc : 'this -> 'env -> expr * mtype -> T.expr,
       visit_decl : 'this -> 'env ctx -> decl -> T.decl,
       visit_DVal : 'this -> 'env ctx -> ename binder * (tname binder list, expr) bind outer * region outer -> T.decl,
       visit_DValPtrn : 'this -> 'env ctx -> ptrn * expr outer * region outer -> T.decl,
       visit_DRec : 'this -> 'env ctx -> ename binder * (tname binder list * stbind tele rebind, (mtype * idx) * expr) bind inner * region outer -> T.decl,
       visit_DDatatype : 'this -> 'env ctx -> mtype datatype_def * region outer -> T.decl,
       visit_DIdxDef : 'this -> 'env ctx -> iname binder * sort outer * idx outer -> T.decl,
       visit_DAbsIdx2 : 'this -> 'env ctx -> iname binder * sort outer * idx outer -> T.decl,
       visit_DAbsIdx : 'this -> 'env ctx -> (iname binder * sort outer * idx outer) * decl tele rebind * region outer -> T.decl,
       visit_DTypeDef : 'this -> 'env ctx -> tname binder * mtype outer -> T.decl,
       visit_DOpen : 'this -> 'env ctx -> mod_projectible outer * scoping_ctx option -> T.decl,
       visit_var : 'this -> 'env -> var -> T.var,
       visit_mod_projectible : 'this -> 'env -> mod_projectible -> T.mod_projectible,
       visit_idx : 'this -> 'env -> idx -> T.idx,
       visit_sort : 'this -> 'env -> sort -> T.sort,
       visit_mtype : 'this -> 'env -> mtype -> T.mtype,
       visit_datatype : 'this -> 'env ctx -> mtype datatype_def -> T.mtype T.datatype_def,
       visit_ptrn : 'this -> 'env ctx -> ptrn -> T.ptrn,
       extend_i : 'this -> 'env -> iname -> 'env,
       extend_t : 'this -> 'env -> tname -> 'env,
       extend_c : 'this -> 'env -> cname -> 'env,
       extend_e : 'this -> 'env -> ename -> 'env
     }
       
type ('this, 'env) expr_visitor_interface =
     ('this, 'env) expr_visitor_vtable
                                       
(***************** the default visitor  **********************)    

open VisitorUtil
       
(* val visit_ibind = Unbound.visit_bind_simp *)
(* val visit_tbind = Unbound.visit_bind_simp *)
(* val visit_ebind = Unbound.visit_bind_simp *)
                    
fun default_expr_visitor_vtable
      (cast : 'this -> ('this, 'env) expr_visitor_interface)
      extend_i
      extend_t
      extend_c
      extend_e
      visit_var
      visit_mod_projectible
      visit_idx
      visit_sort
      visit_mtype
      visit_datatype
      visit_ptrn
    : ('this, 'env) expr_visitor_vtable =
  let
    fun visit_expr this env data =
      let
        val vtable = cast this
      in
        case data of
	    EVar data => #visit_EVar vtable this env data
          | EConst data => #visit_EConst vtable this env data
          | EUnOp data => #visit_EUnOp vtable this env data
          | EBinOp data => #visit_EBinOp vtable this env data
	  | ETriOp data => #visit_ETriOp vtable this env data
          | EEI data => #visit_EEI vtable this env data
          | EET data => #visit_EET vtable this env data
          | ET data => #visit_ET vtable this env data
	  | EAbs data => #visit_EAbs vtable this env data
	  | EAbsI data => #visit_EAbsI vtable this env data
	  | EAppConstr data => #visit_EAppConstr vtable this env data
	  | ECase data => #visit_ECase vtable this env data
	  | ELet data => #visit_ELet vtable this env data
	  | EAsc data => #visit_EAsc vtable this env data
      end
    fun visit_EVar this env data =
      let
        val vtable = cast this
        val (var, eia) = data
        val var = #visit_var vtable this env var
      in
        T.EVar (var, eia)
      end
    fun visit_EConst this env data =
      let
        val vtable = cast this
      in
        T.EConst data
      end
    fun visit_EUnOp this env data =
      let
        val vtable = cast this
        val (opr, e, r) = data
        val e = #visit_expr vtable this env e
      in
        T.EUnOp (opr, e, r)
      end
    fun visit_EBinOp this env data =
      let
        val vtable = cast this
        val (opr, e1, e2) = data
        val e1 = #visit_expr vtable this env e1
        val e2 = #visit_expr vtable this env e2
      in
        T.EBinOp (opr, e1, e2)
      end
    fun visit_ETriOp this env data =
      let
        val vtable = cast this
        val (opr, e1, e2, e3) = data
        val e1 = #visit_expr vtable this env e1
        val e2 = #visit_expr vtable this env e2
        val e3 = #visit_expr vtable this env e3
      in
        T.ETriOp (opr, e1, e2, e3)
      end
    fun visit_EEI this env data = 
      let
        val vtable = cast this
        val (opr, e, i) = data
        val e = #visit_expr vtable this env e
        val i = #visit_idx vtable this env i
      in
        T.EEI (opr, e, i)
      end
    fun visit_EET this env data = 
      let
        val vtable = cast this
        val (opr, e, t) = data
        val e = #visit_expr vtable this env e
        val t = #visit_mtype vtable this env t
      in
        T.EET (opr, e, t)
      end
    fun visit_ET this env data = 
      let
        val vtable = cast this
        val (opr, t, r) = data
        val t = #visit_mtype vtable this env t
      in
        T.ET (opr, t, r)
      end
    fun visit_EAbs this env data =
      let
        val vtable = cast this
        val data = visit_bind (#visit_ptrn vtable this) (#visit_expr vtable this) env data
      in
        T.EAbs data
      end
    fun visit_ibind_anno this = visit_bind_anno (#extend_i (cast this) this)
    fun visit_EAbsI this env data =
      let
        val vtable = cast this
        val (bind, r) = data
        val bind = visit_ibind_anno this (#visit_sort vtable this) (#visit_expr vtable this) env bind
      in
        T.EAbsI (bind, r)
      end
    fun visit_EAppConstr this env data = 
      let
        val vtable = cast this
        val ((var, eia), ts, is, e, ot) = data
        val var = #visit_var vtable this env var
        val ts = map (#visit_mtype vtable this env) ts
        val is = map (#visit_idx vtable this env) is
        val e = #visit_expr vtable this env e
        val ot = Option.map (mapSnd (#visit_mtype vtable this env)) ot
      in
        T.EAppConstr ((var, eia), ts, is, e, ot)
      end
    fun visit_return this env (t, i) =
      let
        val vtable = cast this
        val t = Option.map (#visit_mtype vtable this env) t                                      
        val i = Option.map (#visit_idx vtable this env) i                                     
      in
        (t, i)
      end
    fun visit_ECase this env data =
      let
        val vtable = cast this
        val (e, return, binds, r) = data
        val e = #visit_expr vtable this env e
        val return = visit_return this env return
        val binds = map (visit_bind (#visit_ptrn vtable this) (#visit_expr vtable this) env) binds
      in
        T.ECase (e, return, binds, r)
      end
    fun visit_ELet this env data =
      let
        val vtable = cast this
        val (return, bind, r) = data
        val return = visit_return this env return
        val bind = visit_bind (visit_tele (#visit_decl vtable this)) (#visit_expr vtable this) env bind
      in
        T.ELet (return, bind, r)
      end
    fun visit_EAsc this env data = 
      let
        val vtable = cast this
        val (e, t) = data
        val e = #visit_expr vtable this env e
        val t = #visit_mtype vtable this env t
      in
        T.EAsc (e, t)
      end
    fun visit_decl this env data =
      let
        val vtable = cast this
      in
        case data of
            DVal data => #visit_DVal vtable this env data
          | DValPtrn data => #visit_DValPtrn vtable this env data
          | DRec data => #visit_DRec vtable this env data
	  | DDatatype data => #visit_DDatatype vtable this env data
          | DIdxDef data => #visit_DIdxDef vtable this env data
          | DAbsIdx2 data => #visit_DAbsIdx2 vtable this env data
          | DAbsIdx data => #visit_DAbsIdx vtable this env data
          | DTypeDef data => #visit_DTypeDef vtable this env data
          | DOpen data => #visit_DOpen vtable this env data
      end
    fun visit_ibinder this env name =
      let
        val vtable = cast this
        val name = visit_binder (#extend_i vtable this) env name
      in
        name
      end
    fun visit_tbinder this env name =
      let
        val vtable = cast this
        val name = visit_binder (#extend_t vtable this) env name
      in
        name
      end
    fun visit_cbinder this env name =
      let
        val vtable = cast this
        val name = visit_binder (#extend_c vtable this) env name
      in
        name
      end
    fun visit_ebinder this env name =
      let
        val vtable = cast this
        val name = visit_binder (#extend_e vtable this) env name
      in
        name
      end
    fun visit_DVal this env data =
      let
        val vtable = cast this
        val (name, bind, r) = data
        val name = visit_ebinder this env name
        val bind = visit_outer (visit_bind (visit_list (visit_tbinder this)) (#visit_expr vtable this)) env bind
      in
        T.DVal (name, bind, r)
      end
    fun visit_DValPtrn this env data =
      let
        val vtable = cast this
        val (pn, e, r) = data
        val pn = #visit_ptrn vtable this env pn
        val e = visit_outer (#visit_expr vtable this) env e
      in
        T.DValPtrn (pn, e, r)
      end
    fun visit_stbind this env data =
      let
        val vtable = cast this
      in
        case data of
            SortingST data => T.SortingST $ visit_pair (visit_ibinder this) (visit_outer (#visit_sort vtable this)) env data
          | TypingST pn => T.TypingST $ #visit_ptrn vtable this env pn
      end
    fun visit_DRec this env data =
      let
        val vtable = cast this
        val (name, bind, r) = data
        val name = visit_ebinder this env name
        val bind =
            visit_inner (
              visit_bind (visit_pair (visit_list (visit_tbinder this))
                                     (visit_rebind (visit_tele (visit_stbind this))))
                         (visit_pair (visit_pair (#visit_mtype vtable this)
                                                 (#visit_idx vtable this))
                                     (#visit_expr vtable this))) env bind
      in
        T.DRec (name, bind, r)
      end
    fun visit_DIdxDef this env data =
      let
        val vtable = cast this
        val (name, s, i) = data
        val name = visit_ibinder this env name
        val s = visit_outer (#visit_sort vtable this) env s
        val i = visit_outer (#visit_idx vtable this) env i
      in
        T.DIdxDef (name, s, i)
      end
    fun visit_DAbsIdx2 this env data =
      let
        val vtable = cast this
        val (name, s, i) = data
        val name = visit_ibinder this env name
        val s = visit_outer (#visit_sort vtable this) env s
        val i = visit_outer (#visit_idx vtable this) env i
      in
        T.DAbsIdx2 (name, s, i)
      end
    fun visit_DAbsIdx this env data =
      let
        val vtable = cast this
        val ((name, s, i), decls, r) = data
        val name = visit_ibinder this env name
        val s = visit_outer (#visit_sort vtable this) env s
        val i = visit_outer (#visit_idx vtable this) env i
        val decls = visit_rebind (visit_tele (#visit_decl vtable this)) env decls
      in
        T.DAbsIdx ((name, s, i), decls, r)
      end
    fun visit_DTypeDef this env data =
      let
        val vtable = cast this
        val (name, t) = data
        val name = visit_tbinder this env name
        val t = visit_outer (#visit_mtype vtable this) env t
      in
        T.DTypeDef (name, t)
      end
    fun visit_DDatatype this env data =
      let
        val vtable = cast this
        val (dt, r) = data
        val dt = #visit_datatype vtable this env dt
      in
        T.DDatatype (dt, r)
      end
    fun visit_scoping_ctx this env (sctx, kctx, cctx, tctx) =
      let
        val sctx = visit_list (visit_ibinder this) env sctx
        val kctx = visit_list (visit_tbinder this) env kctx
        val cctx = visit_list (visit_cbinder this) env cctx
        val tctx = visit_list (visit_ebinder this) env tctx
      in
        (sctx, kctx, cctx, tctx)
      end
    fun visit_DOpen this env data =
      let
        val vtable = cast this
        val (m, scp) = data
        val m = visit_outer (#visit_mod_projectible vtable this) env m
        val scp = Option.map (visit_scoping_ctx this env) scp
      in
        T.DOpen (m, scp)
      end
    (* fun default_visit_binder extend this = visit_binder (extend this) *)
    (* val visit_ebind = fn this => visit_ebind (#extend_e (cast this) this) *)
    (* val visit_ibind = fn this => visit_ibind (#extend_i (cast this) this) *)
  in
    {
      visit_expr = visit_expr,
      visit_EVar = visit_EVar,
      visit_EConst = visit_EConst,
      visit_EUnOp = visit_EUnOp,
      visit_EBinOp = visit_EBinOp,
      visit_ETriOp = visit_ETriOp,
      visit_EEI = visit_EEI,
      visit_EET = visit_EET,
      visit_ET = visit_ET,
      visit_EAbs = visit_EAbs,
      visit_EAbsI = visit_EAbsI,
      visit_EAppConstr = visit_EAppConstr,
      visit_ECase = visit_ECase,
      visit_ELet = visit_ELet,
      visit_EAsc = visit_EAsc,
      visit_decl = visit_decl,
      visit_DVal = visit_DVal,
      visit_DValPtrn = visit_DValPtrn,
      visit_DRec = visit_DRec,
      visit_DDatatype = visit_DDatatype,
      visit_DIdxDef = visit_DIdxDef,
      visit_DAbsIdx2 = visit_DAbsIdx2,
      visit_DAbsIdx = visit_DAbsIdx,
      visit_DTypeDef = visit_DTypeDef,
      visit_DOpen = visit_DOpen,
      visit_var = visit_var,
      visit_mod_projectible = visit_mod_projectible,
      visit_idx = visit_idx,
      visit_sort = visit_sort,
      visit_mtype = visit_mtype,
      visit_datatype = visit_datatype,
      visit_ptrn = visit_ptrn,
      extend_i = extend_i,
      extend_t = extend_t,
      extend_c = extend_c,
      extend_e = extend_e
    }
  end

datatype 'env expr_visitor =
         ExprVisitor of ('env expr_visitor, 'env) expr_visitor_interface

fun expr_visitor_impls_interface (this : 'env expr_visitor) :
    ('env expr_visitor, 'env) expr_visitor_interface =
  let
    val ExprVisitor vtable = this
  in
    vtable
  end

fun new_expr_visitor vtable params =
  let
    val vtable = vtable expr_visitor_impls_interface params
  in
    ExprVisitor vtable
  end
    
(***************** the "shift_e_e" visitor  **********************)    

open Bind
       
fun on_e_ibind f x n (Bind (name, b) : ('a * 'b) ibind) = Bind (name, f x n b)
                                                               
fun on_e_e on_v =
  let
    fun f x n b =
      case b of
	  EVar (y, b) => EVar (on_v x n y, b)
        | EConst _ => b
	| EUnOp (opr, e, r) => EUnOp (opr, f x n e, r)
	| EBinOp (opr, e1, e2) => EBinOp (opr, f x n e1, f x n e2)
	| ETriOp (opr, e1, e2, e3) => ETriOp (opr, f x n e1, f x n e2, f x n e3)
	| EEI (opr, e, i) => EEI (opr, f x n e, i)
	| EET (opr, e, t) => EET (opr, f x n e, t)
	| ET (opr, t, r) => ET (opr, t, r)
	| EAbs bind =>
          let
            val (pn, e) = unBind bind
          in
            EAbs $ Unbound.Bind (pn, f (x + (length $ snd $ ptrn_names pn)) n e)
          end
	| EAbsI (bind, r) =>
          let
            val ((name, s), e) = unBindAnno bind
            val bind = Bind (name, e)
            val Bind (name, e) = on_e_ibind f x n bind
            val bind = BindAnno ((name, s), e)
          in
            EAbsI (bind, r)
          end
	| ELet (return, bind, r) =>
	  let
            val (decls, e) = unBind bind
            val decls = unTeles decls
	    val (decls, m) = f_decls x n decls
            val decls = Teles decls
	  in
	    ELet (return, Unbound.Bind (decls, f (x + m) n e), r)
	  end
	| EAsc (e, t) => EAsc (f x n e, t)
	| EAppConstr (cx, ts, is, e, ot) => EAppConstr (cx, ts, is, f x n e, ot)
	| ECase (e, return, rules, r) => ECase (f x n e, return, map (f_rule x n) rules, r)

    and f_decls x n decls =
	let 
          fun g (dec, (acc, m)) =
	    let
	      val (dec, m') = f_dec (x + m) n dec
	    in
	      (dec :: acc, m' + m)
	    end
	  val (decls, m) = foldl g ([], 0) decls
	  val decls = rev decls
	in
          (decls, m)
        end

    and f_dec x n dec =
	case dec of
	    DVal (name, Outer bind, r) => 
	    let
              val (tnames, e) = unBind bind
	    in
              (DVal (name, Outer $ Unbound.Bind (tnames, f x n e), r), 1)
            end
	  | DValPtrn (pn, Outer e, r) => 
	    let 
              val (_, enames) = ptrn_names pn 
	    in
              (DValPtrn (pn, Outer $ f x n e, r), length enames)
            end
          | DRec (name, bind, r) => 
            let
              val ((tnames, Rebind binds), ((t, d), e)) = unBind $ unInner bind
              val binds = unTeles binds
              fun g (bind, m) =
                case bind of
                    SortingST _ => m
                  | TypingST pn =>
	            let 
                      val (_, enames) = ptrn_names pn 
	            in
                      m + length enames
                    end
              val m = foldl g 0 binds
              val e = f (x + 1 + m) n e
            in
              (DRec (name, Inner $ Unbound.Bind ((tnames, Rebind $ Teles binds), ((t, d), e)), r), 1)
            end
          | DDatatype a => (DDatatype a, 0)
          | DIdxDef a => (DIdxDef a, 0)
          | DAbsIdx2 a => (DAbsIdx2 a, 0)
          | DAbsIdx (a, Rebind decls, r) => 
            let
              val decls = unTeles decls
              val (decls, m) = f_decls x n decls
            in
              (DAbsIdx (a, Rebind $ Teles decls, r), m)
            end
          | DTypeDef (name, t) => (DTypeDef (name, t), 0)
          | DOpen (m, octx) =>
            case octx of
                NONE => raise Impossible "ctx can't be NONE"
              | SOME ctx => (DOpen (m, octx), length $ #4 ctx)

    and f_rule x n bind =
	let
          val (pn, e) = unBind bind
          val (_, enames) = ptrn_names pn 
	in
	  Unbound.Bind (pn, f (x + length enames) n e)
	end
  in
    f
  end

(* fun shiftx_e_e x n b = on_e_e shiftx_v x n b *)
(* fun shift_e_e b = shiftx_e_e 0 1 b *)
(* fun forget_e_e x n b = on_e_e forget_v x n b *)
                              
end
