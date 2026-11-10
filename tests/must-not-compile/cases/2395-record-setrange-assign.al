// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Field' of 'SetRange(Joker, [Joker], [Joker])'
// Record.SetRange has a required parameter and two optional ones: `Rec.SetRange := 1` is checked as SetRange() and refused. (al-runner 7597)
codeunit 50000 "MNC C2395"
{
    procedure Run1()
    var
        Row: Record "MNC C2395 Row";
    begin
        Row.SetRange := 1;
    end;
}

table 50001 "MNC C2395 Row"
{
    fields { field(1; Id; Integer) { } }
}
