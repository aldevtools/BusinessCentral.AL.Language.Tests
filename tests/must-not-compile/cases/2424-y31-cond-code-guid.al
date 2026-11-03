// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): B ? Code[10] : Guid (B ? Text : Guid compiles).
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Code[10]' which is shorter than the converted textual representation of a 'Guid'.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        B: Boolean;
        C: Code[10];
        G: Guid;
    begin
        Message('%1', B ? C : G);
    end;
}
