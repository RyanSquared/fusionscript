local pretty = require("pl.pretty");
local re = require("re"); -- vim:set noet sts=0 sw=3 ts=3:

local defs = {}

defs['true'] = function() return true end
defs['false'] = function() return false end

function defs:transform_binary_expression()
	table.insert(self, 1, 'expression')
	self.type = 'binary'
	return self
end

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
		variable ({:has_self: ':' -> true :} value ws
				{:index_class: ws '<' ws {value} ws '>' :}? )?
			ws function_args
	) |}
	function_args <- '(' expression_list? ')'

	assignment <- {| '' -> 'assignment'
		{| variable_list ws '=' ws expression_list |}
	|}
	expression_list <- {:expression_list: {|
		expression (ws ',' ws expression)*
	|} :}

	expression <- ex_or
	ex_or <- {|
		(ex_and ws {:operator: '||' :} ws ex_and)
	|} -> transform_binary_expression / ex_and
	ex_and <- {|
		ex_equality ws {:operator: '&&' :} ws ex_equality
	|} -> transform_binary_expression / ex_equality
	ex_equality <- {|
		ex_binary_or ws {:operator: ([<>!=] '=' / [<>]) :} ws ex_binary_or
	|} -> transform_binary_expression / ex_binary_or
	ex_binary_or <- {|
		ex_binary_xor ws {:operator: '|' :} ws ex_binary_xor
	|} -> transform_binary_expression / ex_binary_xor
	ex_binary_xor <- {|
		ex_binary_and ws {:operator: '~' :} ws ex_binary_and
	|} -> transform_binary_expression / ex_binary_and
	ex_binary_and <- {|
		ex_binary_shift ws {:operator: '&' :} ws ex_binary_shift
	|} -> transform_binary_expression / ex_binary_shift
	ex_binary_shift <- {|
		ex_concat ws {:operator: ('<<' / '>>') :} ws ex_concat
	|} -> transform_binary_expression / ex_concat
	ex_concat <- {|
		ex_term ws {:operator: '..' :} ws ex_term
	|} -> transform_binary_expression / ex_term
	ex_term <- {|
		ex_factor ws {:operator: [+-] :} ws expression
	|} -> transform_binary_expression / ex_factor
	ex_factor <- {|
		ex_unary ws {:operator: ([*/%] / '//') :} ws ex_unary
	|} -> transform_binary_expression / ex_unary
	ex_unary <- {| '' -> 'expression' {:type: '' -> 'unary' :}
		{:operator: [-!#~] :} ws ex_power
	|} / ex_power
	ex_power <- {|
		value ws {:operator: '^' :} ws value
	|} -> transform_binary_expression / value
	value <-
		literal /
		variable /
		'(' expression ')'
	variable_list <- {:variable_list: {|
		variable (ws ',' ws variable)*
	|} :}
	variable <- {| '' -> 'variable'
		name ws ('.' ws name / ws '[' ws value ws ']')*
	|}
	name <- {[A-Za-z_][A-Za-z0-9_]*}

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
a = b.c;
]]));
