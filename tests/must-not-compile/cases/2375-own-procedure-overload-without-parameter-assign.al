// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// Two overloads, one without a parameter: `POv := 1` picks POv() and is refused; the one-parameter overload is not tried. (al-runner 7597)
codeunit 50000 "MNC C2375"
{
    procedure POv()
    begin
    end;

    procedure POv(V: Integer)
    begin
    end;

    procedure Run1()
    begin
        POv := 1;
    end;
}
