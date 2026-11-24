// @expect AL0105 | Syntax error, identifier expected; 'fieldattribute' is a keyword
// The member FieldAttribute, unquoted, in an option variable's member list, `O: Option Zero,FieldAttribute;` (al-runner issue 8657).
// Quoted, as "FieldAttribute", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53569 "MNC KO3569"
{
    procedure P()
    var
        O: Option Zero,FieldAttribute;

    begin
    end;
}
