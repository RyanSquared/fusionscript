--- Lex FusionScript files.
-- @module fusion.core.parser

local re = require("re");

--- @table defs
-- @field true Convert input to `true` boolean
-- @field false Convert input to `false` boolean
-- @field bool Convert input to `defs[input]` - should be `true`/`false`
-- @field numberify Convert input to number via `tonumber`
-- @field err Generate a SyntaxError on current line
-- @field semicolon Generate a SyntaxError for a missing semicolon
local defs = {} -- Definitions for LPeg Regex pattern.
local current_file;

defs['true'] = function() return true end
defs['false'] = function() return false end
defs['bool'] = function(...) return defs[(...)]() end
defs['numberify'] = tonumber

defs.print = print

defs.err = function(pos, char, ctx)
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
	local input = current_file:sub(pos, pos + 7):gsub("[\r\n\t]", "")
	local errormsg_table = {
		"SyntaxError";
		("Unexpected character on line %d"):format(line);
		("Token: %s"):format(current_file:match("%w+", pos) or char);
		("Input: >> %q <<"):format(input);
		ctx
	}
	local errormsg = {
		msg = errormsg_table;
		pos = {
			y = line;
			x = math.max(1, pos - line_start);
		};
		context = current_file:sub(math.max(pos - 2, line_start),
			math.min(pos + 5, current_file:match("()$")));
		quick = "syntax"
	}
	if current_file:match("^[A-Za-z_]", pos) then
		-- found text, match as context
		errormsg.context = current_file:match("[A-Za-z_][A-Za-z0-9_]*", pos);
	end
	setmetatable(errormsg, {
		__tostring = function()
			return table.concat(errormsg_table, "\n")
		end
	})
	error(errormsg, 0)
end

defs.semicolon = function(pos)
	pos = current_file:sub(1, pos - 1):match("()%s-$")
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
	local input = current_file:sub(math.max(pos - 7, 0), pos):gsub("[\r\n\t]",
		"")
	local errormsg_table = {
		"SyntaxError";
		("Expected semicolon on line %d"):format(line);
		("Input: >> %q <<"):format(input);
	}
	local errormsg = {
		msg = errormsg_table;
		pos = {
			y = line;
			x = math.max(1, pos - line_start);
		};
		context = current_file:sub(pos - 7, pos);
		quick = "semicolon"
	}
	setmetatable(errormsg, {
		__tostring = function()
			return table.concat(errormsg_table, "\n")
		end
	})
	error(errormsg, 0)
end

