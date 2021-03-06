functor IdxUtilFn (Idx : IDX where type name = string * Region.region
                                         and type region = Region.region
                  ) = struct

open Idx
open Operators
open Util
open Region
       
infixr 0 $

(* some shorthands *)

fun ITime (s, r) = IConst (ICTime s, r)
fun INat (d, r) = IConst (ICNat d, r)
fun IBool (d, r) = IConst (ICBool d, r)
fun T0 r = ITime (TimeType.zero, r)
fun is_T0 i =
  case i of
      IConst (ICTime s, _) => TimeType.time_eq (s, TimeType.zero)
    | _ => false
fun is_N0 i =
  case i of
      IConst (ICNat n, _) => n = 0
    | _ => false
fun T1 r = ITime (TimeType.one, r)
fun N0 r = INat (0, r)
fun N1 r = INat (1, r)
fun IDiv (i, (n, r)) = IUnOp (IUDiv n, i, r)
(* fun ExpI (i, (s, r)) = IUnOp (IUExp s, i, r) *)
fun IMod (a, b) = IBinOp (IBMod (), a, b)
fun IXor (a, b) = IBinOp (IBXor (), a, b)
fun ITrue r = IConst (ICBool true, r)
fun IFalse r = IConst (ICBool false, r)
fun ITT r = IConst (ICTT (), r)
fun IAdmit r = IConst (ICAdmit (), r)
fun PTrue r = PTrueFalse (true, r)
fun PFalse r = PTrueFalse (false, r)
fun PEq (a, b) = PBinPred (BPEq (), a, b)             
fun IMax (i1, i2) = IBinOp (IBMax (), i1, i2)
fun IToReal (i, r) = IUnOp (IUToReal (), i, r)                           
fun IFloor (i, r) = IUnOp (IUFloor (), i, r)
fun ICeil (i, r) = IUnOp (IUCeil (), i, r)
fun ILog (base, i, r) = IUnOp (IULog base, i, r)
fun INeg (i, r) = IUnOp (IUNeg (), i, r)
fun IEq (a, b) = IBinOp (IBEq (), a, b)
fun INeq (a, b) = INeg (IEq (a, b), dummy)

(* notations *)
         
infix 9 %@
infix 8 %**
infix 7 %*
infix 7 %/
infix 6 %+ 
infix 4 %<
infix 4 %>
infix 4 %<=
infix 4 %>=
infix 4 %=
infix 4 <?
infix 4 >?
infix 4 <=?
infix 4 >=?
infix 4 =?
infix 4 <>?
infixr 3 /\
infixr 3 /\?
infixr 2 \/
infixr 2 \/?
infixr 1 -->
infix 1 <->

fun a %@ b = IBinOp (IBApp (), a, b)
fun a %** b = IBinOp (IBExpN (), a, b)
fun a %* b = IBinOp (IBMult (), a, b)
fun a %/ b = IDiv (a, b)
fun a %+ b = IBinOp (IBAdd (), a, b)
fun a %< b = PBinPred (BPLt (), a, b)
fun a %> b = PBinPred (BPGt (), a, b)
fun a %<= b = PBinPred (BPLe (), a, b)
fun a %>= b = PBinPred (BPGe (), a, b)
fun a %= b = PEq (a, b)
fun a <? b = IBinOp (IBLt (), a, b)
fun a >? b = IBinOp (IBGt (), a, b)
fun a <=? b = IBinOp (IBLe (), a, b)
fun a >=? b = IBinOp (IBGe (), a, b)
fun a =? b = IBinOp (IBEq (), a, b)
fun a <>? b = INeq (a, b)
fun a /\ b = PBinConn (BCAnd (), a, b)
fun a \/ b = PBinConn (BCOr (), a, b)
fun a /\? b = IBinOp (IBAnd (), a, b)
fun a \/? b = IBinOp (IBOr (), a, b)
fun a --> b = PBinConn (BCImply (), a, b)
fun a <-> b = PBinConn (BCIff (), a, b)
                      
fun combine_And ps = foldl' (fn (p, acc) => acc /\ p) (PTrue dummy) ps
                            
