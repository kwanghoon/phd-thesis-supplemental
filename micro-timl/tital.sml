(* Timed and Typed Assembly Language *)

structure TiTAL = struct

type reg = int
type label = int

(* word values *)
datatype word =
         WLabel of label
         | WConst of Operators.expr_const
         | WUninit of ty
         | WAppT of word * ty
         | WPack of ty * ty * word
           
(* small values *)
datatype value =
         VReg of reg
         | VWordVal of word
         | VAppT of value * ty
         | VPack of ty * ty * value
         
datatype inst =
         IBinOpPrim of prim_expr_bin_op * reg * reg * value
         | IBr of reg * value
         | ILd of reg * (reg * projector)
         | IMallocPair of reg * (value * value)
         | IMov of reg * value
         | ISt of (reg * projector) * reg
         | IUnpack of name * reg * value
         | IInj of reg * injector * value
         | IAscTime of idx

datatype insts =
         ISCons of inst * insts
         | ISJmp of value
         | ISHalt of ty

fun cg_v ectx v =
  case v of
      EVar (ID (x, _)) =>
      (case nth_error rctx x of
           SOME r => VReg r
         | NONE => raise Impossible $ "no mapping for variable " ^ str_int x)
    | EConst c => VWordVal $ WConst c
    | EAppT (v, t) => VAppT (cg_v ectx v, cg_t t)
    | EPack (t_pack, t, v) => VPack (cg_t t_pack, cg_t t, cg_v ectx v)
                         
fun cg_e (ectx, itctx, rctx) e =
  case e of
      ELet (e1, bind) =>
      let
        val (I1, r, t) =
            case fst $ collect_EAscType e1 of
                EProjProtected (proj, v) =>
                let
                  val (_, t) = assert_EAscType e1
                  val t = cg_t t
                  val r = fresh_reg ()
                in
                  ([IMov (r, cg_v ectx v),
                    ILd (r, (r, proj))],
                   r, t)
                end
              | EBinOp (EBPrim opr, v1, v2) =>
                let
                  val (_, t) = assert_EAscType e1
                  val t = cg_t t
                  val r = fresh_reg ()
                in
                  ([IMov (r, cg_v ectx v1),
                   IBinOpPrim (opr, r, r, cg_v ectx v2)],
                   r, t)
                end
              | EUnOp (EUInj (inj, t_other), v) =>
                let
                  val (v, t_v) = assert_EAscType v
                  val t_sum = TSum $ choose_pair_inj (t_v, t_other) inj
                  val t_sum = cg_t t_sum
                  val r = fresh_reg ()
                  fun choose_pair_inj (t, t_other) inj =
                    case inj of
                        InjInl => (t, t_other)
                      | InjInr => (t_other, t)
                in
                  ([IInj (r, inj, cg_v ectx v)],
                   r, t_sum)
                end
              | v =>
                let
                  val (_, t) = assert_EAscType e1
                  val t = cg_t t
                  val r = fresh_reg ()
                in
                  ([IMov (r, cg_v ectx v)],
                   r, t)
                end
              | EMallocPair (v1, v2) =>
                let
                  val (_, t) = assert_EAscType e1
                  val t = cg_t t
                  val r = fresh_reg ()
                in
                  ([IMallocPair (r, cg_v ectx v1, cg_v ectx v2)],
                   r, t)
                end
              | EPairAssign (v1, proj, v2) =>
                let
                  val (_, t) = assert_EAscType e1
                  val t = cg_t t
                  val r = fresh_reg ()
                  val r' = fresh_reg ()
                in
                  ([IMov (r, cg_v ectx v1),
                            IMov (r', cg_v ectx v2),
                            ISt ((r, proj), r')],
                   r, t)
                end
        val (name, e2) = unBindSimpName bind
        val I = cg_e (inl r :: ectx, itctx, rctx @+ (r, t)) e2
      in
        I1 @@ I
      end
    | EUnpack (v, bind) =>
      let
        val (v, t) = assert_EAscType v
        val ((_, k), t) = assert_TExists t
        val t = cg_t t
        val r = fresh_reg ()
        val i = IUnpack (name_a, r, cg_v ectx v)
        val (name_x, bind) = unBindSimpName bind
        val (name_a, e2) = unBindSimpName bind
        val I = cg_e (inl r :: ectx, inr (name_a, k) :: itctx, rctx @+ (r, t)) e2
      in
        i @:: I
      end
    | EBinOp (EBApp, v1, v2) =>
      let
        val r = fresh_reg_util (fn r => r <> 1)
        val i = IUnpack (name_a, r, cg_v ectx v)
      in
        IMove (r, cg_v ectx v1) @::
        IMove (1, cg_v ectx v2) @::
        ISJmp (VReg r)
      end
    | ECase (v, bind1, bind2) =>
      let
        val (v, t) = assert_EAscType v
        val t = cg_t t
        val (t1, t2) => assert_TSum t
        val (name1, e1) = unBindSimpName bind1
        val (name2, e2) = unBindSimpName bind2
        val (e2, i_e2) = assert_EAscTime e2
        val r = fresh_reg ()
        val v = cg_v ectx v
        val I1 = cg_e (inl r :: ectx, itctx, rctx @+ (r, t1)) e1
        val rctx2 = rctx @+ (r, t2)
        val I2 = cg_e (inl r :: ectx, itctx, rctx2) e2
        val itbinds = rev itctx
        val hval = MakeHCode (itbinds, (rctx2, i_e2), I2)
        val l = fresh_label ()
        val () = output_heap_single (l, hval)
      in
        IMove (r, v) @::
        IBr (r, VAppITs_binds (VLabel l, itbinds)) @::
        I1
      end
    | EHalt v =>
      let
        val (v, t) = assert_EAscType v
        val t = cg_t t
      in
        IMov (1, cg_v ectx v) @::
        ISHalt t
      end
        
                       
(* ectx: variable mapping, maps variables to registers or labels *)
fun cg_hval ectx (e, t_all) =
  let
    val (itbinds, e) = collect_EAbsIT e
    val ((name, t), e) = assert_EAbs e
    val t = cg_t t
    (* input argument is always stored in r1 *)
    val ectx = (inl 1) :: ectx
    val rctx = rctx_single (1, t)
    val I = cg_e (ectx, rev itbinds, rctx) e
    val hval = MakeHCode (itbinds, (rctx, get_time t_all), I)
  in
    hval
  end
  
fun cg_prog e =
  let
    val () = heap_ref := []
    val (binds, e) = collect_ELetRec e
    val len = length binds
    fun on_bind bind =
      let
        ((name, t), e) = unBindAnnoName bind
        (* val t = cg_t t *)
        val l = fresh_label ()
        val hval = cg_hval [inr l] (e, t)
        val () = output_heap_single (l, hval)
      in
        l
      end
    val labels = map on_bind binds
    val ectx = map inr $ rev labels
    val I = cg_e (ectx, [], rctx_empty) e
    val H = !heap_ref
  in
    (H, I)
  end

end
