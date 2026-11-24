// @expect AL0105 | Syntax error, identifier expected; 'event' is a keyword
// The member Event, unquoted, in an option variable's member list, `O: Option Zero,Event;` (al-runner issue 8657).
// Quoted, as "Event", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53566 "MNC KO3566"
{
    procedure P()
    var
        O: Option Zero,Event;

    begin
    end;
}
