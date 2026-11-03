// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained log 72776, page 72777, pageextensions 72778 and 72779, test codeunit 72780
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: trigger OnAfterAction in modify(action) of a pageextension may not compile for runtime 16; this file is separate so only it drops.
// UQ (al-runner 6216): OnBeforeAction and OnAfterAction in one modify block, no invoke, error in OnBeforeAction, no base OnAction, page 90470, pageextension 90471.
// Facts: invoking an action through a TestPage runs the base OnAction and then the OnAfterAction of every extension that modifies the action; order between two extensions; an action without OnAction in the base; the base OnAction raising an error.
codeunit 72776 "LT PgExtAct Log"
{
    SingleInstance = true;

    procedure Add(Entry: Text)
    begin
        Entries.Add(Entry);
    end;

    procedure Reset()
    begin
        Clear(Entries);
    end;

    procedure Count(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure Get(Index: Integer): Text
    begin
        if (Index < 1) or (Index > Entries.Count()) then
            exit('<none>');
        exit(Entries.Get(Index));
    end;

    var
        Entries: List of [Text];
}

page 72777 "LT PgExtAct Host"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Dummy; Dummy)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Alpha)
            {
                ApplicationArea = All;
                Caption = 'Alpha';

                trigger OnAction()
                begin
                    Trace.Add('base Alpha OnAction');
                end;
            }
            action(Beta)
            {
                ApplicationArea = All;
                Caption = 'Beta';
            }
            action(Gamma)
            {
                ApplicationArea = All;
                Caption = 'Gamma';

                trigger OnAction()
                begin
                    Trace.Add('base Gamma OnAction');
                    Error('LT PgExtAct gamma failure');
                end;
            }
        }
    }

    var
        Dummy: Integer;
        Trace: Codeunit "LT PgExtAct Log";
}

pageextension 72778 "LT PgExtAct Ext One" extends "LT PgExtAct Host"
{
    actions
    {
        modify(Alpha)
        {
            trigger OnAfterAction()
            begin
                Trace.Add('ext one Alpha OnAfterAction');
            end;
        }
        modify(Beta)
        {
            trigger OnAfterAction()
            begin
                Trace.Add('ext one Beta OnAfterAction');
            end;
        }
        modify(Gamma)
        {
            trigger OnAfterAction()
            begin
                Trace.Add('ext one Gamma OnAfterAction');
            end;
        }
    }

    var
        Trace: Codeunit "LT PgExtAct Log";
}

pageextension 72779 "LT PgExtAct Ext Two" extends "LT PgExtAct Host"
{
    actions
    {
        modify(Alpha)
        {
            trigger OnAfterAction()
            begin
                Trace.Add('ext two Alpha OnAfterAction');
            end;
        }
    }

    var
        Trace: Codeunit "LT PgExtAct Log";
}

