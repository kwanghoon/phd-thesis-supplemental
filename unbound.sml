(* an implementation of Stephanie Weirich's "Unbound" DSL *)

structure Unbound = struct

open Util
open VisitorUtil
       
infixr 0 $
         
datatype 'p abs = Abs of 'p
datatype 'name binder = Binder of 'name
datatype 't outer = Outer of 't
datatype 'p rebind = Rebind of 'p
           
type 'env ctx = {outer : 'env, current : 'env ref}
fun env2ctx env = {outer = env, current = ref env}
fun visit_abs visit_'p env (Abs p1) =
  Abs $ visit_'p (env2ctx env) p1
fun visit_binder extend (ctx : 'env ctx) (Binder x) =
  let
    val env = !(#current ctx)
    val (env, x) = extend env x
    val () = #current ctx := env
  in
    Binder x
  end
fun visit_outer visit_'t (ctx : 'env ctx) (Outer t1) = Outer $ visit_'t (#outer ctx) t1
fun visit_rebind visit_'p (ctx : 'env ctx) (Rebind p1) = Rebind $ visit_'p {outer = !(#current ctx), current = #current ctx} p1
    
type 't inner = ('t outer) rebind
type ('p, 't) bind = ('p * 't inner) abs

fun visit_inner x = (visit_rebind o visit_outer) x
fun visit_bind visit_'p = visit_abs o visit_pair visit_'p o visit_inner
                                             
datatype 'p tele =
         TeleNil
         | TeleCons of 'p * 'p tele rebind

type ('name, 't) bind_simp = ('name binder, 't) bind
type ('name, 'anno, 't) bind_anno = ('name binder * 'anno outer, 't) bind

fun Inner t = Rebind (Outer t)
fun Bind (p, t) = Abs (p, Inner t)
fun Teles ps = foldr (TeleCons o mapSnd Rebind) TeleNil ps
fun BindSimp (name, t) = Bind (Binder name, t)
fun BindAnno ((name, anno), t) = Bind ((Binder name, Outer anno), t)

fun unBinder (Binder n) = n
fun unOuter (Outer t) = t
fun unBind (Abs (p, Rebind (Outer t))) = (p, t)
fun unInner (Rebind (Outer t)) = t
fun unTeles t =
  case t of
      TeleNil => []
    | TeleCons (p, Rebind t) => p :: unTeles t
fun unBindAnno t =
  let
    val ((Binder name, Outer anno), t) = unBind t
  in
    ((name, anno), t)
  end
                                      
fun visit_bind_simp extend = visit_bind (visit_binder extend)
fun visit_bind_anno extend visit_'anno = visit_bind (visit_pair (visit_binder extend) (visit_outer visit_'anno))

fun visit_tele visit_p ctx t =
  case t of
      TeleNil => TeleNil
    | TeleCons a => TeleCons $ visit_pair visit_p (visit_rebind (visit_tele visit_p)) ctx a
    
end

functor NamespacesFn (type name) = struct

open Util
       
infixr 0 $

type name = name
datatype idx_namespace = IdxNS
datatype type_namespace = TypeNS
datatype constr_namespace = ConstrNS
datatype expr_namespace = ExprNS
type iname = idx_namespace * name
type tname = type_namespace * name
type cname = constr_namespace * name
type ename = expr_namespace * name
fun IName name = (IdxNS, name)
fun TName name = (TypeNS, name)
fun CName name = (ConstrNS, name)
fun EName name = (ExprNS, name)
val unName = Util.snd
                   
