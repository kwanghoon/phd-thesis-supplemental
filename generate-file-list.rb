#!/usr/bin/env ruby

require 'stringio'

def usage
 puts "usage: THIS_SCRIPT [smlnj|mlton|Makefile]"  
end

def wrong_arguments
  puts "wrong arguments"
  usage
  exit 1
end

if ARGV.size != 1 then
  wrong_arguments
end

target = ARGV[0]

if target == "smlnj" then
  target = :smlnj
elsif target == "mlton" then
  target = :mlton
elsif target == "Makefile" then
  target = :Makefile
else
  wrong_arguments
end

captured_stdio = StringIO.new('', 'w')
old_stdout = $stdout
$stdout = captured_stdio

if target == :smlnj then
  
print %{
Group is
      
cont-smlnj.sml
}

elsif target == :mlton then

print %{  
$(SML_LIB)/basis/basis.mlb
$(SML_LIB)/basis/build/sources.mlb
$(SML_LIB)/mlyacc-lib/mlyacc-lib.mlb
$(SML_LIB)/smlnj-lib/Util/smlnj-lib.mlb
$(SML_LIB)/smlnj-lib/PP/pp-lib.mlb
}

end

if target == :mlton || target == :Makefile then
  
print %{
cont-mlton.sml
}

end

print %{
enumerator.sml
util.sml
string-key.sml
list-pair-map.sml
set-util.sml
map-util.sml
unique-map.sml
region.sml
time.sml
operators.sml
}

if target == :smlnj || target == :Makefile then

print %{  
sexp/sexp.sml
sexp/sexp.grm
sexp/sexp.lex
sexp/parser.sml
parser/ast.sml
parser/timl.grm
parser/timl.lex
parser/parser.sml
}

elsif target == :mlton then

print %{  
sexp/sexp.sml
sexp/sexp.grm.sig
sexp/sexp.grm.sml
sexp/sexp.lex.sml
sexp/parser.sml
parser/ast.sml
parser/timl.grm.sig
parser/timl.grm.sml
parser/timl.lex.sml
parser/parser.sml
}

end

print %{
cont-util.sml
module-context.sml
to-string-util.sml
long-id.sml
uvar.sig
base-sorts.sml
bind.sml
visitor-util.sml                                 
unbound.sml
idx.sig
idx-visitor.sml
idx.sml
shift-util.sml
idx-trans.sml
type.sig
type-visitor.sml
type.sml
type-trans.sml
pattern.sml
pattern-visitor.sml                                 
hyp.sml
expr.sig
expr-util.sml
expr-visitor.sml                                 
expr-fn.sml
get-region.sml
base-types.sml
idx-util.sml
type-util.sml
idx-type-expr.sig
idx-type-expr-fn.sml
expr-trans.sml
simp.sml
simp-type.sml
vc.sml
equal.sml
subst.sml
long-id-subst.sml
export.sml
to-string-raw.sml
to-string-nameful.sml
to-string.sml
uvar.sml
uniquefy.sml
expr.sml
underscore-exprs.sml
pervasive.sml
elaborate.sml
name-resolve.sml
package.sml
typecheck-util.sml
normalize.sml
simp-expr.sml
collect-var.sml
collect-uvar.sml
parallel-subst.sml
fresh-uvar.sml
uvar-forget.sml
unify.sml
redundant-exhaust.sml
collect-mod.sml
subst-uvar.sml
update-expr.sml
sortcheck.sml
topo-sort-fn.sml
typecheck-main.sml
trivial-solver.sml
derived-trans.sml
unpackage.sml
post-typecheck.sml
typecheck.sml
smt2-printer.sml
smt-solver.sml
long-id-map.sml
bigO-solver.sml
simp-ctx.sml
pp-util.sml
nouvar-expr.sml
visitor.sml                                 
parse-filename.sml
vc-solver.sml
remove-open.sml
merge-modules.sml
micro-timl/micro-timl.sml
micro-timl/micro-timl-visitor.t.sml
micro-timl/micro-timl-long-id.sml
micro-timl/micro-timl-visitor2.sml
micro-timl/micro-timl-util.sml
micro-timl/micro-timl-pp.sml
micro-timl/pattern-ex.sml
micro-timl/post-process.sml
micro-timl/export-pp.sml
micro-timl/timl-to-micro-timl.sml
micro-timl/micro-timl-util-timl.sml
micro-timl/micro-timl-typecheck.sml
micro-timl/micro-timl-locally-nameless.sml
micro-timl/compiler-util.sml
micro-timl/cps.sml
micro-timl/cc.sml
# micro-timl/pair-alloc.sml
# micro-timl/tital.sml
# micro-timl/tital-visitor.sml
# micro-timl/tital-pp.sml
# micro-timl/tital-export-pp.sml
# micro-timl/tital-tc.sml
# micro-timl/tital-eval.sml
# micro-timl/code-gen.sml
micro-timl/evm1.sml
micro-timl/evm1-visitor.sml
micro-timl/evm1-pp.sml
micro-timl/evm1-export-pp.sml
micro-timl/evm1-pp.sml
micro-timl/evm-costs.sml
micro-timl/evm1-util.sml
micro-timl/evm1-tc.sml
micro-timl/evm1-assemble.sml
micro-timl/to-evm1.sml
unit-test.sml
main.sml
}

if target == :smlnj then

print %{  
$/basis.cm
$/smlnj-lib.cm
$/ml-yacc-lib.cm
$/pp-lib.cm
}

elsif target == :mlton || target == :Makefile then

print %{  
mlton-main.sml
}

end

$stdout = old_stdout
output = captured_stdio.string

output.gsub!(/#.*/, '')

print output
