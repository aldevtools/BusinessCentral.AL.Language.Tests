// @expect AL0126 | No overload for method 'SetTable' takes 0 arguments
// RecordRef.SetTable has two overloads and none without arguments: `RR.SetTable := Rec` is refused. (al-runner 7597)
codeunit 50000 "MNC C2396"
{
    procedure Run1()
    var
        RR: RecordRef;
        Row: Record "MNC C2396 Row";
    begin
        RR.SetTable := Row;
    end;
}

table 50001 "MNC C2396 Row"
{
    fields { field(1; Id; Integer) { } }
}
