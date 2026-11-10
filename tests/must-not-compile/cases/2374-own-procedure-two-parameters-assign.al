// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'A' of 'P2(Integer, Integer)'
// A procedure with two parameters: `P2 := 1` is checked as `P2() := 1`, and P2() lacks its arguments. (al-runner 7597)
codeunit 50000 "MNC C2374"
{
    procedure P2(A: Integer; B: Integer)
    begin
    end;

    procedure Run1()
    begin
        P2 := 1;
    end;
}
