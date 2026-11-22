// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
// A Char loop variable with a multi-character literal bound.
codeunit 50001 "MNC For Char Multi"
{
    procedure Run1()
    var
        c: Char;
    begin
        for c := '0' to '45' do
            ;
    end;
}
