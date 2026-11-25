// @expect AL0105 | Syntax error, identifier expected; 'fieldgroups' is a keyword
// The member FieldGroups, unquoted, in an option variable's member list, `O: Option Zero,FieldGroups;` (al-runner issue 8657).
// Quoted, as "FieldGroups", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53571 "MNC KO3571"
{
    procedure P()
    var
        O: Option Zero,FieldGroups;

    begin
    end;
}
