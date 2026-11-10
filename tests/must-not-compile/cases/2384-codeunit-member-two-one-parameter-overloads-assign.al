// @expect AL0126 | No overload for method 'PTwo' takes 0 arguments
// The member form of case 2376: `Cu.PTwo := 1` with overloads PTwo(Integer) and PTwo(Text). (al-runner 7597)
codeunit 50000 "MNC C2384"
{
    procedure Run1()
    var
        Cu: Codeunit "MNC C2384 Target";
    begin
        Cu.PTwo := 1;
    end;
}

codeunit 50001 "MNC C2384 Target"
{
    procedure PTwo(V: Integer)
    begin
    end;

    procedure PTwo(V: Text)
    begin
    end;
}
