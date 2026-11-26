// @expect AL0136 | The loop variable in a 'for' statement must be a numeric type
// A Text loop variable with one-character literal bounds.
codeunit 50001 "MNC For Text Var"
{
    procedure Run1()
    var
        t: Text;
    begin
        for t := '0' to '4' do
            ;
    end;
}
