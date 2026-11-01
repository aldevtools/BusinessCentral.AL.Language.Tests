// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): one-character literal + Byte is ambiguous.
// @expect AL0174 | Operator '+' is ambiguous on operands of type 'Char' and 'Byte'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        By: Byte;
    begin
        Message('%1', 'a' + By);
    end;
}
