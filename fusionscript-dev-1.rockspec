package = "fusionscript"
version = "dev-1"

source = {
	url = "git://github.com/ChickenNuggers/FusionScript.git"
}

description = {
	summary = "A Lua compilable language based on C and Python",
	maintainer = "Ryan <ryan@github.com>",
	license = "MIT"
}

dependencies = {
	"lua >= 5.1",
	"lpeg >= 1.0"
}

build = {
	type = "builtin",
	modules = {
		["fusion.core.parsers.source"] = "fusion/core/parsers/source.lua",
		["fusion.core.lexer"] = "fusion/core/lexer.lua"
	},
	install = {
		bin = {
			["fuse-ast"] = "fuse/ast.lua";
			["fuse-source"] = "fuse/source.lua";
		}
	}
}
