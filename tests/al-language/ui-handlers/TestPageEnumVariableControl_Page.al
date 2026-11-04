// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Enum Var Row (60717), Test Page Enum Var Kind (60718)
//
// A modal list page whose selector binds to a page GLOBAL VARIABLE of type Enum (as opposed
// to Option — see TestPageVariableControl_Page.al / TestPageModalHandler_ModalVarsPage.al for
// the Option/Text siblings of this exact shape). Only Enum can go wrong on its own: an enum's
// members live on a SEPARATE object the control only references by id, whereas Option carries
// its members inline on the field/variable declaration itself.
//
// The OnValidate trigger writes into the table so the test can observe, from outside the page,
// that setting the control actually ran the page's AL.

page 60719 "Test Page Enum Var Modal"
{
    PageType = List;
    SourceTable = "Test Page Enum Var Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(KindSelector; SelectedKind)
            {
                ApplicationArea = All;
                Caption = 'Kind';

                trigger OnValidate()
                var
                    Echo: Record "Test Page Enum Var Row";
                begin
                    if not Echo.Get('KIND') then begin
                        Echo.Init();
                        Echo."No." := 'KIND';
                        Echo.Insert();
                    end;
                end;
            }
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
            }
        }
    }

    procedure GetSelectedKindOrdinal(): Integer
    begin
        exit(SelectedKind.AsInteger());
    end;

    // Lets a test seed a NON-DEFAULT member before RunModal, so a read-side test proving
    // TestPage.Value() answers the caption cannot be satisfied by coincidence (the default
    // member's caption, 'Fields', would otherwise be the only value ever observed).
    procedure SeedKind(NewKind: Enum "Test Page Enum Var Kind")
    begin
        SelectedKind := NewKind;
    end;

    var
        SelectedKind: Enum "Test Page Enum Var Kind";
}
