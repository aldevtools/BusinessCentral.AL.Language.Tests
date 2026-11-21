// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '[' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ']' expected
// @expect AL0111 | Semicolon expected
// An option member named In is a keyword: D::In on an Option variable needs quotes (D::"In" compiles).
// The quoted form D::"In" compiles (AL 16, 17, 18 and 30). AL 16 stops the texts after the first sentence; AL 17 and later append an explanation.
codeunit 53159 "MNC OI3159 C"
{
    procedure GetIn(): Integer
    var
        D: Option "In","Out";
    begin
        D := D::In;
        exit(D);
    end;
}
