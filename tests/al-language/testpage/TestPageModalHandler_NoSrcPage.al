// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702)
//
// A modal page with NO SourceTable at all — the ordinary AL shape for a StandardDialog
// picker/prompt whose state lives entirely in page globals (issue #2007). Unlike "Test Page
// Modal Vars" (60705), which pairs a page-variable control with a Rec-bound repeater, this
// page has no record anywhere: SourceTable is simply absent from its declaration. A
// [ModalPageHandler] must still be handed a working TestPage for it — the control's own
// OnValidate is what proves the handler's SetValue reached the page's AL rather than just
// being stashed and echoed back.

page 60730 "Test Page Modal NoSrc"
{
    PageType = StandardDialog;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Mode; SelectedMode)
            {
                ApplicationArea = All;
                Caption = 'Mode';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Modal Handler Row";
                begin
                    // Writing through to the table is what proves the page's own AL ran,
                    // rather than a value having been stashed and handed back — the same
                    // proof "Test Page Modal Vars" (60705) uses for its own OnValidate.
                    Echo.Init();
                    Echo."No." := 'NOSRC-MODE';
                    Echo.Descr := CopyStr(SelectedMode, 1, MaxStrLen(Echo.Descr));
                    if not Echo.Insert() then
                        Echo.Modify();
                end;
            }
        }
    }

    var
        SelectedMode: Text;
}
