// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Date += Date.
// @expect AL0175 | Operator '+=' cannot be applied to operands of type 'Date' and 'Date'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        D: Date;
        D2: Date;
    begin
        D += D2;
    end;
}
