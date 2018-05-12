signature SIG_MICRO_TIML_HOISTED_DEF =
sig
    structure MicroTiMLDef : SIG_MICRO_TIML_DEF

    datatype atom_expr =
             AEVar of MicroTiMLDef.var
             | AEConst of MicroTiMLDef.expr_const
             | AEFuncPointer of int
             | AEAppC of atom_expr * MicroTiMLDef.cstr
             | AEPack of MicroTiMLDef.cstr * atom_expr
             | AEFold of atom_expr
             | AEInj of MicroTiMLDef.injector * atom_expr

         and complex_expr =
             CEUnOp of MicroTiMLDef.expr_un_op * atom_expr (* no fold, inj *)
             | CEBinOp of MicroTiMLDef.expr_bin_op * atom_expr * atom_expr (* no app *)
             | CETriOp of MicroTiMLDef.expr_tri_op * atom_expr * atom_expr * atom_expr
             | CEAtom of atom_expr

         and hoisted_expr =
             HELet of complex_expr * hoisted_expr
             | HEUnpack of atom_expr * hoisted_expr
             | HEApp of atom_expr * atom_expr
             | HECase of atom_expr * hoisted_expr * hoisted_expr
             | HEHalt of atom_expr

         and func_expr =
             FEFix of int * hoisted_expr

    type hoi_fctx = MicroTiMLDef.cstr list
    type hoi_ctx = hoi_fctx * MicroTiMLDef.kctx * MicroTiMLDef.tctx

    type atom_typing_judgement = hoi_ctx * atom_expr * MicroTiMLDef.cstr
    type complex_typing_judgement = hoi_ctx * complex_expr * MicroTiMLDef.cstr
    type hoisted_typing_judgement = hoi_ctx * hoisted_expr * MicroTiMLDef.cstr
    type func_typing_judgement = hoi_fctx * func_expr * MicroTiMLDef.cstr

    datatype atom_typing =
             ATyVar of atom_typing_judgement
             | ATyConst of atom_typing_judgement
             | ATyFuncPointer of atom_typing_judgement
             | ATyAppC of atom_typing_judgement * atom_typing * MicroTiMLDef.kinding
             | ATyPack of atom_typing_judgement * MicroTiMLDef.kinding * MicroTiMLDef.kinding * atom_typing
             | ATyFold of atom_typing_judgement * MicroTiMLDef.kinding * atom_typing
             | ATyInj of atom_typing_judgement * atom_typing * MicroTiMLDef.kinding
             | ATySubTy of atom_typing_judgement * atom_typing * MicroTiMLDef.tyeq

         and complex_typing =
             CTyProj of complex_typing_judgement * atom_typing
             | CTyPair of complex_typing_judgement * atom_typing * atom_typing
             | CTyUnfold of complex_typing_judgement * atom_typing
             | CTyNew of complex_typing_judgement * atom_typing * atom_typing
             | CTyRead of complex_typing_judgement * atom_typing * atom_typing * MicroTiMLDef.proping
             | CTyWrite of complex_typing_judgement * atom_typing * atom_typing * MicroTiMLDef.proping * atom_typing
             | CTyPrimBinOp of complex_typing_judgement * atom_typing * atom_typing
             | CTyAtom of complex_typing_judgement * atom_typing
             | CTySubTy of complex_typing_judgement * complex_typing * MicroTiMLDef.tyeq

         and hoisted_typing =
             HTyLet of hoisted_typing_judgement * complex_typing * hoisted_typing
             | HTyUnpack of hoisted_typing_judgement * atom_typing * hoisted_typing
             | HTyApp of hoisted_typing_judgement * atom_typing * atom_typing
             | HTyCase of hoisted_typing_judgement * atom_typing * hoisted_typing * hoisted_typing
             | HTyHalt of hoisted_typing_judgement * atom_typing
             | HTySubTi of hoisted_typing_judgement * hoisted_typing * MicroTiMLDef.proping

         and func_typing =
             FTyFix of func_typing_judgement * MicroTiMLDef.kinding * hoisted_typing

    datatype program =
             Program of func_expr list * hoisted_expr
    type program_typing_judgement = program * MicroTiMLDef.cstr
    datatype program_typing =
             TyProgram of program_typing_judgement * func_typing list * hoisted_typing

    val CEProj : MicroTiMLDef.projector * atom_expr -> complex_expr
    val CEPair : atom_expr * atom_expr -> complex_expr
    val CEUnfold : atom_expr -> complex_expr
    val CENew : atom_expr * atom_expr -> complex_expr
    val CERead : atom_expr * atom_expr -> complex_expr
    val CEWrite : atom_expr * atom_expr * atom_expr -> complex_expr

    val extract_judge_ptyping : program_typing -> program_typing_judgement
    val extract_judge_htyping : hoisted_typing -> hoisted_typing_judgement
    val extract_judge_atyping : atom_typing -> atom_typing_judgement
    val extract_judge_ctyping : complex_typing -> complex_typing_judgement
    val extract_judge_ftyping : func_typing -> func_typing_judgement

    val str_atom_expr : atom_expr -> string
    val str_complex_expr : complex_expr -> string
    val str_hoisted_expr : string -> hoisted_expr -> string
    val str_func_expr : int -> func_expr -> string
    val str_program : program -> string

    val hoist_deriv : MicroTiMLDef.typing -> program_typing
end
