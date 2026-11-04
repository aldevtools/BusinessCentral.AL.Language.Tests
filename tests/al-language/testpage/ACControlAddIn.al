// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-control-addin-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: a control add-in with a procedure and an event, hosted by a usercontrol of a page. A field trigger calls the add-in procedure; the test sets the field on a TestPage (there is no client, so no add-in script runs). The compile error for an unknown add-in procedure is must-not-compile case 0991. Settles #626 item 16.
// BC versions: 27, 28, 29

controladdin "LT AC Addin"
{
    RequestedHeight = 50;
    RequestedWidth = 50;

    procedure Say(Message: Text);
    procedure Count(Value: Integer; Flag: Boolean);
    event Ready();
    event Answered(Answer: Text);
}

table 77540 "LT AC Addin Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

page 77540 "LT AC Addin Card"
{
    PageType = Card;
    SourceTable = "LT AC Addin Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    CurrPage.Ctl.Say(Rec.Name);
                    CurrPage.Ctl.Count(1, true);
                    AddinCalls += 1;
                end;
            }
            usercontrol(Ctl; "LT AC Addin")
            {
                ApplicationArea = All;

                trigger Ready()
                begin
                    ReadyCalls += 1;
                end;

                trigger Answered(Answer: Text)
                begin
                    LastAnswer := Answer;
                end;
            }
        }
    }

    var
        AddinCalls: Integer;
        ReadyCalls: Integer;
        LastAnswer: Text;
}

codeunit 77540 "LT AC ControlAddIn"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_ControlAddIn_ProcedureCallFromFieldTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Addin Row";
        TP: TestPage "LT AC Addin Card";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'start';
        Row.Insert();
        TP.OpenEdit();
        Observer.Observe('opened', TP.NameF.Value());
        asserterror TP.NameF.SetValue('changed');
        Observer.ObserveError('set_name');
#if BC28PLUS
        Observer.Expect('opened', 'start');
        Observer.Expect('set_name|text', 'The control add-in on control Ctl on page LT AC Addin Card has not been instantiated.');
        Observer.Expect('set_name|code', 'NSValidationFailed:DotNetControlAddInNotCreated');
        Observer.Verify();
#elif LT_HELD_BCLINUX_133
        // Held on Linux BC 27 (LT_HELD_BCLINUX_133): the Linux value of the image before the bc-linux #133 fix. The image at dbee8022 gives
        // 'The control add-in on control Ctl on page LT AC Addin Card has not been instantiated.' on 27.5 (PR run 39475237141); Windows BC 27.5
        // (Windows run 2026-10-20) gives a client callback error. Re-assert after the Windows check (windows-queue), then remove this hold.
        Observer.Expect('opened', 'start');
        Observer.Expect('set_name|text', 'Validation error for Field: NameF,  Message = ''A call to Say failed with this message: Object reference not set to an instance of an object. (Select Refresh to discard errors)''');
        Observer.Expect('set_name|code', 'TestValidation');
        Observer.Verify();
#else
        Observer.Discard();
