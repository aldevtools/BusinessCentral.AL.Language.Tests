// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal Vars (60705)
//
// A modal page whose selector binds to a PAGE VARIABLE rather than to a Rec field — the shape
// of every picker that puts a mode selector above its list.
//
// It only matters here because this page is opened by AL with RunModal: the runner never
// constructs that instance, so it is not the one the TestPage machinery built and marked. A
// Rec-bound control on the same page resolves either way, which is why the two are tested side
// by side.

page 60705 "Test Page Modal Vars"
{
    PageType = List;
    SourceTable = "Test Page Modal Handler Row";
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
                    // rather than a value having been stashed and handed back.
                    Echo.Init();
                    Echo."No." := 'MODE';
                    Echo.Descr := CopyStr(SelectedMode, 1, MaxStrLen(Echo.Descr));
                    if not Echo.Insert() then
                        Echo.Modify();
                end;
            }
            repeater(Rows)
            {
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }

    var
        SelectedMode: Text;
}
