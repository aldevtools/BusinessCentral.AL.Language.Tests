// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Code[10] in [Guid] (Text in [Guid] compiles).
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Code[10]' which is shorter than the converted textual representation of a 'Guid'.
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        C: Code[10];
        G: Guid;
    begin
        if C in [G] then;
    end;
}
