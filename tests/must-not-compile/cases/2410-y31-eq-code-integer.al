// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): Code[10] = Integer.
// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Code[10]' and 'Integer'
codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        C: Code[10];
        I: Integer;
    begin
        if C = I then;
    end;
}
