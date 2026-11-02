// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Boolean < Integer.
// @expect AL0175 | Operator '<' cannot be applied to operands of type 'Boolean' and 'Integer'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
        I: Integer;
    begin
        if B < I then;
    end;
}
