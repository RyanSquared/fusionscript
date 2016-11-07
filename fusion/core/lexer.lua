local pretty = require("pl.pretty");
local re = require("re"); -- vim:set noet sts=0 sw=3 ts=3:

local defs = {}

pattern = re.compile([[
	statement_list <- {| (statement ws)* |}
	statement_block <- '{' ws statement_list ws '}'
	statement <- (
		assignment /
		function_call
	) ws ';' ws / (
		statement_block
	)

	function_call <- {| '' -> 'function_call' (
		value ws args /
		value ws ':' ws variable ws args
	) |}
	args <- '(' expression_list? ')'

	assignment <- {| '' -> 'assignment'
		{| variable_list ws '=' ws expression_list |}
	|}
	expression_list <- {:expression_list: {|
		expression (ws ',' ws expression)* 
	|} :}
	expression <- ex_or
	ex_or <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_and ws {:operator: '||' :} ws ex_and
	|} / ex_and
	ex_and <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_equality ws {:operator: '&&' :} ws ex_equality
	|} / ex_equality
	ex_equality <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_binary_or ws {:operator: ([<>!=] '=' / [<>]) :} ws ex_binary_or
	|} / ex_binary_or
	ex_binary_or <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_binary_xor ws {:operator: '|' :} ws ex_binary_xor
	|} / ex_binary_xor
	ex_binary_xor <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_binary_and ws {:operator: '~' :} ws ex_binary_and
	|} / ex_binary_and
	ex_binary_and <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_binary_shift ws {:operator: '&' :} ws ex_binary_shift
	|} / ex_binary_shift
	ex_binary_shift <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_concat ws {:operator: ('<<' / '>>') :} ws ex_concat
	|} / ex_concat
	ex_concat <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_term ws {:operator: '..' :} ws ex_term
	|} / ex_term
	ex_term <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_factor ws {:operator: [+-] :} ws expression
	|} / ex_factor
	ex_factor <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		ex_unary ws {:operator: ([*/%] / '//') :} ws ex_unary
	|} / ex_unary
	ex_unary <- {| '' -> 'expression' {:type: '' -> 'unary' :}
		{:operator: [-!#~] :} ws ex_power
	|} / ex_power
	ex_power <- {| '' -> 'expression' {:type: '' -> 'binary' :}
		value ws {:operator: '^' :} ws value
	|} / value
	value <-
		literal /
		variable /
		'(' expression ')'
	variable_list <- {:variable_list: {| 
		variable (ws ',' ws variable)*
	|} :}
	variable <- {| '' -> 'variable' {[A-Za-z_][A-Za-z0-9_]*} |}

	literal <-
		{| '' -> 'vararg' { '...' } |} /
		number /
		string /
		{| '' -> 'boolean' { 'true' / 'false' } |} /
		{| {'nil' -> 'nil'} |}
	number <- {| '' -> 'number' (
		base16num /
		base10num
	) |}
	base10num <- {:type: '' -> 'base10' :} {
		((integer '.' integer) /
		(integer '.') /
		('.' integer) /
		integer) int_exponent?
	}
	integer <- [0-9]+
	int_exponent <- [eE] [+-]? integer
	base16num <- {:type: '' -> 'base16' :} {
		'0' [Xx] [0-9A-Fa-f]+ hex_exponent?
	}
	hex_exponent <- [pP] [+-]? integer

	string <- {| dqstring / sqstring / blstring |}
	dqstring <- '' -> 'dqstring' '"' { (('\\' .) / ([^\r\n"]))* } '"'
	sqstring <- '' -> 'sqstring' "'" { [^\r\n']* } "'"
	blstring <- '' -> 'blstring' '[' {:eq: '='* :} '[' blclose
	blclose <- ']' =eq ']' / . blclose

	ws <- %s*
]], defs);


pretty.dump(pattern:match([[
a = test || asdf;
]]));
