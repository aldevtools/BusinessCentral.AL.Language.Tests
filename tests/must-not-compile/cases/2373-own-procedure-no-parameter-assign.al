// @expect AL0129 | The left-hand side of an assignment must be a variable or field
// A procedure without a parameter: `P0 := 1` is checked as `P0() := 1`. The form compiles only for a procedure with exactly one parameter (tests/al-language/codeunits/procedures/AssignIsCallRule.al). (al-runner 7597)
codeunit 50000 "MNC C2373"
{
    procedure P0()
    begin
    end;

    procedure Run1()
    begin
        P0 := 1;
    end;
}
