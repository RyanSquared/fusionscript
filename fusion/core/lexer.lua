local re = require("re");

local defs = {}
local current_file;

defs['true'] = function() return true end
defs['false'] = function() return false end
defs['bool'] = function(...) return defs[(...)]() end
defs['numberify'] = tonumber

defs.print = print

balanced_borders = re.compile [=[
	match <- { parens / square / curly }
	parens <- "(" ([^()] / parens)^-10 ")"?
	square <- "[" ([^][] / square)^-10 "]"?
	curly <- "{" ([^{}] / parens)^-10 "}"?
]=]

defs.incomplete_statement = function(pos, char)
	local line = 1
	local start = 1
	local line_start = 0
	while start < pos do
		if current_file:find("^\n", start) then
			line_start = start + 1
			line = line + 1
		end
		start = start + 1
	end
	local line_end = current_file:find("\n", pos)
	if not line_end then
		line_end = #current_file
	else
		line_end = line_end - 1
	end
	local msg_start = math.max(pos - 5, line_start)
	local msg_end = math.min(pos + 5, line_end)
	local input = ""
	local tab_len = 8
	if msg_start == pos - 5 and msg_start ~= line_start then
		tab_len = 11
		input = "..."
	end
	input = input .. current_file:sub(msg_start, msg_end)
	if msg_end ~= line_end and msg_end == pos + 5 then
		input = input .. "..."
	end
	errormsg_table = {
		"SyntaxError";
		("Unfinished statement on line %d"):format(line);
		("Input: %q"):format(input);
		(" "):rep(tab_len + math.max(pos - msg_start, 0)) .. "^";
	}
	errormsg = {
		pos = {
			y = line;
			x = pos - line_start;
		};
		context = current_file:sub(pos, pos + 10);
		quick = "syntax"
	}
	if current_file:match("[A-Za-z_]") then
		-- found text, match as context
		errormsg.context = current_file:match("[A-Za-z_][A-Za-z0-9_]*", pos);
	elseif current_file:match("%[%]{}%(%)") then
		-- found brackets, match text up to newline as context
		errormsg.context = balanced_borders:match(current_file:sub(pos, pos+30));
	end
	setmetatable(errormsg, {
		__tostring = function()
			return table.concat(errormsg_table, "\n")
		end
	})
	error(errormsg, 0)
end

