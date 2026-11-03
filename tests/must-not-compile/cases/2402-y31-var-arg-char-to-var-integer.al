// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Char variable passed to a var Integer parameter.
// @expect AL0133 | Argument 1: cannot convert from 'Char' to 'var Integer'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        Ch: Char;
    begin
        P(Ch);
    end;

    local procedure P(var I: Integer) begin end;
}
