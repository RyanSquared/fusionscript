-- vim:set noet sts=0 sw=3 ts=3:
import Number, Variable, Macro, String, Boolean, Nil,
	Whitespace from require "sun.lexer.literal"
import P, V, S from require "lpeg"

Literal = Number + Boolean + Nil + Variable + String

-- Expressions

binary_symbols = {
	"+",  "-",  "*",  "//",  "/",  "^",  "%", "&", "~", "|", ">>", "<<", "..",
	"<", "<=", ">", ">=", "==", "!=", "&&", "||"
}
to_unpack = {}
local BinarySymbolPattern
for i=1, #binary_symbols do
	if #(binary_symbols[i]) == 1
		to_unpack[#to_unpack + 1] = binary_symbols[i]
	else
		if BinarySymbolPattern
			BinarySymbolPattern = BinarySymbolPattern + P(binary_symbols[i])
		else
			BinarySymbolPattern = P(binary_symbols[i])

BinarySymbolPattern = BinarySymbolPattern + S(table.concat(binary_symbols))

Base = {
	Call: Variable * P"(" * Whitespace * V"Vararg" ^ -1 * Whitespace * P")"
	Vararg: (V"Call" + V"Expression") * (Whitespace * P"," * Whitespace * (
		V"Call" + V"Expression")) ^ 0
	BinaryExpression: V"Value" * Whitespace * BinarySymbolPattern *
		Whitespace * V"Expression"
	UnaryExpression: S"#-~!" * Whitespace * V"ValueNoUnary"
	Expression: V"BinaryExpression" + V"UnaryExpression" + V"Value"
	ValueNoUnary: V"Call" + Literal * P"[" * V"Value" * P"]" + Literal + (
		P"(" * Whitespace * V"Value" * Whitespace * P")"
	)
	Value: V"UnaryExpression" + V"ValueNoUnary"
}

patterns = {}
do
	temp = {}
	names = {"Call", "Vararg", "BinaryExpression", "UnaryExpression",
		"Expression", "ValueNoUnary", "Value"}
	Vararg_0, Call_0 = {}, {}
	for k, v in pairs(Base)
		for i, _v in pairs(names) do
			temp[_v] = {_v} if not temp[_v]
			temp[_v][k] = v
	for k, v in pairs(temp) do
		patterns[k] = P(v)
import Call, Vararg, BinaryExpression, UnaryExpression, Expression,
	ValueNoUnary, Value from patterns

VariableList = Variable * (Whitespace * P"," * Whitespace * Variable) ^ 0
Assignment = VariableList * Whitespace * P"=" * Whitespace * Vararg

Statement = Whitespace * (Assignment + Call) * Whitespace * ";"

return {
	:Call, :Vararg, :BinaryExpression, :UnaryExpression, :Expression,
	:ValueNoUnary, :Value, :VariableList, :Assignment, :Statement
}
