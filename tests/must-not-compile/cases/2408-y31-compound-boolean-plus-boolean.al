// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Boolean += Boolean.
// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Boolean' and 'Boolean'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
        B2: Boolean;
    begin
        B += B2;
    end;
}
