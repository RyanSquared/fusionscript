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
	statement_list <- ws {| (statement ws)* |}
	statement_block <- {| '' -> 'block' '{' ws statement_list ws '}' |}
	statement <- (
		function_call /
		assignment /
		return /
		{| {'break'} |} /
		'--' [^;]*
	) ws ';' ws / (
		statement_block
	) / (
		while_loop /
		numeric_for_loop /
		iterative_for_loop /
		function_definition /
		if /
		class
	)

	class <- {| 'new' -> 'class' space {:name: name :}
		(ws 'extends' ws {:extends: variable :})? ws
		'{' ws {| (class_field ws)* |} ws '}'
	|}
	class_field <-
		function_definition /
		{| '' -> 'class_field'
			(
				'[' ws {:name: variable :} ws ']' ws '=' ws expression ws ';' /
				{:name: name :} ws '=' ws expression ws ';'
			)
		|}

	return <- {| {'return' / 'yield'} ws expression_list? |}

	lambda <- {| '' -> 'lambda'
		function_body
	|}
	function_definition <- {| '' -> 'function_definition'
		{:is_async: 'async' -> true :}? ws
		variable ws function_body
	|}
	function_body <- 
		'(' ws function_defined_arguments? ws ')' ws 
			({:is_self: '=' -> true :} / '-') '>' ws
			(statement / expression_list)
	function_defined_arguments <- {|
		function_argument (ws ',' ws function_argument)*
	|}
	function_argument <- {|
		{:name: name :} (ws '=' ws {:default: expression :})?
	|}

	while_loop <- {| '' -> 'while_loop'
		'while' ws {:condition: expression :} ws statement
	|}
	iterative_for_loop <- {| '' -> 'iterative_for_loop'
		'for' ws '(' ws name_list ws 'in' ws expression ws ')' ws statement
	|}
	numeric_for_loop <- {| '' -> 'numeric_for_loop'
		'for' ws numeric_for_assignment ws statement
	|}
	numeric_for_assignment <- '('
		{:incremented_variable: name :} ws '=' ws
		{:start: expression :} ws
		',' ws {:stop: expression :} ws
		(',' ws {:step: expression :})?
	')'

	if <- {|
		{'if'} ws {:condition: expression :} ws statement
		(ws 'else' ws {:else: statement :})?
	|}

	function_call <- {| '' -> 'function_call' (
		variable ({:has_self: ':' -> true :} variable ws
				{:index_class: ws '<' ws {value} ws '>' :}? )?
			ws '(' ws function_call_body? ws ')'
	) |}
	function_call_body <- {:generator: {|
		expression (ws 'for' ws variable_list)? ws 'in' ws expression
	|} :} / function_args
	function_args <- expression_list?

	assignment <- {| '' -> 'assignment'
		(variable_list ws '=' ws expression_list /
		{:is_local: 'local' -> true :} space name_list ws '=' ws
			expression_list)
	|}
	name_list <- {:variable_list: {|
		local_name (ws ',' ws local_name)*
	|} :} / {:variable_list: {|
		{:is_destructuring: '' -> true :}
		'{' ws local_name (ws ',' ws local_name)* ws '}'
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
		lambda /
		function_call /
		literal /
		variable /
		'(' expression ')'
	variable_list <- {:variable_list: {|
		variable (ws ',' ws variable)*
	|} :}
	variable <- {| '' -> 'variable' ('@' -> 'self')?
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
