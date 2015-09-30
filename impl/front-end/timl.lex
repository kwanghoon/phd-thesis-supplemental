open Ast
open Util

structure T = Tokens

type pos = pos
type svalue = T.svalue
type ('a, 'b) token = ('a, 'b) T.token
type lexresult = (svalue, pos) token
type lexarg = reporter
type arg = lexarg

val line = ref 1
val linestart = ref 0

fun inc r = r := !r + 1
fun make_region (abs, size) : pos * pos = 
    ({abs = abs, line = !line, col = abs - !linestart}, 
     {abs = abs + size, line = 0, col = 0})
fun update_line yypos = (inc line; linestart := yypos)

fun eof _ = T.EOF (make_region (!linestart, 0))
fun error (f, msg, left, right) = f (msg, left, right)

fun flat (a, (b, c)) = (a, b, c)

val keywords = [
    ("fn", T.FN),
    ("fix", T.FIX),
    ("case", T.CASE),
    ("of", T.OF),
    ("let", T.LET),
    ("in", T.IN),
    ("end", T.END),
    ("return", T.RETURN),
    ("mu", T.MU),
    ("val", T.VAL),
    ("forall", T.FORALL),
    ("exists", T.EXISTS),
    ("max", T.MAX),
    ("min", T.MIN)
]

fun find (m, k) = Option.map #2 (List.find (fn (k', _) => k' = k) m)

fun is_keyword s = find (keywords, s)

				 %%

				 %header (functor TiMLLexFun (structure Tokens : TiML_TOKENS));

%arg (reporter : reporter);
				 %s COMMENT;

alpha = [A-Za-z];
digit = [0-9];
ws = [\ \t];
eol = ("\013\010"|"\010"|"\013");
id_init = ({alpha}|[_']);

%%

eol => (update_line yypos; continue());

<INITIAL>{ws}+ => (continue ());

<INITIAL>"(" => (T.LPAREN (make_region (yypos, 0)));
<INITIAL>")" => (T.RPAREN (make_region (yypos, 0)));
<INITIAL>"=>" => (T.DRARROW (make_region (yypos, 0)));
<INITIAL>"[" => (T.LSQ (make_region (yypos, 0)));
<INITIAL>"]" => (T.RSQ (make_region (yypos, 0)));
<INITIAL>"{" => (T.LCUR (make_region (yypos, 0)));
<INITIAL>"}" => (T.RCUR (make_region (yypos, 0)));
<INITIAL>":" => (T.COLON (make_region (yypos, 0)));
<INITIAL>"|>" => (T.RTRI (make_region (yypos, 0)));
<INITIAL>"," => (T.COMMA (make_region (yypos, 0)));
<INITIAL>"->" => (T.ARROW (make_region (yypos, 0)));
<INITIAL>"--" => (T.DDASH (make_region (yypos, 0)));
<INITIAL>"|" => (T.BAR (make_region (yypos, 0)));
<INITIAL>"/\\" => (T.AND (make_region (yypos, 0)));
<INITIAL>"\\/" => (T.OR (make_region (yypos, 0)));
<INITIAL>"<->" => (T.IFF (make_region (yypos, 0)));
<INITIAL>"=" => (T.EQ (make_region (yypos, 0)));
<INITIAL>"<=" => (T.LE (make_region (yypos, 0)));
<INITIAL>"+" => (T.PLUS (make_region (yypos, 0)));
<INITIAL>"-" => (T.MULT (make_region (yypos, 0)));

<INITIAL>{digit}+ => ((T.INT o flat)
                 (foldl (fn (a,r) => ord(a)-ord(#"0")+10*r) 0 (explode yytext),
                    make_region (yypos, 0)));
 
<INITIAL>{id_init}({id_init}|{digit})* => ((getOpt (is_keyword yytext, fn r => (T.ID o flat) (yytext, r)))
				  (make_region (yypos, size yytext)));

<INITIAL>"(*" => (YYBEGIN COMMENT; continue());
<COMMENT>"*)" => (YYBEGIN INITIAL; continue());
<COMMENT>. => (continue());
