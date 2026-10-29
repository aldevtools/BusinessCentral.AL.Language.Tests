// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC TL 2249"' to 'Decimal'. Use an explicit conversion or change the type.
// An Enum variable is assigned to a Decimal. Unlike an Option, an Enum has no implicit conversion to a number (al-runner issue 6060).
enum 52249 "MNC TL 2249"
{
    value(0; A) { }
    value(5; B) { }
}

codeunit 52250 "MNC TL 2249 Cu"
{
    procedure Run1()
    var
        K: Enum "MNC TL 2249";
        D: Decimal;
    begin
        K := K::B;
        D := K;
    end;
}
