// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Code[10] variable passed to a var Text parameter.
// @expect AL0133 | Argument 1: cannot convert from 'Code[10]' to 'var Text'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        C: Code[10];
    begin
        P(C);
    end;

    local procedure P(var T: Text) begin end;
}
