// @expect AL0126 | No overload for method 'PMix' takes 0 arguments
// Overloads with one and with two parameters: `PMix := 1` is refused although only one overload takes one argument. (al-runner 7597)
codeunit 50000 "MNC C2377"
{
    procedure PMix(V: Integer)
    begin
    end;

    procedure PMix(A: Integer; B: Integer)
    begin
    end;

    procedure Run1()
    begin
        PMix := 1;
    end;
}
