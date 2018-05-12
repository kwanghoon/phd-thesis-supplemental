signature SIG_TYPED_ASSEMBLY_DEF =
sig
    structure MicroTiMLHoistedDef : SIG_MICRO_TIML_HOISTED_DEF

    type tal_register = int
    type tal_location = int
    type tal_var = int

    datatype tal_cstr =
             TCVar of tal_var
             | TCConst of MicroTiMLHoistedDef.MicroTiMLDef.cstr_const
             | TCBinOp of MicroTiMLHoistedDef.MicroTiMLDef.cstr_bin_op * tal_cstr * tal_cstr
             | TCIte of tal_cstr * tal_cstr * tal_cstr
             | TCTimeAbs of tal_cstr
             | TCTimeApp of int * tal_cstr * tal_cstr
             | TCArrow of tal_cstr list * tal_cstr (* type of register file & index of running time *)
             | TCAbs of tal_cstr
             | TCApp of tal_cstr * tal_cstr
             | TCQuan of MicroTiMLHoistedDef.MicroTiMLDef.quan * tal_kind * tal_cstr
             | TCRec of tal_kind * tal_cstr
             | TCTypeNat of tal_cstr
             | TCTypeArr of tal_cstr * tal_cstr
             | TCUnOp of MicroTiMLHoistedDef.MicroTiMLDef.cstr_un_op * tal_cstr

         and tal_kind =
             TKType
             | TKArrow of tal_kind * tal_kind
             | TKBaseSort of MicroTiMLHoistedDef.MicroTiMLDef.sort
             | TKSubset of tal_kind * tal_prop

         and tal_prop =
             TPTrue
             | TPFalse
             | TPBinConn of MicroTiMLHoistedDef.MicroTiMLDef.prop_bin_conn * tal_prop * tal_prop
             | TPNot of tal_prop
             | TPBinPred of MicroTiMLHoistedDef.MicroTiMLDef.prop_bin_pred * tal_cstr * tal_cstr
             | TPQuan of MicroTiMLHoistedDef.MicroTiMLDef.quan * MicroTiMLHoistedDef.MicroTiMLDef.sort * tal_prop

    datatype tal_word =
             TWLoc of tal_location
             | TWConst of MicroTiMLHoistedDef.MicroTiMLDef.expr_const
             | TWAppC of tal_word * tal_cstr
             | TWPack of tal_cstr * tal_word
             | TWFold of tal_word
             | TWInj of MicroTiMLHoistedDef.MicroTiMLDef.injector * tal_word

    datatype tal_value =
             TVReg of tal_register
             | TVWord of tal_word
             | TVAppC of tal_value * tal_cstr
             | TVPack of tal_cstr * tal_value
             | TVFold of tal_value
             | TVInj of MicroTiMLHoistedDef.MicroTiMLDef.injector * tal_value

    datatype tal_instr =
             TINewpair of tal_register * tal_register * tal_register
             | TIProj of MicroTiMLHoistedDef.MicroTiMLDef.projector * tal_register * tal_register
             | TIUnfold of tal_register
             | TINewarray of tal_register * tal_register * tal_register
             | TILoad of tal_register * tal_register * tal_register
             | TIStore of tal_register * tal_register * tal_register
             | TIPrimBinOp of MicroTiMLHoistedDef.MicroTiMLDef.prim_expr_bin_op * tal_register * tal_register * tal_register
             | TIMove of tal_register * tal_value
             | TIUnpack of tal_register * tal_value
             | TICase of tal_register * tal_value

    datatype tal_control =
             TCJump of tal_value
           | TCHalt of tal_cstr

    type tal_block = tal_instr list * tal_control

    datatype tal_heap =
             THCode of int * tal_block
             | THPair of tal_word * tal_word
             | THWords of tal_word list

    datatype tal_program =
             TProgram of tal_heap list * tal_word list * tal_block

    type tal_hctx = tal_cstr list
    type tal_kctx = tal_kind list
    type tal_tctx = tal_cstr list
    type tal_ctx = tal_hctx * tal_kctx * tal_tctx

    type tal_proping_judgement = tal_kctx * tal_prop

    datatype tal_proping =
             TPrAdmit of tal_proping_judgement

    type tal_kdeq_judgement = tal_kctx * tal_kind * tal_kind

    datatype tal_kdeq =
             TKdEqKType of tal_kdeq_judgement
             | TKdEqKArrow of tal_kdeq_judgement * tal_kdeq * tal_kdeq
             | TKdEqBaseSort of tal_kdeq_judgement
             | TKdEqSubset of tal_kdeq_judgement * tal_kdeq * tal_proping
             | TKdEqSubsetElimLeft of tal_kdeq_judgement * tal_proping
             | TKdEqSubsetElimRight of tal_kdeq_judgement * tal_proping

    type tal_kinding_judgement = tal_kctx * tal_cstr * tal_kind
    type tal_wfkind_judgement = tal_kctx * tal_kind
    type tal_wfprop_judgement = tal_kctx * tal_prop

    datatype tal_kinding =
             TKdVar of tal_kinding_judgement
             | TKdConst of tal_kinding_judgement
             | TKdBinOp of tal_kinding_judgement * tal_kinding * tal_kinding
             | TKdIte of tal_kinding_judgement * tal_kinding * tal_kinding * tal_kinding
             | TKdArrow of tal_kinding_judgement * tal_kinding list * tal_kinding
             | TKdAbs of tal_kinding_judgement * tal_wfkind * tal_kinding
             | TKdApp of tal_kinding_judgement * tal_kinding * tal_kinding
             | TKdTimeAbs of tal_kinding_judgement * tal_kinding
             | TKdTimeApp of tal_kinding_judgement * tal_kinding * tal_kinding
             | TKdQuan of tal_kinding_judgement * tal_wfkind * tal_kinding
             | TKdRec of tal_kinding_judgement * tal_wfkind * tal_kinding
             | TKdTypeNat of tal_kinding_judgement * tal_kinding
             | TKdTypeArr of tal_kinding_judgement * tal_kinding * tal_kinding
             | TKdEq of tal_kinding_judgement * tal_kinding * tal_kdeq
             | TKdUnOp of tal_kinding_judgement * tal_kinding
             | TKdAdmit of tal_kinding_judgement

         and tal_wfkind =
             TWfKdType of tal_wfkind_judgement
             | TWfKdArrow of tal_wfkind_judgement * tal_wfkind * tal_wfkind
             | TWfKdBaseSort of tal_wfkind_judgement
             | TWfKdSubset of tal_wfkind_judgement * tal_wfkind * tal_wfprop
             | TWfKdAdmit of tal_wfkind_judgement

         and tal_wfprop =
             TWfPropTrue of tal_wfprop_judgement
             | TWfPropFalse of tal_wfprop_judgement
             | TWfPropBinConn of tal_wfprop_judgement * tal_wfprop * tal_wfprop
             | TWfPropNot of tal_wfprop_judgement * tal_wfprop
             | TWfPropBinPred of tal_wfprop_judgement * tal_kinding * tal_kinding
             | TWfPropQuan of tal_wfprop_judgement * tal_wfprop

    type tal_tyeq_judgement = tal_kctx * tal_cstr * tal_cstr

    datatype tal_tyeq =
             TTyEqVar of tal_tyeq_judgement
             | TTyEqConst of tal_tyeq_judgement
             | TTyEqBinOp of tal_tyeq_judgement * tal_tyeq * tal_tyeq
             | TTyEqIte of tal_tyeq_judgement * tal_tyeq * tal_tyeq * tal_tyeq
             | TTyEqArrow of tal_tyeq_judgement * tal_tyeq list * tal_proping
             | TTyEqApp of tal_tyeq_judgement * tal_tyeq * tal_tyeq
             | TTyEqTimeApp of tal_tyeq_judgement
             | TTyEqBeta of tal_tyeq_judgement
             | TTyEqBetaRev of tal_tyeq_judgement
             | TTyEqQuan of tal_tyeq_judgement * tal_kdeq * tal_tyeq
             | TTyEqRec of tal_tyeq_judgement * tal_kdeq * tal_tyeq
             | TTyEqAbs of tal_tyeq_judgement
             | TTyEqTimeAbs of tal_tyeq_judgement
             | TTyEqTypeNat of tal_tyeq_judgement * tal_proping
             | TTyEqTypeArr of tal_tyeq_judgement * tal_tyeq * tal_proping
             | TTyEqUnOp of tal_tyeq_judgement * tal_tyeq
             | TTyEqNat of tal_tyeq_judgement * tal_proping
             | TTyEqTime of tal_tyeq_judgement * tal_proping
             | TTyEqTrans of tal_tyeq_judgement * tal_tyeq * tal_tyeq

    type tal_word_typing_judgement = (tal_hctx * tal_kctx) * tal_word * tal_cstr

    datatype tal_word_typing =
             TWTyLoc of tal_word_typing_judgement
             | TWTyConst of tal_word_typing_judgement
             | TWTyAppC of tal_word_typing_judgement * tal_word_typing * tal_kinding
             | TWTyPack of tal_word_typing_judgement * tal_kinding * tal_kinding * tal_word_typing
             | TWTyFold of tal_word_typing_judgement * tal_kinding * tal_word_typing
             | TWTyInj of tal_word_typing_judgement * tal_word_typing * tal_kinding
             | TWTySub of tal_word_typing_judgement * tal_word_typing * tal_tyeq
             | TWTyLocAdmit of tal_word_typing_judgement (* only used during code generation *)

    type tal_value_typing_judgement = tal_ctx * tal_value * tal_cstr

    datatype tal_value_typing =
             TVTyReg of tal_value_typing_judgement
             | TVTyWord of tal_value_typing_judgement * tal_word_typing
             | TVTyAppC of tal_value_typing_judgement * tal_value_typing * tal_kinding
             | TVTyPack of tal_value_typing_judgement * tal_kinding * tal_kinding * tal_value_typing
             | TVTyFold of tal_value_typing_judgement * tal_kinding * tal_value_typing
             | TVTyInj of tal_value_typing_judgement * tal_value_typing * tal_kinding
             | TVTySub of tal_value_typing_judgement * tal_value_typing * tal_tyeq

    type tal_instr_typing_judgement = tal_ctx * tal_block * tal_cstr

    datatype tal_instr_typing =
             TITyNewpair of tal_instr_typing_judgement * tal_value_typing * tal_value_typing * tal_instr_typing
             | TITyProj of tal_instr_typing_judgement * tal_value_typing * tal_instr_typing
             | TITyUnfold of tal_instr_typing_judgement * tal_value_typing * tal_instr_typing
             | TITyNewarray of tal_instr_typing_judgement * tal_value_typing * tal_value_typing * tal_instr_typing
             | TITyLoad of tal_instr_typing_judgement * tal_value_typing * tal_value_typing * tal_proping * tal_instr_typing
             | TITyStore of tal_instr_typing_judgement * tal_value_typing * tal_value_typing * tal_proping * tal_value_typing * tal_instr_typing
             | TITyPrimBinOp of tal_instr_typing_judgement * tal_value_typing * tal_value_typing * tal_instr_typing
             | TITyMove of tal_instr_typing_judgement * tal_value_typing * tal_instr_typing
             | TITyUnpack of tal_instr_typing_judgement * tal_value_typing * tal_instr_typing
             | TITyCase of tal_instr_typing_judgement * tal_value_typing * tal_instr_typing * tal_value_typing
             | TITyJump of tal_instr_typing_judgement * tal_value_typing
             | TITyHalt of tal_instr_typing_judgement * tal_value_typing
             | TITySub of tal_instr_typing_judgement * tal_instr_typing * tal_proping

    type tal_heap_typing_judgement = tal_hctx * tal_heap * tal_cstr

    datatype tal_heap_typing =
             THTyCode of tal_heap_typing_judgement * tal_kinding * tal_instr_typing
             | THTyPair of tal_heap_typing_judgement * tal_word_typing * tal_word_typing
             | THTyWords of tal_heap_typing_judgement * tal_word_typing list

    type tal_program_typing_judgement = tal_program * tal_cstr

    datatype tal_program_typing =
             TPTyProgram of tal_program_typing_judgement * tal_heap_typing list * tal_word_typing list * tal_instr_typing

    val TKUnit : tal_kind
    val TKBool : tal_kind
    val TKNat : tal_kind
    val TKTimeFun : int -> tal_kind
    val TKTime : tal_kind

    val TTconst : MicroTiMLHoistedDef.MicroTiMLDef.Time.time_type -> tal_cstr
    val TT0 : tal_cstr
    val TT1 : tal_cstr
    val TTadd : tal_cstr * tal_cstr -> tal_cstr
    val TTminus : tal_cstr * tal_cstr -> tal_cstr
    val TTmult : tal_cstr * tal_cstr -> tal_cstr
    val TTmax : tal_cstr * tal_cstr -> tal_cstr

    val TTfromNat : tal_cstr -> tal_cstr

    val TPAnd : tal_prop * tal_prop -> tal_prop
    val TPOr : tal_prop * tal_prop -> tal_prop
    val TPImply : tal_prop * tal_prop -> tal_prop
    val TPIff : tal_prop * tal_prop -> tal_prop

    val TCForall : tal_kind * tal_cstr -> tal_cstr
    val TCExists : tal_kind * tal_cstr -> tal_cstr

    val TCTypeUnit : tal_cstr
    val TCTypeInt : tal_cstr

    val TCProd : tal_cstr * tal_cstr -> tal_cstr
    val TCSum : tal_cstr * tal_cstr -> tal_cstr

    val TTLe : tal_cstr * tal_cstr -> tal_prop
    val TTEq : tal_cstr * tal_cstr -> tal_prop

    val TNLt : tal_cstr * tal_cstr -> tal_prop
    val TNEq : tal_cstr * tal_cstr -> tal_prop

    val TCNat : MicroTiMLHoistedDef.MicroTiMLDef.Nat.nat_type -> tal_cstr

    val TCApps : tal_cstr -> tal_cstr list -> tal_cstr

    val TBSTime : MicroTiMLHoistedDef.MicroTiMLDef.sort

    val const_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.cstr_const -> tal_kind
    val const_tal_type : MicroTiMLHoistedDef.MicroTiMLDef.expr_const -> tal_cstr
    val cbinop_arg1_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.cstr_bin_op -> tal_kind
    val cbinop_arg2_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.cstr_bin_op -> tal_kind
    val cbinop_result_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.cstr_bin_op -> tal_kind
    val cunop_arg_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.cstr_un_op -> tal_kind
    val cunop_result_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.cstr_un_op -> tal_kind
    val binpred_arg1_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.prop_bin_pred -> tal_kind
    val binpred_arg2_tal_kind : MicroTiMLHoistedDef.MicroTiMLDef.prop_bin_pred -> tal_kind
    val pebinop_arg1_tal_type : MicroTiMLHoistedDef.MicroTiMLDef.prim_expr_bin_op -> tal_cstr
    val pebinop_arg2_tal_type : MicroTiMLHoistedDef.MicroTiMLDef.prim_expr_bin_op -> tal_cstr
    val pebinop_result_tal_type : MicroTiMLHoistedDef.MicroTiMLDef.prim_expr_bin_op -> tal_cstr

    val update_tal_tctx : tal_register -> tal_cstr -> tal_tctx -> tal_tctx

    val extract_judge_tal_proping : tal_proping -> tal_proping_judgement
    val extract_judge_tal_kdeq : tal_kdeq -> tal_kdeq_judgement
    val extract_judge_tal_kinding : tal_kinding -> tal_kinding_judgement
    val extract_judge_tal_wfkind : tal_wfkind -> tal_wfkind_judgement
    val extract_judge_tal_wfprop : tal_wfprop -> tal_wfprop_judgement
    val extract_judge_tal_tyeq : tal_tyeq -> tal_tyeq_judgement
    val extract_judge_tal_word_typing : tal_word_typing -> tal_word_typing_judgement
    val extract_judge_tal_value_typing : tal_value_typing -> tal_value_typing_judgement
    val extract_judge_tal_instr_typing : tal_instr_typing -> tal_instr_typing_judgement
    val extract_judge_tal_heap_typing : tal_heap_typing -> tal_heap_typing_judgement
    val extract_judge_tal_program_typing : tal_program_typing -> tal_program_typing_judgement

    val extract_tal_p_bin_conn : tal_prop -> MicroTiMLHoistedDef.MicroTiMLDef.prop_bin_conn * tal_prop * tal_prop
    val extract_tal_p_bin_pred : tal_prop -> MicroTiMLHoistedDef.MicroTiMLDef.prop_bin_pred * tal_cstr * tal_cstr
    val extract_tal_k_arrow : tal_kind -> tal_kind * tal_kind
    val extract_tal_k_time_fun : tal_kind -> int
    val extract_tal_c_quan : tal_cstr -> MicroTiMLHoistedDef.MicroTiMLDef.quan * tal_kind * tal_cstr
    val extract_tal_c_arrow : tal_cstr -> tal_cstr list * tal_cstr
    val extract_tal_c_abs : tal_cstr -> tal_cstr
    val extract_tal_c_prod : tal_cstr -> tal_cstr * tal_cstr
    val extract_tal_c_rec : tal_cstr -> tal_kind * tal_cstr
    val extract_tal_c_sum : tal_cstr -> tal_cstr * tal_cstr
    val extract_tal_c_type_nat : tal_cstr -> tal_cstr
    val extract_tal_c_type_arr : tal_cstr -> tal_cstr * tal_cstr
    val extract_tal_v_reg : tal_value -> tal_register

    val str_tal_cstr : tal_cstr -> string
    val str_tal_kind : tal_kind -> string
    val str_tal_prop : tal_prop -> string

    val str_tal_program : tal_program -> string
end
