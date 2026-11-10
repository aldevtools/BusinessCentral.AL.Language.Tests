// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'V' of 'P1(Integer)'
// The member form of case 2378: `Cu.P1 += 1`. (al-runner 7597)
codeunit 50000 "MNC C2385"
{
    procedure Run1()
    var
        Cu: Codeunit "MNC C2385 Target";
    begin
        Cu.P1 += 1;
    end;
}

codeunit 50001 "MNC C2385 Target"
{
    procedure P1(V: Integer)
    begin
    end;
}
