// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Enum Var Kind (60718)
//
// Captions deliberately differ from member names — a TestPage sets an enum member by what the
// user sees (the caption), so resolving it needs the control's real OptionCaption list, not
// just the member's name matching by coincidence.

enum 60718 "Test Page Enum Var Kind"
{
    Extensible = false;

    value(0; Field) { Caption = 'Fields'; }
    value(1; Block) { Caption = 'Blocks'; }
    value(2; Image) { Caption = 'Images'; }
}
