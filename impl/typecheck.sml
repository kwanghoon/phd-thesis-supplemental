structure TypeCheck = struct
open Region
structure U = UnderscoredExpr
open Expr
open VC

infixr 0 $

infix 6 %+
infix 6 %*
infix 4 %<=
infix 3 /\
infix 1 -->
infix 1 <->

fun is_value (e : expr) : bool =
    case e of
        Var _ => true
      | App _ => false
      | Abs _ => true
      | TT _ => true
      | Pair (e1, e2) => is_value e1 andalso is_value e2
      | Fst _ => false
      | Snd _ => false
      | AbsI _ => true
      | AppI _ => false
      | Pack (_, _, e) => is_value e
      | Unpack _ => false
      | Fix _ => false
      | Let _ => false
      | Ascription _ => false
      | AscriptionTime _ => false
      | BinOp _ => false
      | Const _ => true
      | AppConstr (_, _, e) => is_value e
      | Case _ => false
      | Never _ => false

fun is_fixpoint e =
    case e of
        Fix _ => true
      | _ => false

open Subst

(* sorting context *)
type scontext = (string * sort) list
(* kinding context *)
type kcontext = (string * kind) list 
(* constructor context *)
type ccontext = (string * constr) list
(* typing context *)
type tcontext = (string * ty) list
type context = scontext * kcontext * ccontext * tcontext

fun names (ctx : ('a * 'b) list) = map #1 ctx

fun shiftx_i_ps n ps = 
    map (shiftx_i_p 0 n) ps
fun shiftx_i_ks n ctx = 
    map (mapSnd (shiftx_i_k 0 n)) ctx
fun shiftx_i_cs n ctx = 
    map (mapSnd (shiftx_i_c 0 n)) ctx
fun shiftx_t_cs n ctx = 
    map (mapSnd (shiftx_t_c 0 n)) ctx
fun shiftx_i_ts n ctx = 
    map (mapSnd (shiftx_i_t 0 n)) ctx
fun shiftx_t_ts n ctx = 
    map (mapSnd (shiftx_t_t 0 n)) ctx

fun add_sorting pair pairs = pair :: pairs
fun add_sorting_sk pair (sctx, kctx) = 
    (add_sorting pair sctx, 
     shiftx_i_ks 1 kctx)
fun add_sorting_skc pair (sctx, kctx, cctx) = 
    (add_sorting pair sctx, 
     shiftx_i_ks 1 kctx,
     shiftx_i_cs 1 cctx)
fun add_sorting_skct pair (sctx, kctx, cctx, tctx) = 
    (add_sorting pair sctx, 
     shiftx_i_ks 1 kctx, 
     shiftx_i_cs 1 cctx, 
     shiftx_i_ts 1 tctx)
(* Within 'pairs', sort depends on previous sort *)
fun add_sortings_skct pairs' (pairs, kctx, cctx, tctx) : context = 
    let val n = length pairs' 
    in
        (pairs' @ pairs, 
         shiftx_i_ks n kctx, 
         shiftx_i_cs n cctx, 
         shiftx_i_ts n tctx)
    end
