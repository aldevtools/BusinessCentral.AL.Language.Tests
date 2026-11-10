// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// The member form of case 2375: `Cu.POv := 1` with overloads POv() and POv(Integer). (al-runner 7597)
codeunit 50000 "MNC C2383"
{
    procedure Run1()
    var
        Cu: Codeunit "MNC C2383 Target";
    begin
        Cu.POv := 1;
    end;
}

codeunit 50001 "MNC C2383 Target"
{
    procedure POv()
    begin
    end;

    procedure POv(V: Integer)
    begin
    end;
}
