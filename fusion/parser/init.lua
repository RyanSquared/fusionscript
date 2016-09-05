-- Import LPeg variables

local lpeg = require("lpeg")
local P, V, S, R = lpeg.P, lpeg.V, lpeg.S

-- Somewhat out of place patterns

local Space      = P" "
local WS         = S" \t\r\n\v" ^ 0
local EndOfLine  = P"\r" ^ -1 * P"\n"
local Shebang    = P"#!" * P(1 - EndOfLine) ^ 0 * EndOfLine
-- ::TODO:: comments

-- Number parsers

local Length    = (S"uU" ^ -1 * S"lL" ^ -2) ^ -1
local Integer   = R"09" ^ 1
local HexNumber = P"0x" * R("09", "af", "AF") * S"pP" * S"+-" * Integer
local DecNumber = Integer ^ -1 * (P"." * Integer)
local IntNumber = Integer * Length
local Extension = S"eE" * P"-" ^ -1
local Number = (HexNumber + DecNumber + IntNumber) * Extension ^ -1

-- Strings

local SingleQuote = P"'"
local DoubleQuote = P'"'
local FullEscape  = P"\\" * P(1)

local SingleQuoteString = SingleQuote * (P(1) - SingleQuote) ^ 0 * SingleQuote
local DoubleQuoteString = DoubleQuote * ((FullEscape + P(1)) - P"\\" *
    DoubleQuote) ^ 0 * DoubleQuote
    -- match either an escape sequence or single byte that is not '\"'

local String = SingleQuoteString + DoubleQuoteString

-- Booleans

local True = P"true"
local False = P"false"
local Boolean = True + False

-- Nil

local Nil = P"nil"

-- Import LPeg variables

local lpeg = require("lpeg")
local P, R = lpeg.P, lpeg.R

-- Variable names

local Upper  = R"AZ"
local Lower  = R"az"
local Letter = Upper + Lower

local VariableName = (Letter + P"_") * (Letter + P"_" + Integer) ^ 0
local Filters = P(false)
local Keywords = {"else", "if", "true", "false", "nil", "while", "do", "new"}
for key, word in pairs(Keywords)
    Filters = Filters + P(word)
end
local Variable = VariableName - Filters

-- Binary symbol pattern

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
    FunctionCall        = V"PrefixExpression" * V"Arguments" + V"PrefixExpression" *
        P":" * Variable * V"Arguments";
    PrefixExpression    = V"Name" + V"FunctionCall" + P"(" * WS * V"Expression" *
        WS * P")";
    Name                = Variable + V"PrefixExpression" * WS * P"[" * WS *
        V"Expression" * WS * P"]" + V"PrefixExpression" *WS * P"." * WS *
        Variable;
    Expression          = V"Literal" + P"..." + V"PrefixExpression" +
        V"Expression" * WS * BinarySymbol * WS * V"Expression" + UnarySymbol * WS
        * V"Expression";
    Literal             = V"TableConstructor" + V"FunctionDeclaration" + V"Class" +
        Number + String + Boolean + Nil;
    Arguments           = P"(" * V"ExpressionList" * V")";
    ExpressionList      = V"Expression" * (WS * P"," * WS * V"Expression") ^ 0;
    TableConstructor    = P"{" * WS * V"TableFieldList" * WS * P"}";
    TableFieldList      = V"TableField" * (WS * P"," * WS * V"TableField") ^ 0;
    TableField          = P"[" * WS * V"Expression" * WS * P"]" * WS * P"=" *
        V"Expression" + Variable * WS * P"=" * WS * V"Expression" +
        V"Expression";
    FunctionDeclaration = P"(" * WS * V"VariableList" * WS * P")" * WS * (P"-" +
        P"=") * P">" * WS * V"StatementList";
    VariableList        = Variable * (WS * P"," * WS * Variable) ^ 0;
    Assignment          = V"VariableList" * WS * P"=" * WS * V"ExpressionList";
    StatementList       = V"Statement" + P"{" * V"Statement" * (WS *
        V"Statement") ^ 0 * P"}";
    Statement           = (P"return" * WS * V"ExpressionList" + P";" +
        V"Assignment" + P"break" + V"While" + V"For" + V"If" + V"Class") * WS *
        P";";
    While               = P"while" * WS * V"Expression" * V"StatementList";
    For                 = (V"FunctionCall" + V"Name") * WS * (P"|>" + P"|" *
        V"Arguments" * P">") * WS * StatementList;
    If                  = P"if" * WS * V"Expression" * WS * StatementList *
        (WS * P"else" * WS * V"Statement") ^ 0
    Class               = P"new" * (WS * Variable) ^ -1 * V"TableConstructor" *
        (WS * P"::" * WS * Variable) ^ -1  
    File                = Shebang ^ -1 * (V"Statement" * (WS * V"Statement") ^
        0) ^ -1
}