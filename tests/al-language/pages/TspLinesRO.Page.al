// Migrated from AL Runner tests/runner-extras/testpage-subpage-part (TspSrc.al).
/// <summary>
/// A read-only lines part. Its own page — not the parent card — declares
/// InsertAllowed = false, which is what New() through the part must obey.
/// </summary>
page 60853 "TSP Lines RO"
{
    PageType = ListPart;
    SourceTable = "TSP Line";
    ApplicationArea = All;
    InsertAllowed = false;

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
