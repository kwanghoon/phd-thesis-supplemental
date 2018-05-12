functor HoistedDerivCheckerFun(MicroTiMLHoistedDef : SIG_MICRO_TIML_HOISTED_DEF) : SIG_HOISTED_DERIV_CHECKER =
struct
open List
open Util
infixr 0 $

structure MicroTiMLHoistedDef = MicroTiMLHoistedDef
open MicroTiMLHoistedDef
open MicroTiMLDef
structure MicroTiMLUtil = MicroTiMLUtilFun(MicroTiMLDef)
open MicroTiMLUtil
structure AstTransformers = AstTransformersFun(MicroTiMLDef)
open AstTransformers

open ShiftCstr
open ShiftExpr
open SubstCstr
open SubstExpr

exception CheckFail

fun assert b =
  if b then () else raise CheckFail

fun check_atyping ty =
  (case ty of
       ATyVar ((fctx, kctx, tctx), AEVar x, t) => assert (nth (tctx, x) = t)
     | ATyConst ((fctx, kctx, tctx), AEConst cn, t) => assert (const_type cn = t)
     | ATyFuncPointer ((fctx, kctx, tctx), AEFuncPointer f, t) => assert (nth (fctx, f) = t) 
     | ATyAppC ((ctx as (fctx, kctx, tctx), AEAppC (e, c), t), ty, kd) =>
       let
           val () = check_atyping ty
           val jty = extract_judge_atyping ty
           val jkd = extract_judge_kinding kd
           val () =
               case (#3 jty) of
                   CQuan (QuanForall, k, t') =>
                   let
                       val () = assert (#1 jty = ctx)
                       val () = assert (#2 jty = e)
                       val () = assert (#1 jkd = kctx)
                       val () = assert (#2 jkd = c)
                       val () = assert (#3 jkd = k)
                       val () = assert (t = subst0_c_c c t')
                   in
                       ()
                   end
                 | _ => assert false
       in
           ()
       end
     | ATyPack ((ctx as (fctx, kctx, tctx), AEPack (c, e), CQuan (QuanExists, k, t1)), kd1, kd2, ty) =>
       let
           val () = check_atyping ty
           val jkd1 = extract_judge_kinding kd1
           val jkd2 = extract_judge_kinding kd2
           val jty = extract_judge_atyping ty
           val () = assert (#1 jkd1 = kctx)
           val () = assert (#2 jkd1 = CExists (k, t1))
           val () = assert (#3 jkd1 = KType)
           val () = assert (#1 jkd2 = kctx)
           val () = assert (#2 jkd2 = c)
           val () = assert (#3 jkd2 = k)
           val () = assert (#1 jty = ctx)
           val () = assert (#2 jty = e)
           val () = assert (#3 jty = subst0_c_c c t1)
       in
           ()
       end
     | ATyInj ((ctx as (fctx, kctx, tctx), AEInj (inj, e), CBinOp (CBTypeSum, t1, t2)), ty, kd) =>
         let
             val () = check_atyping ty
             val jty = extract_judge_atyping ty
             val jkd = extract_judge_kinding kd
             val () = assert (#1 jty = ctx)
             val () = assert (#2 jty = e)
             val () = assert (#3 jty = (case inj of InjInl => t1 | InjInr => t2))
             val () = assert (#1 jkd = kctx)
             val () = assert (#2 jkd = (case inj of InjInl => t2 | InjInr => t1))
             val () = assert (#3 jkd = KType)
         in
             ()
         end
       | ATyFold ((ctx as (fctx, kctx, tctx), AEFold e, t), kd, ty) =>
         let
             val () = check_atyping ty
             val jkd = extract_judge_kinding kd
             val jty = extract_judge_atyping ty
             fun unfold_CApps t cs =
               case t of
                   CApp (t, c) => unfold_CApps t (c :: cs)
                 | _ => (t, cs)
             val (t1, cs) = unfold_CApps t []
             val () =
                 case t1 of
                     CRec (k, t2) =>
                     let
                         val () = assert (#1 jkd = kctx)
                         val () = assert (#2 jkd = t)
                         val () = assert (#3 jkd = KType)
                         val () = assert (#1 jty = ctx)
                         val () = assert (#2 jty = e)
                         val () = assert (#3 jty = CApps (subst0_c_c t1 t2) cs)
                     in
                         ()
                     end
                   | _ => assert false
         in
             ()
         end
     | ATySubTy ((ctx as (fctx, kctx, tctx), e, t2), ty, te) =>
       let
           val () = check_atyping ty
           val jty = extract_judge_atyping ty
           val jte = extract_judge_tyeq te
           val () = assert (#1 jty = ctx)
           val () = assert (#2 jty = e)
           val () = assert (#1 jte = kctx)
           val () = assert (#2 jte = #3 jty)
           val () = assert (#3 jte = t2)
       in
           ()
       end
     | _ => assert false)

and check_ctyping ty =
    (case ty of
         CTyProj ((ctx as (fctx, kctx, tctx), CEUnOp (EUProj p, e), t), ty) =>
         let
             val () = check_atyping ty
             val jty = extract_judge_atyping ty
             val () =
                 case (#3 jty) of
                     CBinOp (CBTypeProd, t1, t2) =>
                     let
                         val () = assert (#1 jty = ctx)
                         val () = assert (#2 jty = e)
                         val () = assert (t = (case p of ProjFst => t1 | ProjSnd => t2))
                     in
                         ()
                     end
                   | _ => assert false
         in
             ()
         end
       | CTyPair ((ctx, CEBinOp (EBPair, e1, e2), CBinOp (CBTypeProd, t1, t2)), ty1, ty2) =>
         let
             val () = check_atyping ty1
             val () = check_atyping ty2
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_atyping ty2
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#3 jty1 = t1)
             val () = assert (#1 jty2 = ctx)
             val () = assert (#2 jty2 = e2)
             val () = assert (#3 jty2 = t2)
         in
             ()
         end
       | CTyUnfold ((ctx as (fctx, kctx, tctx), CEUnOp (EUUnfold, e), t'), ty) =>
         let
             val () = check_atyping ty
             val jty = extract_judge_atyping ty
             fun unfold_CApps t cs =
               case t of
                   CApp (t, c) => unfold_CApps t (c :: cs)
                 | _ => (t, cs)
             val (t, cs) = unfold_CApps (#3 jty) []
             val () =
                 case t of
                     CRec (k, t1) =>
                     let
                         val () = assert (#1 jty = ctx)
                         val () = assert (#2 jty = e)
                         val () = assert (t' = CApps (subst0_c_c t t1) cs)
                     in
                         ()
                     end
                   | _ => assert false
         in
             ()
         end
       | CTyNew ((ctx, CEBinOp (EBNew, e1, e2), CTypeArr (t, j)), ty1, ty2) =>
         let
             val () = check_atyping ty1
             val () = check_atyping ty2
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_atyping ty2
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#3 jty1 = t)
             val () = assert (#1 jty2 = ctx)
             val () = assert (#2 jty2 = e2)
             val () = assert (#3 jty2 = CTypeNat j)
         in
             ()
         end
       | CTyRead ((ctx, CEBinOp (EURead, e1, e2), t), ty1, ty2, pr) =>
         let
             val () = check_atyping ty1
             val () = check_atyping ty2
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_atyping ty2
             val jpr = extract_judge_proping pr
             val (opr, j1, j2) = extract_p_bin_pred (#2 jpr)
             val () = assert (opr = PBNatLt)
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#3 jty1 = CTypeArr (t, j2))
             val () = assert (#1 jty2 = ctx)
             val () = assert (#2 jty2 = e2)
             val () = assert (#3 jty2 = CTypeNat j1)
         in
             ()
         end
       | CTyWrite ((ctx, CETriOp (ETWrite, e1, e2, e3), CConst CCTypeUnit), ty1, ty2, pr, ty3) =>
         let
             val () = check_atyping ty1
             val () = check_atyping ty2
             val () = check_atyping ty3
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_atyping ty2
             val jpr = extract_judge_proping pr
             val jty3 = extract_judge_atyping ty3
             val (opr, j1, j2) = extract_p_bin_pred (#2 jpr)
             val () = assert (opr = PBNatLt)
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#3 jty1 = CTypeArr (#3 jty3, j2))
             val () = assert (#1 jty2 = ctx)
             val () = assert (#2 jty2 = e2)
             val () = assert (#3 jty2 = CTypeNat j1)
             val () = assert (#1 jty3 = ctx)
             val () = assert (#2 jty3 = e3)
         in
             ()
         end
       | CTyAtom ((ctx, CEAtom e, t), ty) =>
         let
             val () = check_atyping ty
             val jty = extract_judge_atyping ty
             val () = assert (#1 jty = ctx)
             val () = assert (#2 jty = e)
             val () = assert (#3 jty = t)
         in
             ()
         end
       | CTySubTy ((ctx as (fctx, kctx, tctx), e, t2), ty, te) =>
         let
             val () = check_ctyping ty
             val jty = extract_judge_ctyping ty
             val jte = extract_judge_tyeq te
             val () = assert (#1 jty = ctx)
             val () = assert (#2 jty = e)
             val () = assert (#1 jte = kctx)
             val () = assert (#2 jte = #3 jty)
             val () = assert (#3 jte = t2)
         in
             ()
         end
       | CTyPrimBinOp ((ctx as (fctx, kctx, tctx), CEBinOp (EBPrim opr, e1, e2), t), ty1, ty2) =>
         let
             val () = check_atyping ty1
             val () = check_atyping ty2
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_atyping ty2
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#3 jty1 = pebinop_arg1_type opr)
             val () = assert (#1 jty2 = ctx)
             val () = assert (#2 jty2 = e2)
             val () = assert (#3 jty2 = pebinop_arg2_type opr)
             val () = assert (t = pebinop_result_type opr)
         in
             ()
         end
       | _ => assert false)

and check_htyping ty =
    (case ty of
         HTyLet ((ctx as (fctx, kctx, tctx), HELet (e1, e2), i), ty1, ty2) =>
         let
             val () = check_ctyping ty1
             val () = check_htyping ty2
             val jty1 = extract_judge_ctyping ty1
             val jty2 = extract_judge_htyping ty2
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#1 jty2 = (fctx, kctx, #3 jty1 :: tctx))
             val () = assert (#2 jty2 = e2)
             val () = assert (#3 jty2 = i)
         in
             ()
         end
       | HTyUnpack ((ctx as (fctx, kctx, tctx), HEUnpack (e1, e2), i), ty1, ty2) =>
         let
             val () = check_atyping ty1
             val () = check_htyping ty2
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_htyping ty2
             val () =
                 case (#3 jty1) of
                     CQuan (QuanExists, k, t) =>
                     let
                         val () = assert (#1 jty1 = ctx)
                         val () = assert (#2 jty1 = e1)
                         val () = assert (#1 jty2 = (fctx, k :: kctx, t :: map shift0_c_c tctx))
                         val () = assert (#2 jty2 = e2)
                         val () = assert (#3 jty2 = shift0_c_c i)
                     in
                         ()
                     end
                   | _ => assert false
         in
             ()
         end
       | HTyApp ((ctx, HEApp (e1, e2), CBinOp (CBTimeAdd, T1, i)), ty1, ty2) =>
         let
             val () = check_atyping ty1
             val () = check_atyping ty2
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_atyping ty2
             val () = assert (#1 jty1 = ctx)
             val () = assert (#2 jty1 = e1)
             val () = assert (#3 jty1 = CArrow (#3 jty2, i, CTypeUnit))
             val () = assert (#1 jty2 = ctx)
             val () = assert (#2 jty2 = e2)
         in
             ()
         end
       | HTyCase ((ctx as (fctx, kctx, tctx), HECase (e, e1, e2), CBinOp (CBTimeMax, i1, i2)), ty1, ty2, ty3) =>
         let
             val () = check_atyping ty1
             val () = check_htyping ty2
             val () = check_htyping ty3
             val jty1 = extract_judge_atyping ty1
             val jty2 = extract_judge_htyping ty2
             val jty3 = extract_judge_htyping ty3
             val () =
                 case (#3 jty1) of
                     CBinOp (CBTypeSum, t1, t2) =>
                     let
                         val () = assert (#1 jty1 = ctx)
                         val () = assert (#2 jty1 = e)
                         val () = assert (#1 jty2 = (fctx, kctx, t1 :: tctx))
                         val () = assert (#2 jty2 = e1)
                         val () = assert (#3 jty2 = i1)
                         val () = assert (#1 jty3 = (fctx, kctx, t2 :: tctx))
                         val () = assert (#2 jty3 = e2)
                         val () = assert (#3 jty3 = i2)
                     in
                         ()
                     end
                   | _ => assert false
         in
             ()
         end
       | HTyHalt ((ctx as (fctx, kctx, tctx), HEHalt e, T0), ty) =>
         let
             val () = check_atyping ty
             val jty = extract_judge_atyping ty
             val () = assert (#1 jty = ctx)
             val () = assert (#2 jty = e)
         in
             ()
         end
       | HTySubTi ((ctx as (fctx, kctx, tctx), e, i2), ty, pr) =>
         let
             val () = check_htyping ty
             val jty = extract_judge_htyping ty
             val jpr = extract_judge_proping pr
             val () = assert (#1 jty = ctx)
             val () = assert (#2 jty = e)
             val () = assert (#1 jpr = kctx)
             val () = assert (#2 jpr = TLe (#3 jty, i2))
         in
             ()
         end
       | _ => assert false)

and check_ftyping ty =
    (case ty of
         FTyFix ((fctx, FEFix (n, e), t), kd, ty) =>
         let
             val () = check_htyping ty
             val jkd = extract_judge_kinding kd
             val jty = extract_judge_htyping ty
             val () = assert (#1 jkd = [])
             val () = assert (#2 jkd = t)
             val () = assert (#3 jkd = KType)
             fun unfold_CForalls t ks =
               case t of
                   CQuan (QuanForall, k, t) => unfold_CForalls t (k :: ks)
                 | _ => (t, ks)
             val (it, ks) = unfold_CForalls t []
             val () = assert (n = length ks)
             val () =
                 case it of
                     CArrow (t1, i, CTypeUnit) =>
                     let
                         val () = assert (#1 jty = (fctx, ks, [t1, t]))
                         val () = assert (#2 jty = e)
                         val () = assert (#3 jty = i)
                     in
                         ()
                     end
                   | _ => assert false
         in
             ()
         end)

and check_program ty =
    (case ty of
         TyProgram ((Program (exprs, body), i), typings, ty) =>
         let
             val () = List.app check_ftyping typings
             val () = check_htyping ty
             val fctx = List.map (fn ty => #3 (extract_judge_ftyping ty)) typings
             val () = List.app (fn ty => assert ((#1 (extract_judge_ftyping ty)) = fctx)) typings
             val jty = extract_judge_htyping ty
             val () = assert (#1 jty = (fctx, [], []))
             val () = assert (#2 jty = body)
             val () = assert (#3 jty = i)
         in
             ()
         end)
end
