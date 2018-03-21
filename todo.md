- [x] Remove bsort from Eq 
- [x] `msg` in `str_error` should be of (string list)
- [x] split `case` syntax into `case`, `sumcase` and `unpack`
- [x] `case` and `unpack` should allow omitting return-clause and try to forget unescapable variables (like what `let` does)
- [x] Distill the `bind` pattern
- [x] Disallow impredicative universal types
- [x] Type inference
- [x] Idx inference
- [x] \(Kind-of) Allow `datatype` to have idx arguments that do not change.
- [x] Multi-argument idx functions.
- [x] Add an optional idx to `Quan`, to link the remaining unification variables in types and the witnesses found by the Master Theorem solver.
- [x] Infer by Master Theorem then check.
- [x] Single variable Master Theorem case.
- [x] Error line number on multiple files.
- [x] Make linking between inferred existential variable values and types better.
- [x] Copy function signature annotation to case annotation
- [ ] \(Abondoned. No problem.) Unit and product types are required to define datatypes. 17. Remove unit and product types from the language, and have standard library.
- [x] Example: Tree flatten.
- [x] Example: Insertion sort.
- [x] Have reference and arrays.
- [x] RB-tree insertion.
- [x] RB-tree lookup.
- [x] Braun tree insertion.
- [ ] A bug of position reporting when I change bigO spec of msort in msort.timl from `$m * $n * log2 $n` to `$n * log2 $n`.
- [x] `return _ using` works but `return using` does not in msort.timl and tree.timl.
- [x] Change syntax order of function name and `t` declares.
- [x] Be able to infer for `tree_map` and `tree_foldl`.
- [x] \(Partially) Have module system.
    Road map to add module system:
    * [x] Have a barebone module system with only modules, signatures, sealing, functors and `open`. No hierarchy (embeded modules), module alias, signature alias, `where`/`sharing`, `include`.
    * [ ] Combine name-resolve and typecheck.
    * [ ] Combine cctx and tctx into tctx.
    * [ ] (\Abondoned.) Combine idx and type into constructors, sort and kind into kind, Combine sctx and kctx into kctx.
    * [ ] Add record types.
    * [ ] Add singleton kinds, dependent record kinds, dependent arrow kinds.
    * [ ] Elaborate modules and signatures into core language.
- [x] Bug of type inference in tree_append_rlm. The inferred type has `{n} tree tree` and `{n} list list`.
- [x] Put `Unit` back to mtype from `base_type` because `Unit` is not a base type like `Int` but a structural building block.
- [ ] Have a good error message when insertion_sort.timl/`insert` does not have the needed return-annotation on `case`.
- [x] Be able to infer for `insertion_sort`.
- [ ] \(Solved by new unification framework) `unify`'s `(UVar, UVar)` case could be dangerous: shift_invis may not be transactional, and there is no circularity check.
- [x] Have a standard library.
- [x] Automatically generate premises in `(VarP, Never)` case of `match_ptrn`, from complement cover of previous rules.
- [x] `case` should also copy `fun`'s `return` clause even without `using`.
- [ ] \(Abondoned. No problem.) `as` pattern may have a problem in `balance_left`.
- [x] Bug: redundancy checker runs forever on `balance_left`.
- [x] rbt.timl typecheckes when using ForgetError-less `subst` and ForgetError-full `forget`. Investigate why.
- [x] `find_habitant` can further simplify covers and speed up.
- [x] Have `type =` type aliasing.
- [x] Maximally insertion of index arguments.
- [x] Maximally insertion of index arguments in patterns.
- [x] nouvar-expr/passp/Imply/_ is not sound, possibly losing information.
- [ ] \(Solved by new unification framework) `subst_invis_no_throw` should be implemented in a safe way where uvars that can see the target variable are unified with a new shifted uvars that cannot see it, and `bring_forward_anchor` needs to be more sophisticated to only put new anchor when there is no shift (and the notifier in `Exists` needs to do some shift) because now not every uvar has an anchor.
- [x] Braun tree extraction.
- [x] rename "peel_" to "collect_".
- [x] Register admitted things.
- [ ] Make SMT batch response parsing smarter (do not check response length beforehand)
- [x] Simplify MaxI using SMT solver.
- [x] Have binary search with arrays.
- [x] Have binary heap with arrays.
- [x] Have in-place merge sort with arrays.
- [x] Have k-median search with arrays.
- [x] Investigate amortized complexity analysis.
- [x] Prove in Coq.
- [x] Infer `BigO` arity.
- [x] Have built-in indexed `uint`.
- [ ] Pretty-print to SML.
- [ ] Combine cctx and tctx.
- [x] Add <> notation.
- [ ] Add a return clause in `Case` to mean the time including the matchee.
- [x] Amortized complexity of queue implementation by two stacks.
- [x] Infer type according to pattern.
- [ ] \(No longer exists.) Wrongly inferred `T_insert_delete_seq_0` to be (fn n => $n) without the `2.0 + 48.0 * $n` annotation. The source of the problem: unsoundness in bigO-solver.sml/solve_exists(). 
- [ ] Have some Nat/Time inference.
- [x] Unify `UnOpI`, `DivI` and `ExpI`.
- [x] Unify `True` and `False`.
- [x] Change `unify_s` to `is_sub_sort`.
- [x] Should apply solvers and check no-uvar after every module, not every file (unless we enforce one-module-per-file policy). 
- [ ] Move VC openings from `check_decl` to `check_decls`.
- [x] `subst` should do lazy shifting, not eager.
- [x] The last two examples in bigO-evolve.timl about using `idx` instead of `absidx` does not work now.
- [x] Simplify unused `forall` in `prop`. The unused foralls are Big-O premises.
- [x] `BigOEvolveSealed` in bigO-evolve.timl does not work yet.
- [x] if-then-else and list syntax.
- [ ] \(No longer needed because uvars can be retrieved from modules now) Restore the version of `link_sig` in revision 00ba072, because a module may have uvars before sealing, and uvars cannot be retrieved from modules.
- [x] Big-O solver should heuristically distinguish "defining" side of `TimeFun` uvars from the "using" side, by the rule-of-thumb that only `_ <= f x` is a defining constraint of `f`.
- [x] Do a module dependent analysis of each module and only bring the needed modules into `gctx` VC context.
- [x] Have double-linked lists.
- [x] rbt6.timl:  absidx sort `Time` inference error in `IntKey`.
- [x] Currently `absidx ... with ... end` is "scoped abstract index". We should have "unscoped" or "module-scoped" abstract index `absidx id = ...` so within the module `id`'s definition is visible but outside the module it is not.
- [x] Make `kind`'s sorts dependent, or only use `bsort` in `kind`.
- [ ] Generate typing derivations.
    Road map (a translation validation (i.e. derivation reconstruction) approach):
    * [ ] Generate type-annotation TiML syntax
    * [ ] Translate it to type-annotated micro-TiML syntax
    * [ ] Reconstruct micro-TiML typing derivations from type-annotated micro-TiML syntax
    * [ ] The micro-TiML to assembly-TiML compilation should also use this approach