local pattern = re.compile([[
	statement_list <- ws {| ((! '}') rstatement ws)* |}
	statement_block <- {| {:type: '' -> 'block' :} '{' ws statement_list ws '}' |}
	statement <- (
		function_call /
		assignment /
		return /
		{| {:type: 'break' :} |} /
		'--' {| {:type: '' -> 'comment' :} ws {[^;]*} |}
	) ws ';' ws / (
		statement_block /
		while_loop /
		numeric_for_loop /
		iterative_for_loop /
		function_definition /
		if /
		class
	)
	rstatement <- statement / required
	required <- ({} {.}) -> incomplete_statement
	class <- {| {:type: 'new' -> 'class' :} space {:name: name :}
		(ws 'extends' ws {:extends: variable :})? ws
		'{' ws {| ((! '}') (class_field / required) ws)* |} ws '}'
	|}
	class_field <-
		function_definition /
		{| {:type: '' -> 'class_field' :}
			(
				'[' ws {:name: variable :} ws ']' ws '=' ws expression ws ';' /
				{:name: name :} ws '=' ws expression ws ';'
			)
		|}

	return <- {| {:type: {'return' / 'yield'} :} ws expression_list? |}

	lambda <- {| {:type: '' -> 'lambda' :}
		function_body
	|}
	function_definition <- {| {:type: '' -> 'function_definition' :}
		{:is_async: 'async' -> true space :}? ws
		variable ws function_body -- Do NOT write functions with :
	|}
	function_body <- 
		'(' ws function_defined_arguments? ws ')' ws 
			({:is_self: '=' -> true :} / '-') '>' ws
			(statement / expression_list / required)
	function_defined_arguments <- {|
		function_argument (ws ',' ws function_argument)*
	|}
	function_argument <- {|
		{:name: name :} (ws '=' ws {:default: expression :})?
	|}

	while_loop <- {| {:type: '' -> 'while_loop' :}
		'while' ws {:condition: expression :} ws rstatement
	|}
	iterative_for_loop <- {| {:type: '' -> 'iterative_for_loop' :}
		'for' ws '(' ws name_list ws 'in' ws expression ws ')' ws rstatement
	|}
	numeric_for_loop <- {| {:type: '' -> 'numeric_for_loop' :}
		'for' ws numeric_for_assignment ws rstatement
	|}
	numeric_for_assignment <- '('
		{:incremented_variable: name :} ws '=' ws
		{:start: expression :} ws
		',' ws {:stop: expression :} ws
		(',' ws {:step: expression :})?
	')'

	if <- {|
		{:type: 'if' :} ws {:condition: expression :} ws rstatement
		{:elseif: {| (ws {|
			'elseif' ws {:condition: expression :} ws rstatement
		|})* |} :}
		(ws 'else' ws {:else: rstatement :})?
	|}

	function_call <- {| {:type: '' -> 'function_call' :} (
		variable ({:has_self: ':' -> true :} variable ws
		{:index_class: ws '<' ws {expression} ws '>' :}? )?
		) ws '(' ws function_call_body? ws ')'
	|}
	function_call_body <- {:generator: {|
		expression (ws 'for' ws variable_list)? ws 'in' ws expression
	|} :} / function_args
	function_args <- expression_list?

	assignment <- {| {:type: '' -> 'assignment' :}
		(variable_list ws '=' ws expression_list /
		{:is_local: 'local' -> true :} space name_list ws '=' ws
			expression_list)
	|}
	name_list <- {:variable_list: {|
		local_name (ws ',' ws local_name)*
	|} :} / {:variable_list: {|
		{:is_destructuring: '{' -> true :} ws local_name
		(ws ',' ws local_name)* ws '}'
	|} :} 
	local_name <- {| {:type: '' -> 'variable' :} name |}
	expression_list <- {:expression_list: {|
		expression (ws ',' ws expression)*
	|} :}

	expression <- value / {| {:type: '' -> 'expression' :}
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
		variable
	variable_list <- {:variable_list: {|
		variable (ws ',' ws variable)*
	|} :}
	variable <- {| {:type: '' -> 'variable' :}
		((('@' -> 'self' name? / name) / '(' expression ')') ws ('.' ws name /
		'[' ws expression ws ']')*)
	|}
	name <- {[A-Za-z_][A-Za-z0-9_]*}

	literal <-
		table /
		{| {:type: '' -> 'vararg' :} { '...' } |} /
		number /
		string /
		{| {:type: '' -> 'boolean' :}
			('true' / 'false') -> bool
		|} /
		{| {:type: {'nil'} :} |}
	number <- {| {:type: '' -> 'number' :} {:is_negative: '-' -> true :}? (
		base16num /
		base10num
	) |}
	base10num <- {:base: '' -> '10' :} {
		((integer '.' integer) /
		(integer '.') /
		('.' integer) /
		integer) int_exponent?
	} -> numberify
	integer <- [0-9]+
	int_exponent <- [eE] [+-]? integer
	base16num <- {:base: '' -> '16' :} {
		'0' [Xx] [0-9A-Fa-f]+ hex_exponent?
	} -> numberify
	hex_exponent <- [pP] [+-]? integer

	string <- {| dqstring / sqstring / blstring |}
	dqstring <- {:type: '' -> 'dqstring' :} '"' { (('\' .) /
		([^]] .. '\r\n' .. [["]))* } '"' -- no escape codes in block quotes
	sqstring <- {:type: '' -> 'sqstring' :} "'" { [^]] .. '\r\n' .. [[']* } "'"
	blstring <- {:type: '' -> 'blstring' :} '[' {:eq: '='* :} '[' blclose
	blclose <- ']' =eq ']' / . blclose

	table <- {| {:type: '' -> 'table' :} '{' ws -- TODO `for` constructor
		(
			table_generator /
			table_field (ws ',' ws table_field)*
		)?
	ws '}' |}
	table_generator <- {| {:type: '' -> 'generator' :}
		table_field (ws 'for' ws variable_list)? ws 'in' ws expression
	|}
	table_field <-
		{| '[' ws {:index: variable :} ws ']' ws '=' ws expression |} /
		{| {:name: name :} ws '=' ws expression |} /
		expression

	ws <- %s*
	space <- %s+
]], defs);

return {
	match = function(self, input)
		current_file = input
		return pattern:match(input)
	end
}
