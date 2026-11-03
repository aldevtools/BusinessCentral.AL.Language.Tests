// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-minvalue-property
// Scope: in-scope
// Fixtures used: Test Page MinMax Row (60908)
//
// A plain card page over the bounded table — nothing more is needed to reach TestPage field
// SetValue.

page 60909 "Test Page MinMax Card"
{
    PageType = Card;
    SourceTable = "Test Page MinMax Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Completion; Rec.Completion)
            {
                ApplicationArea = All;
            }
            field(Score; Rec.Score)
            {
                ApplicationArea = All;
            }
        }
    }
}
