// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'A' of 'P2(Integer, Integer)'
// The member form of case 2374: `Cu.P2 := 1` where P2 has two parameters. (al-runner 7597)
codeunit 50000 "MNC C2382"
{
    procedure Run1()
    var
        Cu: Codeunit "MNC C2382 Target";
    begin
        Cu.P2 := 1;
    end;
}

codeunit 50001 "MNC C2382 Target"
{
    procedure P2(A: Integer; B: Integer)
    begin
    end;
}
