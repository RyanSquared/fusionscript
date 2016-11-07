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
	expression <- ex_term
	ex_term <- {| '' -> 'expression'
		(ex_factor) ws {:operator: [+-] :} ws expression
	|} / ex_factor
	ex_factor <- {| '' -> 'expression'
		ex_power ws {:operator: ([*/%] / '//') :} ws ex_power
	|} / ex_power
	ex_power <- {| '' -> 'expression'
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
a = 1 + 2 * 3;
]]));
