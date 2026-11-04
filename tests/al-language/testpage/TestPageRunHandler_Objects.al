// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-handler
// Scope: in-scope
// Fixtures used: Test Page Run Handler Row (60748), Test Page Run Target (60749)
//
// Fixtures for the NON-modal Page.Run dispatch suite: one row table, and one card page over
// it that a test opens with Page.Run rather than RunModal.

table 60748 "Test Page Run Handler Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 60749 "Test Page Run Target"
{
    PageType = Card;
    SourceTable = "Test Page Run Handler Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
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
