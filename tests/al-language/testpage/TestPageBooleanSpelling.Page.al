// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
// Scope: in-scope
// Fixtures used: TPB Bool Row (60664)
//
// Two Rec-bound Boolean controls and two bound to page GLOBALS. The global pair is not
// redundant: a control bound to a page variable round-trips through different runtime plumbing
// than one bound to a source-table field (same reasoning as TestPageBooleanRecBound_Page.al),
// and TestPageSubpagePartNewRecordInit's BooleanFieldControl_ReadsAsYesOrNo already pins only
// the Rec-bound shape.
//
// The globals are seeded in OnOpenPage rather than left at their type default, so the true
// spelling is observable on the variable-bound path too.

page 60665 "TPB Bool Card"
{
    PageType = Card;
    SourceTable = "TPB Bool Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPB Bool Card';

    layout
    {
        area(Content)
        {
            field(RecMarker; Rec.Marker) { ApplicationArea = All; Caption = 'Rec Marker'; }
            field(RecTrue; Rec.TrueFlag) { ApplicationArea = All; Caption = 'Rec True'; }
            field(RecFalse; Rec.FalseFlag) { ApplicationArea = All; Caption = 'Rec False'; }
            field(GlobalTrue; GlobalTrue) { ApplicationArea = All; Caption = 'Global True'; }
            field(GlobalFalse; GlobalFalse) { ApplicationArea = All; Caption = 'Global False'; }
        }
    }

    var
        GlobalTrue: Boolean;
        GlobalFalse: Boolean;

    trigger OnOpenPage()
    begin
        GlobalTrue := true;
        GlobalFalse := false;
    end;
}
