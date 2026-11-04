// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-caption-method
// Scope: in-scope
// Fixtures used: TP Caption Row (60992), TP Static Caption Card (60936), TP Dynamic Caption Card (60937)
//
// Two pages that share a static Caption property; one of them overwrites it at runtime via
// CurrPage.Caption in OnOpenPage. TestPage.Caption() must reflect the runtime value once it has
// been set, and the compile-time value when it hasn't.

page 60936 "TP Static Caption Card"
{
    PageType = Card;
    SourceTable = "TP Caption Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Static Caption';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }
}

page 60937 "TP Dynamic Caption Card"
{
    PageType = Card;
    SourceTable = "TP Caption Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'Static Caption';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
        }
    }

    trigger OnOpenPage()
    begin
        CurrPage.Caption := 'Dynamic Caption';
    end;
}
