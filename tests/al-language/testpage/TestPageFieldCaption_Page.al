// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-caption-method
// Scope: in-scope
// Fixtures used: TP Field Caption Row (60993), TP Field Caption List (60938)
//
// Three controls, three caption sources:
//   PK     - no control Caption, no field Caption -> falls back to the field's name.
//   Klass  - no control Caption, field Caption = 'Severity' -> falls back to the field's Caption.
//   Chosen - control Caption = 'Control Cap', field Caption = 'Accept' -> the control wins.

page 60938 "TP Field Caption List"
{
    PageType = List;
    SourceTable = "TP Field Caption Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP Field Caption Rows';

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(PK; Rec.PK) { ApplicationArea = All; }
                field(Klass; Rec.Klass) { ApplicationArea = All; }
                field(Chosen; Rec.Chosen) { ApplicationArea = All; Caption = 'Control Cap'; }
            }
        }
    }
}
