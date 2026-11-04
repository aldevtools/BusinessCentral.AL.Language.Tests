// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-editable-method
// Scope: in-scope
// Fixtures used: (none — the table below is the card page's SourceTable)
//
// Two controls over the SAME source-table field, distinguished only by their own properties. A
// page showing one field twice under different conditions is ordinary AL, and it is also how a
// page shows one field in two groups with different visibility.
//
// The two controls are told apart by Editable, not by Visible. A literal `Visible = false` is
// dead-code-eliminated by the AL compiler: the control never exists on the runtime page, so a
// TestPage reference to it raises "field ... is not found on the page" instead of reporting a
// property. A literal `Editable = false` is not eliminated, so the control stays on the page and
// its own Editable is what a test reads.
//
// ThirdOverOwnField exists so a failure that collapses every control onto the first one can be
// told apart from a failure that collapses only the controls sharing a source field.

table 60261 "TPSF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; PK; Code[10]) { }
        field(2; Shared; Text[30]) { }
        field(3; Other; Text[30]) { }
    }

    keys
    {
        key(K; PK) { Clustered = true; }
    }
}

page 60262 "TPSF Card"
{
    PageType = Card;
    SourceTable = "TPSF Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPSF Card';

    layout
    {
        area(Content)
        {
            // Declares no Editable of its own, so it inherits the page's, which is editable.
            field(FirstOverShared; Rec.Shared)
            {
                ApplicationArea = All;
                Caption = 'First Over Shared';
            }

            // Same source field, its own Editable.
            field(SecondOverShared; Rec.Shared)
            {
                ApplicationArea = All;
                Caption = 'Second Over Shared';
                Editable = false;
            }

            field(ThirdOverOwnField; Rec.Other)
            {
                ApplicationArea = All;
                Caption = 'Third Over Own Field';
                Editable = false;
            }
        }
    }
}
