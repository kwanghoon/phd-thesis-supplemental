signature TYPE = sig

  type bsort
  type idx
  type sort
  type base_type
  type var
  (* type kind *)
  type kind = int (*number of type arguments*) * bsort list
  type name
  type region
  include UVAR_T
         
  type 'mtype constr_core = (sort, name, 'mtype * idx list) Bind.ibinds
  type 'mtype constr_decl = name * 'mtype constr_core * region
  (* to be used in typing context *)                                                          
  type 'mtype constr_info = var(*family*) * (unit, name, 'mtype constr_core) Bind.tbinds

  type 'mtype datatype_def = (name(*for datatype self-reference*) * (unit, name, bsort list * 'mtype constr_decl list) Bind.tbinds) Bind.tbind

  (* monotypes *)
  datatype mtype = 
	   Arrow of mtype * idx * mtype
           | TyNat of idx * region
           | TyArray of mtype * idx
	   | BaseType of base_type * region
           | Unit of region
	   | Prod of mtype * mtype
	   | UniI of sort * (name * mtype) Bind.ibind * region
           | MtVar of var
           | MtAbs of kind * (name * mtype) Bind.tbind * region
           | MtApp of mtype * mtype
           | MtAbsI of bsort * (name * mtype) Bind.ibind  * region
           | MtAppI of mtype * idx
           | UVar of (bsort, kind, mtype) uvar_mt * region
           | TDatatype of mtype datatype_def * region
           | TSumbool of sort * sort

  datatype ty = 
	   Mono of mtype
	   | Uni of (name * ty) Bind.tbind * region

end