#endif
    end;

    // ---- TZ (scope 2026-10-29, ADR-027 row 18): control add-ins on a TestPage. Fixtures in TzAddinFixtures.al (90210-90213). ----
    // Already pinned elsewhere: OnOpenPage and SetValue run with no add-in event (pages/lt-ab-tests/ABTests.al, P118RiskyUserControls.al);
    // a call from a field OnValidate (above), from an action (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), from OnOpenPage under
    // Page.Run with a page handler and on a Page variable never opened (pages/lt-f3-pages/F3ValidationAddinFilter.al). A usercontrol is no
    // TestPage member (must-not-compile 1864). These tests add: TestPage.OpenEdit with a call in OnOpenPage, OnAfterGetRecord,
    // OnAfterGetCurrRecord and OnClosePage, a second procedure, a TryFunction around the call, a usercontrol with Visible = false, and a
    // usercontrol added by a page extension. A page extension cannot call the base page's usercontrol (must-not-compile 2261, AL0783).

    local procedure TzSeed(Mode: Text)
    var
        Row: Record "LT TZ Addin Row";
        Log: Codeunit "LT TZ Addin Log";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Insert();
        Log.Reset(Mode);
    end;

    [Test]
    procedure TZ_OpenNavigateClose_NoAddinEventRuns()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('');
        TP.OpenEdit();
        Observer.Observe('after-open', Log.Dump());
        Observer.Observe('name', TP.NameF.Value());
        Observer.Observe('next', Format(TP.Next()));
        Observer.Observe('after-next', Log.Dump());
        TP.Close();
        Observer.Observe('after-close', Log.Dump());
        // CI 2026-10-29: the same on 27.5, 28.5 and 29.0. No add-in event trigger (ControlAddInReady) runs on open, Next or Close.
        Observer.Expect('after-open', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1');
        Observer.Expect('name', 'one');
        Observer.Expect('next', 'Yes');
        Observer.Expect('after-next', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 2 | OnAfterGetCurrRecord 2');
        Observer.Expect('after-close', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 2 | OnAfterGetCurrRecord 2 | OnClosePage');
        Observer.Verify();
    end;

    [Test]
    procedure TZ_CallInOnOpenPage_TestPageOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('OnOpenPage');
        asserterror TP.OpenEdit();
        Observer.ObserveError('open');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('open|text', 'The control add-in on control Ctl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('open|code', 'DotNetControlAddInNotCreated');
        Observer.Expect('log', 'OnOpenPage');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [Test]
    procedure TZ_CallInOnAfterGetRecord_TestPageOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('OnAfterGetRecord');
        asserterror TP.OpenEdit();
        Observer.ObserveError('open');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('open|text', 'The control add-in on control Ctl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('open|code', 'DotNetControlAddInNotCreated');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [Test]
    procedure TZ_CallInOnAfterGetCurrRecord_TestPageOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('OnAfterGetCurrRecord');
        asserterror TP.OpenEdit();
        Observer.ObserveError('open');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('open|text', 'The control add-in on control Ctl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('open|code', 'DotNetControlAddInNotCreated:TargetInvocation');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [Test]
    procedure TZ_CallInOnClosePage_TestPageClose()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('OnClosePage');
        TP.OpenEdit();
        asserterror TP.Close();
        Observer.ObserveError('close');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('close|text', 'One or more errors occurred while closing the page.\n\nThe control add-in on control Ctl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('close|code', 'TestWrapped');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnClosePage');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [Test]
    procedure TZ_TwoProceduresFromActions_PageStaysUsable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        // TryFunction, not asserterror: asserterror rolls back the seeded rows and the page then shows "The record that you tried to open
        // is not available" (CI 2026-10-29).
        TzSeed('');
        TP.OpenEdit();
        ClearLastError();
        Observer.Observe('say-ok', Format(TzTryInvoke(TP, 1)));
        Observer.ObserveError('say');
        Observer.Observe('count-ok', Format(TzTryInvoke(TP, 2)));
        Observer.ObserveError('count');
        Observer.Observe('name-after', TP.NameF.Value());
        TP.NameF.SetValue('changed');
        Observer.Observe('next-after', Format(TP.Next()));
        TP.Close();
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0). The page stays usable after a failed add-in call.
        Observer.Expect('say-ok', 'No');
        Observer.Expect('say|text', 'The control add-in on control Ctl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('say|code', 'TestWrapped:DotNetControlAddInNotCreated');
        Observer.Expect('count-ok', 'No');
        Observer.Expect('count|text', 'The control add-in on control Ctl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('count|code', 'TestWrapped:DotNetControlAddInNotCreated');
        Observer.Expect('name-after', 'one');
        Observer.Expect('next-after', 'Yes');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 1 | CallAct before | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 1 | CountAct before | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 2 | OnAfterGetCurrRecord 2 | OnClosePage');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [TryFunction]
    local procedure TzTryInvoke(var TP: TestPage "LT TZ Addin Card"; Which: Integer)
    begin
        case Which of
            1:
                TP.CallAct.Invoke();
            2:
                TP.CountAct.Invoke();
        end;
    end;

    [Test]
    procedure TZ_TryFunctionAroundCall_InsideAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('');
        TP.OpenEdit();
        asserterror begin
            TP.TryCallAct.Invoke();
            Error('LT-NOERROR');
        end;
        Observer.ObserveError('invoke');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('invoke|text', 'LT-NOERROR');
        Observer.Expect('invoke|code', 'Dialog');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 1 | TryCallAct ok=No text=The control add-in on control Ctl on page LT TZ Addin Card has not been instantiated. code=DotNetControlAddInNotCreated | OnAfterGetRecord 1 | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [Test]
    procedure TZ_HiddenUserControl_CallFromAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('');
        TP.OpenEdit();
        asserterror TP.HiddenCallAct.Invoke();
        Observer.ObserveError('hidden');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('hidden|text', 'The control add-in on control HiddenCtl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('hidden|code', 'TestWrapped:DotNetControlAddInNotCreated');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 1 | HiddenCallAct before');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;

    [Test]
    procedure TZ_PageExtensionUserControl_CallFromExtAction()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT TZ Addin Log";
        TP: TestPage "LT TZ Addin Card";
    begin
        TzSeed('');
        TP.OpenEdit();
        asserterror TP.ExtCallAct.Invoke();
        Observer.ObserveError('ext');
        Observer.Observe('log', Log.Dump());
#if BC28PLUS
        // CI 2026-10-29 (Linux, 28.5 and 29.0).
        Observer.Expect('ext|text', 'The control add-in on control ExtCtl on page LT TZ Addin Card has not been instantiated.');
        Observer.Expect('ext|code', 'TestWrapped:DotNetControlAddInNotCreated');
        Observer.Expect('log', 'OnOpenPage | ext OnOpenPage | OnAfterGetRecord 1 | OnAfterGetCurrRecord 1 | OnAfterGetRecord 1 | ExtCallAct before');
        Observer.Verify();
#else
        // Linux CI 27.5 gives the same values; the Windows BC 27.5 TestRunnerHub gave a client callback error for add-in calls
        // (pages/lt-ao-testpage/AoTests.al AddinProcedureFromAction), so 27 is not asserted until the Windows check (windows-queue).
        Observer.Discard();
#endif
    end;
}
