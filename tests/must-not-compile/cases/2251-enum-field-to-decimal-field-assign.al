// @expect AL0122 | Cannot implicitly convert type 'Enum "MNC TL 2251"' to 'Decimal'. Use an explicit conversion or change the type.
// An Enum field of a record is assigned to a Decimal field of a record.
enum 52253 "MNC TL 2251"
{
    value(0; A) { }
    value(5; B) { }
}

table 52254 "MNC TL 2251 Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "MNC TL 2251") { }
        field(3; Amount; Decimal) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 52255 "MNC TL 2251 Cu"
{
    procedure Run1()
    var
        Source: Record "MNC TL 2251 Rec";
        Target: Record "MNC TL 2251 Rec" temporary;
    begin
        Target.Amount := Source.Kind;
    end;
}