fun collect_IBinOp opr i =
  case i of
      IBinOp (opr', i1, i2) =>
      if opr' = opr then
        collect_IBinOp opr i1 @ collect_IBinOp opr i2
      else [i]
    | _ => [i]
             
fun collect_IBinOp_left opr i =
  case i of
      IBinOp (opr', i1, i2) =>
      if opr' = opr then
        collect_IBinOp_left opr i1 @ [i2]
      else [i]
    | _ => [i]
             
val collect_IBAdd = collect_IBinOp (IBAdd ())
val collect_IBAdd_left = collect_IBinOp_left (IBAdd ())
val collect_IBMult = collect_IBinOp (IBMult ())
val collect_IBMax = collect_IBinOp (IBMax ())

fun combine_IBinOp f init is = foldl' (fn (i, acc) => f (acc, i)) init is
fun combine_IBinOp_nonempty f is = foldl_nonempty (fn (i, acc) => f (acc, i)) is
                                    
fun combine_IBAdd zero is = combine_IBinOp op%+ zero is
fun combine_IBAdd_Time is = combine_IBAdd (T0 dummy) is
fun combine_IBAdd_Nat is = combine_IBAdd (N0 dummy) is
fun combine_IBAdd_nonempty (i, is) = combine_IBinOp_nonempty op%+ (i :: is)
fun combine_IBMult one is = combine_IBinOp op%* one is
fun combine_IBMult_nonempty (i, is) = combine_IBinOp_nonempty op%* (i :: is)
fun combine_IBMax_nonempty (i, is) = combine_IBinOp_nonempty IMax (i :: is)
                                            
fun collect_PBinConn opr i =
  case i of
      PBinConn (opr', i1, i2) =>
      if opr' = opr then
        collect_PBinConn opr i1 @ collect_PBinConn opr i2
      else [i]
    | _ => [i]
             
val collect_PAnd = collect_PBinConn (BCAnd ())

fun collect_IBApp i =
  case collect_IBinOp_left (IBApp ()) i of
      f :: args => (f, args)
    | [] => raise Impossible "collect_IBApp(): null"

open Bind
       
fun collect_IAbs i =
  case i of
      IAbs (b, Bind ((name, _), i), _) =>
      let
        val (bs_names, i) = collect_IAbs i
      in
        ((b, name) :: bs_names, i)
      end
    | _ => ([], i)

fun is_time_fun b =
  case b of
      BSBase Time => SOME 0
    | BSArrow (BSBase Nat, b) =>
      opt_bind (is_time_fun b) (fn n => opt_return $ 1 + n)
    | _ => NONE
             
fun collect_BSArrow b =
  case b of
      BSBase _ => ([], b)
    | BSArrow (a, b) =>
      let
        val (args, ret) = collect_BSArrow b
      in
        (a :: args, ret)
      end
    | BSUVar u => ([], b)

fun combine_BSArrow (args, b) = foldr BSArrow b args
                    
fun is_IBApp_IUVar i =
  let
    val (f, args) = collect_IBApp i
  in
    case f of
        IUVar (x, r) => SOME ((x, r), args)
      | _ => NONE
  end
    
fun collect_SApp s =
  case s of
      SApp (s, i) =>
      let 
        val (s, is) = collect_SApp s
      in
        (s, is @ [i])
      end
    | _ => (s, [])
             
fun is_SApp_SUVar s =
  let
    val (f, args) = collect_SApp s
  in
    case f of
        SUVar (x, r) => SOME ((x, r), args)
      | _ => NONE
  end
    
fun IApps f args = foldl (fn (arg, f) => IBinOp (IBApp (), f, arg)) f args
fun SApps f args = foldl (fn (arg, f) => SApp (f, arg)) f args
                         
fun SAbs_Many (ctx, s, r) = foldr (fn ((name, s_arg), s) => SAbs (s_arg, Bind ((name, r), s), r)) s ctx
fun IAbs_Many (ctx, i, r) = foldr (fn ((name, b), i) => IAbs (b, Bind ((name, r), i), r)) i ctx
                                 
fun interp_ibool_expr_bin_op opr (i1, i2) =
  case opr of
      EBBAnd () => i1 /\? i2
    | EBBOr () => i1 \/? i2
    | EBBXor () => IXor (i1, i2)
         
fun interp_nat_expr_bin_op opr (i1, i2) err =
  case opr of
      EBNAdd () => i1 %+ i2
    | EBNBoundedMinus () => IBinOp (IBBoundedMinus (), i1, i2)
    | EBNMult () => i1 %* i2
    | EBNDiv () =>
      (case i2 of
          IConst (ICNat n, r) => IUnOp (IUFloor (), IUnOp (IUDiv n, IUnOp (IUToReal (), i1, r), r), r)
        | _ => err ()
      )
    | EBNMod () => IMod (i1, i2)
    | EBNExp () => i1 %** i2
         
fun interp_nat_cmp r opr =
  let
    fun neq (a, b) = IUnOp (IUNeg (), a =? b, r)
  in
  case opr of
      NCLt () => op<?
    | NCGt () => op>?
    | NCLe () => op<=?
    | NCGe () => op>=?
    | NCEq () => op=?
    | NCNEq () => neq
  end
    
fun IUnion (a, b) = IBinOp (IBUnion (), a, b)
val collect_IUnion = collect_IBinOp (IBUnion ())
fun combine_IUnion i is = foldl (fn (i, acc) => IUnion (acc, i)) i is
val IEmptyState = IState StMap.empty
                         
infix 6 %%+ 
infix 4 %%<=

fun unop_pair f (a, b) = (f a, f b)
fun binop_pair f ((a, b), (a', b')) = (f (a, a'), f (b, b'))
fun IAddPair a = binop_pair op%+ a
val op%%+ = IAddPair
fun IMaxPair a = binop_pair IMax a
fun ILePair a = op/\ $ binop_pair op%<= a
val op%%<= = ILePair                                             

fun TN0 r = (T0 r, N0 r)
              
fun combine_IBAdd_Time_Nat ls =
  let
    val (is, js) = unzip ls
  in
    (combine_IBAdd_Time is, combine_IBAdd_Nat js)
  end

end
