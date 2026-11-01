// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Duration assigned to Text.
// @expect AL0122 | Cannot implicitly convert type 'Duration' to 'Text'. Use an explicit conversion or change the type.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        Du: Duration;
        T: Text;
    begin
        T := Du;
    end;
}
