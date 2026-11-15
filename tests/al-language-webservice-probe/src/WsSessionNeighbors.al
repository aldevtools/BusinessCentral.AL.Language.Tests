// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testing-application
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160, main corpus app); own objects 97880-97882 (WsSessionDialogs.al), 97884-97889 and
//   97893-97898 (LT WS ...)
// Probe (observe only): the neighbors of the cells in WsSessionDialogs.al, for the `--no-client` option of al-runner (al-runner
//   issues 8154, 8158 and 8028; review round 1 of al-runner PR 8163). Run in the same web-service session as WsSessionDialogs.al:
//   codeunit 130454 called over OData. Per cell:
//   - CurrentClientType, DefaultClientType and GuiAllowed in an OnCompanyOpenCompleted subscriber (login code, before the first
//     test) and in the test codeunit's OnRun, logged in a SingleInstance codeunit; whether the login events are raised at all;
//     DefaultClientType in a test method;
//   - Confirm and Message with their handler bound, called inside Codeunit.Run, a TryFunction and an event subscriber; a Message
//     that no handler takes inside `if Codeunit.Run` and a TryFunction;
//   - Report.RunModal of the measured report with a RequestPageHandler and with a ReportHandler;
//   - Report.Run and Report.RunModal of the measured report after an Insert (a write transaction is open);
//   - Report.Run of reports that differ from the measured one (report 97882) in one fact: SaveValues on the request page, a column,
//     UseTemporary on the data item, Caption and SourceTable on the request page, a global variable and a procedure.
// How to run: as WsSessionDialogs.al (test codeunit range 97880..97899). Each test ends with Finish, and its failure message
//   carries what BC did. ci.yml and the Windows nightly cannot run it (a test cannot start a web-service session).
// BC versions: 27, 28, 29 (to run)

report 97884 "LT WS Report SaveValues"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT WS Row") { }
    }
    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content) { }
        }
    }
}

report 97885 "LT WS Report Column"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT WS Row")
        {
            column(No; "No.") { }
        }
    }
    requestpage
    {
        layout
        {
            area(Content) { }
        }
    }
}

report 97886 "LT WS Report Temp Item"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT WS Row")
        {
            UseTemporary = true;
        }
    }
    requestpage
    {
        layout
        {
            area(Content) { }
        }
    }
}

report 97887 "LT WS Report Page Props"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "LT WS Row") { }
    }
    requestpage
    {
        Caption = 'Ask';
        SourceTable = "LT WS Row";

        layout
        {
            area(Content) { }
        }
    }
}

report 97888 "LT WS Report Global"
{
    ProcessingOnly = true;

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

    var
        Counter: Integer;

    procedure SetCounter(Value: Integer)
    begin
        Counter := Value;
    end;
}

// What login code and the test codeunit's OnRun saw: kept for the session, read by the tests.
codeunit 97889 "LT WS Login Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Get(): Text
    begin
        exit(Log);
    end;
}

codeunit 97893 "LT WS Login Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted()
    var
        LoginLog: Codeunit "LT WS Login Log";
    begin
        LoginLog.Add(StrSubstNo('login gui=%1 ct=%2 default=%3', GuiAllowed(), CurrentClientType(), DefaultClientType()));
    end;
}

codeunit 97894 "LT WS Dialog Runner"
{
    trigger OnRun()
    begin
        if Confirm('In Codeunit.Run?') then;
        Message('In Codeunit.Run.');
    end;
}

codeunit 97895 "LT WS Message Runner"
{
    trigger OnRun()
    begin
        Message('Unhandled in Codeunit.Run.');
    end;
}

codeunit 97896 "LT WS Publisher"
{
    procedure Raise()
    begin
        OnDialogEvent();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDialogEvent()
    begin
    end;
}

codeunit 97897 "LT WS Dialog Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT WS Publisher", 'OnDialogEvent', '', false, false)]
    local procedure OnDialogEvent()
    begin
        if Confirm('In a subscriber?') then;
        Message('In a subscriber.');
    end;
}

