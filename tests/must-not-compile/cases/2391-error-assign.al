// @expect AL0126 | No overload for method 'Error' takes 0 arguments
// Error has two overloads and none without arguments: `Error := 'x'` is refused. (al-runner 7597)
codeunit 50000 "MNC C2391"
{
    procedure Run1()
    begin
        Error := 'x';
    end;
}
