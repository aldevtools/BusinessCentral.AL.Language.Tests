// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Text += Integer.
// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Text' and 'Integer'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        T: Text;
        I: Integer;
    begin
        T += I;
    end;
}
