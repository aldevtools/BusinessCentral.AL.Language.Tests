// @expect AL0175 | Operator '=' cannot be applied to operands of type 'Codeunit "MNC This Compare"' and 'Codeunit "MNC This Compare"'
// Codeunit variables, also "this", cannot be compared.
codeunit 50000 "MNC This Compare"
{
    var
        "this": Codeunit "MNC This Compare";

    procedure P(): Boolean
    begin
        exit("this" = "this");
    end;
}
