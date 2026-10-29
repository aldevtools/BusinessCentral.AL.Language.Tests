// @expect AL0383 | The option value 'Nope' is not defined on field 'Src'.
// SubPageLink const with a bare enum value that the enum does not declare.
enum 50000 "MNC UJ Src"
{
    value(0; Resource) { }
    value(1; Header) { }
}

table 50000 "MNC UJ Line"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Src; Enum "MNC UJ Src") { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC UJ Part"
{
    PageType = ListPart;
    SourceTable = "MNC UJ Line";
    layout { area(Content) { repeater(R) { field(IdCtl; Rec.Id) { } } } }
}

page 50002 "MNC UJ Card"
{
    PageType = Card;
    SourceTable = "MNC UJ Line";
    layout
    {
        area(Content)
        {
            part(Lines; "MNC UJ Part")
            {
                SubPageLink = Src = const(Nope);
            }
        }
    }
}
