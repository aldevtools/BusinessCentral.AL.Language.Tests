// Implicit conversion matrix (scripts/conversion-matrix/compile-matrix.csv, writer Y31): case on a Decimal with an Enum label.
// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC Y31 E"' to 'Decimal'. Use an explicit conversion or change the type.
enum 50001 "MNC Y31 E"
{
    value(0; A) { }
}

codeunit 50000 "MNC Y31 Case"
{
    procedure Probe()
    var
        D: Decimal;
        E: Enum "MNC Y31 E";
    begin
        case D of E: ; end;
    end;
}
