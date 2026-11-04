// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-editable-method
// Scope: in-scope
// Fixtures used: Test Page Editable Row (60685), Test Page Editable Card (60686)
//
// A card whose read-only contract is expressed the two ways AL expresses it: a constant
// Editable = false for a control that is never writable, and Editable = RowEditable for one
// that depends on the row currently loaded.
//
// Both are ordinary AL and both are how a real app protects data it does not own. The page
// also flips CurrPage.Editable so the page-level state is exercised alongside the per-control
// state — they are different mechanisms and a runner can get one right and the other wrong.

page 60686 "Test Page Editable Card"
{
    PageType = Card;
    SourceTable = "Test Page Editable Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                // Never editable, regardless of the row: the primary key of an existing row.
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                }
                // Editable only for rows this page owns.
                field(Name; Rec.Name)
                {
                    ApplicationArea = All;
                    Editable = RowEditable;
                }
                // No Editable property at all — the default. This is the control that stops a
                // "return false everywhere" fix from passing.
                field(Note; Rec.Note)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Rename)
            {
                ApplicationArea = All;
                Caption = 'Rename';
                Enabled = RowEditable;

                trigger OnAction()
                begin
                    Rec.Name := 'renamed';
                    Rec.Modify();
                end;
            }
            action(Refresh)
            {
                ApplicationArea = All;
                Caption = 'Refresh';

                trigger OnAction()
                begin
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        RowEditable: Boolean;

    trigger OnAfterGetRecord()
    begin
        RowEditable := not Rec.Locked;
        CurrPage.Editable(RowEditable);
    end;
}
