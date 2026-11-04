// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-runmodal-method
// Scope: in-scope
// Fixtures used: Test RunModal LookupPage Row (60995), Test RunModal LookupPage List (60996)
//
// The page "Test RunModal LookupPage Row".LookupPageId names — a static Page.RunModal(0,
// Record) built from that table must resolve to THIS page.

page 60996 "Test RunModal LookupPage List"
{
    PageType = List;
    SourceTable = "Test RunModal LookupPage Row";
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
