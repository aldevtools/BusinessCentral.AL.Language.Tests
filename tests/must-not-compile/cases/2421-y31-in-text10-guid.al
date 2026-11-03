// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Text[10] in [Guid].
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Text[10]' which is shorter than the converted textual representation of a 'Guid'.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        T: Text[10];
        G: Guid;
    begin
        if T in [G] then;
    end;
}
