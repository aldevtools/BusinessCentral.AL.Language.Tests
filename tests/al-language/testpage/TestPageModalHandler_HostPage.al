// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modal-page-handler
// Scope: in-scope
// Fixtures used: Test Page Modal Handler Row (60702), Test Page Modal (60703),
//   Test Page Modal Host (60704), Test Page Modal Vars (60705), Test Page Modal NoSrc (60730)
//
// Hosts the action that opens the modal page. The OnAction records what RunModal returned, so
// a test can tell "the handler ran" from "the handler's answer got back".

page 60704 "Test Page Modal Host"
{
    PageType = List;
    SourceTable = "Test Page Modal Handler Row";
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }

                // A LOOKUP-mode modal, which closes with LookupOK rather than OK. The
                // `<> Action::LookupOK` gate is the documented AL idiom for a lookup and
                // is what makes this field a regression test rather than a duplicate of
                // the action-driven RunModal above.
                field(Picked; Rec.Picked)
                {
                    ApplicationArea = All;
                    Lookup = true;

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        Modal: Page "Test Page Modal";
                    begin
                        Modal.LookupMode(true);
                        if Modal.RunModal() <> Action::LookupOK then
                            exit(false);
                        Text := 'PICKED';
                        exit(true);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(PickIt)
            {
                ApplicationArea = All;
                Caption = 'Pick It';

                trigger OnAction()
                var
                    Modal: Page "Test Page Modal";
                    Outcome: Record "Test Page Modal Handler Row";
                    Result: Action;
                begin
                    Result := Modal.RunModal();

                    Outcome.Init();
                    Outcome."No." := 'RESULT';
                    Outcome.Descr := Format(Result);
                    if not Outcome.Insert() then
                        Outcome.Modify();
                end;
            }

            action(PickWithVars)
            {
                ApplicationArea = All;
                Caption = 'Pick With Vars';

                trigger OnAction()
                var
                    Modal: Page "Test Page Modal Vars";
                begin
                    Modal.RunModal();
                end;
            }

            // Issue #2007: a page with NO SourceTable at all, not merely one whose control
            // is bound to a page variable alongside a Rec-bound repeater (PickWithVars
            // above). The result is recorded the same way PickIt does, so Cancel is
            // distinguishable from OK for this shape too.
            action(PickWithNoSourceTable)
            {
                ApplicationArea = All;
                Caption = 'Pick With No Source Table';

                trigger OnAction()
                var
                    Modal: Page "Test Page Modal NoSrc";
                    Outcome: Record "Test Page Modal Handler Row";
                    Result: Action;
                begin
                    Result := Modal.RunModal();

                    Outcome.Init();
                    Outcome."No." := 'NOSRC-RESULT';
                    Outcome.Descr := Format(Result);
                    if not Outcome.Insert() then
                        Outcome.Modify();
                end;
            }
        }
    }
}
