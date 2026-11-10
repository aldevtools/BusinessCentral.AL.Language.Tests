// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// Record.Insert has an overload without a parameter: `Rec.Insert := true` picks Insert() and is refused. `Rec.Modify := true` and `Rec.Delete := true` (one optional parameter, no other overload) compile. (al-runner 7597)
codeunit 50000 "MNC C2387"
{
    procedure Run1()
    var
        Row: Record "MNC C2387 Row";
    begin
        Row.Insert := true;
    end;
}

table 50001 "MNC C2387 Row"
{
    fields { field(1; Id; Integer) { } }
}
