// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Date = DateTime.
// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Date' and 'DateTime'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        D: Date;
        DT: DateTime;
    begin
        if D = DT then;
    end;
}
