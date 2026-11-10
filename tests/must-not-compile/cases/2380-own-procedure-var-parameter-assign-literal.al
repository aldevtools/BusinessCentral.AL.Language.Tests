// @expect AL0130 | A 'var' argument must be an assignable variable
// A procedure with one `var` parameter: `P1Var := 5` is the call P1Var(5), and a literal is no `var` argument. `P1Var := I` compiles. (al-runner 7597)
codeunit 50000 "MNC C2380"
{
    procedure P1Var(var V: Integer)
    begin
    end;

    procedure Run1()
    begin
        P1Var := 5;
    end;
}