codeunit 72780 "LT PgExtAct"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Trace: Codeunit "LT PgExtAct Log";

    [Test]
    procedure P195_ActionWithOnAction_RunsBaseThenExtensions()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PgExtAct Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Trace.Add('before invoke');
        Host.Alpha.Invoke();
        Trace.Add('after invoke');
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '5');
        Observer.Expect('e1', 'before invoke');
        Observer.Expect('e2', 'base Alpha OnAction');
        Observer.Expect('e3', 'ext one Alpha OnAfterAction');
        Observer.Expect('e4', 'ext two Alpha OnAfterAction');
        Observer.Expect('e5', 'after invoke');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure P195_ActionWithoutBaseOnAction_RunsOnAfterAction()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PgExtAct Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Host.Beta.Invoke();
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '1');
        Observer.Expect('e1', 'ext one Beta OnAfterAction');
        Observer.Expect('e2', '<none>');
        Observer.Expect('e3', '<none>');
        Observer.Expect('e4', '<none>');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure P195_BaseOnActionRaises_OnAfterActionSkipped()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PgExtAct Host";
    begin
        Trace.Reset();
        Host.OpenView();
        asserterror Host.Gamma.Invoke();
        Observer.ObserveError('gamma-invoke');
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('gamma-invoke|text', 'LT PgExtAct gamma failure');
        Observer.Expect('gamma-invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('count', '1');
        Observer.Expect('e1', 'base Gamma OnAction');
        Observer.Expect('e2', '<none>');
        Observer.Expect('e3', '<none>');
        Observer.Expect('e4', '<none>');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure P195_ActionInvokedTwice_OnAfterActionEachTime()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT PgExtAct Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Host.Alpha.Invoke();
        Host.Alpha.Invoke();
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '6');
        Observer.Expect('e1', 'base Alpha OnAction');
        Observer.Expect('e2', 'ext one Alpha OnAfterAction');
        Observer.Expect('e3', 'ext two Alpha OnAfterAction');
        Observer.Expect('e4', 'base Alpha OnAction');
        Observer.Expect('e5', 'ext one Alpha OnAfterAction');
        Observer.Expect('e6', 'ext two Alpha OnAfterAction');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure UQ_OpenWithoutInvoke_NoBeforeOrAfter()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT UQ Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '0');
        Observer.Expect('e1', '<none>');
        Observer.Expect('e2', '<none>');
        Observer.Expect('e3', '<none>');
        Observer.Expect('e4', '<none>');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure UQ_BeforeAndAfterInOneModify_Order()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT UQ Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Host.Doit.Invoke();
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '3');
        Observer.Expect('e1', 'ext Doit OnBeforeAction');
        Observer.Expect('e2', 'base Doit OnAction');
        Observer.Expect('e3', 'ext Doit OnAfterAction');
        Observer.Expect('e4', '<none>');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure UQ_BeforeActionWithoutBaseOnAction()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT UQ Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Host.Bare.Invoke();
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '2');
        Observer.Expect('e1', 'ext Bare OnBeforeAction');
        Observer.Expect('e2', 'ext Bare OnAfterAction');
        Observer.Expect('e3', '<none>');
        Observer.Expect('e4', '<none>');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure UQ_BeforeActionRaises_OnActionAndAfterSkipped()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT UQ Host";
    begin
        Trace.Reset();
        Host.OpenView();
        asserterror Host.Fails.Invoke();
        Observer.ObserveError('invoke');
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('invoke|text', 'LT UQ before failure');
        Observer.Expect('invoke|code', 'TestWrapped:Dialog');
        Observer.Expect('count', '1');
        Observer.Expect('e1', 'ext Fails OnBeforeAction');
        Observer.Expect('e2', '<none>');
        Observer.Expect('e3', '<none>');
        Observer.Expect('e4', '<none>');
        Observer.Expect('e5', '<none>');
        Observer.Expect('e6', '<none>');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    [Test]
    procedure UQ_BeforeAction_InvokedTwice_EachTime()
    var
        Observer: Codeunit "Probe Observer";
        Host: TestPage "LT UQ Host";
    begin
        Trace.Reset();
        Host.OpenView();
        Host.Doit.Invoke();
        Host.Doit.Invoke();
        Host.Close();
        DumpTrace(Observer);
        Observer.Expect('count', '6');
        Observer.Expect('e1', 'ext Doit OnBeforeAction');
        Observer.Expect('e2', 'base Doit OnAction');
        Observer.Expect('e3', 'ext Doit OnAfterAction');
        Observer.Expect('e4', 'ext Doit OnBeforeAction');
        Observer.Expect('e5', 'base Doit OnAction');
        Observer.Expect('e6', 'ext Doit OnAfterAction');
        Observer.Expect('e7', '<none>');
        Observer.Expect('e8', '<none>');
        Observer.Expect('e9', '<none>');
        Observer.Expect('e10', '<none>');
        Observer.Verify();
    end;

    local procedure DumpTrace(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        Observer.Observe('count', Format(Trace.Count()));
        for I := 1 to 10 do
            Observer.Observe('e' + Format(I), Trace.Get(I));
    end;
}

page 90470 "LT UQ Host"
{
    PageType = Card;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(Dummy; Dummy)
            {
                ApplicationArea = All;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Doit)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Trace.Add('base Doit OnAction');
                end;
            }
            action(Bare)
            {
                ApplicationArea = All;
            }
            action(Fails)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Trace.Add('base Fails OnAction');
                end;
            }
        }
    }

    var
        Dummy: Integer;
        Trace: Codeunit "LT PgExtAct Log";
}

pageextension 90471 "LT UQ Host Ext" extends "LT UQ Host"
{
    actions
    {
        modify(Doit)
        {
            trigger OnBeforeAction()
            begin
                Trace.Add('ext Doit OnBeforeAction');
            end;

            trigger OnAfterAction()
            begin
                Trace.Add('ext Doit OnAfterAction');
            end;
        }
        modify(Bare)
        {
            trigger OnBeforeAction()
            begin
                Trace.Add('ext Bare OnBeforeAction');
            end;

            trigger OnAfterAction()
            begin
                Trace.Add('ext Bare OnAfterAction');
            end;
        }
        modify(Fails)
        {
            trigger OnBeforeAction()
            begin
                Trace.Add('ext Fails OnBeforeAction');
                Error('LT UQ before failure');
            end;

            trigger OnAfterAction()
            begin
                Trace.Add('ext Fails OnAfterAction');
            end;
        }
    }

    var
        Trace: Codeunit "LT PgExtAct Log";
}
