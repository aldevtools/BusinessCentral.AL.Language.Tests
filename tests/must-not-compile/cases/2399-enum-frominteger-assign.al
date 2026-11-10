// @expect AL0135 | There is no argument given that corresponds to the required formal parameter 'Value' of 'FromInteger(Integer)'
// The static form `Enum::"E".FromInteger := 1` is refused although FromInteger is one method with one parameter. (al-runner 7597)
codeunit 50000 "MNC C2399"
{
    procedure Run1()
    begin
        Enum::"MNC C2399 Enum".FromInteger := 1;
    end;
}

enum 50001 "MNC C2399 Enum"
{
    value(0; None) { }
    value(1; One) { }
}
