// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): B ? Date : DateTime.
// @expect AL0122 | Cannot implicitly convert type 'DateTime' to 'Date'. Use an explicit conversion or change the type.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
        D: Date;
        DT: DateTime;
    begin
        Message('%1', B ? D : DT);
    end;
}
