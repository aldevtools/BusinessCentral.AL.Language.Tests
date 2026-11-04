// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page Enum Field Row (60689), Test Page Enum Field Card (60690)

page 60690 "Test Page Enum Field Card"
{
    PageType = Card;
    SourceTable = "Test Page Enum Field Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Kind; Rec.Kind) { ApplicationArea = All; }
                field(Grade; Rec.Grade) { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}
