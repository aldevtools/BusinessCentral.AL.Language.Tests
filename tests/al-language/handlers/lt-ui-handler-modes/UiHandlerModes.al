// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-the-user-interface
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained page 97536 and log codeunit 97535
// Probe: corpus issue "handler-less UI calls under the two BC test runners", writer Y53, 2026-11-01.
//
// BC runs tests in two ways, and they treat a UI call that has no handler differently:
// 1. Through a test runner codeunit (Test Runner 130450 driven by the Command Line Test Tool,
//    the way BcContainerHelper and this corpus's CI run tests). Every handler-less Confirm,
//    StrMenu, Message, Page.RunModal, Page.Run, Report request page and Hyperlink is refused
//    with "Unhandled UI: <Kind> <text>", code MissingUIHandler. The [Test] procedures below
//    pin this mode only.
// 2. Through the dev endpoint's test runner (/dev/TestRunnerHub, used by VS Code "Run tests" and
//    `al runtests`). It runs no AL test runner codeunit. From BC 28 on it does NOT refuse those
//    calls: each returns a default and the test goes on. On BC 27.5 it refuses them like mode 1.
//    A [Test] cannot assert this mode (the corpus CI runs mode 1), so the measured values are in
//    the non-[Test] procedure DevEndpointTestRunner_MeasuredValues below.
//
// Facts pinned here (mode 1, measured on the corpus CI BC 27.5, 28.5 and 29.0, and on a Windows
// BC 27.5 container): a handler-less Page.RunModal or Page.Run is refused before the page's
// OnOpenPage runs. Already pinned elsewhere: the refusal texts (handlers/TestUnhandledUiAndDialogDefaults.al,
// misc/lt-probes-needed-3/PnC09UnhandledUi.al, handlers/W3Hyperlink.al), the refused Confirm with a
// default (handlers/TestConfirmNoHandler.al), OnInitReport before the request-page refusal
// (report/lt-report-requestpage/RptTriggerOrder.al), Notification.Send without a handler gives no
// error (session/TestProbeSessionMiscContracts.al).
// BC versions: 27, 28, 29

codeunit 97535 "LT UiMode Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;
}

page 97536 "LT UiMode Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Info; InfoText)
            {
                ApplicationArea = All;
                Caption = 'Info';
            }
        }
    }

    var
        InfoText: Text;

    trigger OnOpenPage()
    var
        Log: Codeunit "LT UiMode Log";
    begin
        Log.Add('OnOpenPage');
    end;

    trigger OnClosePage()
    var
        Log: Codeunit "LT UiMode Log";
    begin
        Log.Add('OnClosePage');
    end;
}

codeunit 97538 "LT UiMode Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT UiMode Log";

    [Test]
    procedure PageRunModal_NoHandler_RefusedBeforeOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        asserterror Page.RunModal(Page::"LT UiMode Card");
        Observer.ObserveError('modal');
        Observer.Observe('log', Log.Take());
        Observer.Expect('modal|text', 'Unhandled UI: ModalPage 97536');
        Observer.Expect('modal|code', 'MissingUIHandler');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [Test]
    procedure PageRun_NoHandler_RefusedBeforeOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        asserterror Page.Run(Page::"LT UiMode Card");
        Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Expect('run|text', 'Unhandled UI: Page 97536');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    // Not a test. What the dev endpoint's test runner (/dev/TestRunnerHub) did with the same calls,
    // each made with NO handler declared, measured 2026-11-01 with a probe codeunit that ended every
    // test with an error carrying the result. One line per call: call | BC 27.5 | BC 28.5 and 29.
    // BC 27.5 and 28.5: Windows sandbox containers. BC 29: the SaaS sandbox (its TestRunnerHub);
    // the Windows 29.0 container was not reachable that day.
    // The hub sends no log line for a call it answers this way (no LogServerMessage frame).
    procedure DevEndpointTestRunner_MeasuredValues(): Text
    begin
        exit(
            'Confirm(Q) | refused "Unhandled UI: Confirm Q" | returns false, test goes on\' +
            'Confirm(Q, true) | refused | returns true\' +
            'Confirm(Q, false) | refused | returns false\' +
            'StrMenu(''Alpha,Beta,Gamma'', 2, Instr) | refused "Unhandled UI: StrMenu Alpha,Beta,Gamma" | returns 2\' +
            'StrMenu(''Alpha,Beta,Gamma'') | refused | returns 1\' +
            'Message(..) | refused "Unhandled UI: Message <text>" | no error, test goes on\' +
            'Page.RunModal | refused "Unhandled UI: ModalPage <id>" | returns Action::None; OnOpenPage, OnQueryClosePage, OnClosePage do not run\' +
            'Page.Run | refused "Unhandled UI: Page <id>" | no error; OnOpenPage does not run\' +
            'Report.RunModal with a request page | refused "Unhandled UI: RequestPage <id>" | request page skipped (its OnOpenPage does not run); the report runs: OnInitReport, OnPreReport, OnAfterGetRecord, OnPostReport\' +
            'Hyperlink(Url) | refused "Unhandled UI: Hyperlink <url>" | no error\' +
            'Notification.Send | no error | no error\' +
            'declared handler never called | test fails "The following UI handlers were not executed: <name>" | same, test fails\' +
            'bound ConfirmHandler | called, its reply is returned | same\' +
            'GuiAllowed() in the test | true | true');
    end;
}
