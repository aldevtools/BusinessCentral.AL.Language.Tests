// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): B ? Text[10] : Guid.
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Text[10]' which is shorter than the converted textual representation of a 'Guid'.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
        T: Text[10];
        G: Guid;
    begin
        Message('%1', B ? T : G);
    end;
}
