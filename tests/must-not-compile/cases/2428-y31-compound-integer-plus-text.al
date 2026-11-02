// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Integer += Text.
// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Integer' and 'Text'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        I: Integer;
        T: Text;
    begin
        I += T;
    end;
}
