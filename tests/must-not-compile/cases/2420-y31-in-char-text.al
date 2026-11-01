// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Char in [Text] (Char = Text compiles).
// @expect AL0122 | Cannot implicitly convert type 'Text' to 'Char'. Use an explicit conversion or change the type.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        Ch: Char;
        T: Text;
    begin
        if Ch in [T] then;
    end;
}
