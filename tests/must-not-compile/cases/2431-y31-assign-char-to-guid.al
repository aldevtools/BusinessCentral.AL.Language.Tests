// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Char assigned to Guid (Text and Code convert).
// @expect AL0122 | Cannot implicitly convert type 'Char' to 'Guid'. Use an explicit conversion or change the type.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        Ch: Char;
        G: Guid;
    begin
        G := Ch;
    end;
}
