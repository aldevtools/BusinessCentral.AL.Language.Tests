// Migrated from AL Runner tests/runner-extras/testpage-subpage-part (TspSrc.al).
/// <summary>
/// The canonical card-with-lines shape: a part bound to a related table, linked to the
/// current header row by SubPageLink. An AL test reaches the lines only through the part.
/// </summary>
page 60851 "TSP Card"
{
    PageType = Card;
    SourceTable = "TSP Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field(ReportId; Rec.ReportId)
            {
                ApplicationArea = All;
            }
            part(Lines; "TSP Lines")
            {
                ApplicationArea = All;
                SubPageLink = ReportId = field(ReportId);
            }
        }
    }
}
