// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope
// Fixtures used: TP Blank Temporal Row (60660)
//
// Three Rec-bound temporal controls plus a page-VARIABLE-bound DateTime control. The variable
// one is not redundant: a control bound to a page global round-trips through different runtime
// plumbing than one bound to a source-table field (same reasoning as
// TestPageBooleanRecBound_Page.al), and Base Application page 9807 "User Card" renders its blank
// WebServiceExpiryDate through exactly the variable-bound shape.
//
// GlobalWhen is deliberately left unassigned by the page — no OnOpenPage, no OnAfterGetRecord —
// so its value is the AL type default and nothing else, which is precisely the state under test.

page 60661 "TP Blank Temporal Card"
{
    PageType = Card;
    SourceTable = "TP Blank Temporal Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP Blank Temporal Card';

    layout
    {
        area(Content)
        {
            field(RecMarker; Rec.Marker)
            {
                ApplicationArea = All;
                Caption = 'Rec Marker';
            }

            field(RecWhen; Rec."When")
            {
                ApplicationArea = All;
                Caption = 'Rec When';
            }

            field(RecOn; Rec."On")
            {
                ApplicationArea = All;
                Caption = 'Rec On';
            }

            field(RecAt; Rec."At")
            {
                ApplicationArea = All;
                Caption = 'Rec At';
            }

            field(GlobalWhen; GlobalWhen)
            {
                ApplicationArea = All;
                Caption = 'Global When';
                Editable = false;
            }
        }
    }

    var
        GlobalWhen: DateTime;
}
