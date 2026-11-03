// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: page property PromotedActionCategories with Promoted actions (PromotedCategory, PromotedIsBig, PromotedOnly). The categories are no TestPage members: declared, the Visible and Enabled of the actions are observed.

page 71673 "LT P119 Promoted Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;
    PromotedActionCategories = 'New,Process,Report,Custom One,Custom Two';

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PromProcess)
            {
                ApplicationArea = All;
                Caption = 'Promoted Process';
                Promoted = true;
                PromotedCategory = Process;
                PromotedIsBig = true;
                trigger OnAction()
                begin
                end;
            }
            action(PromCustom)
            {
                ApplicationArea = All;
                Caption = 'Promoted Custom';
                Promoted = true;
                PromotedCategory = Category4;
                PromotedOnly = true;
                trigger OnAction()
                begin
                end;
            }
            action(NotPromoted)
            {
                ApplicationArea = All;
                Caption = 'Not Promoted';
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 71674 "LT P119 Promoted Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_PromotedActions()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Promoted Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Prom';
        Row.Insert();
        TP.OpenView();
        Observer.Observe('process-visible', Format(TP.PromProcess.Visible()));
        Observer.Observe('process-enabled', Format(TP.PromProcess.Enabled()));
        Observer.Observe('custom-visible', Format(TP.PromCustom.Visible()));
        Observer.Observe('custom-enabled', Format(TP.PromCustom.Enabled()));
        Observer.Observe('not-visible', Format(TP.NotPromoted.Visible()));
        TP.PromProcess.Invoke();
        TP.PromCustom.Invoke();
        Observer.Observe('invoked', 'no error');
        TP.Close();
        Observer.Expect('process-visible', 'Yes');
        Observer.Expect('process-enabled', 'Yes');
        Observer.Expect('custom-visible', 'Yes');
        Observer.Expect('custom-enabled', 'Yes');
        Observer.Expect('not-visible', 'Yes');
        Observer.Expect('invoked', 'no error');
        Observer.Verify();
    end;
}
