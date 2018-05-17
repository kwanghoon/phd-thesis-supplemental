structure SimpUtil = struct

open Bind
       
fun simp_bind f (Bind (name, inner)) = Bind (name, f inner)
fun simp_binds f_cls f binds =
  case binds of
      BindNil a => BindNil (f a)
    | BindCons (cls, bind) => BindCons (f_cls cls, simp_bind (simp_binds f_cls f) bind)

end

signature SIMP_PARAMS = sig
  structure Idx : IDX where type var = int LongId.long_id
                                 and type base_sort = BaseSorts.base_sort
                                          and type name = string * Region.region
                                                   and type region = Region.region
                                                            and type 'idx exists_anno = ('idx -> unit) option
  val get_region_i : Idx.idx -> Region.region
  val get_region_p : Idx.prop -> Region.region
  val eq_i : Idx.idx -> Idx.idx -> bool
  val eq_p : Idx.prop -> Idx.prop -> bool
  val shift_i_i : Idx.idx -> Idx.idx
  val forget_i_i : int -> int -> Idx.idx -> Idx.idx
  val forget_i_p : int -> int -> Idx.prop -> Idx.prop
  val subst_i_i : Idx.idx -> Idx.idx -> Idx.idx
  val subst_i_s : Idx.idx -> Idx.sort -> Idx.sort
  val substx_i_p : int -> int -> Idx.idx -> Idx.prop -> Idx.prop
  val str_p : Idx.prop -> string
end

functor SimpFn (Params : SIMP_PARAMS) = struct

open Params
open Idx
open SimpUtil
open Region
open Operators
open Util
open ShiftUtil
open LongId
open Hyp
open BaseSorts
       
structure IdxUtil = IdxUtilFn (Idx)
open IdxUtil

infixr 0 $

infix 9 %@
infix 8 %^
infix 7 %*
infix 6 %+ 
infix 4 %<=
infix 4 %>=
infix 4 %=
infixr 3 /\
infixr 2 \/
infixr 1 -->
infix 1 <->
        
