structure MicroTiMLVisitor = struct

open Operators
open MicroTiML
open Unbound
open Util
       
infixr 0 $
infix 0 !!

(***************** type visitor  **********************)    

type ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
     {
       visit_kind : 'this -> 'env -> 'bsort kind -> 'bsort2 kind,
       visit_KType : 'this -> 'env -> unit -> 'bsort2 kind,
       visit_KArrow : 'this -> 'env -> 'bsort * 'bsort kind -> 'bsort2 kind,
       visit_KArrowT : 'this -> 'env -> 'bsort kind * 'bsort kind -> 'bsort2 kind,
       visit_ty : 'this -> 'env -> ('var, 'bsort, 'idx, 'sort) ty -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TVar : 'this -> 'env -> 'var * 'bsort kind list -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TConst : 'this -> 'env -> ty_const -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TBinOp : 'this -> 'env -> ty_bin_op * ('var, 'bsort, 'idx, 'sort) ty * ('var, 'bsort, 'idx, 'sort) ty -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TArrow : 'this -> 'env -> ('idx * ('var, 'bsort, 'idx, 'sort) ty) * ('idx * 'idx) * ('idx * ('var, 'bsort, 'idx, 'sort) ty) -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TAbsI : 'this -> 'env -> ('bsort, ('var, 'bsort, 'idx, 'sort) ty) ibind_anno -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TAppI : 'this -> 'env -> ('var, 'bsort, 'idx, 'sort) ty * 'idx -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TQuan : 'this -> 'env -> unit quan * ('idx * 'idx) * ('bsort kind, ('var, 'bsort, 'idx, 'sort) ty) tbind_anno -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TQuanI : 'this -> 'env -> unit quan * ('sort, ('idx * 'idx) * ('var, 'bsort, 'idx, 'sort) ty) ibind_anno -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TRec : 'this -> 'env -> ('bsort kind, ('var, 'bsort, 'idx, 'sort) ty) tbind_anno -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TNat : 'this -> 'env -> 'idx -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TArray : 'this -> 'env -> int * ('var, 'bsort, 'idx, 'sort) ty * 'idx -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TAbsT : 'this -> 'env -> ('bsort kind, ('var, 'bsort, 'idx, 'sort) ty) tbind_anno -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       visit_TAppT : 'this -> 'env -> ('var, 'bsort, 'idx, 'sort) ty * ('var, 'bsort, 'idx, 'sort) ty -> ('var2, 'bsort2, 'idx2, 'sort2) ty,
       (* visit_TProdEx : 'this -> 'env -> (('var, 'bsort, 'idx, 'sort) ty * bool) * (('var, 'bsort, 'idx, 'sort) ty * bool) -> ('var2, 'bsort2, 'idx2, 'sort2) ty, *)
       (* visit_TArrowTAL : 'this -> 'env -> ('var, 'bsort, 'idx, 'sort) ty Rctx.map * 'idx -> ('var2, 'bsort2, 'idx2, 'sort2) ty, *)
       visit_var : 'this -> 'env -> 'var -> 'var2,
       visit_bsort : 'this -> 'env -> 'bsort -> 'bsort2,
       visit_idx : 'this -> 'env -> 'idx -> 'idx2,
       visit_sort : 'this -> 'env -> 'sort -> 'sort2,
       visit_ty_const : 'this -> 'env -> ty_const -> ty_const,
       visit_ty_bin_op : 'this -> 'env -> ty_bin_op -> ty_bin_op,
       visit_quan : 'this -> 'env -> unit quan -> unit quan,
       visit_ibind_anno_bsort : 'this -> ('env -> 'bsort -> 'bsort2) -> ('env -> ('var, 'bsort, 'idx, 'sort) ty -> ('var2, 'bsort2, 'idx2, 'sort2) ty) -> 'env -> ('bsort, ('var, 'bsort, 'idx, 'sort) ty) ibind_anno -> ('bsort2, ('var2, 'bsort2, 'idx2, 'sort2) ty) ibind_anno,
       visit_ibind_anno_sort : 'this -> ('env -> 'sort -> 'sort2) -> ('env -> ('idx * 'idx) * ('var, 'bsort, 'idx, 'sort) ty -> ('idx2 * 'idx2) * ('var2, 'bsort2, 'idx2, 'sort2) ty) -> 'env -> ('sort, ('idx * 'idx) * ('var, 'bsort, 'idx, 'sort) ty) ibind_anno -> ('sort2, ('idx2 * 'idx2) * ('var2, 'bsort2, 'idx2, 'sort2) ty) ibind_anno,
       visit_tbind_anno : 'this -> ('env -> 'bsort kind -> 'bsort2 kind) -> ('env -> ('var, 'bsort, 'idx, 'sort) ty -> ('var2, 'bsort2, 'idx2, 'sort2) ty) -> 'env -> ('bsort kind, ('var, 'bsort, 'idx, 'sort) ty) tbind_anno -> ('bsort2 kind, ('var2, 'bsort2, 'idx2, 'sort2) ty) tbind_anno,
       extend_i : 'this -> 'env -> iname -> 'env * iname,
       extend_t : 'this -> 'env -> tname -> 'env * tname
     }
       
type ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_interface =
     ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable
                                       
datatype ('env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor =
         TyVisitor of (('env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_interface

fun ty_visitor_impls_interface (this : ('env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor) :
    (('env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_interface =
  let
    val TyVisitor vtable = this
  in
    vtable
  end

fun new_ty_visitor vtable params =
  let
    val vtable = vtable ty_visitor_impls_interface params
  in
    TyVisitor vtable
  end

(***************** the default visitor  **********************)    

open VisitorUtil
       
fun default_ty_visitor_vtable
      (cast : 'this -> ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_interface)
      extend_i
      extend_t
      visit_var
      visit_bsort
      visit_idx
      visit_sort
    : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  let
    fun visit_kind this env data =
      let
        val vtable = cast this
      in
        case data of
            KType () => #visit_KType vtable this env ()
          | KArrow data => #visit_KArrow vtable this env data
          | KArrowT data => #visit_KArrowT vtable this env data
      end
    fun visit_KType this env data = KType ()
    fun visit_KArrow this env data = 
      let
        val vtable = cast this
        val (b, k) = data
        val b = #visit_bsort vtable this env b
        val k = #visit_kind vtable this env k
      in
        KArrow (b, k)
      end
    fun visit_KArrowT this env data = 
      let
        val vtable = cast this
        val (k1, k2) = data
        val k1 = #visit_kind vtable this env k1
        val k2 = #visit_kind vtable this env k2
      in
        KArrowT (k1, k2)
      end
    fun visit_ty this env data =
      let
        val vtable = cast this
      in
        case data of
            TVar data => #visit_TVar vtable this env data
          | TConst data => #visit_TConst vtable this env data
          | TBinOp data => #visit_TBinOp vtable this env data
          | TArrow data => #visit_TArrow vtable this env data
          | TAbsI data => #visit_TAbsI vtable this env data
          | TAppI data => #visit_TAppI vtable this env data
          | TQuan data => #visit_TQuan vtable this env data
          | TQuanI data => #visit_TQuanI vtable this env data
          | TRec data => #visit_TRec vtable this env data
          | TNat data => #visit_TNat vtable this env data
          | TArray data => #visit_TArray vtable this env data
          | TAbsT data => #visit_TAbsT vtable this env data
          | TAppT data => #visit_TAppT vtable this env data
          | TiBool idx => TiBool $ #visit_idx vtable this env idx
          (* | TProdEx data => #visit_TProdEx vtable this env data *)
          (* | TArrowTAL data => #visit_TArrowTAL vtable this env data *)
          | TArrowEVM (i1, rctx, ts, i2) =>
            TArrowEVM (#visit_idx vtable this env i1,
                       Rctx.map (#visit_ty vtable this env) rctx,
                       visit_list (#visit_ty vtable this) env ts,
                       visit_pair (#visit_idx vtable this) (#visit_idx vtable this) env i2)
          | TPreArray (w, t, i1, i2, b) => TPreArray (w, #visit_ty vtable this env t, #visit_idx vtable this env i1, #visit_idx vtable this env i2, b)
          | TArrayPtr (w, t, i1, i2) => TArrayPtr (w, #visit_ty vtable this env t, #visit_idx vtable this env i1, #visit_idx vtable this env i2)
          | TPreTuple (ts, i, i2) => TPreTuple (visit_list (#visit_ty vtable this) env ts, i, i2)
          | TTuplePtr (ts, i, b) => TTuplePtr (visit_list (#visit_ty vtable this) env ts, i, b)
          | TVectorPtr (x, i) => TVectorPtr (x, #visit_idx vtable this env i)
          | TTuple ts => TTuple (visit_list (#visit_ty vtable this) env ts)
          | TRecord fields => TRecord $ SMap.map (#visit_ty vtable this env) fields
          | TState x =>  TState x
          | TMap t => TMap $ #visit_ty vtable this env t
          | TVector t => TVector $ #visit_ty vtable this env t
          | TSCell t => TSCell $ #visit_ty vtable this env t
          | TNatCell r => TNatCell r
          | TPtr t => TPtr $ #visit_ty vtable this env t
      end
    fun visit_TVar this env data =
      let
        val vtable = cast this
      in
        TVar $ visit_pair (#visit_var vtable this) (visit_list (#visit_kind vtable this)) env data
      end
    fun visit_TConst this env data =
      let
        val vtable = cast this
      in
        TConst $ #visit_ty_const vtable this env data
      end
    fun visit_TBinOp this env data = 
      let
        val vtable = cast this
        val (opr, t1, t2) = data
        val opr = #visit_ty_bin_op vtable this env opr
        val t1 = #visit_ty vtable this env t1
        val t2 = #visit_ty vtable this env t2
      in
        TBinOp (opr, t1, t2)
      end
    fun visit_TArrow this env data = 
      let
        val vtable = cast this
        val ((i1, t1), i, (i2, t2)) = data
        val i1 = #visit_idx vtable this env i1
        val t1 = #visit_ty vtable this env t1
        val i = visit_pair (#visit_idx vtable this) (#visit_idx vtable this) env i
        val i2 = #visit_idx vtable this env i2
        val t2 = #visit_ty vtable this env t2
      in
        TArrow ((i1, t1), i, (i2, t2))
      end
    fun visit_TAbsI this env data =
      let
        val vtable = cast this
      in
        TAbsI $ #visit_ibind_anno_bsort vtable this (#visit_bsort vtable this) (#visit_ty vtable this) env data
      end
    fun visit_TAppI this env data = 
      let
        val vtable = cast this
        val (t, i) = data
        val t = #visit_ty vtable this env t
        val i = #visit_idx vtable this env i
      in
        TAppI (t, i)
      end
    fun visit_TQuan this env data =
      let
        val (q, i, bind) = data
        val vtable = cast this
        val q = #visit_quan vtable this env q
        val i = visit_pair (#visit_idx vtable this) (#visit_idx vtable this) env i
        val bind = #visit_tbind_anno vtable this (#visit_kind vtable this) (#visit_ty vtable this) env bind
      in
        TQuan (q, i, bind)
      end
    fun visit_TQuanI this env data =
      let
        val (q, bind) = data
        val vtable = cast this
        val q = #visit_quan vtable this env q
        val bind = #visit_ibind_anno_sort vtable this (#visit_sort vtable this) (visit_pair (visit_pair (#visit_idx vtable this) (#visit_idx vtable this)) (#visit_ty vtable this)) env bind
      in
        TQuanI (q, bind)
      end
    fun visit_TRec this env data =
      let
        val vtable = cast this
      in
        TRec $ #visit_tbind_anno vtable this (#visit_kind vtable this) (#visit_ty vtable this) env data
      end
    fun visit_TNat this env data = 
      let
        val vtable = cast this
      in
        TNat $ #visit_idx vtable this env data
      end
    fun visit_TArray this env (w, t, i) = 
      let
        val vtable = cast this
        val t = #visit_ty vtable this env t
        val i = #visit_idx vtable this env i
      in
        TArray (w, t, i)
      end
    fun visit_TAbsT this env data =
      let
        val vtable = cast this
      in
        TAbsT $ #visit_tbind_anno vtable this (#visit_kind vtable this) (#visit_ty vtable this) env data
      end
    fun visit_TAppT this env data = 
      let
        val vtable = cast this
        val (t1, t2) = data
        val t1 = #visit_ty vtable this env t1
        val t2 = #visit_ty vtable this env t2
      in
        TAppT (t1, t2)
      end
    (* fun visit_TProdEx this env data =  *)
    (*   let *)
    (*     val vtable = cast this *)
    (*     val ((t1, b1), (t2, b2)) = data *)
    (*     val t1 = #visit_ty vtable this env t1 *)
    (*     val t2 = #visit_ty vtable this env t2 *)
    (*   in *)
    (*     TProdEx ((t1, b1), (t2, b2)) *)
    (*   end *)
    (* fun visit_TArrowTAL this env data =  *)
    (*   let *)
    (*     val vtable = cast this *)
    (*     val (ts, i) = data *)
    (*     val ts = Rctx.map (#visit_ty vtable this env) ts *)
    (*     val i = #visit_idx vtable this env i *)
    (*   in *)
    (*     TArrowTAL (ts, i) *)
    (*   end *)
    fun default_visit_bind_anno extend this = visit_bind_anno (extend this)
  in
    {visit_kind = visit_kind,
     visit_KType = visit_KType,
     visit_KArrow = visit_KArrow,
     visit_KArrowT = visit_KArrowT,
     visit_ty = visit_ty,
     visit_TVar = visit_TVar,
     visit_TConst = visit_TConst,
     visit_TBinOp = visit_TBinOp,
     visit_TArrow = visit_TArrow,
     visit_TAbsI = visit_TAbsI,
     visit_TAppI = visit_TAppI,
     visit_TQuan = visit_TQuan,
     visit_TQuanI = visit_TQuanI,
     visit_TRec = visit_TRec,
     visit_TNat = visit_TNat,
     visit_TArray = visit_TArray,
     visit_TAbsT = visit_TAbsT,
     visit_TAppT = visit_TAppT,
     (* visit_TProdEx = visit_TProdEx, *)
     (* visit_TArrowTAL = visit_TArrowTAL, *)
     visit_var = visit_var,
     visit_bsort = visit_bsort,
     visit_idx = visit_idx,
     visit_sort = visit_sort,
     visit_ty_const = visit_noop,
     visit_ty_bin_op = visit_noop,
     visit_quan = visit_noop,
     visit_ibind_anno_bsort = default_visit_bind_anno extend_i,
     visit_ibind_anno_sort = default_visit_bind_anno extend_i,
     visit_tbind_anno = default_visit_bind_anno extend_t,
     extend_i = extend_i,
     extend_t = extend_t
    }
  end

(* overrides *)
    
fun override_visit_TVar (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = new,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TAppT (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = new,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TAppI (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = new,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TBinOp (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = new,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

(* fun override_visit_TProdEx (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable = *)
(*   { *)
(*        visit_kind = #visit_kind record, *)
(*        visit_KType = #visit_KType record, *)
(*        visit_KArrow = #visit_KArrow record, *)
(*        visit_KArrowT = #visit_KArrowT record, *)
(*        visit_ty = #visit_ty record, *)
(*        visit_TVar = #visit_TVar record, *)
(*        visit_TConst = #visit_TConst record, *)
(*        visit_TBinOp = #visit_TBinOp record, *)
(*        visit_TArrow = #visit_TArrow record, *)
(*        visit_TAbsI = #visit_TAbsI record, *)
(*        visit_TAppI = #visit_TAppI record, *)
(*        visit_TQuan = #visit_TQuan record, *)
(*        visit_TQuanI = #visit_TQuanI record, *)
(*        visit_TRec = #visit_TRec record, *)
(*        visit_TNat = #visit_TNat record, *)
(*        visit_TArray = #visit_TArray record, *)
(*        visit_TAbsT = #visit_TAbsT record, *)
(*        visit_TAppT = #visit_TAppT record, *)
(*        visit_TProdEx = new, *)
(*        (* visit_TArrowTAL = #visit_TArrowTAL record, *) *)
(*        visit_var = #visit_var record, *)
(*        visit_bsort = #visit_bsort record, *)
(*        visit_idx = #visit_idx record, *)
(*        visit_sort = #visit_sort record, *)
(*        visit_ty_const = #visit_ty_const record, *)
(*        visit_ty_bin_op = #visit_ty_bin_op record, *)
(*        visit_quan = #visit_quan record, *)
(*        visit_ibind_anno_bsort = #visit_ibind_anno_bsort record, *)
(*        visit_ibind_anno_sort = #visit_ibind_anno_sort record, *)
(*        visit_tbind_anno = #visit_tbind_anno record, *)
(*        extend_i = #extend_i record, *)
(*        extend_t = #extend_t record *)
(*   } *)

fun override_visit_ty (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = new,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TAbsI (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = new,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TAbsT (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = new,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TArrow (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = new,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TQuanI (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = new,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TQuan (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = new,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = #visit_TArray record,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

fun override_visit_TArray (record : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable) new : ('this, 'env, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort2, 'idx2, 'sort2) ty_visitor_vtable =
  {
       visit_kind = #visit_kind record,
       visit_KType = #visit_KType record,
       visit_KArrow = #visit_KArrow record,
       visit_KArrowT = #visit_KArrowT record,
       visit_ty = #visit_ty record,
       visit_TVar = #visit_TVar record,
       visit_TConst = #visit_TConst record,
       visit_TBinOp = #visit_TBinOp record,
       visit_TArrow = #visit_TArrow record,
       visit_TAbsI = #visit_TAbsI record,
       visit_TAppI = #visit_TAppI record,
       visit_TQuan = #visit_TQuan record,
       visit_TQuanI = #visit_TQuanI record,
       visit_TRec = #visit_TRec record,
       visit_TNat = #visit_TNat record,
       visit_TArray = new,
       visit_TAbsT = #visit_TAbsT record,
       visit_TAppT = #visit_TAppT record,
       (* visit_TProdEx = #visit_TProdEx record, *)
       (* visit_TArrowTAL = #visit_TArrowTAL record, *)
       visit_var = #visit_var record,
       visit_bsort = #visit_bsort record,
       visit_idx = #visit_idx record,
       visit_sort = #visit_sort record,
       visit_ty_const = #visit_ty_const record,
       visit_ty_bin_op = #visit_ty_bin_op record,
       visit_quan = #visit_quan record,
       visit_ibind_anno_bsort = #visit_ibind_anno_bsort record,
       visit_ibind_anno_sort = #visit_ibind_anno_sort record,
       visit_tbind_anno = #visit_tbind_anno record,
       extend_i = #extend_i record,
       extend_t = #extend_t record
  }

(***************** the "shift_i_t" visitor  **********************)    
    
fun shift_i_ty_visitor_vtable cast ((shift_i, shift_s), n) : ('this, int, 'var, 'bsort, 'idx, 'sort, 'var, 'bsort, 'idx2, 'sort2) ty_visitor_vtable =
  let
    fun extend_i this env name = (env + 1, name)
    val extend_t = extend_noop
    val visit_var = visit_noop
    fun do_shift shift this env b = shift env n b
  in
    default_ty_visitor_vtable
      cast
      extend_i
      extend_t
      visit_var
      visit_noop
      (do_shift shift_i)
      (do_shift shift_s)
  end

fun new_shift_i_ty_visitor a = new_ty_visitor shift_i_ty_visitor_vtable a
    
fun shift_i_t_fn shifts x n b =
  let
    val visitor as (TyVisitor vtable) = new_shift_i_ty_visitor (shifts, n)
  in
    #visit_ty vtable visitor x b
  end
    
(***************** the "shift_t_t" visitor  **********************)    
    
fun shift_t_ty_visitor_vtable cast (shift_var, n) : ('this, int, 'var, 'bsort, 'idx, 'sort, 'var2, 'bsort, 'idx, 'sort) ty_visitor_vtable =
  let
    val extend_i = extend_noop
    fun extend_t this env name = (env + 1, name)
    fun visit_var this env data = shift_var env n data
  in
    default_ty_visitor_vtable
      cast
      extend_i
      extend_t
      visit_var
      visit_noop
      visit_noop
      visit_noop
  end

fun new_shift_t_ty_visitor a = new_ty_visitor shift_t_ty_visitor_vtable a
    
fun shift_t_t_fn shift_var x n b =
  let
    val visitor as (TyVisitor vtable) = new_shift_t_ty_visitor (shift_var, n)
  in
    #visit_ty vtable visitor x b
  end
    
(***************** the "subst_i_t" visitor  **********************)    

fun subst_i_ty_visitor_vtable cast ((subst_i_i, subst_i_s), d, x, v) : ('this, int, 'var, 'bsort, 'idx, 'sort, 'var, 'bsort, 'idx2, 'sort2) ty_visitor_vtable =
  let
    fun extend_i this env name = (env + 1, name)
    fun visit_idx this env b = subst_i_i (d + env) (x + env) v b
    fun visit_sort this env b = subst_i_s (d + env) (x + env) v b
  in
    default_ty_visitor_vtable
      cast
      extend_i
      extend_noop
      visit_noop
      visit_noop
      visit_idx
      visit_sort
  end

fun new_subst_i_ty_visitor params = new_ty_visitor subst_i_ty_visitor_vtable params
    
fun subst_i_t_fn substs d x v b =
  let
    val visitor as (TyVisitor vtable) = new_subst_i_ty_visitor (substs, d, x, v)
  in
    #visit_ty vtable visitor 0 b
  end

(***************** the "subst_t_t" visitor  **********************)    

fun subst_t_ty_visitor_vtable cast ((compare_var, shift_var, shift_i_i, shift_i_s), d, x, v) : ('this, idepth * tdepth, 'var, 'bsort, 'idx, 'sort, 'var, 'bsort, 'idx, 'sort) ty_visitor_vtable =
  let
    fun extend_i this (di, dt) name = ((idepth_inc di, dt), name)
    fun extend_t this (di, dt) name = ((di, tdepth_inc dt), name)
    fun add_depth (di, dt) (di', dt') = (idepth_add (di, di'), tdepth_add (dt, dt'))
    fun get_di (di, dt) = di
    fun get_dt (di, dt) = dt
    val shift_i_t = shift_i_t_fn (shift_i_i, shift_i_s)
    val shift_t_t = shift_t_t_fn shift_var
    fun visit_TVar this env (y, anno) =
      let
        val x = x + unTDepth (get_dt env)
      in
        case compare_var y x of
            CmpEq =>
            let
              val (di, dt) = add_depth d env
            in
              shift_i_t 0 (unIDepth di) $ shift_t_t 0 (unTDepth dt) v
            end
          | CmpGreater y' =>
            TVar (y', anno)
          | _ =>
            TVar (y, anno)
      end
    val vtable = 
        default_ty_visitor_vtable
          cast
          extend_i
          extend_t
          (visit_imposs "subst_t_t/visit_var")
          visit_noop
          visit_noop
          visit_noop
    val vtable = override_visit_TVar vtable visit_TVar
  in
    vtable
  end

fun new_subst_t_ty_visitor params = new_ty_visitor subst_t_ty_visitor_vtable params
    
fun subst_t_t_fn params d x v b =
  let
    val visitor as (TyVisitor vtable) = new_subst_t_ty_visitor (params, d, x, v)
  in
    #visit_ty vtable visitor (IDepth 0, TDepth 0) b
  end
                               
(***************** the "normalize_t" visitor  **********************)    
    
fun normalize_ty_visitor_vtable cast (subst0_i_t, subst0_t_t) : ('this, unit, 'var, 'bsort, 'idx, 'sort, 'var, 'bsort, 'idx, 'sort) ty_visitor_vtable =
  let
    fun visit_TAppT this env data = 
      let
        val vtable = cast this
        val (t1, t2) = data
        val t1 = #visit_ty vtable this env t1
        val t2 = #visit_ty vtable this env t2
      in
        case t1 of
            TAbsT bind =>
            let
              val (_, t1) = unBindAnno bind
            in
              #visit_ty vtable this env $ subst0_t_t t2 t1
            end
          | _ => TAppT (t1, t2)
      end
    fun visit_TAppI this env data = 
      let
        val vtable = cast this
        val (t, i) = data
        val t = #visit_ty vtable this env t
      in
        case t of
            TAbsI bind =>
            let
              val (_, t) = unBindAnno bind
            in
              #visit_ty vtable this env $ subst0_i_t i t
            end
          | _ => TAppI (t, i)
      end
    val vtable =
        default_ty_visitor_vtable
          cast
          extend_noop
          extend_noop
          visit_noop
          visit_noop
          visit_noop
          visit_noop
    val vtable = override_visit_TAppT vtable visit_TAppT
    val vtable = override_visit_TAppI vtable visit_TAppI
  in
    vtable
  end

fun new_normalize_ty_visitor a = new_ty_visitor normalize_ty_visitor_vtable a
    
fun normalize_t_fn params t =
  let
    val visitor as (TyVisitor vtable) = new_normalize_ty_visitor params
  in
    #visit_ty vtable visitor () t
  end
    
(********* the "export" visitor: convertnig de Bruijn indices to nameful terms *************)
fun export_ty_visitor_vtable cast (omitted, visit_var, visit_bs, visit_idx, visit_sort) =
  let
    fun extend_i this (depth, (sctx, kctx)) name = ((depth, (Name2str name :: sctx, kctx)), name)
    fun extend_t this (depth, (sctx, kctx)) name = ((depth, (sctx, Name2str name :: kctx)), name)
    fun only_s f this (depth, (sctx, kctx)) name = f sctx name
    fun ignore_this_depth f this (depth, ctx) = f ctx
    val vtable = 
        default_ty_visitor_vtable
          cast
          extend_i
          extend_t
          (ignore_this_depth visit_var)
          (ignore_this_env visit_bs)
          (only_s visit_idx)
          (only_s visit_sort)
    fun visit_ty this (depth, ctx) t = 
      let
        val (reached_depth_limit, depth) =
            case depth of
                NONE => (false, NONE)
              | SOME n => if n <= 0 then
                            (true, NONE)
                          else
                            (false, SOME (n-1))
      in
        if reached_depth_limit then omitted
        else
          (* call super *)
          #visit_ty vtable this (depth, ctx) t
      end
    val vtable = override_visit_ty vtable visit_ty
  in
    vtable
  end

fun new_export_ty_visitor params = new_ty_visitor export_ty_visitor_vtable params
    
fun export_t_fn params depth ctx b =
  let
    val visitor as (TyVisitor vtable) = new_export_ty_visitor params
  in
    #visit_ty vtable visitor (depth, ctx) b
  end

(********* the "uniquefy" visitor: makes variable names unique to remove shadowing *********)
fun uniquefy_ty_visitor_vtable cast (visit_idx, visit_sort) =
  let
    fun extend names name =
      let
        val (tag, (name, r)) = name
        val name = find_unique names name
        val names = name :: names
        val name = (tag, (name, r))
      in
        (names, name)
      end
    fun extend_i this (sctx, kctx) name =
      let val (sctx, name) = extend sctx name in ((sctx, kctx), name) end
    fun extend_t this (sctx, kctx) name =
      let val (kctx, name) = extend kctx name in ((sctx, kctx), name) end
    fun only_s f this (sctx, kctx) name = f sctx name
    fun ignore_this_depth f this ctx = f ctx
    val vtable = 
        default_ty_visitor_vtable
          cast
          extend_i
          extend_t
          visit_noop
          visit_noop
          (only_s visit_idx)
          (only_s visit_sort)
  in
    vtable
  end

fun new_uniquefy_ty_visitor params = new_ty_visitor uniquefy_ty_visitor_vtable params
    
fun uniquefy_t_fn params ctx b =
  let
    val visitor as (TyVisitor vtable) = new_uniquefy_ty_visitor params
  in
    #visit_ty vtable visitor ctx b
  end

(***************** expr visitor  **********************)    

(**overrides*)
type ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
     {
       visit_expr : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EVar : 'this -> 'env -> 'var -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EConst : 'this -> 'env -> Operators.expr_const -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       (* visit_ELoc : 'this -> 'env -> loc -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr, *)
       visit_EUnOp : 'this -> 'env -> 'ty expr_un_op * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EBinOp : 'this -> 'env -> expr_bin_op * ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ETriOp : 'this -> 'env -> expr_tri_op * ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ECase : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAbs : 'this -> 'env -> 'idx * ('ty, ('var, 'idx, 'sort, 'kind, 'ty) expr) ebind_anno * ('idx * 'idx) option -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ERec : 'this -> 'env -> ('ty, ('var, 'idx, 'sort, 'kind, 'ty) expr) ebind_anno -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAbsT : 'this -> 'env -> ('kind, ('var, 'idx, 'sort, 'kind, 'ty) expr) tbind_anno -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAppT : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * 'ty -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAbsI : 'this -> 'env -> ('sort, ('var, 'idx, 'sort, 'kind, 'ty) expr) ibind_anno -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAppI : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * 'idx -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EPack : 'this -> 'env -> 'ty * 'ty * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EUnpack : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind tbind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EPackI : 'this -> 'env -> 'ty * 'idx * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EPackIs : 'this -> 'env -> 'ty * 'idx list * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EUnpackI : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind ibind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAscTime : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * 'idx -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAscType : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * 'ty -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ENever : 'this -> 'env -> 'ty -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EBuiltin : 'this -> 'env -> string * 'ty -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ELet : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ELetIdx : 'this -> 'env -> 'idx * ('var, 'idx, 'sort, 'kind, 'ty) expr ibind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ELetType : 'this -> 'env -> 'ty * ('var, 'idx, 'sort, 'kind, 'ty) expr tbind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_ELetConstr : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr cbind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAbsConstr : 'this -> 'env -> (tbinder list * ibinder list * ebinder, ('var, 'idx, 'sort, 'kind, 'ty) expr) bind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EAppConstr : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * 'ty list * 'idx list * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EVarConstr : 'this -> 'env -> 'var -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_EMatchSum : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind list -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       (* visit_EMatchPair : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind ebind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr, *)
       visit_EMatchUnfold : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr ebind -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       (* visit_EMallocPair : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr, *)
       (* visit_EPairAssign : 'this -> 'env -> ('var, 'idx, 'sort, 'kind, 'ty) expr * projector * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr, *)
       (* visit_EProjProtected : 'this -> 'env -> projector * ('var, 'idx, 'sort, 'kind, 'ty) expr -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr, *)
       visit_EHalt : 'this -> 'env -> bool * ('var, 'idx, 'sort, 'kind, 'ty) expr * 'ty -> ('var2, 'idx2, 'sort2, 'kind2, 'ty2) expr,
       visit_var : 'this -> 'env -> 'var -> 'var2,
       visit_cvar : 'this -> 'env -> 'var -> 'var2,
       visit_idx : 'this -> 'env -> 'idx -> 'idx2,
       visit_sort : 'this -> 'env -> 'sort -> 'sort2,
       visit_kind : 'this -> 'env -> 'kind -> 'kind2,
       visit_ty : 'this -> 'env -> 'ty -> 'ty2,
       extend_i : 'this -> 'env -> iname -> 'env * iname,
       extend_t : 'this -> 'env -> tname -> 'env * tname,
       extend_c : 'this -> 'env -> cname -> 'env * cname,
       extend_e : 'this -> 'env -> ename -> 'env * ename
     }
       
type ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_interface =
     ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable
                                       
(***************** the default visitor  **********************)    

fun default_expr_visitor_vtable
      (cast : 'this -> ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_interface)
      extend_i
      extend_t
      extend_c
      extend_e
      visit_var
      visit_cvar
      visit_kind
      visit_idx
      visit_sort
      visit_ty
    : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  let
    fun visit_ibinder this = visit_binder (#extend_i (cast this) this)
    fun visit_tbinder this = visit_binder (#extend_t (cast this) this)
    fun visit_ebinder this = visit_binder (#extend_e (cast this) this)
    fun visit_ibind this = visit_bind_simp (#extend_i (cast this) this)
    fun visit_tbind this = visit_bind_simp (#extend_t (cast this) this)
    fun visit_cbind this = visit_bind_simp (#extend_c (cast this) this)
    fun visit_ebind this = visit_bind_simp (#extend_e (cast this) this)
    fun visit_ibind_anno this = visit_bind_anno (#extend_i (cast this) this)
    fun visit_tbind_anno this = visit_bind_anno (#extend_t (cast this) this)
    fun visit_cbind_anno this = visit_bind_anno (#extend_c (cast this) this)
    fun visit_ebind_anno this = visit_bind_anno (#extend_e (cast this) this)
    fun visit_expr this env data =
      let
        val vtable = cast this
      in
        case data of
            EVar data => #visit_EVar vtable this env data
          | EConst data => #visit_EConst vtable this env data
          (* | ELoc data => #visit_ELoc vtable this env data *)
          | EUnOp data => #visit_EUnOp vtable this env data
          | EBinOp data => #visit_EBinOp vtable this env data
          | ETriOp data => #visit_ETriOp vtable this env data
          | ECase data => #visit_ECase vtable this env data
          | EAbs data => #visit_EAbs vtable this env data
          | ERec data => #visit_ERec vtable this env data
          | EAbsT data => #visit_EAbsT vtable this env data
          | EAppT data => #visit_EAppT vtable this env data
          | EAbsI data => #visit_EAbsI vtable this env data
          | EAppI data => #visit_EAppI vtable this env data
          | EPack data => #visit_EPack vtable this env data
          | EUnpack data => #visit_EUnpack vtable this env data
          | EPackI data => #visit_EPackI vtable this env data
          | EPackIs data => #visit_EPackIs vtable this env data
          | EUnpackI data => #visit_EUnpackI vtable this env data
          | EAscTime data => #visit_EAscTime vtable this env data
          | EAscSpace (e, i) => EAscSpace (#visit_expr vtable this env e, #visit_idx vtable this env i)
          | EAscState (e, i) => EAscState (#visit_expr vtable this env e, #visit_idx vtable this env i)
          | EAscType data => #visit_EAscType vtable this env data
          | ENever data => #visit_ENever vtable this env data
          | EBuiltin data => #visit_EBuiltin vtable this env data
          | ELet data => #visit_ELet vtable this env data
          | ELetIdx data => #visit_ELetIdx vtable this env data
          | ELetType data => #visit_ELetType vtable this env data
          | ELetConstr data => #visit_ELetConstr vtable this env data
          | EAbsConstr data => #visit_EAbsConstr vtable this env data
          | EAppConstr data => #visit_EAppConstr vtable this env data
          | EVarConstr data => #visit_EVarConstr vtable this env data
          | EMatchSum data => #visit_EMatchSum vtable this env data
          (* | EMatchPair data => #visit_EMatchPair vtable this env data *)
          | EMatchTuple (e, bind) =>
            let
              val e = #visit_expr vtable this env e
              val bind = visit_bind (visit_list (visit_ebinder this)) (#visit_expr vtable this) env bind
            in
              EMatchTuple (e, bind)
            end
          | EMatchUnfold data => #visit_EMatchUnfold vtable this env data
          (* | EMallocPair data => #visit_EMallocPair vtable this env data *)
          (* | EPairAssign data => #visit_EPairAssign vtable this env data *)
          (* | EProjProtected data => #visit_EProjProtected vtable this env data *)
          | EHalt data => #visit_EHalt vtable this env data
          | ENewArrayValues (w, t, es) => ENewArrayValues (w, #visit_ty vtable this env t, visit_list (#visit_expr vtable this) env es)
          | ETuple es => ETuple (map (#visit_expr vtable this env) es)
          | EIfi (e, e1, e2) =>
            EIfi
              (#visit_expr vtable this env e,
               visit_ebind this (#visit_expr vtable this) env e1,
               visit_ebind this (#visit_expr vtable this) env e2)
          | EState x => EState x
          | EEnv name => EEnv name
          | ERecord fields => ERecord $ SMap.map (#visit_expr vtable this env) fields
          | EDispatch ls => EDispatch $ map (fn (name, e, t1, t2) => (name, #visit_expr vtable this env e, #visit_ty vtable this env t1, #visit_ty vtable this env t2)) ls
          (* | EDebugLog e => EDebugLog $ #visit_expr vtable this env e *)
      end
    fun visit_EVar this env data =
      let
        val vtable = cast this
      in
        EVar $ #visit_var vtable this env data
      end
    fun visit_EVarConstr this env data =
      let
        val vtable = cast this
      in
        EVarConstr $ #visit_cvar vtable this env data
      end
    fun visit_EConst this env data = EConst data
    (* fun visit_ELoc this env data = ELoc data *)
    fun visit_un_op this env opr = 
      let
        val vtable = cast this
        fun on_t x = #visit_ty vtable this env x
      in
        case opr of
            EUInj (opr, t) => EUInj (opr, on_t t)
          | EUFold t => EUFold $ on_t t
          | EUUnfold () => EUUnfold ()
          | EUTiML opr => EUTiML opr
          (* | EUTupleProj n => EUTupleProj n *)
      end
    fun visit_EUnOp this env data = 
      let
        val vtable = cast this
        val (opr, e) = data
        val opr = visit_un_op this env opr
        val e = #visit_expr vtable this env e
      in
        EUnOp (opr, e)
      end
    fun visit_EBinOp this env data = 
      let
        val vtable = cast this
        val (opr, e1, e2) = data
        val e1 = #visit_expr vtable this env e1
        val e2 = #visit_expr vtable this env e2
      in
        EBinOp (opr, e1, e2)
      end
    fun visit_ETriOp this env data = 
      let
        val vtable = cast this
        val (opr, e1, e2, e3) = data
        val e1 = #visit_expr vtable this env e1
        val e2 = #visit_expr vtable this env e2
        val e3 = #visit_expr vtable this env e3
      in
        ETriOp (opr, e1, e2, e3)
      end
    fun visit_ECase this env data =
      let
        val vtable = cast this
        val (e, e1, e2) = data
        val e = #visit_expr vtable this env e
        val e1 = visit_ebind this (#visit_expr vtable this) env e1
        val e2 = visit_ebind this (#visit_expr vtable this) env e2
      in
        ECase (e, e1, e2)
      end
    fun visit_EAbs this env (i, bind, spec) =
      let
        val vtable = cast this
        val i = #visit_idx vtable this env i
        val bind = visit_ebind_anno this (#visit_ty vtable this) (#visit_expr vtable this) env bind
        val spec = visit_option (visit_pair (#visit_idx vtable this) (#visit_idx vtable this)) env spec
      in
        EAbs (i, bind, spec)
      end
    fun visit_EAbsConstr this env data =
      let
        val vtable = cast this
        val data = visit_bind (visit_triple (visit_list $ visit_tbinder this) (visit_list $ visit_ibinder this) (visit_ebinder this)) (#visit_expr vtable this) env data
      in
        EAbsConstr data
      end
    fun visit_ERec this env data =
      let
        val vtable = cast this
        val data = visit_ebind_anno this (#visit_ty vtable this) (#visit_expr vtable this) env data
      in
        ERec data
      end
    fun visit_EAbsT this env data =
      let
        val vtable = cast this
        val data = visit_tbind_anno this (#visit_kind vtable this) (#visit_expr vtable this) env data
      in
        EAbsT data
      end
    fun visit_EAppT this env data = 
      let
        val vtable = cast this
        val (e, t) = data
        val e = #visit_expr vtable this env e
        val t = #visit_ty vtable this env t
      in
        EAppT (e, t)
      end
    fun visit_EAppConstr this env data = 
      let
        val vtable = cast this
        val (e1, ts, is, e2) = data
        val e1 = #visit_expr vtable this env e1
        val ts = visit_list (#visit_ty vtable this) env ts
        val is = visit_list (#visit_idx vtable this) env is
        val e2 = #visit_expr vtable this env e2
      in
        EAppConstr (e1, ts, is, e2)
      end
    fun visit_EAbsI this env data =
      let
        val vtable = cast this
        val data = visit_ibind_anno this (#visit_sort vtable this) (#visit_expr vtable this) env data
      in
        EAbsI data
      end
    fun visit_EAppI this env data = 
      let
        val vtable = cast this
        val (e, i) = data
        val e = #visit_expr vtable this env e
        val i = #visit_idx vtable this env i
      in
        EAppI (e, i)
      end
    fun visit_EPack this env data = 
      let
        val vtable = cast this
        val (t_all, t, e) = data
        val t_all = #visit_ty vtable this env t_all
        val t = #visit_ty vtable this env t
        val e = #visit_expr vtable this env e
      in
        EPack (t_all, t, e)
      end
    fun visit_EUnpack this env data =
      let
        val vtable = cast this
        val (e, bind) = data
        val e = #visit_expr vtable this env e
        val bind = (visit_tbind this o visit_ebind this) (#visit_expr vtable this) env bind
      in
        EUnpack (e, bind)
      end
    fun visit_EPackI this env data = 
      let
        val vtable = cast this
        val (t, i, e) = data
        val t = #visit_ty vtable this env t
        val i = #visit_idx vtable this env i
        val e = #visit_expr vtable this env e
      in
        EPackI (t, i, e)
      end
    fun visit_EPackIs this env data = 
      let
        val vtable = cast this
        val (t, is, e) = data
        val t = #visit_ty vtable this env t
        val is = map (#visit_idx vtable this env) is
        val e = #visit_expr vtable this env e
      in
        EPackIs (t, is, e)
      end
    fun visit_EUnpackI this env data =
      let
        val vtable = cast this
        val (e, bind) = data
        val e = #visit_expr vtable this env e
        val bind = (visit_ibind this o visit_ebind this) (#visit_expr vtable this) env bind
      in
        EUnpackI (e, bind)
      end
    fun visit_EAscTime this env data = 
      let
        val vtable = cast this
        val (e, i) = data
        val e = #visit_expr vtable this env e
        val i = #visit_idx vtable this env i
      in
        EAscTime (e, i)
      end
    fun visit_EAscType this env data = 
      let
        val vtable = cast this
        val (e, t) = data
        val e = #visit_expr vtable this env e
        val t = #visit_ty vtable this env t
      in
        EAscType (e, t)
      end
    fun visit_ENever this env data = 
      let
        val vtable = cast this
        val data = #visit_ty vtable this env data
      in
        ENever data
      end
    fun visit_EBuiltin this env (name, t) = 
      let
        val vtable = cast this
        val t = #visit_ty vtable this env t
      in
        EBuiltin (name, t)
      end
    fun visit_ELet this env data =
      let
        val vtable = cast this
        val (e, bind) = data
        val e = #visit_expr vtable this env e
        val bind = visit_ebind this (#visit_expr vtable this) env bind
      in
        ELet (e, bind)
      end
    fun visit_ELetIdx this env data =
      let
        val vtable = cast this
        val (i, bind) = data
        val i = #visit_idx vtable this env i
        val bind = visit_ibind this (#visit_expr vtable this) env bind
      in
        ELetIdx (i, bind)
      end
    fun visit_ELetType this env data =
      let
        val vtable = cast this
        val (t, bind) = data
        val t = #visit_ty vtable this env t
        val bind = visit_tbind this (#visit_expr vtable this) env bind
      in
        ELetType (t, bind)
      end
    fun visit_ELetConstr this env data =
      let
        val vtable = cast this
        val (e, bind) = data
        val e = #visit_expr vtable this env e
        val bind = visit_cbind this (#visit_expr vtable this) env bind
      in
        ELetConstr (e, bind)
      end
    fun visit_EMatchSum this env data =
      let
        val vtable = cast this
        val (e, branches) = data
        val e = #visit_expr vtable this env e
        val branches = (visit_list o visit_ebind this) (#visit_expr vtable this) env branches
      in
        EMatchSum (e, branches)
      end
    (* fun visit_EMatchPair this env data = *)
    (*   let *)
    (*     val vtable = cast this *)
    (*     val (e, branch) = data *)
    (*     val e = #visit_expr vtable this env e *)
    (*     val branch = (visit_ebind this o visit_ebind this) (#visit_expr vtable this) env branch *)
    (*   in *)
    (*     EMatchPair (e, branch) *)
    (*   end *)
    fun visit_EMatchUnfold this env data =
      let
        val vtable = cast this
        val (e, branch) = data
        val e = #visit_expr vtable this env e
        val branch = visit_ebind this (#visit_expr vtable this) env branch
      in
        EMatchUnfold (e, branch)
      end
    (* fun visit_EMallocPair this env (a, b) = *)
    (*   let *)
    (*     val vtable = cast this *)
    (*     val a = #visit_expr vtable this env a *)
    (*     val b = #visit_expr vtable this env b *)
    (*   in *)
    (*     EMallocPair (a, b) *)
    (*   end *)
    (* fun visit_EPairAssign this env (e1, proj, e2) = *)
    (*   let *)
    (*     val vtable = cast this *)
    (*     val e1 = #visit_expr vtable this env e1 *)
    (*     val e2 = #visit_expr vtable this env e2 *)
    (*   in *)
    (*     EPairAssign (e1, proj, e2) *)
    (*   end *)
    (* fun visit_EProjProtected this env (proj, e) = *)
    (*   let *)
    (*     val vtable = cast this *)
    (*     val e = #visit_expr vtable this env e *)
    (*   in *)
    (*     EProjProtected (proj, e) *)
    (*   end *)
    fun visit_EHalt this env (b, e, t) =
      let
        val vtable = cast this
        val e = #visit_expr vtable this env e
        val t = #visit_ty vtable this env t
      in
        EHalt (b, e, t)
      end
  in
    {
      visit_expr = visit_expr,
      visit_EVar = visit_EVar,
      visit_EConst = visit_EConst,
      (* visit_ELoc = visit_ELoc, *)
      visit_EUnOp = visit_EUnOp,
      visit_EBinOp = visit_EBinOp,
      visit_ETriOp = visit_ETriOp,
      visit_ECase = visit_ECase,
      visit_EAbs = visit_EAbs,
      visit_ERec = visit_ERec,
      visit_EAbsT = visit_EAbsT,
      visit_EAppT = visit_EAppT,
      visit_EAbsI = visit_EAbsI,
      visit_EAppI = visit_EAppI,
      visit_EPack = visit_EPack,
      visit_EUnpack = visit_EUnpack,
      visit_EPackI = visit_EPackI,
      visit_EPackIs = visit_EPackIs,
      visit_EUnpackI = visit_EUnpackI,
      visit_EAscTime = visit_EAscTime,
      visit_EAscType = visit_EAscType,
      visit_ENever = visit_ENever,
      visit_EBuiltin = visit_EBuiltin,
      visit_ELet = visit_ELet,
      visit_ELetIdx = visit_ELetIdx,
      visit_ELetType = visit_ELetType,
      visit_ELetConstr = visit_ELetConstr,
      visit_EAbsConstr = visit_EAbsConstr,
      visit_EAppConstr = visit_EAppConstr,
      visit_EVarConstr = visit_EVarConstr,
      visit_EMatchSum = visit_EMatchSum,
      (* visit_EMatchPair = visit_EMatchPair, *)
      visit_EMatchUnfold = visit_EMatchUnfold,
      (* visit_EMallocPair = visit_EMallocPair, *)
      (* visit_EPairAssign = visit_EPairAssign, *)
      (* visit_EProjProtected = visit_EProjProtected, *)
      visit_EHalt = visit_EHalt,
      visit_var = visit_var,
      visit_cvar = visit_cvar,
      visit_idx = visit_idx,
      visit_sort = visit_sort,
      visit_kind = visit_kind,
      visit_ty = visit_ty,
      extend_i = extend_i,
      extend_t = extend_t,
      extend_c = extend_c,
      extend_e = extend_e
    }
  end

datatype ('env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor =
         ExprVisitor of (('env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_interface

fun expr_visitor_impls_interface (this : ('env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor) :
    (('env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_interface =
  let
    val ExprVisitor vtable = this
  in
    vtable
  end

fun new_expr_visitor vtable params =
  let
    val vtable = vtable expr_visitor_impls_interface params
  in
    ExprVisitor vtable
  end
    
(***************** boring overrides **********************)    

fun override_visit_EVar (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = new,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_ELet (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = new,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EMatchUnfold (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = new,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_expr (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = new,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EMatchTuple (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  let
    fun visit_expr this env p =
      case p of
          EMatchTuple data => new this env data
        | _ => #visit_expr record this env p
  in
    override_visit_expr record visit_expr
  end

(* fun override_visit_EMatchPair (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable = *)
(*   { *)
(*     visit_expr = #visit_expr record, *)
(*     visit_EVar = #visit_EVar record, *)
(*     visit_EConst = #visit_EConst record, *)
(*     (* visit_ELoc = #visit_ELoc record, *) *)
(*     visit_EUnOp = #visit_EUnOp record, *)
(*     visit_EBinOp = #visit_EBinOp record, *)
(*     visit_ETriOp = #visit_ETriOp record, *)
(*     visit_ECase = #visit_ECase record, *)
(*     visit_EAbs = #visit_EAbs record, *)
(*     visit_ERec = #visit_ERec record, *)
(*     visit_EAbsT = #visit_EAbsT record, *)
(*     visit_EAppT = #visit_EAppT record, *)
(*     visit_EAbsI = #visit_EAbsI record, *)
(*     visit_EAppI = #visit_EAppI record, *)
(*     visit_EPack = #visit_EPack record, *)
(*     visit_EUnpack = #visit_EUnpack record, *)
(*     visit_EPackI = #visit_EPackI record, *)
(*     visit_EPackIs = #visit_EPackIs record, *)
(*     visit_EUnpackI = #visit_EUnpackI record, *)
(*     visit_EAscTime = #visit_EAscTime record, *)
(*     visit_EAscType = #visit_EAscType record, *)
(*     visit_ENever = #visit_ENever record, *)
(*     visit_EBuiltin = #visit_EBuiltin record, *)
(*     visit_ELet = #visit_ELet record, *)
(*     visit_ELetConstr = #visit_ELetConstr record, *)
(*     visit_EAbsConstr = #visit_EAbsConstr record, *)
(*     visit_EAppConstr = #visit_EAppConstr record, *)
(*     visit_EVarConstr = #visit_EVarConstr record, *)
(*     visit_ELetType = #visit_ELetType record, *)
(*     visit_ELetIdx = #visit_ELetIdx record, *)
(*     visit_EMatchSum = #visit_EMatchSum record, *)
(*     visit_EMatchPair = new, *)
(*     visit_EMatchUnfold = #visit_EMatchUnfold record, *)
(*     (* visit_EMallocPair = #visit_EMallocPair record, *) *)
(*     (* visit_EPairAssign = #visit_EPairAssign record, *) *)
(*     (* visit_EProjProtected = #visit_EProjProtected record, *) *)
(*     visit_EHalt = #visit_EHalt record, *)
(*     visit_var = #visit_var record, *)
(*     visit_cvar = #visit_cvar record, *)
(*     visit_idx = #visit_idx record, *)
(*     visit_sort = #visit_sort record, *)
(*     visit_kind = #visit_kind record, *)
(*     visit_ty = #visit_ty record, *)
(*     extend_i = #extend_i record, *)
(*     extend_t = #extend_t record, *)
(*     extend_c = #extend_c record, *)
(*     extend_e = #extend_e record *)
(*   } *)

fun override_visit_EMatchSum (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = new,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EVarConstr (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = new,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EAppConstr (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = new,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EAscType (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = new,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_ERec (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = new,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EAbs (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = new,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }
    
fun override_visit_EUnOp (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = new,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EBinOp (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = new,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EUnpack (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = new,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EUnpackI (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = new,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_ECase (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = new,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EAscTime (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = new,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EAppI (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    (* visit_ELoc = #visit_ELoc record, *)
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = #visit_ETriOp record,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = new,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_ETriOp (record : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable) new : ('this, 'env, 'var, 'idx, 'sort, 'kind, 'ty, 'var2, 'idx2, 'sort2, 'kind2, 'ty2) expr_visitor_vtable =
  {
    visit_expr = #visit_expr record,
    visit_EVar = #visit_EVar record,
    visit_EConst = #visit_EConst record,
    visit_EUnOp = #visit_EUnOp record,
    visit_EBinOp = #visit_EBinOp record,
    visit_ETriOp = new,
    visit_ECase = #visit_ECase record,
    visit_EAbs = #visit_EAbs record,
    visit_ERec = #visit_ERec record,
    visit_EAbsT = #visit_EAbsT record,
    visit_EAppT = #visit_EAppT record,
    visit_EAbsI = #visit_EAbsI record,
    visit_EAppI = #visit_EAppI record,
    visit_EPack = #visit_EPack record,
    visit_EUnpack = #visit_EUnpack record,
    visit_EPackI = #visit_EPackI record,
    visit_EPackIs = #visit_EPackIs record,
    visit_EUnpackI = #visit_EUnpackI record,
    visit_EAscTime = #visit_EAscTime record,
    visit_EAscType = #visit_EAscType record,
    visit_ENever = #visit_ENever record,
    visit_EBuiltin = #visit_EBuiltin record,
    visit_ELet = #visit_ELet record,
    visit_ELetConstr = #visit_ELetConstr record,
    visit_EAbsConstr = #visit_EAbsConstr record,
    visit_EAppConstr = #visit_EAppConstr record,
    visit_EVarConstr = #visit_EVarConstr record,
    visit_ELetType = #visit_ELetType record,
    visit_ELetIdx = #visit_ELetIdx record,
    visit_EMatchSum = #visit_EMatchSum record,
    (* visit_EMatchPair = #visit_EMatchPair record, *)
    visit_EMatchUnfold = #visit_EMatchUnfold record,
    (* visit_EMallocPair = #visit_EMallocPair record, *)
    (* visit_EPairAssign = #visit_EPairAssign record, *)
    (* visit_EProjProtected = #visit_EProjProtected record, *)
    visit_EHalt = #visit_EHalt record,
    visit_var = #visit_var record,
    visit_cvar = #visit_cvar record,
    visit_idx = #visit_idx record,
    visit_sort = #visit_sort record,
    visit_kind = #visit_kind record,
    visit_ty = #visit_ty record,
    extend_i = #extend_i record,
    extend_t = #extend_t record,
    extend_c = #extend_c record,
    extend_e = #extend_e record
  }

fun override_visit_EIfi vtable new =
  let
    fun visit_expr this env data =
      case data of
          EIfi data => new this env data
        | _ => #visit_expr vtable this env data (* call super *)
  in
    override_visit_expr vtable visit_expr
  end
    
(***************** the "shift_i_e" visitor  **********************)    
    
fun shift_i_expr_visitor_vtable cast ((shift_i, shift_s, shift_t), n) : ('this, int, 'var, 'idx, 'sort, 'kind, 'ty, 'var, 'idx2, 'sort2, 'kind, 'ty2) expr_visitor_vtable =
  let
    fun extend_i this env name = (env + 1, name)
    fun do_shift shift this env b = shift env n b
  in
    default_expr_visitor_vtable
      cast
      extend_i
      extend_noop
      extend_noop
      extend_noop
      visit_noop
      visit_noop
      visit_noop
      (do_shift shift_i)
      (do_shift shift_s)
      (do_shift shift_t)
  end

fun new_shift_i_expr_visitor params = new_expr_visitor shift_i_expr_visitor_vtable params
    
fun shift_i_e_fn shifts x n b =
  let
    val visitor as (ExprVisitor vtable) = new_shift_i_expr_visitor (shifts, n)
  in
    #visit_expr vtable visitor x b
  end
    
(***************** the "shift_t_e" visitor  **********************)    
    
fun shift_t_expr_visitor_vtable cast (shift_t, n) : ('this, int, 'var, 'idx, 'sort, 'kind, 'ty, 'var, 'idx, 'sort, 'kind, 'ty2) expr_visitor_vtable =
  let
    fun extend_t this env name = (env + 1, name)
    fun do_shift shift this env b = shift env n b
  in
    default_expr_visitor_vtable
      cast
      extend_noop
      extend_t
      extend_noop
      extend_noop
      visit_noop
      visit_noop
      visit_noop
      visit_noop
      visit_noop
      (do_shift shift_t)
  end

fun new_shift_t_expr_visitor params = new_expr_visitor shift_t_expr_visitor_vtable params
    
fun shift_t_e_fn shift_t x n b =
  let
    val visitor as (ExprVisitor vtable) = new_shift_t_expr_visitor (shift_t, n)
  in
    #visit_expr vtable visitor x b
  end
    
(***************** the "shift_c_e" visitor  **********************)    
    
fun shift_c_expr_visitor_vtable cast (shift_var, n) : ('this, int, 'var, 'idx, 'sort, 'kind, 'ty, 'var, 'idx, 'sort, 'kind, 'ty) expr_visitor_vtable =
  let
    fun extend_c this env name = (env + 1, name)
    fun visit_cvar this env data = shift_var env n data
  in
    default_expr_visitor_vtable
      cast
      extend_noop
      extend_noop
      extend_c
      extend_noop
      visit_noop
      visit_cvar
      visit_noop
      visit_noop
      visit_noop
      visit_noop
  end

fun new_shift_c_expr_visitor params = new_expr_visitor shift_c_expr_visitor_vtable params
    
fun shift_c_e_fn shift_var x n b =
  let
    val visitor as (ExprVisitor vtable) = new_shift_c_expr_visitor (shift_var, n)
  in
    #visit_expr vtable visitor x b
  end
    
(***************** the "shift_e_e" visitor  **********************)    
    
fun shift_e_expr_visitor_vtable cast (shift_var, n) : ('this, int, 'var, 'idx, 'sort, 'kind, 'ty, 'var, 'idx, 'sort, 'kind, 'ty) expr_visitor_vtable =
  let
    fun extend_e this env name = (env + 1, name)
    fun visit_var this env data = shift_var env n data
  in
    default_expr_visitor_vtable
      cast
      extend_noop
      extend_noop
      extend_noop
      extend_e
      visit_var
      visit_noop
      visit_noop
      visit_noop
      visit_noop
      visit_noop
  end

fun new_shift_e_expr_visitor params = new_expr_visitor shift_e_expr_visitor_vtable params
    
fun shift_e_e_fn shift_var x n b =
  let
    val visitor as (ExprVisitor vtable) = new_shift_e_expr_visitor (shift_var, n)
  in
    #visit_expr vtable visitor x b
  end
    
(***************** the "subst_i_e" visitor  **********************)    

(* todo: combine shift_i_expr_visitor_vtable and subst_i_expr_visitor_vtable *)    
fun subst_i_expr_visitor_vtable cast (visit_idx, visit_sort, visit_ty) =
  let
    fun extend_i this env name = (env + 1, name)
  in
    default_expr_visitor_vtable
      cast
      extend_i
      extend_noop
      extend_noop
      extend_noop
      visit_noop
      visit_noop
      visit_noop
      (ignore_this visit_idx)
      (ignore_this visit_sort)
      (ignore_this visit_ty)
  end

fun new_subst_i_expr_visitor params = new_expr_visitor subst_i_expr_visitor_vtable params
    
fun subst_i_e_fn params b =
  let
    val visitor as (ExprVisitor vtable) = new_subst_i_expr_visitor params
  in
    #visit_expr vtable visitor 0 b
  end

(***************** the "subst_t_e" visitor  **********************)    

fun subst_t_expr_visitor_vtable cast visit_ty =
  let
    fun extend_i this env name = (mapFst idepth_inc env, name)
    fun extend_t this env name = (mapSnd tdepth_inc env, name)
  in
    default_expr_visitor_vtable
      cast
      extend_i
      extend_t
      extend_noop
      extend_noop
      visit_noop
      visit_noop
      visit_noop
      visit_noop
      visit_noop
      (ignore_this visit_ty)
  end

fun new_subst_t_expr_visitor params = new_expr_visitor subst_t_expr_visitor_vtable params
    
fun subst_t_e_fn params b =
  let
    val visitor as (ExprVisitor vtable) = new_subst_t_expr_visitor params
  in
    #visit_expr vtable visitor (IDepth 0, TDepth 0) b
  end

(***************** the "subst_c_e" visitor  **********************)    

fun subst_c_expr_visitor_vtable cast ((compare_var, shift_var, shift_i_i, shift_i_s, shift_i_t, shift_t_t), d, x, v) : ('this, idepth * tdepth * cdepth * edepth, 'var, 'idx, 'sort, 'kind, 'ty, 'var, 'idx, 'sort, 'kind, 'ty) expr_visitor_vtable =
  let
    fun extend_i this (di, dt, dc, de) name = ((idepth_inc di, dt, dc, de), name)
    fun extend_t this (di, dt, dc, de) name = ((di, tdepth_inc dt, dc, de), name)
    fun extend_c this (di, dt, dc, de) name = ((di, dt, cdepth_inc dc, de), name)
    fun extend_e this (di, dt, dc, de) name = ((di, dt, dc, edepth_inc de), name)
    fun add_depth (di, dt, dc, de) (di', dt', dc', de') = (idepth_add (di, di'), tdepth_add (dt, dt'), cdepth_add (dc, dc'), edepth_add (de, de'))
    fun get_di (di, dt, dc, de) = di
    fun get_dt (di, dt, dc, de) = dt
    fun get_dc (di, dt, dc, de) = dc
    fun get_de (di, dt, dc, de) = de
    val shift_i_e = shift_i_e_fn (shift_i_i, shift_i_s, shift_i_t)
    val shift_t_e = shift_t_e_fn shift_t_t
    val shift_c_e = shift_c_e_fn shift_var
    val shift_e_e = shift_e_e_fn shift_var
    fun visit_EVarConstr this env y =
      let
        val x = x + unCDepth (get_dc env)
      in
        case compare_var y x of
            CmpEq =>
            let
              val (di, dt, dc, de) = add_depth d env
            in
              shift_i_e 0 (unIDepth di) $ shift_t_e 0 (unTDepth dt) $ shift_c_e 0 (unCDepth dc) $ shift_e_e 0 (unEDepth de) v
            end
          | CmpGreater y' =>
            EVarConstr y'
          | _ =>
            EVarConstr y
      end
    val vtable = 
        default_expr_visitor_vtable
          cast
          extend_i
          extend_t
          extend_c
          extend_e
          visit_noop
          (visit_imposs "subst_c_e/visit_cvar")
          visit_noop
          visit_noop
          visit_noop
          visit_noop
    val vtable = override_visit_EVarConstr vtable visit_EVarConstr
  in
    vtable
  end

fun new_subst_c_expr_visitor params = new_expr_visitor subst_c_expr_visitor_vtable params
    
fun subst_c_e_fn params d x v b =
  let
    val visitor as (ExprVisitor vtable) = new_subst_c_expr_visitor (params, d, x, v)
  in
    #visit_expr vtable visitor (IDepth 0, TDepth 0, CDepth 0, EDepth 0) b
  end

(***************** the "subst_e_e" visitor  **********************)    

fun subst_e_expr_visitor_vtable cast ((compare_var, shift_var, shift_i_i, shift_i_s, shift_i_t, shift_t_t), d, x, v) : ('this, idepth * tdepth * cdepth * edepth, 'var, 'idx, 'sort, 'kind, 'ty, 'var, 'idx, 'sort, 'kind, 'ty) expr_visitor_vtable =
  let
    fun extend_i this (di, dt, dc, de) name = ((idepth_inc di, dt, dc, de), name)
    fun extend_t this (di, dt, dc, de) name = ((di, tdepth_inc dt, dc, de), name)
    fun extend_c this (di, dt, dc, de) name = ((di, dt, cdepth_inc dc, de), name)
    fun extend_e this (di, dt, dc, de) name = ((di, dt, dc, edepth_inc de), name)
    fun add_depth (di, dt, dc, de) (di', dt', dc', de') = (idepth_add (di, di'), tdepth_add (dt, dt'), cdepth_add (dc, dc'), edepth_add (de, de'))
    fun get_di (di, dt, dc, de) = di
    fun get_dt (di, dt, dc, de) = dt
    fun get_dc (di, dt, dc, de) = dc
    fun get_de (di, dt, dc, de) = de
    val shift_i_e = shift_i_e_fn (shift_i_i, shift_i_s, shift_i_t)
    val shift_t_e = shift_t_e_fn shift_t_t
    val shift_c_e = shift_c_e_fn shift_var
    val shift_e_e = shift_e_e_fn shift_var
    fun visit_EVar this env y =
      let
        val x = x + unEDepth (get_de env)
      in
        case compare_var y x of
            CmpEq =>
            let
              val (di, dt, dc, de) = add_depth d env
            in
              shift_i_e 0 (unIDepth di) $ shift_t_e 0 (unTDepth dt) $ shift_c_e 0 (unCDepth dc) $ shift_e_e 0 (unEDepth de) v
            end
          | CmpGreater y' =>
            EVar y'
          | _ =>
            EVar y
      end
    val vtable = 
        default_expr_visitor_vtable
          cast
          extend_i
          extend_t
          extend_c
          extend_e
          (visit_imposs "subst_e_e/visit_var")
          visit_noop
          visit_noop
          visit_noop
          visit_noop
          visit_noop
    val vtable = override_visit_EVar vtable visit_EVar
  in
    vtable
  end

fun new_subst_e_expr_visitor params = new_expr_visitor subst_e_expr_visitor_vtable params
    
fun subst_e_e_fn params d x v b =
  let
    val visitor as (ExprVisitor vtable) = new_subst_e_expr_visitor (params, d, x, v)
  in
    #visit_expr vtable visitor (IDepth 0, TDepth 0, CDepth 0, EDepth 0) b
  end

(*********** the "export" visitor: converting de Bruijn indices to nameful terms ***************)
fun export_expr_visitor_vtable cast (omitted, visit_var, visit_cvar, visit_kind, visit_idx, visit_sort, visit_ty) =
  let
    fun extend_i this (depth, (sctx, kctx, cctx, tctx)) name = ((depth, (Name2str name :: sctx, kctx, cctx, tctx)), name)
    fun extend_t this (depth, (sctx, kctx, cctx, tctx)) name = ((depth, (sctx, Name2str name :: kctx, cctx, tctx)), name)
    fun extend_c this (depth, (sctx, kctx, cctx, tctx)) name = ((depth, (sctx, kctx, Name2str name :: cctx, tctx)), name)
    fun extend_e this (depth, (sctx, kctx, cctx, tctx)) name = ((depth, (sctx, kctx, cctx, Name2str name :: tctx)), name)
    fun ignore_this_depth f this (depth, ctx) = f ctx
    fun only_s f this (_, (sctx, kctx, cctx, tctx)) name = f sctx name
    fun only_sk f this (_, (sctx, kctx, cctx, tctx)) name = f (sctx, kctx) name
    val vtable = 
        default_expr_visitor_vtable
          cast
          extend_i
          extend_t
          extend_c
          extend_e
          (ignore_this_depth visit_var)
          (ignore_this_depth visit_cvar)
          (ignore_this_env visit_kind)
          (only_s visit_idx)
          (only_s visit_sort)
          (only_sk visit_ty)
    fun visit_expr this (depth, ctx) t = 
      let
        val (reached_depth_limit, depth) =
            case depth of
                NONE => (false, NONE)
              | SOME n => if n <= 0 then
                            (true, NONE)
                          else
                            (false, SOME (n-1))
      in
        if reached_depth_limit then omitted
        else
          (* call super *)
          #visit_expr vtable this (depth, ctx) t
      end
    val vtable = override_visit_expr vtable visit_expr
  in
    vtable
  end

fun new_export_expr_visitor params = new_expr_visitor export_expr_visitor_vtable params
    
fun export_e_fn params depth ctx e =
  let
    val visitor as (ExprVisitor vtable) = new_export_expr_visitor params
  in
    #visit_expr vtable visitor (depth, ctx) e
  end

(********* the "uniquefy" visitor: makes variable names unique to remove shadowing *********)
fun uniquefy_expr_visitor_vtable cast (visit_idx, visit_sort, visit_ty) =
  let
    fun extend names name =
      let
        val (tag, (name, r)) = name
        val name = find_unique names name
        val names = name :: names
        val name = (tag, (name, r))
      in
        (names, name)
      end
    fun extend_i this (sctx, kctx, cctx, tctx) name =
      let val (sctx, name) = extend sctx name in ((sctx, kctx, cctx, tctx), name) end
    fun extend_t this (sctx, kctx, cctx, tctx) name =
      let val (kctx, name) = extend kctx name in ((sctx, kctx, cctx, tctx), name) end
    fun extend_c this (sctx, kctx, cctx, tctx) name =
      let val (cctx, name) = extend cctx name in ((sctx, kctx, cctx, tctx), name) end
    fun extend_e this (sctx, kctx, cctx, tctx) name =
      let val (tctx, name) = extend tctx name in ((sctx, kctx, cctx, tctx), name) end
    fun only_s f this (sctx, kctx, cctx, tctx) name = f sctx name
    fun only_sk f this (sctx, kctx, cctx, tctx) name = f (sctx, kctx) name
    val vtable =
        default_expr_visitor_vtable
          cast
          extend_i
          extend_t
          extend_c
          extend_e
          visit_noop
          visit_noop
          visit_noop
          (only_s visit_idx)
          (only_s visit_sort)
          (only_sk visit_ty)
  in
    vtable
  end

fun new_uniquefy_expr_visitor params = new_expr_visitor uniquefy_expr_visitor_vtable params
    
fun uniquefy_e_fn params ctx e =
  let
    val visitor as (ExprVisitor vtable) = new_uniquefy_expr_visitor params
  in
    #visit_expr vtable visitor ctx e
  end
    
end
