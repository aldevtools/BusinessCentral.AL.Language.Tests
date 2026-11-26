// @expect AL0132 | 'Record "MNC Cnt Row"' does not contain a definition for 'FieldCount'
// Rec.FieldCount on a page: Record has no FieldCount method.
table 50002 "MNC Cnt Row"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}
page 50003 "MNC Cnt FieldCount"
{
    PageType = List;
    SourceTable = "MNC Cnt Row";
    ApplicationArea = All;
    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { }
                field(Total; Rec.FieldCount) { }
            }
        }
    }
}