- [x] Remove annotations on `case` (at least in a mode).
- [x] `datatype` can introduce index variable names at the first line for every constructor.
- [ ] `find_hab` is too slow on array-msort.timl and array-msort-inplace.timl
- [x] A new unification framework ("skolemized unification"): every unification variable denotes a *closed* entity, which could be a lambda abstraction. For example, when we see type annotation [a : _] in the sorting context [x:Nat, y:Time], we introduce a uvar ?1 of kind [Nat => Time => Type], and replace the "_" with [AppV ?1 [x,y]]. When we try to unify [AppV ?1 [x,y]] with [int], in principle we can't conclude that [?1 = int]. But exploiting specific knowledge in this language, we can. When we can have such a definitive conclusion, we refine ?1 to be [int]; but when we can't have a definitive conclusion when doing unification, we should record it as a VC. For example, when we try to unify [AppV ?1 [x,y]] with [AppV ?2 [x,y]], we should put [AppV ?1 [x,y] = AppV ?2 [x,y]] in VC, instead of conclude that [?1 = ?2] (unless we want to do incomplete, over-aggressive unification).
- [x] SML supports datatypes instantiated with different type arguments within a constructor, such as [datatype 'a ls = Nil | Cons of 'a * ('a * 'a) ls]. TiML's typechecker also supports this. So TiML's proof should also support this. It has usage in for example Okasaki's implicit queue (thesis Chapter 8).
- [ ] \(Abondoned. Non-constant subtracter is needed to support minus of `nat` type) Change minus from a binop to an unop where the second operand can only be constant.
- [ ] Investigate array-msort-in-place.
- [ ] Generalization has some problems with higher-order uvars.
- [ ] Simplify modules in output.
- [ ] Rename [long_id]'s [ID] to "Bound" and [QID] to "Free", in accordance with locally nameless representation.
- [ ] Add native booleans. Add more integer operations (including comparisons). Add more nat operations.
- [ ] Add example links to website.
- [ ] Remove assert_b and assert_b_m to make sure when assertion are turned off no computation will be wasted.
- [ ] Add ELength.
- [x] eq_mt()/TDatatype needs to be implemented to allow instantiating dynamic-table.timl.
- [ ] Add negative examples.
- [ ] Argument module names of functors are put into global context, which may result in name conflicts. Should prefix argument module names with the functor names.
- [ ] Complete parser support for string literals and unescape().
- [ ] If a primitive shouldn't be redefined (especially base type names because type names appear in feedback messages), it should be made a keyword in timl.lex.

# To-do for MicroTiML

- [ ] remove let x = ... when x is "_", because such case can only be from translation of wildcard patterns
- [ ] remove duplicate EAsc and EAscTime
- [ ] analysing the form of expr is complicated by the pervasion of EAscType and EAscTime; need some principled way to transparently ignore EAscType/Time.
- [x] dynamic-table.timl needs to be instantiated to be tested by MicroTiML compiler
- [x] tc() should add annotations only when specific flags are turned on; the client that turns on these flags should consume the annotations to prevent them from polluting later translations.
- [x] Add level limits to export_t and export_e.
- [x] Add a pass to remove annotations on EVar, TVar and VarI after cc().
- [ ] Uniquefy variable names.
- [x] check_CPSed_expr() should also check types.
- [x] anf_decls() shouldn't alway use "x" as the new variable name, because it will replace other meaningful names after post_process(); it should take suggestions from surrounding ELet.
- [ ] Add a simplification for ECase where if the two branches are identical and don't mention the local variable, combine them and remove ECase.
- [ ] Remove datatype "micro_timl" and rename "micro_timl_ex" to "micro_timl".
- [ ] Rename "micro-timl/" to "compiler/"

# To-do for Examples:

- [x] Binary search with arrays.
- [x] binary heap with arrays.
- [x] In-place merge sort with arrays.
- [x] k-median search with arrays.
- [x] Quicksort.
- [x] Dijkstra algorithm.
- [x] Two-stack queue (amortized).
- [x] Double-linked lists.
- [ ] Union-find (amortized).
- [x] Some example showcasing the flexibility of "size".
