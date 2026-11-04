// Fixture for TestPageCloseVeto_Tests.al.
/// <summary>
/// A page with no SourceTable whose OnQueryClosePage answers whatever "QCV Probe" is set to --
/// allow, a plain veto (exit(false)), a Confirm the test's handler answers, or an AL error -- and
/// which counts its close-lifecycle triggers there. A TestPage cannot call the page's own
/// procedures, so the decision has to live outside the page.
/// </summary>
page 60484 "QCV Veto Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'QCV Veto Card';

    layout
    {
        area(Content)
        {
            field(Marker; MarkerVar)
            {
                ApplicationArea = All;
                Caption = 'Marker';
            }
        }
    }

    var
        Probe: Codeunit "QCV Probe";
        MarkerVar: Text[10];

    trigger OnOpenPage()
    begin
        MarkerVar := 'OPENED';
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        exit(Probe.AnswerQueryClose());
    end;

    trigger OnClosePage()
    begin
        Probe.NoteClosePage();
    end;
}
