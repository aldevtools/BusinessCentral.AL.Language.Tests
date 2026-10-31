// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): DateFormula < DateFormula (= compiles).
// @expect AL0175 | Operator '<' cannot be applied to operands of type 'DateFormula' and 'DateFormula'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        F: DateFormula;
        F2: DateFormula;
    begin
        if F < F2 then;
    end;
}
