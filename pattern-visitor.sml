(* signature BINDER_VISITOR = sig *)
(*   structure Binders : BINDERS *)
(*   val visit_bind_anno : ('env -> 'anno -> 'anno2) -> ('env -> 't -> 't2) -> ('env -> 'name -> 'env) -> 'env -> ('name, 'anno, 't) Binders.bind_anno -> ('name, 'anno2, 't2) Binders.bind_anno         *)
(* end *)
                             
functor PatternVisitorFn (type iname
                          type tname
                          type ename
                         ) = struct

open Util
open Operators
open Region
open Unbound
structure Binders = BinderUtilFn (structure Binders = Unbound
                                  type iname = iname
                                  type tname = tname
                                  type ename = ename
                                 )
open Binders
       
infixr 0 $
infix 0 !!

datatype ('var, 'mtype) ptrn =
         PnVar of ename binder
         | PnTT of region outer
         | PnPair of ('var, 'mtype) ptrn * ('var, 'mtype) ptrn
         | PnAlias of ename binder * ('var, 'mtype) ptrn * region outer
         | PnAnno of ('var, 'mtype) ptrn * 'mtype outer
	 | PnConstr of ('var * bool) outer * iname binder list * ('var, 'mtype) ptrn option * region outer

type ('this, 'env, 'var, 'mtype, 'var2, 'mtype2) ptrn_visitor_vtable =
     {
       visit_ptrn : 'this -> 'env ctx -> ('var, 'mtype) ptrn -> ('var2, 'mtype2) ptrn,
       visit_PnVar : 'this -> 'env ctx -> ename binder -> ('var2, 'mtype2) ptrn,
       visit_PnTT : 'this -> 'env ctx -> region outer -> ('var2, 'mtype2) ptrn,
       visit_PnPair : 'this -> 'env ctx -> ('var, 'mtype) ptrn * ('var, 'mtype) ptrn -> ('var2, 'mtype2) ptrn,
       visit_PnAlias : 'this -> 'env ctx -> ename binder * ('var, 'mtype) ptrn * region outer -> ('var2, 'mtype2) ptrn,
       visit_PnAnno : 'this -> 'env ctx -> ('var, 'mtype) ptrn * 'mtype outer -> ('var2, 'mtype2) ptrn,
       visit_PnConstr : 'this -> 'env ctx -> ('var * bool) outer * iname binder list * ('var, 'mtype) ptrn option * region outer -> ('var2, 'mtype2) ptrn,
       visit_var : 'this -> 'env -> 'var -> 'var2,
       visit_mtype : 'this -> 'env -> 'mtype -> 'mtype2,
       visit_region : 'this -> 'env -> region -> region,
       visit_bool : 'this -> 'env -> bool -> bool,
       visit_ibinder : 'this -> 'env ctx -> iname binder -> iname binder,
       visit_ebinder : 'this -> 'env ctx -> ename binder -> ename binder,
       extend_i : 'this -> 'env -> iname -> 'env,
       extend_e : 'this -> 'env -> ename -> 'env
     }
       
type ('this, 'env, 'var, 'mtype, 'var2, 'mtype2) ptrn_visitor_interface =
     ('this, 'env, 'var, 'mtype, 'var2, 'mtype2) ptrn_visitor_vtable
                                       
(***************** the default visitor  **********************)    

open VisitorUtil
       
fun default_ptrn_visitor_vtable
      (cast : 'this -> ('this, 'env, 'var, 'mtype, 'var2, 'mtype2) ptrn_visitor_interface)
      extend_i
      extend_e
      visit_var
      visit_mtype
    : ('this, 'env, 'var, 'mtype, 'var2, 'mtype2) ptrn_visitor_vtable =
  let
    fun visit_ptrn this env data =
      let
        val vtable = cast this
      in
        case data of
            PnVar data => #visit_PnVar vtable this env data
          | PnTT data => #visit_PnTT vtable this env data
          | PnPair data => #visit_PnPair vtable this env data
          | PnAlias data => #visit_PnAlias vtable this env data
          | PnAnno data => #visit_PnAnno vtable this env data
          | PnConstr data => #visit_PnConstr vtable this env data
      end
    fun visit_PnVar this env data =
      let
        val vtable = cast this
      in
        PnVar $ #visit_ebinder vtable this env data
      end
    fun visit_PnTT this env data =
      let
        val vtable = cast this
      in
        PnTT $ visit_outer (#visit_region vtable this) env data
      end
    fun visit_PnPair this env data = 
      let
        val vtable = cast this
        val (p1, p2) = data
        val p1 = #visit_ptrn vtable this env p1
        val p2 = #visit_ptrn vtable this env p2
      in
        PnPair (p1, p2)
      end
    fun visit_PnAlias this env data =
      let
        val vtable = cast this
        val (name, p, r) = data
        val name = #visit_ebinder vtable this env name
        val p = #visit_ptrn vtable this env p
        val r = visit_outer (#visit_region vtable this) env r
      in
        PnAlias (name, p, r)
      end
    fun visit_PnAnno this env data = 
      let
        val vtable = cast this
        val (p, t) = data
        val p = #visit_ptrn vtable this env p
        val t = visit_outer (#visit_mtype vtable this) env t
      in
        PnAnno (p, t)
      end
    fun visit_PnConstr this env data =
      let
        val vtable = cast this
        val (x, inames, p, r) = data
        val x = visit_outer (visit_pair (#visit_var vtable this) (#visit_bool vtable this)) env x
        val inames = map (#visit_ibinder vtable this env) inames
        val p = Option.map (#visit_ptrn vtable this env) p
        val r = visit_outer (#visit_region vtable this) env r
      in
        PnConstr (x, inames, p, r)
      end
    fun default_visit_binder extend this = visit_binder (extend this)
  in
    {
      visit_ptrn = visit_ptrn,
      visit_PnVar = visit_PnVar,
      visit_PnTT = visit_PnTT,
      visit_PnPair = visit_PnPair,
      visit_PnAlias = visit_PnAlias,
      visit_PnAnno = visit_PnAnno,
      visit_PnConstr = visit_PnConstr,
      visit_var = visit_var,
      visit_mtype = visit_mtype,
      visit_region = visit_noop,
      visit_bool = visit_noop,
      visit_ibinder = default_visit_binder extend_i,
      visit_ebinder = default_visit_binder extend_e,
      extend_i = extend_i,
      extend_e = extend_e
    }
  end

end
