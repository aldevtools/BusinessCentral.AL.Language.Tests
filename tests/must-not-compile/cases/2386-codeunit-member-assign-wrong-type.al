// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// The member form of case 2379: `Cu.P1 := 'text'`. (al-runner 7597)
codeunit 50000 "MNC C2386"
{
    procedure Run1()
    var
        Cu: Codeunit "MNC C2386 Target";
    begin
        Cu.P1 := 'text';
    end;
}

codeunit 50001 "MNC C2386 Target"
{
    procedure P1(V: Integer)
    begin
    end;
}
