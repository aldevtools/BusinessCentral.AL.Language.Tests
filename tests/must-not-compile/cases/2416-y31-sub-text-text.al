// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Text - Text.
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Text' and 'Text'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        T: Text;
        T2: Text;
    begin
        Message('%1', T - T2);
    end;
}