local
  open Bind
  val changed = ref false
  fun unset () = changed := false
  fun set () = changed := true
  fun mark a = (set (); a)
  fun passi i =
    let
      (* val () = println $ str_i [] [] i *)
      fun r () = get_region_i i
      fun reduce_IBinOps (collect_opr, combine_opr, combine_nat, combine_time) i =
        let
          fun simp_consts ls =
            let
              val (nats, times, others) =
                  partition3 (fn (c, r) =>
                                 case c of
                                     ICNat n => inl (n, r)
                                   | ICTime x => inr $ inl (x, r)
                                   | _ => inr $ inr (c, r)
                             ) ls
              fun combine f ls =
                if length ls >= 2 then
                  mark $ [foldl_nonempty (fn ((a, _), (b, r)) => (f (a, b), r)) ls]
                else ls
              val nats = combine combine_nat nats
              val times = combine combine_time times
            in
              map (mapFst ICNat) nats @ map (mapFst ICTime) times @ others
            end
          val is = collect_opr i
          val is = map passi is
          val (consts, toReal_consts, others) =
              partition3
                (fn i =>
                    case i of
                        IConst (c, r) => inl (c, r)
                      | IUnOp (IUToReal (), IConst (c, _), r) => inr $ inl (c, r)
                      | _ => inr $ inr i) is
          val consts = simp_consts consts
          val toReal_consts = simp_consts toReal_consts
          val is = map IConst consts @ map (fn (c, r) => IToReal (IConst (c, r), r)) toReal_consts @ others
        in
          combine_opr $ assert_cons is
        end
    in
      case i of
	  IBinOp (opr, i1, i2) =>
          let
            fun def () = IBinOp (opr, passi i1, passi i2)
          in
            case opr of
	        IBMax () =>
	        if eq_i i1 i2 then
                  mark i1
	        else if eq_i i1 (T0 dummy) orelse eq_i i1 (INat (0, dummy)) then
                  mark i2
	        else if eq_i i2 (T0 dummy) orelse eq_i i2 (INat (0, dummy)) then
                  mark i1
	        else
                  (case (i1, i2) of
                       (IBinOp (opr, i1, i2), IBinOp (opr', i1', i2')) =>
                       if opr = opr' then
                         if opr = IBAdd () orelse opr = IBMult () then
                           if eq_i i1 i1' then
                             mark $ IBinOp (opr, i1, IBinOp (IBMax (), i2, i2'))
                           else if eq_i i2 i2' then
                             mark $ IBinOp (opr, IBinOp (IBMax (), i1, i1'), i2)
                           else def ()
                         else if opr = IBApp () then
                           if eq_i i1 i1' then
                             mark $ IBinOp (opr, i1, IBinOp (IBMax (), i2, i2'))
                           else def ()
                         else def ()
                       else def ()
                     | _ => def ()
                  )
	      | IBMin () =>
	        if eq_i i1 i2 then
                  mark i1
	        else
		  def ()
	      | IBAdd () => 
	        if eq_i i1 (T0 dummy) orelse eq_i i1 (INat (0, dummy)) then
                  mark i2
	        else if eq_i i2 (T0 dummy) orelse eq_i i2 (INat (0, dummy)) then
                  mark i1
	        else
                  reduce_IBinOps (collect_IBAdd, combine_IBAdd_nonempty, op+, TimeType.add) i
	      | IBMult () => 
	        if eq_i i1 (T0 dummy) then
                  mark $ T0 $ r ()
	        else if eq_i i2 (T0 dummy) then
                  mark $ T0 $ r ()
	        else if eq_i i1 (T1 dummy) then
                  mark i2
	        else if eq_i i2 (T1 dummy) then
                  mark i1
	        else
                  let
                    fun reduce () = reduce_IBinOps (collect_IBMult, combine_IBMult_nonempty, op*, TimeType.mult) i
                    val i2s = collect_IBAdd i2
                    fun pred i =
                      case i of
                          IConst (ICNat _, _) => SOME i
                        | IUnOp (IUB2n (), _, _) => SOME i
                        | _ => NONE
                  in
                    case partitionOptionFirst pred i2s of
                        NONE => reduce ()
                      | SOME (i2, rest) =>
                        case rest of
                            [] => reduce ()
                          | hd :: rest => i1 %* i2 %+ i1 %* combine_IBAdd_nonempty (hd, rest)
                  end
              | IBApp () =>
                (case (* passi *) i1 of
                     IAbs (_, Bind (_, body), _) =>
                     (* passi $ *) mark $ subst_i_i (passi i2) body
		   | _ => def ()
                )
              | IBEq () =>
                if eq_i i1 i2 then
                  mark $ ITrue $ r ()
                else def ()
              | IBAnd () =>
                if eq_i i1 (ITrue dummy) then
                  mark i2
                else if eq_i i2 (ITrue dummy) then
                  mark i1
                else if eq_i i1 (IFalse dummy) then
                  mark $ IFalse $ r ()
                else if eq_i i2 (IFalse dummy) then
                  mark $ IFalse $ r ()
                else
                  def ()
              | IBOr () =>
                if eq_i i1 (IFalse dummy) then
                  mark i2
                else if eq_i i2 (IFalse dummy) then
                  mark i1
                else if eq_i i1 (ITrue dummy) then
                  mark $ ITrue $ r ()
                else if eq_i i2 (ITrue dummy) then
                  mark $ ITrue $ r ()
                else
                  def ()
              | IBExpN () =>
                let
                  val r = r ()
                  fun exp i n =
                    if n > 0 then
                      exp i (n-1) %* i
                    else
                      N1 r
                in
                  case i2 of
                      IConst (ICNat n, _) => if n <= 8 then mark $ exp i1 n else def ()
                    | IUnOp (IUB2n (), i, _) => IIte (i, i1, N1 r, r)
                    | _ =>
                      let
                        val i2s = collect_IBAdd i2
                        fun pred i =
                          case i of
                              IConst (ICNat _, _) => SOME i
                            | IUnOp (IUB2n (), _, _) => SOME i
                            | _ => NONE
                      in
                        case partitionOptionFirst pred i2s of
                            SOME (i2, rest) => mark $ i1 %^ i2 %* i1 %^ combine_IBAdd_Nat rest
                          | NONE => def ()
                      end
                end
              | IBMod () => def ()
              | IBLt () => def ()
              | IBGt () => def ()
              | IBLe () => def ()
              | IBGe () => def ()
              | IBBoundedMinus () =>
	        if eq_i i2 (T0 dummy) orelse eq_i i2 (N0 dummy) then
                  mark i1
	        else
                  (case (i1, i2) of
                       (IConst (ICNat n1, _), IConst (ICNat n2, _)) =>
                       mark $ INat (bounded_minus n1 n2, r ())
                     | _ => def ())
              | IBMinus () =>
	        if eq_i i2 (T0 dummy) orelse eq_i i2 (N0 dummy) then
                  mark i1
	        else
                  def ()
              (* | IBMinus () => raise Impossible "simp_p()/MinusI" *)
              | IBUnion () => def ()
          end
        | IIte (i, i1, i2, r) =>
          if eq_i i (ITrue dummy) then
            mark i1
          else if eq_i i (IFalse dummy) then
            mark i2
          else
            IIte (passi i, passi i1, passi i2, r)
        | IUnOp (opr, i, r) =>
          let
            fun default () = IUnOp (opr, passi i, r)
          in
            case opr of
                IUDiv n => IDiv (passi i, (n, r))
              (* | IUExp s => ExpI (passi i, (s, r)) *)
              | IUToReal () =>
                (case i of
                     IBinOp (IBAdd (), i1, i2) =>
                     mark $ IBinOp (IBAdd (), IUnOp (IUToReal (), i1, r), IUnOp (IUToReal (), i2, r))
                   | IBinOp (IBMult (), i1, i2) =>
                     mark $ IBinOp (IBMult (), IUnOp (IUToReal (), i1, r), IUnOp (IUToReal (), i2, r))
                   | IConst (ICNat n, _) =>
                     mark $ ITime (TimeType.fromInt n, r)
                   | _ => default ()
                )
              | IUNeg () =>
                (case i of
                     IConst (ICBool b, r) => mark $ IConst (ICBool (not b), r)
                   | _ => default ()
                )
              | IUB2n () =>
                (case i of
                     IConst (ICBool b, r) => mark $ IConst (ICNat (b2i b), r)
                   | _ => default ()
                )
              | _ => default ()
          end
        | IConst _ => i
        | IAbs (b, Bind (name, i), r) =>
          IAbs (b, Bind (name, passi i), r)
        | IVar _ => i
        | IUVar _ => i
        | IState st => IState $ StMap.map passi st
    end
      
  fun passp p =
    let
      fun r () = get_region_p p
                              (* val () = println $ str_p p *)
    in
      case p of
	  PBinConn (opr, p1, p2) =>
          let
            fun def () = PBinConn (opr, passp p1, passp p2) 
          in
            case opr of
                BCAnd () =>
	        if eq_p p1 (PTrue dummy) then
                  mark p2
	        else if eq_p p2 (PTrue dummy) then
                  mark p1
	        else
	          def ()
              | BCOr () =>
	        if eq_p p1 (PFalse dummy) then
                  mark p2
	        else if eq_p p2 (PFalse dummy) then
                  mark p1
	        else
	          def ()
              | BCImply () =>
	        if eq_p p1 (PTrue dummy) then
                  mark p2
                else if eq_p p2 (PTrue dummy) then
                  mark $ PTrue $ r ()
                else
                  (case p1 of
                       PBinConn (BCAnd (), p1a, p1b) =>
                       mark $ (p1a --> p1b --> p2)
                     | _ => def ()
                  )
              | _ => def ()
          end
	| PBinPred (opr, i1, i2) =>
          let
            fun def () = PBinPred (opr, passi i1, passi i2)
          in
            case opr of 
                BPEq () => if eq_i i1 i2 then
                         mark $ PTrue $ r ()
                       else def ()
              | BPLe () => if eq_i i1 i2 orelse eq_i i1 (T0 dummy) then
                         mark $ PTrue $ r ()
                       else def ()
              | _ => def ()
          end
        | PNot (p, r) => PNot (passp p, r)
        | p_all as PQuan (q, bs, Bind (name, p), r_all) =>
          let
            fun def () = PQuan (q, bs, Bind (name, passp p), r_all)
            fun try_forget_p p =
              let
                fun def () = try_forget (forget_i_p 0 1) p
              in
                case p of
                    PBinConn (BCImply (), PBinPred (BPBigO (), IVar (ID (x, _), _), f), p) =>
                    if x = 0 then
                      (* ignore this variable if the only thing mentioning it is a BigO premise *)
                      (case (try_forget (forget_i_p 0 1) p, try_forget (forget_i_i 0 1) f) of
                           (SOME p, SOME _) => SOME p
                         | _ => def ()
                      )
                    else def ()
                  | _ => def ()
              end                          
          in
            case q of
                Forall () =>
                (case try_forget_p p of
                     SOME p => (set (); p)
                   | _ =>
                     (* try subst if there is a equality premise *)
                     let
                       fun collect_Imply_Forall p =
                         let
                           fun loop (acc, p) =
                             case p of
                                 PBinConn (BCImply (), p1, p2) =>
                                 loop (map PropH (rev $ collect_PAnd p1) @ acc, p2)
                               | PQuan (Forall (), bs, Bind (name, p), r) =>
                                 loop (VarH (name, (bs, r)) :: acc, p)
                               | _ => (acc, p)
                           val (hyps, conclu) = loop ([], p)
                           val hyps = rev hyps
                         in
                           (hyps, conclu)
                         end
                       fun combine_Imply_Forall hyps conclu =
                         let
                           fun iter (h, conclu) =
                             case h of
                                 PropH p =>
                                 p --> conclu
                               | VarH (name, (bs, r))  =>
                                 PQuan (Forall (), bs, Bind (name, conclu), r)
                         in
                           foldr iter conclu hyps
                         end
                       val (hyps, conclu) = collect_Imply_Forall p
                       val hyps = rev hyps
                       val binds_len = length $ hyps2ctx hyps
                       (* test whether [p] is [IVar x = _] or [_ = IVar x] *)
                       fun is_var_equals x p =
                         let
                           fun find_var (i1, i2) =
                             if eq_i i1 (IVar (ID (x, dummy), [])) then
                               SOME (forget_i_i x 1 i2) handle ForgetError _ => NONE
                             else NONE
                         in
                           case p of
                               PBinPred (BPEq (), i1, i2) => firstSuccess find_var [(i1, i2), (i2, i1)]
                             | _ => NONE
                         end
                       fun foldr_hyps shift1 shift2 f init hyps =
                         let
                           fun iter (h, (x, acc)) =
                             case h of
                                 VarH _ => (shift1 x, Option.map shift2 acc)
                               | PropH p =>
                                 case acc of
                                     SOME _ => (x, acc)
                                   | NONE => (x, f x p)
                         in
                           snd $ foldr iter (init, NONE) hyps
                         end
                       val shiftx_v = shiftx_int
                       fun forget_v a = forget_int ForgetError a
                     in
                       case foldr_hyps (fn x => shiftx_v 0 1 x) shift_i_i is_var_equals 0 hyps of
                           SOME i =>
                           (let
                             val x = binds_len
                             val ctxn = map fst $ hyps2ctx hyps
                             (* val () = println $ sprintf "Substing for $ with $" [str_v (ctxn @ [fst name]) x, str_i ctxn i] *)
                             (* val () = app println $ str_hyps_conclu (hyps @ [VarH (name, (bs, r_all))], conclu) @ [""]  *)
                             val conclu = substx_i_p 0 x i conclu
                             fun subst_hyp n p =
                               let
                                 val x = forget_v 0 n x
                                 val p =
                                     case try_forget (forget_i_p x 1) p of
                                         NONE =>
                                         let
                                           val i = forget_i_i 0 n i
                                         in
                                           substx_i_p 0 x i p
                                         end
                                       | SOME p => p
                               in
                                 p
                               end
                             fun foldl_hyps f hyps =
                               let
                                 fun iter (h, (n, acc)) =
                                   case h of
                                       VarH _ => (n + 1, h :: acc)
                                     | PropH p => (n, PropH (f n p) :: acc)
                               in
                                 rev $ snd $ foldl iter (0, []) hyps
                               end
                             val hyps = foldl_hyps subst_hyp hyps
                             (* val () = app println $ str_hyps_conclu (hyps, conclu) @ [""]  *)
                             val ret = combine_Imply_Forall (rev hyps) conclu
                           in
                             mark ret
                           end
                            handle ForgetError _ => def ()
                           )
                         | NONE => def ()
                     end
                )
              | Exists ins =>
                (* for unconstrained Time evar, infer it to be 0 *)
                let
                  (* val () = println $ str_p [] [] p_all *)
                  val p = passp p
                  (* val () = println $ str_bs bs *)
                  fun base_sort_default_idx b =
                    case b of
                        BSSNat () =>
                        N0 dummy
                      | BSSTime () =>
                        T0 dummy
                      | BSSBool () =>
                        IFalse dummy
                      | BSSUnit () =>
                        ITT dummy
                      | BSSState () => IEmptyState
                  fun bsort_default_idx bs =
                    case bs of
                        BSBase b => SOME $ base_sort_default_idx b
                      | BSArrow (a, b) =>
                        opt_bind (bsort_default_idx b)
                                 (fn i => opt_return $ IAbs (a, Bind (("__dummy_default", dummy), i), dummy))
                      | _ => NONE
                  val inferred =
                      opt_bind
                        (try_forget (forget_i_p 0 1) p)
                        (fn p =>
                            opt_bind
                              (bsort_default_idx bs)
                              (fn i =>
                                  opt_return (p, i)))
                in
                  case inferred of
                      SOME (p, v) =>
                      let
                        val () = set ()
                        (* val () = println "before" *)
                        val () = case ins of
                                     SOME f => f v
                                   | NONE => ()
                                               (* val () = println "after" *)
                      in
                        p
                      end
                    | _ =>
                      let
                        val ps = collect_PAnd p
                        val (irrelevant, relevant) = partitionOption (try_forget (forget_i_p 0 1)) ps
                      in
                        case relevant of
                            [] => def ()
                          | _ => combine_And $ PQuan (q, bs, Bind (name, combine_And relevant), r_all) :: irrelevant
                      end
                end
          end
	| PTrueFalse _ => p
    end
      
  fun until_unchanged f a = 
    let fun loop a =
	  let
            val _ = unset ()
            (* val () = println "before f()" *)
            val a = f a
                      (* val () = println "after f()" *)
          in
	    if !changed then loop a
	    else a
	  end
    in
      loop a
    end
in

fun simp_i i =
  let
    (* val () = println $ "Before simp_i: " ^ str_i [] [] i *)
    val i = until_unchanged passi i
                            (* val () = println $ "After simp_i:  " ^ str_i [] [] i *)
                            (* val () = println "" *)
  in
    i
  end

fun simp_i_with_plugin plugin i =
  let
    fun iter i =
      let
        val i = plugin set i
        val i = passi i
      in
        i
      end
    val i = until_unchanged iter i
  in
    i      
  end
    
fun simp_p p =
  let
    (* val () = println $ "Before simp_p: " (* ^ str_p [] [] p *) *)
    val p = until_unchanged passp p
                            (* val () = println $ "After simp_p:  " (* ^ str_p [] [] p *) *)
                            (* val () = println "" *)
  in
    p      
  end
    
fun simp_p_with_plugin plugin p =
  let
    fun iter p =
      let
        val p = plugin set p
        val p = passp p
      in
        p
      end
    val p = until_unchanged iter p
  in
    p      
  end
    
end

fun simp_vc (ctx, ps, p, r) = (ctx, map simp_p ps, simp_p p, r)

fun simp_s s =
  case s of
      SBasic b => SBasic b
    | SSubset (b, bind, r) => SSubset (b, simp_bind simp_p bind, r)
    | SUVar u => SUVar u
    | SAbs (b, bind, r) => SAbs (b, simp_bind simp_s bind, r)
    | SApp (s, i) =>
      let
        val s = simp_s s
        val i = simp_i i
      in
        case s of
            SAbs (_, Bind (_, s), _) => simp_s (subst_i_s i s)
          | _ => SApp (s, i)
      end

end
