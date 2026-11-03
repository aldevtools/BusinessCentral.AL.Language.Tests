// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC TL 2250"' to 'Decimal'. Use an explicit conversion or change the type.
// An Enum value literal is assigned to a Decimal.
enum 52251 "MNC TL 2250"
{
    value(0; A) { }
    value(5; B) { }
}

codeunit 52252 "MNC TL 2250 Cu"
{
    procedure Run1()
    var
        D: Decimal;
    begin
        D := "MNC TL 2250"::B;
    end;
}
