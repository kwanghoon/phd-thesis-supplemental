functor WrapAbsPassFun(MicroTiMLDef : SIG_MICRO_TIML_DEF) : SIG_WRAP_ABS_PASS =
struct
open Util
infixr 0 $

structure MicroTiMLDef = MicroTiMLDef
open MicroTiMLDef
structure MicroTiMLUtil = MicroTiMLUtilFun(MicroTiMLDef)
open MicroTiMLUtil
structure AstTransformers = AstTransformersFun(MicroTiMLDef)
open AstTransformers
structure DerivTransformers = DerivTransformersFun(MicroTiMLDef)
open DerivTransformers

open ShiftCstr
open ShiftExpr
open SubstCstr
open SubstExpr

structure DerivAssembler = DerivAssemblerFun(MicroTiMLDef)
open DerivAssembler

fun meta_lemma ty =
  let
      val ((kctx, _), _, t, i) = extract_judge_typing ty
  in
      (KdAdmit (kctx, t, KType), KdAdmit (kctx, i, KTime))
  end

structure ExprDerivHelper = ExprDerivGenericOnlyDownTransformerFun(
    structure MicroTiMLDef = MicroTiMLDef
    structure Action =
    struct
    type kdown = unit
    type tdown = unit
    type down = kdown * tdown

    fun add_kind (_, ((), ())) = ((), ())
    fun add_type (_, ()) = ()

    fun on_ty_leaf (ty, ((), ())) = ty

    fun transform_proping (pr, ()) = pr
    fun transform_kinding (kd, ()) = kd
    fun transform_wfkind (wk, ()) = wk
    fun transform_tyeq (te, ()) = te

    fun transformer_typing on_typing (ty, ((), ())) =
      case ty of
          TyAbsC ((ctx, _, t, _), _, _, _) =>
          let
              val kd = fst $ meta_lemma ty
              val ty = ShiftCtx.shift0_ctx_ty ([], [t]) ty
          in
              SOME (on_typing (as_TyRec kd ty, ((), ())))
          end
        | TyAbs ((ctx, _, t, _), _, _) =>
          let
              val kd = fst $ meta_lemma ty
              val ty = ShiftCtx.shift0_ctx_ty ([], [t]) ty
          in
              SOME (on_typing (as_TyRec kd ty, ((), ())))
          end
        | TyRec (j, kd, ty) =>
          let
              fun unfold_ty ty wks =
                case ty of
                    TyAbsC (j, wk, va, ty) => unfold_ty ty (wk :: wks)
                  | _ => (ty, wks)
              val (ty, wks) = unfold_ty ty []
          in
              case ty of
                  TyAbs (j_abs, kd_arg, ty_body) =>
                  let
                      val ty_body = on_typing (ty_body, ((), ()))
                      val ty = as_TyAbs kd_arg ty_body
                      val ty = foldl (fn (wk, ty) => as_TyAbsC wk ty) ty wks
                  in
                      SOME (as_TyRec kd ty)
                  end
                | _ => raise (Impossible "WrapLambda")
          end
        | TyFix _ => raise (Impossible "WrapLambda")
        | _ => NONE
    end)

fun wrap_abs_deriv ty = ExprDerivHelper.transform_typing (ty, ((), ()))
end