(* Within 'pairs', sort doesn't depend on previous sort. All of them point to 'sctx'. So the front elements of 'pairs' must be shifted to skip 'pairs' and point to 'sctx' *)
fun add_nondep_sortings pairs sctx = 
    #1 (foldr (fn ((name, s), (ctx, n)) => (add_sorting (name, (shiftx_i_s 0 n s)) ctx, n + 1)) (sctx, 0) pairs)
fun add_nondep_sortings_sk pairs (sctx, kctx) = 
    let val n = length pairs
    in
        (add_nondep_sortings pairs sctx,
         shiftx_i_ks n kctx)
    end
fun add_nondep_sortings_skc pairs (sctx, kctx, cctx) = 
    let val n = length pairs
    in
        (add_nondep_sortings pairs sctx,
         shiftx_i_ks n kctx,
         shiftx_i_ks n cctx)
    end

fun sctx_length (pairs : scontext) = length pairs
fun sctx_names (pairs : scontext) = map fst pairs

fun lookup_sort (n : int) (pairs : scontext) : sort option = 
    case nth_error pairs n of
        NONE => NONE
      | SOME (_, s) => 
        SOME (shiftx_i_s 0 (n + 1) s)

fun add_kinding pair (kctx : kcontext) = pair :: kctx
fun add_kinding_kc pair (kctx, cctx) = 
    (add_kinding pair kctx, 
     shiftx_t_cs 1 cctx)
fun add_kinding_kct pair (kctx, cctx, tctx) = 
    (add_kinding pair kctx,
     shiftx_t_cs 1 cctx,
     shiftx_t_ts 1 tctx)
fun add_kinding_skct pair (sctx, kctx, cctx, tctx) = 
    (sctx,
     add_kinding pair kctx,
     shiftx_t_cs 1 cctx,
     shiftx_t_ts 1 tctx)
fun add_kinding_sk pair (sctx, kctx) = 
    (sctx, 
     add_kinding pair kctx)
fun add_kindings_skct pairs (sctx, kctx, cctx, tctx) =
    let val n = length pairs in
        (sctx,
         pairs @ kctx,
         shiftx_t_cs n cctx,
         shiftx_t_ts n tctx)
    end

fun lookup_kind (n : int) kctx : kind option = 
    case nth_error kctx n of
        NONE => NONE
      | SOME (_, k) => SOME k

fun add_constrs_skct pairs (sctx, kctx, cctx, tctx) = 
    (sctx, 
     kctx, 
     pairs @ cctx,
     tctx)

fun add_typing pair tctx = pair :: tctx
fun add_typing_skct pair ((sctx, kctx, cctx, tctx) : context) : context = 
    (sctx, 
     kctx, 
     cctx,
     add_typing pair tctx)
fun add_typings_skct pairs (sctx, kctx, cctx, tctx) = 
    (sctx, 
     kctx, 
     cctx,
     pairs @ tctx)

fun lookup (n : int) (ctx : tcontext) : ty option = 
    case nth_error ctx n of
        NONE => NONE
      | SOME (_, t) => SOME t

fun ctx_names (sctx, kctx, cctx, tctx) =
    (sctx_names sctx, names kctx, names cctx, names tctx) 

fun add_ctx (sctx, kctx, cctx, tctx) ctx =
    let val ctx = add_sortings_skct sctx ctx
        val ctx = add_kindings_skct kctx ctx
        val ctx = add_constrs_skct cctx ctx
        val ctx = add_typings_skct tctx ctx
    in
        ctx
    end

fun add_ctx_skc ctx (sctx, kctx, cctx) =
    let val (sctx, kctx, cctx, _) = add_ctx ctx (sctx, kctx, cctx, []) in
        (sctx, kctx, cctx)
    end

fun shift_ctx_i (sctx, _, _, _) i =
    shiftx_i_i 0 (sctx_length sctx) i

fun shift_ctx_mt (sctx, kctx, _, _) t =
    (shiftx_t_mt 0 (length kctx) o shiftx_i_mt 0 (sctx_length sctx)) t

fun make_ctx_from_sorting ns = ([ns], [], [], [])

fun get_base s =
    case s of
        Basic (s, _) => s
      | Subset ((s, _), _) => s

(* exception Unimpl *)

exception Error of region * string list

fun runError m _ =
    OK (m ())
    handle
    Error e => Failed e

(* use cell to mimic the Writer monad *)
local								    

    datatype vc_entry =
             ForallVC of string * sort
             | ImplyVC of prop
             | AndVC of prop * region
             | AnchorVC of bsort anchor ref
             | CloseVC

    val acc = ref ([] : vc_entry list)

    fun runWriter m _ =
        (acc := []; let val r = m () in (r, rev (!acc)) end)

    fun write x = push_ref acc x

    fun open_vc (ctx as (sctx, _, _, _)) = (app write o map ForallVC o rev) sctx

    fun close_vc (ctx as (sctx, _, _, _)) = app (fn _ => write CloseVC) sctx

    fun open_vc_by_sorting ns = (write o ForallVC) ns

    fun close_vc_by_sorting _ = write CloseVC

    fun open_premises ps = (app write o map ImplyVC) ps

    fun close_premises nps = Range.app (fn _ => write CloseVC) (Range.zero_to nps)

    fun write_anchor anchor = write (AnchorVC anchor)

    fun write_and (p, r) = write (AndVC (p, r))

    fun write_le (d : idx, d' : idx, r) =
	write_and (d %<= d', r)
	          
    fun check_length_n r (ls, n) =
        if length ls = n then
	    ()
        else
	    raise Error (r, ["List length mismatch"])

    fun check_length r (a, b) =
        if length a = length b then
	    ()
        else
	    raise Error (r, ["List length mismatch"])

    fun update_i i =
        case i of
            UVarI ((invis, x), r) => 
            (case !x of
                 Refined i => 
                 let 
                     val i = update_i i
                     val () = x := Refined i
                 in
                     expand_i invis i
                 end
               | Fresh _ => i
            )
          | UnOpI (opr, i, r) => UnOpI (opr, update_i i, r)
          | BinOpI (opr, i1, i2) => BinOpI (opr, update_i i1, update_i i2)
          | VarI _ => i
          | ConstIN _ => i
          | ConstIT _ => i
          | TTI _ => i
          | TrueI _ => i
          | FalseI _ => i

    fun update_bs bs =
        case bs of
            UVarBS x =>
            (case !x of
                 Refined bs => 
                 let 
                     val bs = update_bs bs
                     val () = x := Refined bs
                 in
                     bs
                 end
               | Fresh _ => bs
            )
          | Base _ => bs

    fun update_s s =
        case s of
            UVarS ((invis, x), r) =>
            (case !x of
                 Refined s => 
                 let 
                     val s = update_s s
                     val () = x := Refined s
                 in
                     expand_s invis s
                 end
               | Fresh _ => s
            )
          | Basic _ => s
          | Subset _ => s

    fun update_mt t =
        case t of
            UVar ((invis, x), r) => 
            (case !x of
                 Refined t => 
                 let 
                     val t = update_mt t
                     val () = x := Refined t
                 in
                     expand_mt invis t
                 end
               | Fresh _ => t
            )
          | Arrow (t1, d, t2) => Arrow (update_mt t1, update_i d, update_mt t2)
          | Unit r => Unit r
          | Prod (t1, t2) => Prod (update_mt t1, update_mt t2)
          | UniI (s, BindI (name, t1)) => UniI (update_s s, BindI (name, update_mt t1))
          | ExI (s, BindI (name, t1)) => ExI (update_s s, BindI (name, update_mt t1))
          | AppV (y, ts, is, r) => AppV (y, map update_mt ts, map update_i is, r)
          | Int r => Int r

    datatype UnifyErrorData =
             UEI of idx * idx
             | UES of sort * sort
             | UET of mtype * mtype

    exception UnifyError of UnifyErrorData
    (* assumes arguments are already checked for well-formedness *)

    fun unify_i r =
        let
            fun loop (i, i') =
                let 
                    val i = update_i i
                    val i' = update_i i'
                in
                    case (i, i') of
                        (UVarI ((invis, x), _), UVarI ((invis', x'), _)) =>
                        if x = x' then ()
                        else
                            (refine x (shrink_i invis i')
		             handle 
                             ForgetError _ => 
                             refine x' (shrink_i invis' i)
                             handle ForgetError _ => raise UnifyError (UEI (i, i')))
                      | (UVarI ((invis, x), _), _) =>
                        (refine x (shrink_i invis i')
		         handle ForgetError _ => raise UnifyError (UEI (i, i')))
                      | (_, UVarI _) =>
                        loop (i', i)
	              | _ => write_and (BinPred (EqP, i, i'), r)
                end
        in
            loop
        end

    fun unify_bs r (bs, bs') =
        case (bs, bs') of
            (UVarBS x, _) =>
            refine x bs'
          | (_, UVarBS _) =>
            unify_bs r (bs', bs)
          | (Base b, Base b') =>
            if b = b' then
	        ()
            else
	        raise Error (r, [sprintf "Base sort mismatch: $ and $" [str_b b, str_b b']])
		      
    fun unify_s r (s, s') =
        let 
            val s = update_s s
            val s' = update_s s'
        in
            (* UVarS can only be fresh *)
            case (s, s') of
                (UVarS ((invis, x), _), UVarS ((invis', x'), _)) =>
                if x = x' then ()
                else
                    (refine x (shrink_s invis s')
		     handle 
                     ForgetError _ => 
                     refine x' (shrink_s invis' s)
                     handle ForgetError _ => raise UnifyError (UES (s, s')))
              | (UVarS ((invis, x), _), _) =>
                (refine x (shrink_s invis s')
	         handle ForgetError _ => raise UnifyError (UES (s, s')))
              | (_, UVarS _) => unify_s r (s', s)
	      | (Basic (bs, _), Basic (bs', _)) =>
	        unify_bs r (bs, bs')
	      | (Subset ((bs, r1), BindI ((name, _), p)), Subset ((bs', _), BindI (_, p'))) =>
                let
	            val () = unify_bs r (bs, bs')
                    val ctxd = make_ctx_from_sorting (name, Basic (bs, r1))
                    val () = open_vc ctxd
	            val () = write_and (p <-> p', r)
                    val () = close_vc ctxd
                in
                    ()
                end
	      | (Subset ((bs, r1), BindI ((name, _), p)), Basic (bs', _)) =>
                let
	            val () = unify_bs r (bs, bs')
                    val ctxd = make_ctx_from_sorting (name, Basic (bs, r1))
                    val () = open_vc ctxd
	            val () = write_and (p, r)
                    val () = close_vc ctxd
                in
                    ()
                end
	      | (Basic (bs, r1), Subset ((bs', _), BindI ((name, _), p))) =>
                let
	            val () = unify_bs r (bs, bs')
                    val ctxd = make_ctx_from_sorting (name, Basic (bs, r1))
                    val () = open_vc ctxd
	            val () = write_and (p, r)
                    val () = close_vc ctxd
                in
                    ()
                end
        end

    fun unify_sorts r (sorts, sorts') =
        (check_length r (sorts, sorts');
         ListPair.app (unify_s r) (sorts, sorts'))

    fun unify r =
        let
            fun loop (t, t') =
                let 
                    val t = update_mt t
                    val t' = update_mt t'
                in
                    (* UVar can only be fresh *)
                    case (t, t') of
                        (UVar ((invis, x), _), UVar ((invis', x'), _)) =>
                        if x = x' then ()
                        else
                            (refine x (shrink_mt invis t')
		             handle 
                             ForgetError _ => 
                             refine x' (shrink_mt invis' t)
                             handle ForgetError _ => raise UnifyError (UET (t, t')))
                      | (UVar ((invis, x), _), _) =>
                        (refine x (shrink_mt invis t')
		         handle ForgetError _ => raise UnifyError (UET (t, t')))
                      | (_, UVar _) => loop (t', t)
                      | (Arrow (t1, d, t2), Arrow (t1', d', t2')) =>
                        (loop (t1, t1');
                         unify_i r (d, d');
                         loop (t2, t2'))
                      | (Prod (t1, t2), Prod (t1', t2')) =>
                        (loop (t1, t1');
                         loop (t2, t2'))
                      | (Unit _, Unit _) => ()
                      | (UniI (s, BindI ((name, _), t1)), UniI (s', BindI (_, t1'))) =>
                        (unify_s r (s, s');
                         open_vc_by_sorting (name, s);
                         loop (t1, t1');
                         close_vc_by_sorting (name, s))
                      | (ExI (s, BindI ((name, _), t1)), ExI (s', BindI (_, t1'))) =>
                        (unify_s r (s, s');
                         open_vc_by_sorting (name, s);
                         loop (t1, t1');
                         close_vc_by_sorting (name, s))
	              | (Int _, Int _) => ()
	              | (AppV ((a, _), ts, is, _), AppV ((a', _), ts', is', _)) => 
	                if a = a' then
		            (ListPair.app loop (ts, ts');
                             ListPair.app (unify_i r) (is, is'))
	                else
		            raise UnifyError (UET (t, t'))
	              | _ => raise UnifyError (UET (t, t'))
                end
        in
            loop
        end

    val counter = ref 0

    fun inc () = 
        let 
            val n = !counter
            val () = counter := n + 1
        in
            n
        end

    fun fresh_bsort () = UVarBS (ref (Fresh (ref (BSort (inc ())))))

    fun fresh_i anchor order bsort r = 
        let
            val name_ref = ref (Idx (inc (), anchor, order, bsort))
            val () = push_ref anchor name_ref
        in
            UVarI (([], ref (Fresh name_ref)), r)
        end

    fun fresh_nonidx f empty_invis anchor order r = 
        let
            val name_ref = ref (NonIdx (inc (), anchor, order))
            val () = push_ref anchor name_ref
        in
            f ((empty_invis, ref (Fresh name_ref)), r)
        end

    fun fresh_sort anchor order r : sort = fresh_nonidx UVarS [] anchor order r
    fun fresh_t anchor order r : mtype = fresh_nonidx UVar ([], []) anchor order r

    fun make_anchor () = 
        let 
            val anchor = ref []
            val () = write_anchor anchor
        in
            anchor
        end

    fun sort_mismatch ctx i expect have =  "Sort mismatch for " ^ str_i ctx i ^ ": expect " ^ expect ^ " have " ^ str_s ctx have

    fun is_wf_bsort (bs : U.bsort) : bsort =
        case bs of
            U.Base bs => Base bs
          | U.UVarBS () => fresh_bsort ()

    fun is_wf_sort order (ctx : scontext, s : U.sort) : sort =
        case s of
	    U.Basic (bs, r) => Basic (is_wf_bsort bs, r)
	  | U.Subset ((bs, r), BindI ((name, r2), p)) =>
            let 
                val bs = is_wf_bsort bs
            in
                Subset ((bs, r),
                        BindI ((name, r2), 
                               is_wf_prop (order + 1) (add_sorting (name, Basic (bs, r)) ctx, p)))
            end

    and is_wf_prop order (ctx : scontext, p : U.prop) : prop =
	case p of
	    U.True r => True r
	  | U.False r => False r
          | U.Not (p, r) => 
            Not (is_wf_prop order (ctx, p), r)
	  | U.BinConn (opr, p1, p2) =>
	    BinConn (opr,
                     is_wf_prop order (ctx, p1),
	             is_wf_prop order (ctx, p2))
	  | U.BinPred (EqP, i1, i2) =>
	    let 
                val (i1, bs1) = get_bsort order (ctx, i1)
		val (i2, bs2) = get_bsort order (ctx, i2)
                val () = unify_bs (U.get_region_p p) (bs1, bs2)
	    in
                BinPred (EqP, i1, i2)
	    end
	  | U.BinPred (opr, i1, i2) =>
	    let 
                val (i1, bs1) = get_bsort order (ctx, i1)
		val (i2, bs2) = get_bsort order (ctx, i2)
                val () = unify_bs (U.get_region_p p) (bs1, bs2)
                val bs = update_bs bs1
                val () =
                    case bs of
                        Base Nat => ()
                      | Base Time => ()
                      | _ => raise Error (U.get_region_p p, sprintf "Sorts of operands of $ must be both Nat or Time:" [str_bin_pred opr] :: indent ["left: " ^ str_bs bs1, "right: " ^ str_bs bs2])
	    in
                BinPred (opr, i1, i2)
	    end

    (* binary operations on idx are overloaded for Nat and Time *)
    and get_bsort order (ctx : scontext, i : U.idx) : idx * bsort =
	case i of
	    U.VarI (x, r) =>
	    (case lookup_sort x ctx of
      		 SOME s => (VarI (x, r), get_base s)
      	       | NONE => raise Error (r, ["Unbound index variable: " ^ str_v (sctx_names ctx) x]))
          | U.UnOpI (ToReal, i, r) =>
            (UnOpI (ToReal,
                    check_bsort order (ctx, i, Base Nat),
                    r),
             Base Time)
          | U.UnOpI (Log2, i, r) =>
            (UnOpI (Log2,
                    check_bsort order (ctx, i, Base Time),
                    r),
             Base Time)
	  | U.BinOpI (opr, i1, i2) =>
            let 
                val (i1, bs1) = get_bsort order (ctx, i1)
                val (i2, bs2) = get_bsort order (ctx, i2)
                val () = unify_bs (U.get_region_i i) (bs1, bs2)
                val bs = update_bs bs1
                val () =
                    case bs of
                        Base Nat => ()
                      | Base Time => ()
                      | _ => raise Error (U.get_region_i i, sprintf "Sorts of operands of $ must be both Nat or Time:" [str_idx_bin_op opr] :: indent ["left: " ^ str_bs bs1, "right: " ^ str_bs bs2])
            in
                (BinOpI (opr, i1, i2), bs)
            end
	  | U.ConstIT (x, r) => 
	    (ConstIT (x, r), Base Time)
	  | U.ConstIN (n, r) => 
	    if n >= 0 then
		(ConstIN (n, r), Base Nat)
	    else
		raise Error (r, ["Natural number constant must be non-negative"])
	  | U.TrueI r => 
            (TrueI r, Base Bool)
	  | U.FalseI r => 
            (FalseI r, Base Bool)
	  | U.TTI r => 
            (TTI r, Base BSUnit)
          | U.UVarI ((), r) =>
            let
                val bs = fresh_bsort ()
            in
                (fresh_i (make_anchor ()) order bs r, bs)
            end


    and check_bsort order (ctx, i : U.idx, bs : bsort) : idx =
        let 
            val (i, bs') = get_bsort order (ctx, i)
	    val () = unify_bs (get_region_i i) (bs', bs)
        in
            i
        end

    fun is_wf_sorts order (ctx, sorts : U.sort list) : sort list = 
        map (fn s => is_wf_sort order (ctx, s)) sorts

    fun check_sort order (ctx, i : U.idx, s : sort) : idx =
	let 
            val (i, bs') = get_bsort order (ctx, i)
            val r = get_region_i i
            val s = update_s s
            val () =
	        (case s of
		     Subset ((bs, _), BindI (_, p)) =>
		     (unify_bs r (bs', bs);
		      write_and (subst_i_p i p, get_region_i i))
	           | Basic (bs, _) => 
		     unify_bs r (bs', bs)
                   | UVarS ((_, x), _) =>
                     (case !x of
                          Refined _ => raise Impossible "check_sort (): s should be Fresh"
                        | Fresh _ => 
                          refine x (Basic (bs', dummy))
                     )
                )
                handle Error (_, msg) => 
                       let val ctxn = sctx_names ctx in
                           raise Error (r, 
                                        sprintf "index $ (of base sort $) is not of sort $" [str_i ctxn i, str_bs bs', str_s ctxn s] :: 
                                        "Cause:" :: 
                                        indent msg)
                       end
        in
            i
	end

    fun check_sorts order (ctx, is : U.idx list, sorts, r) : idx list =
        (check_length r (is, sorts);
         ListPair.map (fn (i, s) => check_sort order (ctx, i, s)) (is, sorts))

    (* k => Type *)
    fun recur_kind k = ArrowK (false, 0, k)

    fun kind_mismatch (ctx as (sctx, kctx)) c expect have =  "Kind mismatch for " ^ str_t ctx c ^ ": expect " ^ expect ^ " have " ^ str_k sctx have

    fun fetch_kind (kctx, (a, r)) =
        case lookup_kind a kctx of
      	    SOME k => k
      	  | NONE => raise Error (r, ["Unbound type variable: " ^ str_v (names kctx) a])

    fun is_wf_mtype order (ctx as (sctx : scontext, kctx : kcontext), c : U.mtype) : mtype = 
        let 
            val ctxn as (sctxn, kctxn) = (sctx_names sctx, names kctx)
	(* val () = print (sprintf "Type wellformedness checking: $\n" [str_t ctxn c]) *)
        in
	    case c of
	        U.Arrow (c1, d, c2) => 
	        Arrow (is_wf_mtype order (ctx, c1),
	               check_bsort order (sctx, d, Base Time),
	               is_wf_mtype order (ctx, c2))
	      | U.Unit r => Unit r
	      | U.Prod (c1, c2) => 
	        Prod (is_wf_mtype order (ctx, c1),
	              is_wf_mtype order (ctx, c2))
	      | U.UniI (s, BindI ((name, r), c)) => 
                let
                    val s = is_wf_sort order (sctx, s)
                in
	            UniI (s,
	                  BindI ((name, r), 
                                 is_wf_mtype (order + 1) (add_sorting_sk (name, s) ctx, c)))
                end
	      | U.ExI (s, BindI ((name, r), c)) => 
                let
                    val s = is_wf_sort order (sctx, s)
                in
	            ExI (s,
	                 BindI ((name, r), 
                                is_wf_mtype (order + 1) (add_sorting_sk (name, s) ctx, c)))
                end
	      | U.AppV (x, ts, is, r) => 
                let
                    val ArrowK (_, n, sorts) = fetch_kind (kctx, x)
		    val () = check_length_n r (ts, n)
                in
		    AppV (x, 
                          map (fn t => is_wf_mtype order (ctx, t)) ts, 
                          check_sorts order (sctx, is, sorts, r), 
                          r)
                end
	      | U.Int r => Int r
              | U.UVar ((), r) => fresh_t (make_anchor ()) order r
        end

    fun is_wf_type order (ctx as (sctx : scontext, kctx : kcontext), c : U.ty) : ty = 
        let 
            val ctxn as (sctxn, kctxn) = (sctx_names sctx, names kctx)
	(* val () = print (sprintf "Type wellformedness checking: $\n" [str_t ctxn c]) *)
        in
	    case c of
                U.Mono t =>
                Mono (is_wf_mtype order (ctx, t))
	      | U.Uni ((name, r), c) => 
	        Uni ((name, r), is_wf_type order (add_kinding_sk (name, Type) ctx, c))
        end

    fun smart_max a b =
        if eq_i op= a (T0 dummy) then
            b
        else if eq_i op= b (T0 dummy) then
            a
        else
            BinOpI (MaxI, a, b)

    fun smart_max_list ds = foldl' (fn (d, ds) => smart_max ds d) (T0 dummy) ds

    fun fetch_constr (ctx, (x, r)) =
        case nth_error ctx x of
	    SOME (name, c) => (name, c)
	  | NONE => raise Error (r, [sprintf "Unbound constructor: $" [str_v (names ctx) x]])

    fun fetch_constr_type (ctx : ccontext, cx) =
        let val (cname, c) = fetch_constr (ctx, cx)
	    val t = constr_type VarT shiftx_v c
        in
	    (cname, t)
        end

    (* redundancy and exhaustiveness checking *)
    (* all the following cover operations assume that the cover has type t *)

    datatype cover =
             TrueC
             | FalseC
             | AndC of cover * cover
             | OrC of cover * cover
             | ConstrC of var * cover
             | PairC of cover * cover
             | TTC

    local
        
        datatype inhab =
                 TrueH
                 | ConstrH of var * inhab
                 | PairH of inhab * inhab
                 | TTH

        fun str_cover cctx c =
            case c of
                TrueC => "_"
              | FalseC => "nothing"
              | AndC (c1, c2) => sprintf "($ /\\ $)" [str_cover cctx c1, str_cover cctx c2]
              | OrC (c1, c2) => sprintf "($ \\/ $)" [str_cover cctx c1, str_cover cctx c2]
              | ConstrC (x, c) => sprintf "($ $)" [str_v cctx x, str_cover cctx c]
              | PairC (c1, c2) => sprintf "($, $)" [str_cover cctx c1, str_cover cctx c2]
              | TTC => "()"

        fun str_inhab cctx c =
            case c of
                TrueH => "_"
              | ConstrH (x, c) => sprintf "($ $)" [str_v cctx x, str_inhab cctx c]
              | PairH (c1, c2) => sprintf "($, $)" [str_inhab cctx c1, str_inhab cctx c2]
              | TTH => "()"

        infix 2 \/
        val op/\ = AndC
        val op\/ = OrC

        fun combine_covers covers = foldl' (swap OrC) FalseC covers

        val impossible = Impossible "cover has the wrong type"

        fun get_family (x : constr) = #1 x
        fun get_family_members cctx x =
            (rev o List.mapPartial (fn (n, (_, c)) => if get_family c = x then SOME n else NONE) o add_idx) cctx

        fun cover_neg cctx (t : ty) c =
            let fun neg c = cover_neg cctx t c
                fun neg' t c = cover_neg cctx t c
            in
                case c of
                    TrueC => FalseC
                  | FalseC => TrueC
                  | AndC (a, b) => neg a \/ neg b
                  | OrC (a, b) => neg a /\ neg b
                  | TTC => FalseC
                  | PairC (c1, c2) =>
                    (case t of
                         Mono (Prod (t1, t2)) =>
                         PairC (neg' (Mono t1) c1, c2) \/
                         PairC (c1, neg' (Mono t2) c2) \/
                         PairC (neg' (Mono t1) c1, neg' (Mono t2) c2)
                       | _ => raise impossible)
                  | ConstrC (x, c) =>
	            (case t of
	                 Mono (AppV ((family, _), ts, _, _)) =>
	                 let val all = get_family_members cctx family
		             val others = diff op= all [x]
                             val (_, (_, _, ibinds)) = fetch_constr (cctx, (x, dummy))
                             val (_, (t', _)) = unfold_ibinds ibinds
		             val t' = subst_ts_mt ts t'
                             val covers = ConstrC (x, cover_neg cctx (Mono t') c) :: map (fn y => ConstrC (y, TrueC)) others
	                 in
                             combine_covers covers
	                 end
	               | _ => raise impossible)
            end

                
        fun find_inhabitant (ctx as (sctx, kctx, cctx)) (t : ty) cs =
            let (* use exception to mimic Error monad *)
                exception Incon of string
                fun f (t : ty) cs : inhab =
                    case cs of
                        [] =>
                        let
                            val () = Debug.println (sprintf "Empty constraints now. Now try to find any inhabitant of type $" [str_t (sctx_names sctx, names kctx) t])
                        in
                            case t of
                                Mono (AppV (tx as (family, _), ts, _, _)) =>
                                (case fetch_kind (kctx, tx) of
                                     ArrowK (true, _, _) =>
	                             let val all = get_family_members cctx family
                                     in
                                         case all of x :: _ => ConstrH (x, TrueH) | [] => raise Incon "empty datatype"
                                     end
                                   | _ => TrueH (* an abstract type is treated as an inhabited type *)
                                )
                              | Mono (Unit _) => TTH
                              | Mono (Prod (t1, t2)) => PairH (f (Mono t1) [], f (Mono t2) [])
                              | _ => TrueH
                        end
                      | c :: cs =>
                        let
                            val () = Debug.println (sprintf "try to satisfy $" [(join ", " o map (str_cover (names cctx))) (c :: cs)])
                        in
                            case (c, t) of
                                (TrueC, _) => f t cs
                              | (FalseC, _) => raise Incon "false"
                              | (AndC (c1, c2), _) => f t (c1 :: c2 :: cs)
                              | (OrC (c1, c2), _) =>
                                (f t (c1 :: cs) handle Incon _ => f t (c2 :: cs))
                              | (TTC, Mono (Unit _)) =>
                                (case allSome (fn c => case c of TTC => SOME () | _ => NONE) cs of
                                     OK _ => TTH
                                   | Failed i => f t (to_hd i cs @ [c])
                                )
                              | (PairC (c1, c2), Mono (Prod (t1, t2))) =>
                                (case allSome (fn c => case c of PairC p => SOME p | _ => NONE ) cs of
                                     OK cs =>
                                     let val (cs1, cs2) = unzip cs
                                         val c1 = f (Mono t1) (c1 :: cs1)
                                         val c2 = f (Mono t2) (c2 :: cs2)
                                     in
                                         PairH (c1, c2)
                                     end
                                   | Failed i => f t (to_hd i cs @ [c])
                                )
                              | (ConstrC (x, c'), Mono (AppV ((family, _), ts, _, _))) =>
                                let fun g c =
                                        case c of
                                            ConstrC (y, c) =>
                                            if y = x then
                                                SOME c
                                            else
                                                raise Incon "diff-constr"
                                          | _ => NONE
                                in
                                    case allSome g cs of
                                        OK cs' =>
                                        let val (_, (_, _, ibinds)) = fetch_constr (cctx, (x, dummy))
                                            val (_, (t', _)) = unfold_ibinds ibinds
		                            val t' = subst_ts_mt ts t'
                                            val () = Debug.println (sprintf "All are $, now try to satisfy $" [str_v (names cctx) x, (join ", " o map (str_cover (names cctx))) (c' :: cs')])
                                            val c' = f (Mono t') (c' :: cs')
                                            val () = Debug.println (sprintf "Plugging $ into $" [str_inhab (names cctx) c', str_v (names cctx) x])
                                        in
                                            ConstrH (x, c')
                                        end
                                      | Failed i => f t (to_hd i cs @ [c])
                                end
                              | _ => raise impossible
                        end
            in
                SOME (f t cs) handle Incon debug => NONE
            end

        fun cover_imply cctx t (a, b) : cover =
            cover_neg cctx t a \/ b
                                      
        fun any_missing ctx t c =
            let val nc = cover_neg (#3 ctx) t c
                val () = Debug.println (str_cover (names (#3 ctx)) nc)
            in
                find_inhabitant ctx t [nc]
            end

        fun is_covered ctx t small big =
            (isNull o any_missing ctx t o cover_imply (#3 ctx) t) (small, big)

    in              

    fun check_redundancy (ctx as (_, _, cctx), t, prevs, this, r) =
        let val prev = combine_covers prevs
        in
	    if not (is_covered ctx t this prev) then ()
	    else raise Error (r, sprintf "Redundant rule: $" [str_cover (names cctx) this] :: indent [sprintf "Has already been covered by previous rules: $" [(join ", " o map (str_cover (names cctx))) prevs]])
        end
            
    fun check_exhaustive (ctx as (_, _, cctx), t : ty, covers, r) =
        let val cover = combine_covers covers
            val () = Debug.println (str_cover (names cctx) cover)
        in
            case any_missing ctx t cover of
                NONE => ()
              | SOME missed =>
	        raise Error (r, [sprintf "Not exhaustive, at least missing this case: $" [str_inhab (names cctx) missed]])
        end

    end

    fun get_ds (_, _, _, tctxd) = map (snd o snd) tctxd

    fun escapes nametype name domaintype domain =
        [sprintf "$ $ escapes local scope in $ $" [nametype, name, domaintype, domain]]
	    
    fun forget_mt r (skctxn as (sctxn, kctxn)) (sctxl, kctxl) t = 
        let val t = forget_t_mt 0 kctxl t
		    handle ForgetError x => raise Error (r, escapes "type variable" (str_v kctxn x) "type" (str_mt skctxn t))
	    val t = forget_i_mt 0 sctxl t
		    handle ForgetError x => raise Error (r, escapes "index variable" (str_v sctxn x) "type" (str_mt skctxn t))
        in
	    t
        end

    fun forget_ctx_mt r (sctx, kctx, _, _) (sctxd, kctxd, _, _) t =
        let val (sctxn, kctxn) = (sctx_names sctx, names kctx)
            val sctxl = sctx_length sctxd
        in
            forget_mt r (sctxn, kctxn) (sctxl, length kctxd) t
        end
            
    fun forget_t r (skctxn as (sctxn, kctxn)) (sctxl, kctxl) t = 
        let val t = forget_t_t 0 kctxl t
		    handle ForgetError x => raise Error (r, escapes "type variable" (str_v kctxn x) "type" (str_t skctxn t))
	    val t = forget_i_t 0 sctxl t
		    handle ForgetError x => raise Error (r, escapes "index variable" (str_v sctxn x) "type" (str_t skctxn t))
        in
	    t
        end

    fun forget_ctx_t r (sctx, kctx, _, _) (sctxd, kctxd, _, _) t =
        let val (sctxn, kctxn) = (sctx_names sctx, names kctx)
            val sctxl = sctx_length sctxd
        in
            forget_t r (sctxn, kctxn) (sctxl, length kctxd) t
        end
            
    fun forget_d r sctxn sctxl d =
        forget_i_i 0 sctxl d
        handle ForgetError x => raise Error (r, escapes "index variable" (str_v sctxn x) "time" (str_i sctxn d))

    fun forget_ctx_d r (sctx, _, _, _) (sctxd, _, _, _) d =
        let val sctxn = sctx_names sctx
            val sctxl = sctx_length sctxd
        in
            forget_d r sctxn sctxl d
        end

    fun mismatch (ctx as (sctx, kctx, _, _)) e expect got =  
        (get_region_e e,
         "Type mismatch:" ::
         indent ["expect: " ^ expect, 
                 "got: " ^ str_t (sctx, kctx) got,
                 "in: " ^ str_e ctx e])

    fun mismatch_anno ctx expect got =  
        (get_region_t got,
         "Type annotation mismatch:" ::
         indent ["expect: " ^ expect,
                 "got: " ^ str_t ctx got])

    fun check_fix_body e =
        case e of
    	    AbsI (_, _, e') => check_fix_body e'
    	  | Abs _ => ()
    	  | _ => raise Error (get_region_e e, ["The body of fixpoint must have the form ({_ : _} ... {_ : _} (_ : _) => _)"])

    fun is_wf_return (skctx as (sctx, _), return) =
        case return of
            (SOME t, SOME d) =>
	    (SOME (is_wf_mtype 0 (skctx, t)),
	     SOME (check_bsort 0 (sctx, d, Base Time)))
          | (SOME t, NONE) =>
	    (SOME (is_wf_mtype 0 (skctx, t)),
             NONE)
          | (NONE, SOME d) =>
	    (NONE,
             SOME (check_bsort 0 (sctx, d, Base Time)))
	  | (NONE, NONE) => (NONE, NONE)

    fun fetch_var (tctx, (x, r)) =
	case lookup x tctx of
      	    SOME t => t
      	  | NONE => raise Error (r, ["Unbound variable: " ^ str_v (names tctx) x])

    fun handle_ue ctx e =             
        raise Error (get_region_e e, 
                     #2 (mismatch ctxn e (str_t (sctxn, kctxn) t) t') @
                     "Cause:" ::
                     indent msg)

    (* t is already checked for wellformedness *)
    fun match_ptrn (ctx as (sctx : scontext, kctx : kcontext, cctx : ccontext), pn : U.ptrn, t : mtype) : ptrn * cover * context * int =
        let 
            val skctxn as (sctxn, kctxn) = (sctx_names sctx, names kctx)
        in
	    case pn of
	        P.ConstrP ((cx, cr), inames, pn, r) =>
                let
                    val t = update_mt t
                in
                    case t of
                        AppV ((family, _), ts, is, _) =>
 	                let val (_, c as (family', tnames, ibinds)) = fetch_constr (cctx, (cx, cr))
                            val (name_sorts, (t1, is')) = unfold_ibinds ibinds
                        in
		            if family' = family andalso length tnames = length ts andalso length is' = length is then
                                if length inames = length name_sorts then
		                    let val t1 = subst_ts_mt ts t1
			                val is = map (shiftx_i_i 0 (length name_sorts)) is
			                val ps = ListPair.map (fn (a, b) => BinPred (EqP, a, b)) (is', is)
                                        val ctxd = (make_ctx_from_sortings o rev o ListPair.zip) (inames, snd (ListPair.unzip name_sorts))
                                        val () = open_vc ctxd
                                        val () = open_premises ps
                                        val ctx = add_ctx_skc ctxd ctx
                                        val (pn, cover, ctxd') = match_ptrn (ctx, default (TTP dummy) pn, t1)
                                        val ctxd = add_ctx ctxd' ctxd
                                        val cover = ConstrC (cx, cover)
		                    in
			                (ConstrP ((cx, cr), inames, pn, r), cover, ctxd, length ps)
		                    end
                                else
                                    raise Error (r, [sprintf "This constructor requires $ index argument(s), not $" [str_int (length name_sorts), str_int (length inames)]])
		            else
		                raise Error 
                                      (r, sprintf "Type of constructor $ doesn't match datatype " [str_v (names cctx) cx] :: 
                                          indent ["expect: " ^ str_v kctxn family, 
                                                  "got: " ^ str_v kctxn family'])
                        end
                      | _ => raise Error (get_region_pn pn, [sprintf "Pattern $ doesn't match type $" [str_pn (names cctx) pn, str_t skctxn t]])
                end
              | U.VarP (name, r) =>
                (VarP (name, r), TrueC, make_ctx_from_typing (name, Mono t), 0)
              | U.PairP (pn1, pn2) =>
                let 
                    val anchor = make_anchor ()
                    val t1 = fresh anchor 0
                    val t2 = fresh anchor 0
                    val () = unify (t, Prod (t1, t2))
                    val (pn1, cover1, ctxd) = match_ptrn (ctx, pn1, t1)
                    val ctx = add_ctx_skc ctxd ctx
                    val (pn2, cover2, ctxd') = match_ptrn (ctx, pn2, shift_ctx_mt ctxd t2)
                    val ctxd = add_ctx ctxd' ctxd
                in
                    (PairP (pn1, pn2), PairC (cover1, cover2), ctxd, 0)
                end
              | U.TTP r =>
                let
                    val () = unify (t, Unit dummy)
                in
                    (TTP r, TTC, empty_ctx, 0)
                end
              | U.AliasP ((pname, r1), pn, r) =>
                let val ctxd = make_ctx_from_typing (pname, t)
                    val (pn, cover, ctxd') = match_ptrn (ctx, pn, t)
                    val ctxd = add_ctx ctxd' ctxd
                in
                    (AliasP ((pname, r1), pn, r), cover, ctxd, 0)
                end
              | U.AnnoP (pn1, t') =>
                let
                    val t' = is_wf_mtype (sctx, kctx) t'
                    val () = unify (U.get_region_pn pn) (t, t')
                    val (pn1, cover, ctxd, nps) = match_ptrn (ctx, pn1, t')
                in
                    (AnnoP (pn1, t'), cover, ctxd, nps)
                end
        end

    fun get_mtype (ctx as (sctx : scontext, kctx : kcontext, cctx : ccontext, tctx : tcontext), e : U.expr) : expr * mtype * idx =
        let val skctx = (sctx, kctx) 
	    val ctxn as (sctxn, kctxn, cctxn, tctxn) = ctx_names ctx
	    val skctxn = (sctxn, kctxn)
	    (* val () = print (sprintf "Typing $\n" [str_e ctxn e]) *)
            fun subst_uvar_error e t i x = Error (get_region_e e, [sprintf "Can't substitute $ in unification variable $ in type $" [str_i sctxn i, str_uvar x, str_t skctxn t]])
	    val (e, t, d) =
	        case e of
		    U.Var x =>
                    let
                        val r = U.get_region_e e
                        fun insert anchor t =
                            case t of
                                Base t => t
                              | Uni (_, t) => insert (subst_t_t (fresh_t anchor 0 r) t)
                    in
                        (Var x, insert (fetch_var (tctx, x)), T0 dummy)
                    end
		  | U.App (e1, e2) =>
		    let 
                        val (e2, t2, d2) = get_mtype (ctx, e2)
                        val anchor = make_anchor ()
                        val d = fresh_i anchor 0 (SOME Time)
                        val t = fresh anchor 0
                        val (e1, _, d1) = check_mtype (ctx, e1, Arrow (t2, d, t)) 
                    in
                        (App (e1, e2), t, d1 %+ d2 %+ T1 dummy %+ d) 
		    end
		  | U.Abs (pn, e) => 
		    let
                        val anchor = make_anchor ()
                        val t = fresh anchor 0
                        val skcctx = (sctx, kctx, cctx) 
                        val (pn, cover, nps (* number of premises *), ctxd) = match_ptrn (skcctx, pn, t)
	                val () = check_exhaustive (skcctx, t, [cover], get_region_pn pn)
                        val ctx = add_ctx ctxd ctx
		        val (e, t1, d) = get_mtype (ctx, e)
		        val t1 = forget_ctx_mt (get_region_e e) ctx ctxd t1 
                        val d = forget_ctx_d (get_region_e e) ctx ctxd d
                        val () = close_premises nps
                        val () = close_vc ctxd
                    in
		        (Abs (pn, e), Arrow (t, d, t1), T0 dummy)
		    end
		  | U.Let (decls, e, r) => 
		    let 
                        val (decls, ctxd as (sctxd, kctxd, _, _), nps, ds, ctx) = check_decls (ctx, decls)
		        val (e, t, d) = get_type (ctx, e)
                        val ds = rev (d :: ds)
		        val t = forget_ctx_t r ctx ctxd t 
                        val ds = map (forget_ctx_d r ctx ctxd) ds
                        val () = close_premises nps
                        val () = close_vc ctxd
                        val d = foldl' (fn (d, acc) => acc %+ d) (T0 dummy) ds
                    in
		        (Let (decls, e, r), t, d)
		    end
		  | U.AbsI (s, (name, r), e) => 
		    if is_value e then
		        let 
                            val s = is_wf_sort (sctx, s)
                            val ctxd = make_ctx_from_sorting (name, s)
                            val ctx = add_ctx ctxd ctx
                            val () = open_vc ctxd
			    val (e, t, _) = get_mtype (ctx, e) 
                            val () = close_vc ctxd
                        in
			    (AbsI (s, (name, r), e), UniI (s, BindI ((name, r), t)), T0 dummy)
		        end 
		    else
		        raise Error (get_region_e e, ["The body of a universal abstraction must be a value"])
		  | U.AppI (e, i) =>
		    let 
                        val anchor = make_anchor ()
                        val r = U.get_region_e e
                        val s = fresh_sort anchor 0 r
                        val t1 = fresh_t anchor 1 r
                        val (e, t, d) = check_mtype (ctx, e, UniI (s, BindI (("uvar", r), t1))) 
                        val i = check_sort (sctx, i, s) 
                    in
			(AppI (e, i), subst_i_mt i t1, d)
                        handle SubstUVar x => raise subst_uvar_error e t i x
		    end
		  | U.Pack (t, i, e) =>
                    let
                        val t = is_wf_mtype (skctx, t)
                        val anchor = make_anchor ()
                        val r = get_region_r r
                        val s = fresh_sort anchor 0 r
                        val t1 = fresh_t anchor 1 r
                        val () = unify (t, ExI (s, BindI (("uvar", r), t1)))
                                 handle UnifyError ue => handle_ue ctxn ue
			val i = check_sort (sctx, i, s)
                        val t1 = subst_i_mt i t1
                                 handle SubstUVar x => raise subst_uvar_error e t i x
			val (e, _, d) = check_mtype (ctx, e, t1)
                    in
			(Pack (t, i, e), t, d)
		    end
		  | U.Unpack (e1, return, idx_var, expr_var, e2) =>
                    let 
                        val anchor = make_anchor ()
                        val r = U.get_region_e e
                        val s = fresh_sort anchor 0 r
                        val t1' = fresh anchor 1 r
                        val (e1, _, d1) = check_mtype (ctx, e1, ExI (s, BindI (("uvar", r), t1')))
                        val ctx' = add_sorting_skct (idx_var, s) ctx
		        val ctx' = add_typing_skct (expr_var, Mono t1') ctx'
                        val sctxn' = idx_var :: sctxn
                        val skctxn' = (sctxn', kctxn)
                        val return = is_wf_return (skctx, return)
                        val (e2, t, d) =
                            case return of
                                (SOME t, SOME d) =>
		                let
                                    val e2 = check_mtype_time (ctx', e2, shift_i_mt t, shift_i_i d)
			        in
				    (e2, t, d)
			        end
                              | (SOME t, NONE) =>
		                let 
				    val (e2, d) = check_mtype (ctx', e2, shift_i_mt t)
                                    val d = forget_d (get_region_e e2) sctxn' 1 d
			        in
				    (e2, t, d)
			        end
                              | (NONE, SOME d) =>
		                let 
				    val (e2, t) = check_time_return_mtype (ctx', e2, shift_i_i d)
                                    val t = forget_mt (get_region_e e2) skctxn' (1, 0) t
			        in
				    (e2, t, d)
			        end
		              | (NONE, NONE) =>
		                let val (e2, t, d) = get_mtype (ctx', e2)
                                    val t = forget_mt (get_region_e e2) skctxn' (1, 0) t
                                    val d = forget_d (get_region_e e2) sctxn' 1 d
			        in
				    (e2, t, d)
			        end
                    in
                        (Unpack (e1, return, idx_var, expr_var, e2), t, d1 %+ d)
                    end
		  | U.TT r => 
                    (TT r, Unit dummy, T0 dummy)
		  | U.Pair (e1, e2) => 
		    let 
                        val (e1, t1, d1) = get_mtype (ctx, e1) 
		        val (e2, t2, d2) = get_mtype (ctx, e2) 
                    in
		        (Pair (e1, e2), Prod (t1, t2), d1 %+ d2)
		    end
		  | U.Fst e => 
		    let 
                        val anchor = make_anchor ()
                        val r = U.get_region_e e
                        val t1 = fresh_t anchor 0 r
                        val t2 = fresh_t anchor 0 r
                        val (e, _, d) = check_mtype (ctx, e, Prod (t1, t2)) 
                    in 
                        (Fst e, t1, d)
		    end
		  | U.Snd e => 
		    let 
                        val anchor = make_anchor ()
                        val r = U.get_region_e e
                        val t1 = fresh_t anchor 0 r
                        val t2 = fresh_t anchor 0 r
                        val (_, d) = check_mtype (ctx, e, Prod (t1, t2)) 
                    in 
                        (Snd e, t2, d)
		    end
		  | U.Ascription (e, t) => 
		    let val t = is_wf_mtype 0 (skctx, t)
		        val (e, _, d) = check_mtype (ctx, e, t)
                    in
		        (Ascription (e, t), t, d)
		    end
		  | U.AscriptionTime (e, d) => 
		    let val d = check_bsort (sctx, d, Base Time)
		        val (e, t) = check_time (ctx, e, d)
                    in
		        (AscriptionTime (e, d), t, d)
		    end
		  | U.BinOp (Add, e1, e2) =>
		    let val (e1, _, d1) = check_mtype (ctx, e1, Int dummy)
		        val (e2, _, d2) = check_mtype (ctx, e2, Int dummy) in
		        (BinOp (Add, e1, e2), Int dummy, d1 %+ d2 %+ T1 dummy)
		    end
		  | U.Const n => 
		    (Const n, Int dummy, T0 dummy)
		  | U.AppConstr (cx as (_, rc), is, e) => 
		    let 
                        val (cname, tc) = fetch_constr_type (cctx, cx)
		        (* delegate to checking (cx {is} e) *)
		        val f = U.Var (0, rc)
		        val f = foldl (fn (i, e) => U.AppI (e, i)) f is
		        val e = U.App (f, shift_e_e e)
		        val (e, t, d) = get_mtype (add_typing_skct (cname, tc) ctx, e) 
                        val (e, d) =
                            case (e, simp_i d) of
		                (* constructor application doesn't incur count *)
                                (App (f, e), (BinOpI (Add, d, T1))) =>
                                let
                                    val (_, is) = peel_AppI f
                                in
                                    (AppConstr (cx, is, e), d)
                                end
		    in
		        (e, t, d)
		    end
		  | U.Case (e, return, rules, r) => 
		    let val (e, t1, d1) = get_mtype (ctx, e)
                        val return = is_wf_return (skctx, return)
                        val (rules, tds) = check_rules (ctx, rules, (t1, return), r)
                        fun computed_t () =
                            case map fst tds of
                                [] => raise Error (r, ["Empty case-matching must have a return type clause"])
                              | t :: ts => 
                                (map (curry unify t) ts; 
                                 t)
                                handle UnifyError ue => handle_ue ctxn ue
                        fun computed_d () =
                            (smart_max_list o map snd) tds
                        val (t, d) = mapPair (lazy_default computed_t, lazy_default computed_d) return
                    in
		        (Case (e, return, rules, r), t, d1 %+ d)
                    end
		  | U.Never t => 
                    let
		        val t = is_wf_mtype (skctx, t)
		        val () = write_and (False dummy, get_region_e e)
                    in
		        (Never t, t, T0 dummy)
                    end
	(* val () = print (sprintf "  type: $ [for $]\n  time: $\n" [str_t skctxn t, str_e ctxn e, str_i sctxn d]) *)
        in
	    (e, t, d)
        end

    and check_decls (ctx, decls) : U.decl list * context * int * idx list * context = 
        let 
            fun f (decl, (decls, ctxd, nps, ds, ctx)) =
                let 
                    val (decl, ctxd', nps', ds') = check_decl (ctx, decl)
                    val decls = decl :: decls
                    val ctxd = add_ctx ctxd' ctxd
                    val nps = nps + nps'
                    val ds = ds' @ map (shift_ctx_i ctxd') ds
                    val ctx = add_ctx ctxd' ctx
                in
                    (decls, ctxd, nps, ds, ctx)
                end
            val (decls, ctxd, nps, ds, ctx) = foldl f ([], empty_ctx, 0, [], ctx) decls
            val decls = rev decls
        in
            (decls, ctxd, nps, ds, ctx)
        end

    and check_decl (ctx as (sctx, kctx, cctx, _), decl) =
        let
            fun fv_mt t =
	        case b of
                    UVar (_, uvar) =>
                    (case !uvar of
                         Refined t => fv_mt t
                       | Fresh y => [y]
                    )
	          | Arrow (t1, _, t2) => fv_mt t1 @ fv_mt t2
	          | Unit r => []
	          | Prod (t1, t2) => fv_mt t1 @ fv_mt t2
	          | Sum (t1, t2) => fv_mt t1 @ fv_mt t2
	          | UniI (s, BindI (name, t1)) => fv_mt t1
	          | ExI (s, BindI (name, t1)) => fv_mt t1
	          | Int r => []
	          | AppV (y, ts, is, r) => concatMap fv_mt ts
            fun fv_t t =
                case t of
                    Mono t => fv_mt t
                  | Uni _ => [] (* fresh uvars in Uni should either have been generalized or in previous ctx *)
            fun generalize t = 
                let
                    fun fv_ctx (_, _, _, tctx) = concatMap (mapSnd fv_t) tctx (* cctx can't contain uvars *)
                    fun subst x v (b : mty) : mty =
	                case b of
                            UVar (_, uvar) =>
                            (case !uvar of
                                 Refined _ => b
                               | Fresh y => if y = x then
                                                AppV ((v, dummy), [], [], dummy)
                                            else 
                                                b
                            )
	                  | Arrow (t1, d, t2) => Arrow (subst x v t1, d, subst x v t2)
	                  | Unit r => Unit r
	                  | Prod (t1, t2) => Prod (subst x v t1, subst x v t2)
	                  | Sum (t1, t2) => Sum (subst x v t1, subst x v t2)
	                  | UniI (s, BindI (name, t1)) => UniI (s, BindI (name, subst x (v + 1) t1))
	                  | ExI (s, BindI (name, t1)) => ExI (s, BindI (name, subst x (v + 1) t1))
	                  | Int r => Int r
	                  | AppV (y, ts, is, r) => 
		            AppV (y, map (subst x v) ts, is, r)
                    fun uvar_t_name n =
                        if n < 26 then
                            "'" ^ chr (ord "a" + n)
                        else
                            "'" ^ str_int n
                    val fv = dedup op= $ diff op= (fv_mt t) (fv_ctx ctx)
                    val t = shiftx_t_t 0 (length fv) t
                    val t = (fst o foldl (fn (uname, (t, v)) => (subst uname v t, v + 1)) (t, 0)) fv
                    val t = for 0 (length fv) (fn (t, i) => (Uni ((uvar_t_name i, dummy), t))) (Mono t)
                in
                    t
                end
        in
            case decl of
                U.Val (U.VarP (x, r), e) =>
                let 
                    val skcctx = (sctx, kctx, cctx) 
                    val (e, t, d) = get_mtype (ctx, e)
                    val t = if is_value e then 
                                generalize t
                            else 
                                Mono t
                in
                    (Val (VarP (x, r), e), make_ctx_from_typing (x, t), 0, [d])
                end
              | U.Val (pn, e) =>
                let 
                    val skcctx = (sctx, kctx, cctx) 
                    val (e, t, d) = get_mtype (ctx, e)
                    val (pn, cover, ctxd, nps) = match_ptrn (skcctx, pn, t)
                    val d = shift_ctx_i ctxd d
	            val () = check_exhaustive (skcctx, t, [cover], get_region_pn pn)
                in
                    (Val (pn, e), ctxd, nps, [d])
                end
	      | U.Rec (t, (name, r), e) => 
	        let 
		    val t = is_wf_mtype (skctx, t)
                    val () = check_fix_body e
		    val (e, _, _) = check_mtype (add_typing_skct (name, Mono t) ctx, e, t)
                    val gt = generalize t
                in
                    (Rec (t, (name, r), e), make_ctx_from_typing (x, gt), 0, [T0 dummy])
	        end
	      | U.Datatype (name, tnames, sorts, constr_decls, _) =>
	        let 
                    val sorts = is_wf_sorts (sctx, sorts)
		    val nk = (name, ArrowK (true, length tnames, sorts))
		    val ctx as (sctx, kctx, _, _) = add_kinding_skct nk ctx
		    fun make_constr ((name, ibinds, r) : U.constr_decl) =
		        let 
                            val c = (0, tnames, ibinds)
		            val t = U.constr_type shiftx_v c
		            val _ = is_wf_type ((sctx, kctx), t)
			            handle Error (_, msg) =>
				           raise Error (r, 
						        "Constructor is ill-formed" :: 
						        "Cause:" :: 
						        indent msg)
                            val () = if length (fv_t t) > 0 then
                                         raise Error (r, ["Constructor has unresolved unification type variable(s)"])
                                     else ()
                            val (_, ibinds) = constr_from_type t
		        in
		            ((name, ibinds, r), (name, (0, tnames, ibinds)))
		        end
		    val (constr_decls, constrs) = map make_constr constr_decls
	        in
		    (constr_decls, (([], []), [nk], rev constrs, []), 0, [])
	        end
        end

    and check_rules (ctx as (sctx, kctx, cctx, tctx), rules, t as (t1, return), r) =
	let 
            val skcctx = (sctx, kctx, cctx) 
	    fun f (rule, acc) =
	        let 
                    val ans as (rule, (td, cover)) = check_rule (ctx, rule, t)
		    val () = check_redundancy (skcctx, Mono t1, (rev o map snd) acc, cover, get_region_rule rule)
	        in
		    (ans :: acc)
	        end 
	    val (rules, (tds, covers)) = (mapSnd unzip o unzip o rev o foldl f []) rules
	in
	    check_exhaustive (skcctx, Mono t1, covers, r);
            (rules, tds)
	end

    and check_rule (ctx as (sctx, kctx, cctx, tctx), (pn, e), t as (t1, return)) =
	let 
            val skcctx = (sctx, kctx, cctx) 
	    val (pn, cover, ctxd as (sctxd, kctxd, _, _), nps) = match_ptrn (skcctx, pn, Mono t1)
	    val ctx = add_ctx ctxd ctx
            val (e, t, d) = 
                case return of
                    (SOME t, SOME d) =>
                    let
	                val e = check_type_time (ctx, e, Mono (shift_ctx_mt ctxd t), shift_ctx_i ctxd d)
                    in
                        (e, t, d)
                    end
                  | (SOME t, NONE) =>
                    let 
                        val (e, d) = check_type (ctx, e, Mono (shift_ctx_mt ctxd t))
			val d = forget_ctx_d (get_region_e e) ctx ctxd d
                    in
                        (e, t, d)
                    end
                  | (NONE, SOME d) =>
                    let 
                        val (e, t) = check_time_return_mtype (ctx, e, shift_ctx_i ctxd d)
			val t = forget_ctx_mt (get_region_e e) ctx ctxd t 
                    in
                        (e, t, d)
                    end
                  | (NONE, NONE) =>
                    let 
                        val (e, t, d) = get_mtype (ctx, e)
			val t = forget_ctx_mt (get_region_e e) ctx ctxd t 
			val d = forget_ctx_d (get_region_e e) ctx ctxd d
                    in
                        (e, t, d)
                    end
            val () = close_premises nps
            val () = close_vc ctxd
	in
	    (e, ((t, d), cover))
	end

    and check_mtype (ctx as (sctx, kctx, cctx, tctx), e, t) =
	let 
	    val ctxn as (sctxn, kctxn, cctxn, tctxn) = ctx_names ctx
	    val (e, t', d) = get_mtype (ctx, e)
            val () = unify (t', t)
                     handle UnifyError ue => handle_ue ctxn ue
        (* val () = println "check type" *)
        (* val () = println $ str_region "" "ilist.timl" $ get_region_e e *)
	in
            (e, t', d)
	end

    and check_time (ctx as (sctx, kctx, cctx, tctx), e, d) : mtype =
	let 
	    val (e, t, d') = get_mtype (ctx, e)
            val () = write_le (d', d, get_region_e e)
	in
            (e, t)
	end

    and check_mtype_time (ctx as (sctx, kctx, cctx, tctx), e, t, d) =
	let 
	    val ctxn as (sctxn, kctxn, cctxn, tctxn) = ctx_names ctx
	    (* val () = print (sprintf "Type checking $ against $ and $\n" [str_e ctxn e, str_t (sctxn, kctxn) t, str_i sctxn d]) *)
	    val (e, _, d') = check_mtype (ctx, e, t)
            (* val () = println "check type & time" *)
            (* val () = println $ str_region "" "ilist.timl" $ get_region_e e *)
            val () = write_le (d', d, get_region_e e)
	in
	    e
	end

in								     

fun vcgen_expr ctx e : (ty * idx) * vc list =
    runWriter (fn () => get_type (ctx, e)) ()
	      
fun vcgen_expr_opt ctx e =
    runError (fn () => vcgen_expr ctx e) ()
	     
fun vcgen_decls ctx decls =
    runWriter (fn () => check_decls (ctx, decls)) ()
	      
fun vcgen_expr_opt ctx decls =
    runError (fn () => vcgen_decls ctx decls) ()
	     
end

open TrivialSolver

fun typecheck_expr (ctx as (sctx, kctx, cctx, tctx) : context) e : (ty * idx) * vc list =
    let 
        val ((t, d), vcs) = vcgen_expr ctx e
        val t = simp_t t
        val d = simp_i d
        val vcs = map (uniquefy_names) vcs
        val vcs = simp_and_solve_vcs vcs
    in
        ((t, d), vcs)
    end

fun typecheck_expr_opt ctx e =
    runError (fn () => typecheck_expr ctx e) ()

type tc_result = (context * idx list * context) * vc list

fun typecheck_decls (ctx as (sctx, kctx, cctx, tctx) : context) decls : tc_result =
    let 
        val ((ctxd, ds, ctx), vcs) = vcgen_decls ctx decls
        val ctxd = (upd4 o map o mapSnd) simp_t ctxd
        val ds = rev ds
        val ds = map simp_i ds
        val vcs = map (uniquefy_names) vcs
        val vcs = simp_and_solve_vcs vcs
    in
        ((ctxd, ds, ctx), vcs)
    end

fun typecheck_decls_opt ctx e =
    runError (fn () => typecheck_decls ctx e) ()

end
	                  
