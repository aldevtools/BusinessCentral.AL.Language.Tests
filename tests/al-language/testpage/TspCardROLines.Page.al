// Migrated from AL Runner tests/runner-extras/testpage-subpage-part (TspSrc.al).
/// <summary>
/// Identical to "TSP Card" except for the part it hosts. The card itself stays insertable,
/// so a runner that answered New() from the PARENT page's InsertAllowed would wrongly
/// allow the insert here.
/// </summary>
page 60854 "TSP Card RO Lines"
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
            part(Lines; "TSP Lines RO")
            {
                ApplicationArea = All;
                SubPageLink = ReportId = field(ReportId);
            }
        }
    }
}
