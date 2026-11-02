// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): exit(Guid) from a procedure that returns Text[10].
// @expect AL0777 | The implicit conversion will overflow when converting from a 'Guid' to a 'Text[10]' which is shorter than the converted textual representation of a 'Guid'.
codeunit 50000 "MNC Y31 Case"
{

    local procedure F(G: Guid): Text[10] begin exit(G); end;
}
