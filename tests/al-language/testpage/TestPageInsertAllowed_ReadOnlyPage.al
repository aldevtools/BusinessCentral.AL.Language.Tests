// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-new-method
// Scope: in-scope
// Fixtures used: Test Page Insert Allowed Row (60698), Test Page Insert ReadOnly (60700)
//
// Contrast case: a page that genuinely forbids inserts. TestPage.New() must still throw here —
// this pins the fix to "honour the declared property" rather than "always allow", which would
// be the same silent fake in the opposite direction.

page 60700 "Test Page Insert ReadOnly"
{
    PageType = List;
    SourceTable = "Test Page Insert Allowed Row";
    ApplicationArea = All;
    UsageCategory = Lists;
    InsertAllowed = false;

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
