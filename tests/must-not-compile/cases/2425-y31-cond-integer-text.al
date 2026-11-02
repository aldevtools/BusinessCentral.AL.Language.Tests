// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): B ? Integer : Text.
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Integer'. Use an explicit conversion or change the type.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
        I: Integer;
        T: Text;
    begin
        Message('%1', B ? I : T);
    end;
}
