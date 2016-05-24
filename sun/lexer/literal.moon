-- vim:set noet sts=0 sw=3 ts=3:

import P, S, R from require "lpeg"

-- "Ignored" patterns

Space      = S" "
Whitespace = S" \t\r\n\v" ^ 0
EndOfLine  = P"\r" ^ -1 * P"\n"
Shebang    = P"#!" * P(1 - EndOfLine) ^ 0 * EndOfLine
Comment    = P"--" * P(1 - EndOfLine) ^ 0 * EndOfLine

-- Number pattern

Number = P"0x" * R("09", "af", "AF") ^ 1 * (S"uU" ^ -1 * S"lL" ^ 2) ^ -1 +
	R"09" ^ 1 * (S"uU" ^ -1 * S"lL" ^ 2) +
	(
		R"09" ^ 1 * (P"." * R"09" ^ 1) ^ -1 +
		P"." * R"09" ^ 1
	) * (S"eE" * P"-" ^ -1 * R"09" ^ 1) ^ -1

-- Names

Upper   = R"AZ"
Lower   = R"az"
Letter  = Upper + Lower
Numeric = R"09"

VariableNotFiltered = Letter * (Letter + Numeric) ^ 0
-- ::TODO:: put all keywords here
Variable = VariableNotFiltered - (P"if" + P"else" + P"elseif")

-- Strings

-- ::TODO:: single strings don't escape with \, double strings do

SingleQuote = P"'"
DoubleQuote = P'"'
FullEscape  = P"\\" * 1 -- backslash followed by something else

SingleQuoteString = SingleQuote * (1 - SingleQuote) ^ 0 * SingleQuote
DoubleQuoteString = DoubleQuote * (FullEscape + (1 - (P"\\" + DoubleQuote))) ^ 0 * DoubleQuote

String = SingleQuoteString + DoubleQuoteString

-- ::TODO:: add Table, TableKey, etc.

-- Booleans (true/false)

True    = P"true"
False   = P"false"
Boolean = True + False

-- Nil

Nil = P"nil"

return {
	:Space, :Whitespace, :EndOfLine, :Shebang, :Comment,
	:Number,
	:Upper, :Lower, :Letter, :Numeric,
	:Variable,
	:SingleQuote, :DoubleQuote, :FullEscape,
	:SingleQuoteString, :DoubleQuoteString,
	:String,
	:True, :False, :Boolean
	:Nil
}
