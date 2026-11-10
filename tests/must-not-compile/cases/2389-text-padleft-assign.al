// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Count' of 'PadLeft(Integer, [Char])'
// Text.PadLeft has a required and an optional parameter: `Txt.PadLeft := 5` is checked as PadLeft() and refused. (al-runner 7597)
codeunit 50000 "MNC C2389"
{
    procedure Run1()
    var
        Txt: Text;
    begin
        Txt.PadLeft := 5;
    end;
}
