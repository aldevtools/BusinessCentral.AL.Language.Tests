// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): one-character literal passed to an Integer parameter (I := 'a' compiles).
// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Integer'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    begin
        P('a');
    end;

    local procedure P(I: Integer) begin end;
}
