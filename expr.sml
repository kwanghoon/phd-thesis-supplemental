structure Expr = IdxTypeExprFn (type v = int
                         structure UVarI = UVar
                         structure UVarT = UVar
                         type ptrn_constr_tag = int * int
                        )
structure IntLongIdCanToString = struct

open LongId
open Gctx
       
fun str_raw_v x = str_int x
fun str_raw_var a = str_raw_long_id str_raw_v a
                                    
fun str_v ctx x : string =
  (* sprintf "%$" [str_int x] *)
  case nth_error ctx x of
      SOME name => name
    | NONE => "unbound_" ^ str_int x
                                   
fun str_id ctx (x, _) =
  str_v ctx x
        
fun lookup_module gctx m =
  case nth_error2 gctx m of
      SOME (name, ctx) => (name, ctx)
    | NONE => ("unbound_module_" ^ m, ([], [], [], []))
                
fun str_var sel gctx ctx id =
  case id of
      QID ((m, _), x) =>
      let
        val (name, ctx) = lookup_module gctx m
        val ctx = sel ctx
      in
        name ^ "." ^ str_id ctx x
      end
    | ID x => str_id ctx x
    
end
                                   
structure CanToString = struct
open UVar
open Expr
open IntLongIdCanToString
end
                       
structure ToString = ToStringFn (structure Expr = Expr
                                 structure CanToString = CanToString
                                )
                                
structure ToString = ToStringFn (structure Expr = Expr
                                 structure CanToString = CanToString
                                )
                                
structure ToStringRaw = ToStringRawFn (structure Expr = Expr
                                    open CanToString
                                   )
                                
structure UniquefyIdx = UniquefyIdxFn (structure Idx = Expr
                                       open CanToString
                                      )
                                
structure LongIdHasEqual = struct
open LongId
fun eq_id ((x, _), (x', _)) = x = x'
fun eq_var a = eq_long_id eq_id a
end
                             
structure HasEqual = struct
open UVar
open Expr
open LongIdHasEqual
fun eq_name ((s, _) : name, (s', _)) = s = s'
end
                       
structure Equal = EqualFn (structure IdxType = struct
                           structure Idx = Expr.Idx
                           structure Type = Expr.Type
                           end
                           structure HasEqual = HasEqual
                           val str_raw_mt = ToStringRaw.str_raw_mt
                          )
                          
structure Subst = SubstFn (structure IdxType = struct
                           structure Idx = Expr.Idx
                           structure Type = Expr.Type
                           end
                           structure SubstableVar = LongIdSubst
)
                          
structure ExprVisitor = ExprVisitorFn (structure S = Expr
                                       structure T = Expr)

structure ExprShift = ExprShiftFn (structure Expr = Expr
                                   structure ShiftableVar = LongIdSubst
                                   open Subst
                                  )
                                      
structure ExprSubst = ExprSubstFn (structure Expr = Expr
                                   open Subst)
                                      
structure Simp = SimpFn (structure Idx = Expr
                         val get_region_i = Expr.get_region_i
                         val get_region_p = Expr.get_region_p
                         val eq_i = Equal.eq_i
                         val eq_p = Equal.eq_p
                         val shift_i_i = Subst.shift_i_i
                         val forget_i_i = Subst.forget_i_i
                         val forget_i_p = Subst.forget_i_p
                         val subst_i_i = Subst.subst_i_i
                         val subst_i_s = Subst.subst_i_s
                         val substx_i_p = Subst.substx_i_p
                         val str_p = fn p => ToString.str_p Gctx.empty [] p
                        )
                        
structure SimpType = SimpTypeFn (structure Type = Expr
                                 val simp_i = Simp.simp_i
                                 val simp_s = Simp.simp_s
                                 val subst_i_mt = Subst.subst_i_mt
                        )
                        
structure VC = VCFn (structure Idx = Expr
                     val get_region_p = Expr.get_region_p
                     val str_bs = ToString.str_bs
                     val str_p = ToString.str_p
                     val simp_p = Simp.simp_p
                    )
                    
