// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal (60703)
//
// The modal page under test — what a [ModalPageHandler] is handed.

page 60703 "Test Page Modal"
{
    PageType = StandardDialog;
    SourceTable = "Test Page Modal Handler Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Descr; Rec.Descr)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            // Verified against real BC: TestPage.Cancel() needs a genuine client Cancel
            // affordance — an action literally named Cancel is not enough on a plain
            // Card-type modal (still "not found" even when declared); PageType =
            // StandardDialog (above) is what actually gives the client OK/Cancel chrome.
            // These declarations exist to give the actions a caption/trigger surface, not
            // to satisfy the built-in-action lookup by themselves.
            action(OK)
            {
                ApplicationArea = All;
            }
            action(Cancel)
            {
                ApplicationArea = All;
            }
        }
    }
}
