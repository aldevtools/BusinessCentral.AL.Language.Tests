// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Option assigned to Text.
// @expect AL0122 | Cannot implicitly convert type 'Option' to 'Text'. Use an explicit conversion or change the type.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        O: Option A,B;
        T: Text;
    begin
        T := O;
    end;
}
