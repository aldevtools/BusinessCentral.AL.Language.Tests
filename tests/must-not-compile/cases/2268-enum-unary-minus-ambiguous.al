// @expect AL0172 | Operator '-' is ambiguous on an operand of type 'Enum "MNC UF Enum"'
// Unary minus on an Enum operand (corpus: outside issue 6156). The binary operators accept an Enum as its ordinal (warning AL0603, tests in types/lt-uf-enum-arithmetic); the unary one is rejected.
enum 50000 "MNC UF Enum"
{
    value(0; Zero) { }
    value(1; One) { }
}

codeunit 50001 "MNC UF Caller"
{
    procedure Run1(): Integer
    var
        E: Enum "MNC UF Enum";
    begin
        E := E::One;
        exit(-E);
    end;
}
