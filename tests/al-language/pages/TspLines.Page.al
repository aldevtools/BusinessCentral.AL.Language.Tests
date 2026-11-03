// Migrated from AL Runner tests/runner-extras/testpage-subpage-part (TspSrc.al).
page 60852 "TSP Lines"
{
    PageType = ListPart;
    SourceTable = "TSP Line";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(LineNo; Rec.LineNo)
                {
                    ApplicationArea = All;
                }
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
