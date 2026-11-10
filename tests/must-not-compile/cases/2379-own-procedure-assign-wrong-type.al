// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
// The right side of `P1 := v` is checked as the argument of P1. (al-runner 7597)
codeunit 50000 "MNC C2379"
{
    procedure P1(V: Integer)
    begin
    end;

    procedure Run1()
    begin
        P1 := 'text';
    end;
}
