// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// Unquoted this is always the keyword: assigning to it does not compile even when a variable "this" is declared (tests/al-language/types/lt-y73-quoted-this/, writer Y73; al-runner issue 6750).
codeunit 50000 "MNC This Assign"
{
    var
        "this": Integer;

    procedure P()
    begin
        this := 5;
    end;
}
