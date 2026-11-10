// @expect AL0126 | No overload for method 'PTwo' takes 0 arguments
// Two overloads with one parameter each: `PTwo := 1` is refused although PTwo(1) compiles; the right side does not pick the overload. (al-runner 7597)
codeunit 50000 "MNC C2376"
{
    procedure PTwo(V: Integer)
    begin
    end;

    procedure PTwo(V: Text)
    begin
    end;

    procedure Run1()
    begin
        PTwo := 1;
    end;
}
