local re = require("re");

local defs = {}

defs['true'] = function() return true end
defs['false'] = function() return false end
defs['bool'] = function(...) return defs[(...)]() end
defs['numberify'] = tonumber

function defs:transform_binary_expression()
	table.insert(self, 1, 'expression')
	self.type = 'binary'
	return self
end

local pattern = re.compile([[
	statement_list <- {| (statement ws)* |}
	statement_block <- '{' ws statement_list ws '}'
	statement <- (
		function_call /
		assignment
	) ws ';' ws / (
		statement_block
	)

	function_call <- {| '' -> 'function_call' (
		variable ({:has_self: ':' -> true :} variable ws
				{:index_class: ws '<' ws {value} ws '>' :}? )?
			ws function_args
	) |}
	function_args <- '(' ws expression_list? ws ')'

	assignment <- {| '' -> 'assignment'
		{|
			(variable_list ws '=' ws expression_list) /
			({:is_local: 'local' -> true :} space local_name_list ws '=' ws
				expression_list)
		|}
	|}
	local_name_list <- {:variable_list: {|
		local_name (ws ',' ws local_name)*
	|} :}
	local_name <- {| '' -> 'variable' name |}
	expression_list <- {:expression_list: {|
		expression (ws ',' ws expression)*
	|} :}

	expression <- value / {| '' -> 'expression'
		'(' ws operator (ws expression)+ ws ')'
	|}
	operator <- {:operator:
		'//' /
		'>>' /
		'<<' /
		[=!<>] '=' /
		'&&' /
		'||' /
		'..' /
		[-!#~+*/%^&|<>]
	:}
	value <-
		function_call /
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
		table /
		{| '' -> 'vararg' { '...' } |} /
		number /
		string /
		{| '' -> 'boolean'
			('true' / 'false') -> bool
		|} /
		{| {'nil' -> 'nil'} |}
	number <- {| '' -> 'number' {:is_negative: '-' -> true :}? (
		base16num /
		base10num
	) |}
	base10num <- {:type: '' -> 'base10' :} {
		((integer '.' integer) /
		(integer '.') /
		('.' integer) /
		integer) int_exponent?
	} -> numberify
	integer <- [0-9]+
	int_exponent <- [eE] [+-]? integer
	base16num <- {:type: '' -> 'base16' :} {
		'0' [Xx] [0-9A-Fa-f]+ hex_exponent?
	} -> numberify
	hex_exponent <- [pP] [+-]? integer

	string <- {| dqstring / sqstring / blstring |}
	dqstring <- '' -> 'dqstring' '"' { (('\\' .) / ([^\r\n"]))* } '"'
	sqstring <- '' -> 'sqstring' "'" { [^\r\n']* } "'"
	blstring <- '' -> 'blstring' '[' {:eq: '='* :} '[' blclose
	blclose <- ']' =eq ']' / . blclose

	table <- {| '' -> 'table' '{' ws -- TODO `for` constructor
		(
			table_generator /
			table_field (ws ',' ws table_field)*
		)?
	ws '}' |}
	table_generator <- {| '' -> 'generator'
		table_field (ws 'for' ws variable_list)? ws 'in' ws expression
	|}
	table_field <-
		{| '[' ws {:index: variable :} ws ']' ws '=' ws expression |} /
		{| {:name: name :} ws '=' ws expression |} /
		expression

	ws <- %s*
	space <- %s+
]], defs);

return pattern
