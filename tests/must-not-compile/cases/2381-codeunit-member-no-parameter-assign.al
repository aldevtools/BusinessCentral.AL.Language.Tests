// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// The member form of case 2373: `Cu.P0 := 1` where P0 has no parameter. (al-runner 7597)
codeunit 50000 "MNC C2381"
{
    procedure Run1()
    var
        Cu: Codeunit "MNC C2381 Target";
    begin
        Cu.P0 := 1;
    end;
}

codeunit 50001 "MNC C2381 Target"
{
    procedure P0()
    begin
    end;
}
