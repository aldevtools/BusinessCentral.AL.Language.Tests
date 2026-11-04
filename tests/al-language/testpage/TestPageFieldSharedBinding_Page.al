// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-value-method
// Scope: in-scope
// Fixtures used: TP Shared Bind Row (60771)
//
// Nothing stops a page from showing ONE value through MORE THAN ONE control, and real pages do
// it constantly — typically two groups, only one of which is visible at a time, each carrying
// its own control over the same variable. Microsoft's own Base Application does this on page
// 1612 "Office Admin. Credentials" (PasswordText shown as both O365Password and
// OnPremPassword) and on page 1327 "Adjust Inventory" (each TempItemJournalLine field shown
// once beside the single-location group and once inside the repeater).
//
// Three bindings, each carried by two controls in two different groups, so the suite can tell
// apart "the SECOND control over a binding resolves" from "controls resolve":
//
//   Rec.Value            -> RowValueFirst   / RowValueSecond
//   GlobalText (a global) -> GlobalFirst    / GlobalSecond
//   Buffer.Value (a field of a global temporary Record) -> BufferFirst / BufferSecond
//
// OnOpenPage seeds the two non-Rec bindings with specific, non-default values so a read
// through EITHER control has something concrete to assert, and neither could be satisfied by
// an implementation that answers a blank.

page 60772 "TP Shared Bind Card"
{
    PageType = Card;
    SourceTable = "TP Shared Bind Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP Shared Bind Card';

    layout
    {
        area(Content)
        {
            group(FirstGroup)
            {
                ShowCaption = false;

                field(RowValueFirst; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Row Value First';
                }
                field(GlobalFirst; GlobalText)
                {
                    ApplicationArea = All;
                    Caption = 'Global First';
                }
                field(BufferFirst; Buffer.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Buffer First';
                }
            }

            group(SecondGroup)
            {
                ShowCaption = false;

                field(RowValueSecond; Rec.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Row Value Second';
                }
                field(GlobalSecond; GlobalText)
                {
                    ApplicationArea = All;
                    Caption = 'Global Second';
                }
                field(BufferSecond; Buffer.Value)
                {
                    ApplicationArea = All;
                    Caption = 'Buffer Second';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        GlobalText := 'seeded global';
        Buffer.Init();
        Buffer.PK := 'BUF';
        Buffer.Value := 'seeded buffer';
        Buffer.Insert();
    end;

    var
        Buffer: Record "TP Shared Bind Row" temporary;
        GlobalText: Text[30];
}