type idepth = idx_namespace * int
type tdepth = type_namespace * int
type cdepth = constr_namespace * int
type edepth = expr_namespace * int
fun IDepth n = (IdxNS, n)
fun TDepth n = (TypeNS, n)
fun CDepth n = (ConstrNS, n)
fun EDepth n = (ExprNS, n)
fun idepth_inc (IdxNS, n) = (IdxNS, n + 1)
fun tdepth_inc (TypeNS, n) = (TypeNS, n + 1)
fun cdepth_inc (ConstrNS, n) = (ConstrNS, n + 1)
fun edepth_inc (ExprNS, n) = (ExprNS, n + 1)
fun idepth_add ((IdxNS, a), (IdxNS, b)) = (IdxNS, a + b)
fun tdepth_add ((TypeNS, a), (TypeNS, b)) = (TypeNS, a + b)
fun cdepth_add ((ConstrNS, a), (ConstrNS, b)) = (ConstrNS, a + b)
fun edepth_add ((ExprNS, a), (ExprNS, b)) = (ExprNS, a + b)
fun unIDepth (IdxNS, n) = n
fun unTDepth (TypeNS, n) = n
fun unCDepth (ConstrNS, n) = n
fun unEDepth (ExprNS, n) = n
                              
fun use_idepth_tdepth f (di, dt) = f (unIDepth di, unTDepth dt)
fun IDepth_TDepth (di, dt) = (IDepth di, TDepth dt)                                      
fun unuse_idepth_tdepth f d = f $ IDepth_TDepth d
                                     
end

signature BINDERS = sig
  type ('name, 't) bind_simp
  type ('name, 'anno, 't) bind_anno
end

functor BinderUtilFn (structure Binders : BINDERS
                      structure Names : sig
                                  type iname
                                  type tname
                                  type cname
                                  type ename
                                end
                     ) = struct
open Names
type 't ibind = (iname, 't) Binders.bind_simp
type 't tbind = (tname, 't) Binders.bind_simp
type 't cbind = (cname, 't) Binders.bind_simp
type 't ebind = (ename, 't) Binders.bind_simp
type ('anno, 't) ibind_anno = (iname, 'anno, 't) Binders.bind_anno
type ('anno, 't) tbind_anno = (tname, 'anno, 't) Binders.bind_anno
type ('anno, 't) cbind_anno = (cname, 'anno, 't) Binders.bind_anno
type ('anno, 't) ebind_anno = (ename, 'anno, 't) Binders.bind_anno
end

structure Namespaces = NamespacesFn (type name = string * Region.region)
                                    
structure Binders = struct

structure BinderUtil = BinderUtilFn (structure Binders = Unbound
                                     structure Names = Namespaces
                                    )
open Util
open Region
open Unbound
open Namespaces
open BinderUtil
       
infixr 0 $

fun IBind (name, t) = BindSimp (IName name, t)
fun TBind (name, t) = BindSimp (TName name, t)
fun CBind (name, t) = BindSimp (CName name, t)
fun EBind (name, t) = BindSimp (EName name, t)
fun IBindAnno ((name, anno), t) = BindAnno ((IName name, anno), t)
fun TBindAnno ((name, anno), t) = BindAnno ((TName name, anno), t)
fun CBindAnno ((name, anno), t) = BindAnno ((CName name, anno), t)
fun EBindAnno ((name, anno), t) = BindAnno ((EName name, anno), t)
                                           
type ibinder = Namespaces.iname Unbound.binder
type tbinder = Namespaces.tname Unbound.binder
type cbinder = Namespaces.cname Unbound.binder
type ebinder = Namespaces.ename Unbound.binder
fun IBinder a = Binder $ IName a
fun TBinder a = Binder $ TName a
fun EBinder a = Binder $ EName a
                     
fun Name2str n = fst $ unName n
fun unBinderName n = (unName o unBinder) n
fun binder2str (Binder n) = Name2str n
fun str2binder2 ns s = Binder (ns, (s, dummy))
fun str2ibinder s = str2binder2 Namespaces.IdxNS s
fun str2ebinder s = str2binder2 Namespaces.ExprNS s

fun unBindAnnoName bind =
  let
    val ((name, anno), t) = unBindAnno bind
    val name = unName name
  in
    (anno, (name, t))
  end
               
fun unBindSimp t =
  let
    val (Binder name, t) = unBind t
  in
    (name, t)
  end
    
fun unBindSimpName bind =
  let
    val (name, e) = unBindSimp bind
  in
    (unName name, e)
  end
    
end                                     
