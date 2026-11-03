// @expect AL0489 | The property expression is not valid. A CONST or FILTER expression is expected.
// A part's SubPageView names a field of the host with field() in its where() condition (only const and filter are valid in a view; field() belongs to SubPageLink).
table 50000 "MNC Head"
{
    fields { field(1; "Code"; Code[20]) { } }
    keys { key(PK; "Code") { Clustered = true; } }
}

table 50001 "MNC Line"
{
    fields { field(1; "Head Code"; Code[20]) { } field(2; "Line No."; Integer) { } }
    keys { key(PK; "Head Code", "Line No.") { Clustered = true; } }
}

page 50002 "MNC Line Part"
{
    PageType = ListPart;
    SourceTable = "MNC Line";

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(HeadCode; Rec."Head Code") { }
            }
        }
    }
}

page 50003 "MNC Host"
{
    PageType = Document;
    SourceTable = "MNC Head";

    layout
    {
        area(Content)
        {
            field(Code; Rec."Code") { }
            part(Lines; "MNC Line Part")
            {
                SubPageView = where("Head Code" = field("Code"));
            }
        }
    }
}
