// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// Record.LockTable has only optional parameters: the assignment form is refused. (al-runner 6526; writer Y29)
codeunit 50000 "MNC C2370"
{
    procedure Run1()
    var
        R: Record "MNC Y29 Row";
    begin
        R.LockTable := true;
    end;
}

table 50001 "MNC Y29 Row"
{
    fields { field(1; Id; Integer) { } }
}
