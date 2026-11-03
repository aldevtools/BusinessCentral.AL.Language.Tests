// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-area
// Scope: in-scope
// Fixtures used: Assert (60021), table 67530 "PAA Area Record", and the page and codeunit
// declared below.
//
// CLAIM: a page ACTION whose ApplicationArea is not enabled for the session is removed from
// the page, so a TestPage reports it as not found, while an action whose area IS enabled
// stays reachable and runs its OnAction. That holds for an action nested in an action group,
// and for a promoted actionref whose target action's area is not enabled. An empty
// application-area string enables every area.
//
// The not-found message was measured on every required leg by corpus run 36292953218. The two
// actionref tests were added after that run; their expectations are a guess until the next run.
//
// Every test sets the session's application areas itself and restores the previous value
// BEFORE it asserts, so the result does not depend on which areas the harness opened the
// session with.
//
// Written by agent stma-auto2-15, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4795.

page 67531 "PAA Action Card"
{
    PageType = Card;
    SourceTable = "PAA Area Record";

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(CodeCtl; Rec."Code")
                {
                    ApplicationArea = Basic;
                }
                field(BasicCtl; Rec."Basic Value")
                {
                    ApplicationArea = Basic;
                }
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            actionref(BasicRef; BasicAction) { }
            actionref(ServiceRef; ServiceAction) { }
        }
        area(Processing)
        {
            action(BasicAction)
            {
                ApplicationArea = Basic;
                Caption = 'Basic Action';

                trigger OnAction()
                begin
                    Rec."Basic Value" := 'BASIC-RAN';
                    Rec.Modify();
                end;
            }
            action(ServiceAction)
            {
                ApplicationArea = Service;
                Caption = 'Service Action';

                trigger OnAction()
                begin
                    Rec."Service Value" := 'SERVICE-RAN';
                    Rec.Modify();
                end;
            }
            group(Functions)
            {
                Caption = 'Functions';

                action(NestedServiceAction)
                {
                    ApplicationArea = Service;
                    Caption = 'Nested Service Action';

                    trigger OnAction()
                    begin
                        Rec."Service Value" := 'NESTED-RAN';
                        Rec.Modify();
                    end;
                }
            }
        }
    }
}

codeunit 67531 "PAA Area Action Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure MakeRecord(var AreaRec: Record "PAA Area Record")
    begin
        AreaRec.DeleteAll();
        AreaRec.Init();
        AreaRec."Code" := 'PAA';
        AreaRec.Insert();
    end;

    [Test]
    procedure AreaNotEnabled_ActionIsNotFound()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.ServiceAction.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    procedure AreaNotEnabled_NestedActionIsNotFound()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.NestedServiceAction.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    procedure AreaNotEnabled_ActionRefToRemovedActionIsNotFound()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        asserterror AreaPage.ServiceRef.Invoke();
        ApplicationArea(PreviousAreas);
        Assert.ExpectedError('is not found on the page.');
    end;

    [Test]
    procedure AreaNotEnabled_ActionRefToEnabledActionRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BasicRef.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('BASIC-RAN', AreaRec."Basic Value", 'the actionref to the #Basic action must run its target''s OnAction');
    end;

    [Test]
    procedure AreaNotEnabled_EnabledActionStillRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.BasicAction.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('BASIC-RAN', AreaRec."Basic Value", 'the #Basic action must stay on the page and run its OnAction');
    end;

    [Test]
    procedure AreaEnabled_ActionRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('#Basic,#Suite,#Service');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.ServiceAction.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('SERVICE-RAN', AreaRec."Service Value", 'with #Service enabled the action must be found and run');
    end;

    [Test]
    procedure EmptyAreaString_NestedActionRuns()
    var
        AreaRec: Record "PAA Area Record";
        AreaPage: TestPage "PAA Action Card";
        PreviousAreas: Text;
    begin
        MakeRecord(AreaRec);
        PreviousAreas := ApplicationArea();
        ApplicationArea('');

        AreaPage.OpenEdit();
        AreaPage.GoToRecord(AreaRec);
        AreaPage.NestedServiceAction.Invoke();
        AreaPage.Close();
        ApplicationArea(PreviousAreas);

        AreaRec.Get('PAA');
        Assert.AreEqual('NESTED-RAN', AreaRec."Service Value", 'with every area enabled the nested #Service action must be found and run');
    end;
}
