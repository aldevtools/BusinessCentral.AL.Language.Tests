// @expect AL0126 | No overload for method 'Get' takes 0 arguments
// List.Get has two overloads and none without arguments: `L.Get := 1` is refused. (al-runner 7597)
codeunit 50000 "MNC C2388"
{
    procedure Run1()
    var
        L: List of [Integer];
    begin
        L.Get := 1;
    end;
}
