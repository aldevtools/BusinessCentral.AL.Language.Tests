// @expect AL0105 | Syntax error, identifier expected; 'false' is a keyword
// The member False, unquoted, in the first member of an option variable, `O: Option False,Zero;` (al-runner issue 8657).
// Quoted, as "False", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53584 "MNC KO3584"
{
    procedure P()
    var
        O: Option False,Zero;

    begin
    end;
}
