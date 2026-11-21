// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '[' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ']' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// An enum value named In is a keyword: "Enum"::In needs quotes ("Enum"::"In" compiles).
// The quoted form "Enum"::"In" compiles (AL 16, 17, 18 and 30). AL 16 stops the texts after the first sentence; AL 17 and later append an explanation.
enum 53160 "MNC OI3160 E" { value(0; "In") { } value(1; Out) { } }

codeunit 53161 "MNC OI3160 C"
{
    procedure GetIn(): Integer
    begin
        exit("MNC OI3160 E"::In.AsInteger());
    end;
}
