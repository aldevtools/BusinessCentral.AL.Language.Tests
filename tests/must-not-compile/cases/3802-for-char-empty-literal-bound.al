// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
// A Char loop variable with an empty literal bound.
codeunit 50001 "MNC For Char Empty"
{
    procedure Run1()
    var
        c: Char;
    begin
        for c := '' to 'e' do
            ;
    end;
}
