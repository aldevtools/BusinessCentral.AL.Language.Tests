// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160, main corpus app); own objects 97880-97883 (LT WS ...)
// Probe (observe only): al-runner issues 8154, 8158 and 8028 (the `--no-client` option, which stands for a web-service session).
//   What a test sees when Microsoft's test runner runs it in a web-service session, as a mutation-testing tool does: the test
//   runner codeunit 130454 called over OData, so the session has no client. Per cell: GuiAllowed and CurrentClientType; Confirm,
//   StrMenu, Message, Hyperlink and Notification.Send with their handler bound (`handler` is the handler's log) and without
//   (the error text and code); Page.Run and Page.RunModal of a page id; Dialog.Open, Update and Close; Report.Run and
//   Report.RunModal of a processing-only report with an empty request page, without a handler, with a RequestPageHandler and with
//   a ReportHandler; Report.RunRequestPage with and without a handler; a TestPage OpenView; a read of the Session table and of
//   the Active Session table.
// How to run: publish this app next to the main corpus app, then call codeunit 130454 over OData for the test codeunit range
//   97880..97889. ci.yml and the Windows nightly cannot run it: they run every test in a session with a client (TestRunnerHub,
//   or page 130455 through Run-TestsInBcContainer), and a test cannot start a web-service session
//   (pages/background-tasks/BjNoClientDialogs.al:7-8). So the expected values are not filled in yet: each test ends with
//   Finish, and its failure message carries what BC did.
// Some cells show only in the runner's result row, not in the observations: a test whose bound handler never runs fails with
//   "The following UI handlers were not executed: <handler>" (ReportRun_RequestPageHandler when BC skips the request page,
//   ReportRunRequestPage_Handler when the call fails first).
// Measured by the reporter of al-runner issue 8154 on BC 28.4 W1 (2026-11-15), the same calls in tests of their own:
//   GuiAllowed false and CurrentClientType ODataV4 (al-runner issue 8028, a July measurement); the bound handlers are called;
//   an unhandled Message or Hyperlink fails with "Unhandled UI: Message <text>" / "Unhandled UI: Hyperlink <url>"; Report.Run
//   and Report.RunModal skip the request page (a bound RequestPageHandler ends in "not executed"); a ReportHandler is called;
//   Report.RunRequestPage fails; a TestPage open fails (NotSupportedException); a Session read fails ("The Active Session does
//   not exist", with and without the Read grant). Not measured yet: Confirm, StrMenu and Notification.Send without a handler,
//   Page.Run and Page.RunModal of a page id, Dialog.Open, the Active Session read.
// BC versions: 27, 28, 29 (to run)

table 97880 "LT WS Row"
{
    fields
    {
        field(1; "No."; Code[10]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 97881 "LT WS Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "LT WS Row";

    layout
    {
        area(Content)
        {
            field(No; Rec."No.") { ApplicationArea = All; }
        }
    }
}

report 97882 "LT WS Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT WS Row") { }
    }
    requestpage
    {
        layout
        {
            area(Content) { }
        }
    }
}

codeunit 97883 "LT WS Session Dialogs"
{
    Subtype = Test;

    var
        Seen: Text;

    [Test]
    procedure Session_GuiAllowedAndClientType()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('gui allowed', Format(GuiAllowed()));
        Observer.Observe('client type', Format(CurrentClientType()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnConfirm')]
    procedure Confirm_Handler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Observer.Observe('reply', Format(Confirm('Go on?')));
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure Confirm_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror if Confirm('Go on?') then;
        Observer.ObserveError('confirm');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnStrMenu')]
    procedure StrMenu_Handler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Observer.Observe('choice', Format(StrMenu('One,Two')));
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure StrMenu_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror if StrMenu('One,Two') = 1 then;
        Observer.ObserveError('strmenu');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnMessage')]
    procedure Message_Handler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Message('Done.');
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure Message_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Message('Done.');
        Observer.ObserveError('message');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnHyperlink')]
    procedure Hyperlink_Handler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Hyperlink('https://example.com');
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure Hyperlink_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Hyperlink('https://example.com');
        Observer.ObserveError('hyperlink');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnSend')]
    procedure Notification_Handler()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        Seen := '';
        N.Message := 'note';
        Observer.Observe('sent', Format(N.Send()));
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure Notification_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        N: Notification;
    begin
        N.Message := 'note';
        Observer.Observe('sent', Format(N.Send()));
        Observer.Finish();
    end;

    [Test]
    procedure PageRun_ById()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Page.Run(Page::"LT WS Card");
        Observer.ObserveError('page run');
        asserterror Page.RunModal(Page::"LT WS Card");
        Observer.ObserveError('page run modal');
        Observer.Finish();
    end;

    [Test]
    procedure Dialog_OpenUpdateClose()
    var
        Observer: Codeunit "Probe Observer";
        D: Dialog;
    begin
        D.Open('working #1######');
        D.Update(1, 5);
        D.Close();
        Observer.Observe('dialog', 'returned');
        Observer.Finish();
    end;

    [Test]
    procedure ReportRun_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Report.Run(Report::"LT WS Report");
        Observer.Observe('run', 'returned');
        Report.RunModal(Report::"LT WS Report");
        Observer.Observe('run modal', 'returned');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnRequest')]
    procedure ReportRun_RequestPageHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Report.Run(Report::"LT WS Report");
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnReport')]
    procedure ReportRun_ReportHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Report.Run(Report::"LT WS Report");
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure ReportRunRequestPage_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror if Report.RunRequestPage(Report::"LT WS Report") = '' then;
        Observer.ObserveError('run request page');
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnRequest')]
    procedure ReportRunRequestPage_Handler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        asserterror if Report.RunRequestPage(Report::"LT WS Report") = '' then;
        Observer.ObserveError('run request page');
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure TestPage_OpenView()
    var
        Observer: Codeunit "Probe Observer";
        P: TestPage "LT WS Card";
    begin
        asserterror P.OpenView();
        Observer.ObserveError('open view');
        Observer.Finish();
    end;

    [Test]
    procedure Session_Read()
    var
        Observer: Codeunit "Probe Observer";
        S: Record Session;
    begin
        asserterror if S.IsEmpty() then;
        Observer.ObserveError('is empty');
        asserterror S.FindFirst();
        Observer.ObserveError('find first');
        Observer.Finish();
    end;

    [Test]
    procedure ActiveSession_Read()
    var
        Observer: Codeunit "Probe Observer";
        A: Record "Active Session";
    begin
        A.SetRange("Session ID", SessionId());
        Observer.Observe('own row', Format(not A.IsEmpty()));
        Observer.Finish();
    end;

    [ConfirmHandler]
    procedure OnConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Seen += 'confirm:' + Question;
        Reply := true;
    end;

    [StrMenuHandler]
    procedure OnStrMenu(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Seen += 'strmenu:' + Options;
        Choice := 1;
    end;

    [MessageHandler]
    procedure OnMessage(Msg: Text[1024])
    begin
        Seen += 'message:' + Msg;
    end;

    [HyperlinkHandler]
    procedure OnHyperlink(Link: Text[1024])
    begin
        Seen += 'hyperlink:' + Link;
    end;

    [SendNotificationHandler]
    procedure OnSend(var N: Notification): Boolean
    begin
        Seen += 'notification:' + N.Message;
    end;

    [RequestPageHandler]
    procedure OnRequest(var R: TestRequestPage "LT WS Report")
    begin
        Seen += 'request page';
        R.OK().Invoke();
    end;

    [ReportHandler]
    procedure OnReport(var R: Report "LT WS Report")
    begin
        Seen += 'report';
    end;
}
