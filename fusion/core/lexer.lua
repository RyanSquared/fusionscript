local pretty = require("pl.pretty");
local re = require("re"); -- vim:set noet sts=0 sw=3 ts=3:

local defs = {}

pattern = re.compile([[
	statement_list <- {| (statement ws)* |}
	statement_block <- '{' ws statement_list ws '}'
	statement <- (
		assignment
	) ';' / (
		statement_block
	)

	assignment <- {| '' -> 'assignment'
		{| variable_list ws '=' ws expression_list |}
	|}
	expression_list <- {:expression_list: {|
		expression (ws ',' ws expression)*
	|} :}
	expression <- variable / literal
	variable_list <- {:variable_list: {| 
		variable (ws ',' ws variable)*
	|} :}
	variable <- {| '' -> 'variable' {[A-Za-z_][A-Za-z0-9_]*} |}

	literal <-
		number /
		string
	number <- base16num / base10num
	base10num <- {| '' -> 'base10num' {
		((integer '.' integer) /
		(integer '.') /
		('.' integer) /
		integer) int_exponent?
	} |}
	integer <- [0-9]+
	int_exponent <- [eE] [+-]? integer
	base16num <- {| '' -> 'base16num' { '0' [Xx] [0-9A-Fa-f]+ hex_exponent? } |}
	hex_exponent <- [pP] [+-]? integer

	string <- {| dqstring / sqstring / blstring |}
	dqstring <- '' -> 'dqstring' '"' { (('\\' .) / ([^\r\n"]))* } '"'
	sqstring <- '' -> 'sqstring' "'" { [^\r\n']* } "'"
	blstring <- '' -> 'blstring' '[' {:eq: '='* :} '[' blclose
	blclose <- ']' =eq ']' / . blclose

	ws <- %s*
]], defs);


pretty.dump(pattern:match([[a = "test";]]));
