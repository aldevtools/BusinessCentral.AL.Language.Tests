// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-visible-method
// Scope: in-scope
// Fixtures used: (none — the table below is the card page's SourceTable)
//
// One page global drives three control properties — a control's own Visible, its Editable and
// its Enabled — so a test can change that global after the page is open and read all three.
// Each control binds to its own source field, because controls sharing one field are a separate
// question (codeunit 60263) and mixing the two makes a failure ambiguous.
//
// Toggle is bound to the global itself, and its OnValidate calls CurrPage.Update, which is how
// the existing group-visibility suite (codeunit 60961) flips a page variable mid-test.

table 60264 "TPCL Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; A; Text[30]) { }
        field(3; B; Text[30]) { }
        field(4; C; Text[30]) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}

page 60265 "TPCL Card"
{
    PageType = Card;
    SourceTable = "TPCL Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPCL Card';

    layout
    {
        area(Content)
        {
            field(VisibleCtl; Rec.A)
            {
                ApplicationArea = All;
                Caption = 'Visible Ctl';
                Visible = not HideIt;
            }

            field(EditableCtl; Rec.B)
            {
                ApplicationArea = All;
                Caption = 'Editable Ctl';
                Editable = not HideIt;
            }

            field(EnabledCtl; Rec.C)
            {
                ApplicationArea = All;
                Caption = 'Enabled Ctl';
                Enabled = not HideIt;
            }

            field(Toggle; HideIt)
            {
                ApplicationArea = All;
                Caption = 'Toggle';

                trigger OnValidate()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        HideIt: Boolean;
}
