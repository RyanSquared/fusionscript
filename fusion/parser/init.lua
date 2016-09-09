local lpeg = require("lpeg")
local P, V, S, R = lpeg.P, lpeg.V, lpeg.S, lpeg.R

local Space       = P" "
local WSPre       = S" \t\r\n\v"
local WS, WSOnce  = WSPre ^ 0, WSPre ^ 1
local EndOfLine   = P"\r" ^ -1 * P"\n"
local Shebang     = P"#!" * P(1 - EndOfLine) ^ 0 * EndOfLine
local Parenthesis = #(P"(") -- lookahead
-- ::TODO:: comments

local Length    = (S"uU" ^ -1 * S"lL" ^ -2) ^ -1
local Integer   = R"09" ^ 1
local HexNumber = P"0x" * R("09", "af", "AF") * S"pP" * S"+-" * Integer
local DecNumber = Integer ^ -1 * (P"." * Integer)
local IntNumber = Integer * Length
local Extension = S"eE" * P"-" ^ -1
local Number = (HexNumber + DecNumber + IntNumber) * Extension ^ -1

local SingleQuote = P"'"
local DoubleQuote = P'"'
local FullEscape  = P"\\" * P(1)

local SingleQuoteString = SingleQuote * (P(1) - SingleQuote) ^ 0 * SingleQuote
local DoubleQuoteString = DoubleQuote * ((FullEscape + P(1)) - P"\\" *
    DoubleQuote) ^ 0 * DoubleQuote
    -- match either an escape sequence or single byte that is not '\"'

local String = SingleQuoteString + DoubleQuoteString
local True = P"true"
local False = P"false"
local Boolean = True + False
local Nil = P"nil"

local Upper  = R"AZ"
local Lower  = R"az"
local Letter = Upper + Lower
local VariableName = (Letter + P"_") * (Letter + P"_" + Integer) ^ 0
local Filters = P(false)
local Keywords = {"else", "if", "true", "false", "nil", "while", "in",
    "new", "for", "extends"}
for key, word in pairs(Keywords) do
    Filters = Filters + P(word)
end
local Variable = P"@" ^ -1 * (VariableName - Filters)

local UnarySymbol = S"#!~-"
local BinarySymbol = P(false)
do
    local BinarySymbolSet = {
        "+", "-", "*",  "//",  "/",  "^",  "%", "&", "~", "|", ">>", "<<", "..",
        "<", "<=", ">", ">=", "==", "!=", "&&", "||"
    }
    local Storage = {}
    for i=1, #BinarySymbolSet do
        if #(BinarySymbolSet[i]) == 1 then
            Storage[#Storage + 1] = BinarySymbolSet[i]
        else
            BinarySymbol = BinarySymbol + P(BinarySymbolSet[i])
        end
    end
    BinarySymbol = BinarySymbol + S(table.concat(Storage))
end

local Base = P {
    "File";
    FunctionCall         = V"PrefixExpression" * V"Arguments" + V"PrefixExpression" * WS * P":" * WS * Variable *
                            V"Arguments";
    PrefixExpression     = V"Name" + V"FunctionCall" + P"(" * WS * V"Expression" * WS * P")";
    Name                 = V"PrefixExpression" * WS * P"[" * WS * V"Expression" * WS * P"]" + V"PrefixExpression" * WS *
                            P"." * WS * Variable + Variable;
    Expression           = V"Literal" + P"..." + V"PrefixExpression" + V"Expression" * WS * BinarySymbol * WS *
                            V"Expression" + UnarySymbol * WS * V"Expression";
    Literal              = V"TableConstructor" + V"FunctionDeclaration" + V"Class" + Number + String + Boolean + Nil;
    Arguments            = P"(" * WS * V"ExpressionList" * WS * V")";
    ExpressionList       = V"Expression" * (WS * P"," * WS * V"Expression") ^ 0;
    TableConstructor     = P"{" * WS * V"TableFieldList" * WS * P"}";
    TableFieldList       = V"TableField" * (WS * P"," * WS * V"TableField") ^ 0;
    TableField           = P"[" * WS * V"Expression" * WS * P"]" * WS * P"=" * V"Expression" + Variable * WS * P"=" *
                            WS * V"Expression" + V"Expression";
    VariableList         = Variable * (WS * P"," * WS * Variable) ^ 0;
    FunctionVariable     = Variable * (WS * P"=" * WS * V"Expression");
    FunctionVariableList = V"FunctionVariable" * (WS * P"," * WS * V"FunctionVariable") ^ 0;
    FunctionBody         = P"(" * WS * V"FunctionVariableList" * WS * P")" * WS * S"-=" * P">" * WS * V"StatementList";
    NamedFunction        = Variable * (WS * P"[" * WS * V"Expression" * WS * P"]") ^ 0 * WS * V"FunctionBody";
    NamedLocalFunction   = P"local" * WSOnce * Variable * WS * V"FunctionDeclaration";
    AnonymousFunction    = V"FunctionBody";
    FunctionDeclaration  = V"NamedFunction" + V"NamedLocalFunction" + V"AnonymousFunction";
    Assignment           =(P"local" * WSOnce) ^ -1 * V"VariableList" * WS * P"=" * WS * V"ExpressionList";
    Reassignment         = Variable * WS * BinarySymbol * P"=" * WS * Expression;
    StatementList        = V"Statement" + P"{" *  WS * V"Statement" * (WS * V"Statement") ^ 0 * P"}";
    Statement            =(P"return" * WSOnce * V"ExpressionList" * WS + V"Assignment" + V"Reassignment" + P"break" +
                            V"FunctionCall") * WS * P";" + V"While" + V"ForwardAssertFor" +
                            V"IteratorFor" + V"NumericFor" + V"If" + V"Class";
    While                = P"while" * WS * Parenthesis * V"Expression" * WS * V"StatementList";
    ForwardAssertFor     =(V"FunctionCall" + V"Name") * WS * P"|>" * WS * V"StatementList";
    NumericForItem       = Number + V"PrefixExpression";
    NumericFor           = P"for" * WS * P"(" * WS * Variable * WS * P"=" * WS * V"NumericForItem" * WS * P"," * WS *
                            V"NumericForItem" * (WS * P"," * WS * V"NumericForItem") ^ -1 * WS * P"do" * WS *
                            V"StatementList";
    IteratorFor          = P"for" * WS * P"(" * WS * V"VariableList" * WS * P"in" * WS * V"ExpressionList" * WS * P")" *
                            V"StatementList";
    If                   = P"if" * WS * P"(" * WS * V"Expression" * P")" * WS * V"StatementList" * (WS * P"else" * WS *
                            V"StatementList") ^ -1;
    ClassAttributeField  = Variable * WS * P"=" * WS * V"Expression" * P";";
    ClassFunctionField   = Variable * WS * V"AnonymousFunction";
    ClassField           = V"ClassAttributeField" + V"ClassFunctionField";
    Class                = P"new" * (WSOnce * Variable) ^ -1 * WS * (P"extends" * WSOnce * V"Expression" * WS) ^ -1 *
                            P"{" * (WS * V"ClassField") ^ 0 * WS * P"}";
    File                 = Shebang ^ -1 * (V"Statement" * (WS * V"Statement") ^ 0) ^ -1;
}