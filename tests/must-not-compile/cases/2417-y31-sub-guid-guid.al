// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Guid - Guid.
// @expect AL0175 | Operator '-' cannot be applied to operands of type 'Guid' and 'Guid'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        G: Guid;
        G2: Guid;
    begin
        Message('%1', G - G2);
    end;
}
