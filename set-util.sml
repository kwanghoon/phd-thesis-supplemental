functor SetUtilFn (S : ORD_SET) = struct
open Util
structure Set = S

infixr 0 $

fun to_set ls = S.addList (S.empty, ls)
val fromList = to_set
                 
val to_list = S.listItems
val toList = to_list
                
fun member x s = S.member (s, x)
                          
fun dedup ls = to_list $ to_set ls
                       
fun pop s =
  case S.find (const_fun true) s of
      SOME e => SOME (e, S.delete (s, e))
    | NONE => NONE
                
fun enumerate c : (S.item, 'result) Enum.enum = fn f => (fn init => S.foldl f init c)
                       
fun str_set f = Util.surround "{" "}" o Util.join ", " o List.map (fn k => f k) o to_list
  
fun delete (s, k) = S.delete (s, k) handle NotFound => s
                                                                    
end

structure IntBinarySetUtil = SetUtilFn (IntBinarySet)
structure StringBinarySetUtil = SetUtilFn (StringBinarySet)
structure ISet = IntBinarySet
structure SSet = StringBinarySet
structure ISetU = IntBinarySetUtil
structure SSetU = StringBinarySetUtil
                                    
