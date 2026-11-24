// @expect AL0105 | Syntax error, identifier expected; 'fieldelement' is a keyword
// The member FieldElement, unquoted, in an option variable's member list, `O: Option Zero,FieldElement;` (al-runner issue 8657).
// Quoted, as "FieldElement", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53570 "MNC KO3570"
{
    procedure P()
    var
        O: Option Zero,FieldElement;

    begin
    end;
}
