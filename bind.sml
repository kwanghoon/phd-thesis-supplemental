structure Bind = struct
open Util
infixr 0 $

(* ['namespace] is just a tag to differentiate different bind types *)         
datatype ('namespace, 'body) bind = Bind of 'body

(* a series of dependent binds ({name1 : classifier1} {name2 : classifier2} {name3 : classifier3}, inner) *)
datatype ('namespace, 'classifier, 'name, 'inner) binds =
         BindNil of 'inner
         | BindCons of 'classifier * ('namespace, 'name * ('namespace, 'classifier, 'name, 'inner) binds) bind

fun unBind (Bind a) = a
                        
fun unfold_binds binds =
    case binds of
        BindNil inner => ([], inner)
      | BindCons (classifier, Bind (name, binds)) =>
        let val (name_classifiers, inner) = unfold_binds binds
        in
          ((name, classifier) :: name_classifiers, inner)
        end

fun fold_binds (binds, inner) =
    foldr (fn ((name, classifier), binds) => BindCons (classifier, Bind (name, binds))) (BindNil inner) binds

fun binds_length binds = length $ fst $ unfold_binds binds
                                  
datatype idx_namespace = IdxNS
datatype type_namespace = TypeNS
                            
type 'body ibind = (idx_namespace, 'body) bind
type 'body tbind = (type_namespace, 'body) bind
type ('classifier, 'name, 'inner) ibinds = (idx_namespace, 'classifier, 'name, 'inner) binds
type ('classifier, 'name, 'inner) tbinds = (type_namespace, 'classifier, 'name, 'inner) binds
                                                                                        
fun visit_bind extend f env data =
  let
    val Bind (name, t) = data
    val (env, name) = extend env name
    val t = f env t
  in
    Bind (name, t)
  end
    
end
(*
structure ExprUtil = struct
open Util
infixr 0 $

datatype 'a ibind = BindI of 'a

(* for a series of sorting binds ({name1 : anno1} {name2 : anno2} {name3 : anno3}, inner) *)
datatype ('anno, 'name, 'inner) ibinds =
         NilIB of 'inner
         | ConsIB of 'anno * ('name * ('anno, 'name, 'inner) ibinds) ibind

fun unfold_ibinds ibinds =
    case ibinds of
        NilIB inner => ([], inner)
      | ConsIB (anno, BindI (name, ibinds)) =>
        let val (name_annos, inner) = unfold_ibinds ibinds
        in
          ((name, anno) :: name_annos, inner)
        end

fun fold_ibinds (binds, inner) =
    foldr (fn ((name, anno), ibinds) => ConsIB (anno, BindI (name, ibinds))) (NilIB inner) binds

fun ibinds_length ibinds = length $ fst $ unfold_ibinds ibinds
                                  
end

*)
