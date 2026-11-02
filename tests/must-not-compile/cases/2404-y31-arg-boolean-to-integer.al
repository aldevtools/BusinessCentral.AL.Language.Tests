// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Boolean passed to an Integer parameter.
// @expect AL0133 | Argument 1: cannot convert from 'Boolean' to 'Integer'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
    begin
        P(B);
    end;

    local procedure P(I: Integer) begin end;
}
