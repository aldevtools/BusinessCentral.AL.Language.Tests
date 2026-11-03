// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test Page GoToRecord Row (60695), Test Page GoToRecord List (60696)
//
// The TestPage under test. A plain list page over "Test Page GoToRecord Row" — GoToRecord's
// job is to move the page's cursor onto the row identified by the record's primary key.

page 60696 "Test Page GoToRecord List"
{
    PageType = List;
    SourceTable = "Test Page GoToRecord Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