codeunit 97898 "LT WS Session Neighbors"
{
    Subtype = Test;

    var
        Seen: Text;

    trigger OnRun()
    var
        LoginLog: Codeunit "LT WS Login Log";
    begin
        LoginLog.Add(StrSubstNo('onrun gui=%1 ct=%2 default=%3', GuiAllowed(), CurrentClientType(), DefaultClientType()));
    end;

    [Test]
    procedure Login_ClientTypes()
    var
        Observer: Codeunit "Probe Observer";
        LoginLog: Codeunit "LT WS Login Log";
    begin
        // Empty when BC raised no OnCompanyOpenCompleted and ran no OnRun in this session.
        Observer.Observe('log', LoginLog.Get());
        Observer.Observe('default client type', Format(DefaultClientType()));
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnConfirm,OnMessage')]
    procedure Dialogs_InCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Observer.Observe('run', Format(Codeunit.Run(Codeunit::"LT WS Dialog Runner")));
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnConfirm,OnMessage')]
    procedure Dialogs_InTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Observer.Observe('try', Format(TryDialogs()));
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnConfirm,OnMessage')]
    procedure Dialogs_InSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Publisher: Codeunit "LT WS Publisher";
    begin
        Seen := '';
        Publisher.Raise();
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure MessageUnhandled_InCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('run', Format(Codeunit.Run(Codeunit::"LT WS Message Runner")));
        Observer.Observe('last error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure MessageUnhandled_InTryFunction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('try', Format(TryMessage()));
        Observer.Observe('last error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnRequest')]
    procedure ReportRunModal_RequestPageHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Report.RunModal(Report::"LT WS Report");
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('OnReport')]
    procedure ReportRunModal_ReportHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seen := '';
        Report.RunModal(Report::"LT WS Report");
        Observer.Observe('handler', Seen);
        Observer.Finish();
    end;

    [Test]
    procedure ReportRun_InWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WS Row";
    begin
        Row."No." := 'RUN';
        Row.Insert();
        asserterror RunAndFail(Report::"LT WS Report");
        Observer.ObserveError('run');
        Observer.Finish();
    end;

    [Test]
    procedure ReportRunModal_InWriteTransaction()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT WS Row";
    begin
        Row."No." := 'MODAL';
        Row.Insert();
        asserterror RunModalAndFail(Report::"LT WS Report");
        Observer.ObserveError('run modal');
        Observer.Finish();
    end;

    [Test]
    procedure ReportNeighbors_Run()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror RunAndFail(Report::"LT WS Report SaveValues");
        Observer.ObserveError('save values');
        asserterror RunAndFail(Report::"LT WS Report Column");
        Observer.ObserveError('column');
        asserterror RunAndFail(Report::"LT WS Report Temp Item");
        Observer.ObserveError('temp item');
        asserterror RunAndFail(Report::"LT WS Report Page Props");
        Observer.ObserveError('page props');
        asserterror RunAndFail(Report::"LT WS Report Global");
        Observer.ObserveError('global');
        Observer.Finish();
    end;

    // Runs report `Id`, then raises a marker error: the observed error is BC's when the run failed, `returned` when it returned.
    local procedure RunAndFail(Id: Integer)
    begin
        Report.Run(Id);
        Error('returned');
    end;

    local procedure RunModalAndFail(Id: Integer)
    begin
        Report.RunModal(Id);
        Error('returned');
    end;

    [TryFunction]
    local procedure TryDialogs()
    begin
        if Confirm('In a TryFunction?') then;
        Message('In a TryFunction.');
    end;

    [TryFunction]
    local procedure TryMessage()
    begin
        Message('Unhandled in a TryFunction.');
    end;

    [ConfirmHandler]
    procedure OnConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Seen += 'confirm:' + Question + ';';
        Reply := true;
    end;

    [MessageHandler]
    procedure OnMessage(Msg: Text[1024])
    begin
        Seen += 'message:' + Msg + ';';
    end;

    [RequestPageHandler]
    procedure OnRequest(var R: TestRequestPage "LT WS Report")
    begin
        Seen += 'request page;';
        R.OK().Invoke();
    end;

    [ReportHandler]
    procedure OnReport(var R: Report "LT WS Report")
    begin
        Seen += 'report;';
    end;
}
