// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefiltertestpagefilter-setfilter-method
// Scope: in-scope
// Fixtures used: Test Page Filter Position Row (60692), Test Page Filter Position List (60693)

page 60693 "Test Page Filter Position List"
{
    PageType = List;
    SourceTable = "Test Page Filter Position Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }
}
