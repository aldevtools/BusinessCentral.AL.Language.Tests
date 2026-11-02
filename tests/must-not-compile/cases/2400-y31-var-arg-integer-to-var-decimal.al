// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Integer variable passed to a var Decimal parameter (by value it converts).
// @expect AL0133 | Argument 1: cannot convert from 'Integer' to 'var Decimal'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        I: Integer;
    begin
        P(I);
    end;

    local procedure P(var D: Decimal) begin end;
}
