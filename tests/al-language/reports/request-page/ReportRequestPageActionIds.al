// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: LT P161 Action Rpt (72713)
//
// Invoke on an action of a request page: the text "The action with ID = <id> is not found on the page."
// carries an id derived from the report id and the action name. Three ids are pinned
// (handlers/TestReportRequestPageAction.al, report 60398). Here eight more action names on another
// report: the observed ids show whether the derivation is the same for every name and report.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72713 "LT P161 Action Rpt"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        actions
        {
            area(Processing)
            {
                action(A)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action(Go)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action(StampText)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action(Zeta)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action(lower)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action("Name With Spaces")
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action("Üni Code")
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
                action(AVeryLongActionNameThatGoesOnAndOnAndOn)
                {
                    ApplicationArea = All;
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
    }
}

codeunit 72714 "LT P161 Action Ids"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Texts: List of [Text];

    [Test]
    [HandlerFunctions('IdsHandler')]
    procedure P161_InvokeEachAction_IdInTheNotFoundText()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        Clear(Texts);
        Commit();
        Report.Run(Report::"LT P161 Action Rpt");
        Observer.Observe('count', Format(Texts.Count()));
        for i := 1 to Texts.Count() do
            Observer.Observe('action' + Format(i), Texts.Get(i));
        Observer.Expect('count', '8');
        Observer.Expect('action1', 'The action with ID = n is not found on the page.');
        Observer.Expect('action2', 'The action with ID = n is not found on the page.');
        Observer.Expect('action3', 'The action with ID = n is not found on the page.');
        Observer.Expect('action4', 'The action with ID = n is not found on the page.');
        Observer.Expect('action5', 'The action with ID = n is not found on the page.');
        Observer.Expect('action6', 'The action with ID = n is not found on the page.');
        Observer.Expect('action7', 'The action with ID = n is not found on the page.');
        Observer.Expect('action8', 'The action with ID = n is not found on the page.');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure IdsHandler(var RequestPage: TestRequestPage "LT P161 Action Rpt")
    begin
        asserterror RequestPage.A.Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage.Go.Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage.StampText.Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage.Zeta.Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage.lower.Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage."Name With Spaces".Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage."Üni Code".Invoke();
        Texts.Add(GetLastErrorText());
        asserterror RequestPage.AVeryLongActionNameThatGoesOnAndOnAndOn.Invoke();
        Texts.Add(GetLastErrorText());
        RequestPage.OK().Invoke();
    end;
}
