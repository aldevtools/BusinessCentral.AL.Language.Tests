// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page Insert Allowed Row (60698), Test Page Insertable (60699),
//   Test Page Insert ReadOnly (60700)
//
// Ordinary list page. Declares no InsertAllowed property, so AL's default applies: inserting
// through the page IS allowed and TestPage.New() must work.

page 60699 "Test Page Insertable"
{
    PageType = List;
    SourceTable = "Test Page Insert Allowed Row";
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
