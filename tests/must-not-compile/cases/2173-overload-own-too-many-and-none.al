// @expect AL0126 | No overload for method 'Pick' takes 3 arguments. Candidates: 'Pick(Integer, Integer)' defined in Codeunit 'MNC SH Caller' by the extension Must Not Compile by AL Language (1.0.0.0), 'Pick(Text)' defined in Codeunit 'MNC SH Caller' by the extension Must Not Compile by AL Language (1.0.0.0)
// @expect AL0126 | No overload for method 'Pick' takes 0 arguments. Candidates: 'Pick(Integer, Integer)' defined in Codeunit 'MNC SH Caller' by the extension Must Not Compile by AL Language (1.0.0.0), 'Pick(Text)' defined in Codeunit 'MNC SH Caller' by the extension Must Not Compile by AL Language (1.0.0.0)
// An overloaded local procedure called with too many and with no arguments: AL0126 for both calls.
codeunit 50002 "MNC SH Caller"
{
    local procedure Pick(A: Integer; B: Integer)
    begin
    end;

    local procedure Pick(A: Text)
    begin
    end;

    procedure Run1()
    begin
        Pick(1, 2, 3);
        Pick();
    end;
}