local pattern = re.compile([[ -- LPEG-RE
	statement_list <- {|
		{:description: '--- ' [^%nl]+ :}? %nl?
		{:directives:
			{| {| '-- @' name (' ' {[^ %nl]+})* ws_noc |}+ |}
		:}?
		ws ((! '}') rstatement ws)*
	|}
	statement_block <- {:type: '' -> 'block' :} '{' ws statement_list ws '}'
	statement <- {| {:pos: {} :} ((
		function_definition /
		class /
		interface
	) / (
		{:type: {'using'} :} (space using_name / ws '{' ws
			using_name (ws ',' ws using_name)*
		ws '}' / ((pos '' -> 'Unclosed using statement') -> err)) /
		import /
		const /
		enum /
		assignment /
		function_call /
		return /
		{:type: 'break' :}
	) (';' / {} -> semicolon) / (
		statement_block /
		while_loop /
		numeric_for_loop /
		iterative_for_loop /
		if
	)) |}

	using_name <- {[A-Za-z]+} / {'*'}
	keyword <- 'local' / 'class' / 'extends' / 'break' / 'return' / 'yield' /
		'true' / 'false' / 'nil' / 'if' / 'else' / 'elseif' / 'while' / 'for' /
		'in' / 'async'
	rstatement <- statement / (pos '' -> 'Missing statement') -> err
	r <- pos -> err
	pos <- {} {.}

	class <- {:is_local: 'local' -> true space :}?
		{:type: {'class'} :} space {:name: variable / r :}
		(ws 'extends' ws {:extends: variable / r :})?
		(ws 'implements' ws {:implements: variable / r :})?
		ws '{' ws {| ((! '}') (class_field / r) ws)* |} ws '}'
	class_field <-
		{| function_definition |} /
		{| {:type: '' -> 'class_field' :}
			(
				'[' ws {:index: expression / r :} ws ']' ws ('=' / r) ws (expression
				/ r) ws (';' / r)
				/ {:name: name / r :} ws ('=' / r) ws (expression / r) ws (';' / r)
			)
		|}
	interface <- {:is_local: 'local' -> true space :}?
		{:type: {'interface'} :} space {:name: variable / r :}
		ws '{' ws {| ((! '}') (interface_field / r) ws)* |} ws '}'
	interface_field <- name ws ';'

	const <- {:type: 'const' :} space name ws '=' ws (number / string / boolean)
	enum <- {:type: 'enum' :} space name ws '{' ws
		enum_field+ '}'
	enum_field <- {| name (ws '=' ws number)? ws ';' ws |}

	return <- {:type: {'return' / 'yield'} :} ws expression_list?

	lambda <- {| {:type: '' -> 'lambda' :}
		'\' ws lambda_args? ws is_self '>' ws (expression_list /
			{| statement_block |} /
			r)
	|}
	lambda_args <- {| lambda_arg (ws ',' ws lambda_arg)* |}
	lambda_arg <- {| {:name: name / '...' :} |}
	function_definition <- {:type: '' -> 'function_definition' :}
		{:is_async: 'async' -> true space :}?
		{:is_local: 'local' -> true space :}? ws
		variable ws function_body -- Do NOT write functions with :, use =>
	function_body <-
		'(' ws function_defined_arguments? ws ')' ws
			is_self '>' ws
			(statement / expression_list / r)
	is_self <- {:is_self: '=' -> true :} / '-'
	function_defined_arguments <- {|
		function_argument ((! ')') ws (',' / r) ws function_argument)*
	|}
	function_argument <- {|
		{:name: ((! ")") (name / {'...'} / r)) :} (ws '=' ws
		{:default: expression / r:})?
	|}

	while_loop <- {:type: '' -> 'while_loop' :}
		'while' ws {:condition: expression / r :} ws rstatement
	iterative_for_loop <- {:type: '' -> 'iterative_for_loop' :}
		'for' ws '(' ws (for_name_list / r) ws 'in' ws (expression / r) ws ')' ws
		rstatement
	numeric_for_loop <- {:type: '' -> 'numeric_for_loop' :}
		'for' ws numeric_for_assignment ws rstatement
	numeric_for_assignment <- '('
		{:incremented_variable: name / r :} ws '=' ws
		{:start: expression :} ws
		',' ws {:stop: expression :} ws
		(',' ws {:step: expression / r :})?
	')'
	for_name_list <- {:variable_list: {|
		for_name (ws ',' ws (for_name / r))*
	|} :}

	for_name <- {| {:type: '' -> 'variable' :} name |}

	if <-
		{:type: 'if' :} ws {:condition: expression / r :} ws rstatement
		{:elseif: {| (ws {|
			'elseif' ws {:condition: expression / r :} ws rstatement
		|})* |} :}
		(ws 'else' ws {:else: rstatement :})?

	function_call_first <-
		variable ws
		({:has_self: ':' ws {name / r} :} ws)?
	function_call_name <-
		(& ('.' variable / ':'))
		'.'? ws variable? ws
		({:has_self: ':' ws {name / r} :} ws)?
	function_call <- {:type: '' -> 'function_call' :}
		((& '@') {:is_self: '' -> true :})? -- the @ at the beginning
		{| function_call_first ws '(' ws function_args? ws ')' ws |} -- first call
		{| (function_call_name ws '(' ws function_args? ws ')' ws) |}* -- chained
	function_args <- expression_list?

	assignment <- {:type: '' -> 'assignment' :}
		(variable_list ws '=' ws (expression_list / r) /
		{:is_local: 'local' -> true :} ws {:is_nil: '(' -> true :} ws local_name
			(ws ',' ws (local_name / r))* ws ')' /
		{:is_local: 'local' -> true :} space (asn_name_list / r) ws ('=' / r) ws
			(expression_list / r))
	asn_name_list <- {:variable_list: {|
		local_name (ws ',' ws (local_name / r))*
	|} :} / {:variable_list: {|
		{:is_destructuring: '{' -> 'table' :} ws des_name -- local {x} = a;
		(ws ',' ws (des_name / r))* ws '}'
	|} :} / {:variable_list: {|
		{:is_destructuring: '[' -> 'array' :} ws local_name -- local [x] = a;
		(ws ',' ws (local_name / r))* ws ']'
	|} :}
	des_name <- {| {:type: '' -> 'variable' :} name
		(ws '=>' ws {:assign_to: name :})? -- local {x => y} = z;
	|}
	local_name <- {| {:type: '' -> 'variable' :} name |}

	import <- {:type: 'import' :} space {:to_import: {| name ('.' name)* |} :}
		ws (
			{:get_everything: '*' -> true :} /
			{:destructured_values: '{' ws {|
				(des_name ws (';' / {} -> semicolon) ws)+
			|} '}' :}
		)

	expression_list <- {:expression_list: {|
		expression (ws ',' ws (expression / r))*
	|} :}
	expression <- value / {| {:type: '' -> 'expression' :}
		'(' ws operator (((! ')') ws expression)+ / r) ws ')'
	|}
	operator <- {:operator:
		'//' /
		'>>' /
		'<<' /
		[=!<>] '=' /
		'&&' /
		'||' /
		'..' /
		'?:' /
		[-!#~+*/%^&|<>]
	:}
	value <-
		lambda /
		{| function_call |} /
		literal /
		variable
	variable_list <- {:variable_list: {|
		variable (ws ',' ws (variable / r))*
	|} :}
	variable <- {| {:type: '' -> 'variable' :}
		((('@' -> 'self' name? / name) / '(' expression ')') ws ('.' ws (name / r
		) / '[' ws (expression / r) ws ']')*)
	|}
	name <- (! (keyword [^A-Za-z0-9_])) {[A-Za-z_][A-Za-z0-9_]*}

	literal <-
		re /
		table /
		{| {:type: '' -> 'vararg' :} { '...' } |} /
		number /
		string /
		boolean /
		{| {:type: {'nil'} :} |}
	boolean <- {| {:type: '' -> 'boolean' :}
		('true' / 'false') -> bool
	|}
	re <- {| {:type: '' -> 're' :}
		'/' {('\' . / [^/]+)*} ('/' / r)
	|}
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
		([^%nl"]))* } ('"' / r) -- no escape codes in block quotes
	sqstring <- {:type: '' -> 'sqstring' :} "'" { [^%nl']* }
		("'" / r)
	blopen <- '[' {:eq: '='* :} '[' %nl?
	blclose <- ']' =eq ']'
	blstring <- {:type: '' -> 'blstring' :} blopen {((! blclose) .)*} blclose

	table <- {| {:type: '' -> 'table' :} '{' ws
		(
			table_generator /
			table_field (ws ',' ws table_field)*
		)?
	ws '}' |}
	table_generator <- {| {:type: '' -> 'generator' :}
		table_field (ws 'for' ws (variable_list / r))? ws 'in' ws (expression / r)
	|}
	table_field <-
		{| '[' ws {:index: expression :} ws ']' ws '=' ws (expression / r) |} /
		{| {:name: name :} ws '=' ws (expression / r) |} /
		expression

	ws <-
		('#!' [^%nl]*)?
		(%s* '--' [^%nl]* %nl?)*
		%s*
	ws_noc <- %s*
	space <- %s+
]], defs);

--- Generate an AST from a file
-- @function lexer:match
-- @tparam string input
-- @treturn table
-- @usage require("pl.pretty").dump(lexer:match("print('hi');"))

return {
	match = function(self, input, filename) -- luacheck: ignore 212
		if filename then
			local is_cached = self:check_cache(filename)
			if is_cached then
					return is_cached
			end
		end

		current_file = input
		local ast = pattern:match(input)

		if filename then
			local digest = require("openssl.digest")
			local basexx = require("basexx")
			local serpent = require("serpent")
			local lfs = require("lfs")

			lfs.mkdir('fs-cache')
			if filename:find("/") then
				local dir = lfs.currentdir()
				lfs.chdir('fs-cache')
				for path in filename:match("(.+)/.+"):gmatch("[^/]+") do
					lfs.mkdir(path)
					lfs.chdir(path)
				end
				lfs.chdir(dir)
			end

			local file = assert(io.open(("./fs-cache/%s"):format(filename), "w"))
			file:write(("-- SHA-1: %s\n"):format(basexx.to_hex(digest.new():final(
				input))))
			file:write("return ")
			file:write(serpent.block(ast, {comment = false}))
			file:write(";")
			file:close()
		end

		return ast
	end;
	check_cache = function(self, file)
		assert(type(file) == "string", "argument to check_cache not string")
		-- import here because these modules affect the filesystem
		local digest = require("openssl.digest")
		local basexx = require("basexx")
		local lfs = require("lfs")
		if lfs.attributes(("./fs-cache/%s"):format(file), "mode") == "file" then
			-- cached found, check against hash of file
			local f = io.open(file)
			local chunk = f:read(1024)
			local cur_digest = digest.new()
			while chunk do
				cur_digest:update(chunk)
				chunk = f:read(1024)
			end
			f:close()
			local hash = cur_digest:final()

			local cached = io.open(("./fs-cache/%s"):format(file))
			if not cached:read() then
				cached:close()
				return
			end
			cached:seek("set")

			local line = cached:read()
			cached:close()
			local stored_hash = line:match("%-%- SHA%-1: (%x+)")
			if not stored_hash then
				return nil, ("unable to recover hash for: %q"):format(file)
			else
				stored_hash = stored_hash:upper()
			end
			if stored_hash == basexx.to_hex(hash) then
				return dofile(("./fs-cache/%s"):format(file))
			else
				return nil, ("hash does not match: (base)%q != (cached)%q"):format(
					basexx.to_hex(hash), stored_hash)
			end
		else
			return nil, ("cached file not found: %q"):format(file)
		end
	end;
}
