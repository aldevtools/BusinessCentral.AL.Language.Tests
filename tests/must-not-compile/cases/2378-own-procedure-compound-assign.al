// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'V' of 'P1(Integer)'
// A compound assignment to a one-parameter procedure: `P1 += 1` is checked as `P1() += 1`; only the plain `P1 := 1` is the call P1(1). (al-runner 7597)
codeunit 50000 "MNC C2378"
{
    procedure P1(V: Integer)
    begin
    end;

    procedure Run1()
    begin
        P1 += 1;
    end;
}
