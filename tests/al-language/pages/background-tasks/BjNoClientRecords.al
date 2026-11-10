// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-currentclienttype-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 81680 and page 81682 of BjNoGuiDialogs.al; report 81972 of BjNoClientDialogs.al;
//   own worker codeunit 81975, page 81976, report 81977, test codeunits 81978 and 81979
// Probe (observe only): al-runner issue 7564 (a run option for a session without a client), second part. BjNoClientDialogs.al pins the dialogs
//   without a record in a page background task worker. This probe asks, in the same worker, what CurrentClientType answers (and how it compares
//   with ClientType values), what Notification.Recall returns after a Send and on a notification never sent, what Page.Run and Page.RunModal do
//   with a record (static and through a Page variable with SetRecord), and what the report entry points do whose request page would open
//   (Report.Run, Report.RunModal, a Report variable, Report.RunRequestPage) or that take the parameters as text (Report.Execute, Report.SaveAs).
//   Each call runs in a TryFunction, so the error code and text show: `<cell>` = `returned: <answer>` or `error: <text> code=<code>`.
//   A worker cannot reach the handlers of the test (BjNoClientDialogs.al: no handler fires for a call of the worker). The second test codeunit
//   declares page, modal page, request page, send and recall notification handlers, runs every group in the worker and logs which handler ran
//   for it; then the test session calls each dialog itself, because a declared handler that never runs fails the test.
// BC versions: 27, 28, 29

codeunit 81975 "LT BJ NC2 Worker"
{
    trigger OnRun()
    var
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Group: Text;
    begin
        Params := Page.GetBackgroundParameters();
        Group := Params.Get('group');
        case Group of
            'client':
                begin
                    Probe(1, 'c1 Format(CurrentClientType())', Results);
                    Probe(2, 'c2 = ClientType::Background', Results);
                    Probe(3, 'c3 = ClientType::ChildSession', Results);
                    Probe(4, 'c4 = ClientType::Web', Results);
                    Probe(5, 'c5 = ClientType::Api', Results);
                    Probe(6, 'c6 = ClientType::NAS', Results);
                    Probe(7, 'n1 Send then Recall', Results);
                    Probe(8, 'n2 Recall never sent', Results);
                    Probe(9, 'n3 Send then Recall twice', Results);
                end;
            'pages':
                begin
                    Probe(20, 'p0 record found', Results);
                    Probe(21, 'p1 Page.Run(Id, Rec)', Results);
                    Probe(22, 'p2 Page.RunModal(Id, Rec)', Results);
                    Probe(23, 'p3 SetRecord then Run', Results);
                    Probe(24, 'p4 SetRecord then RunModal', Results);
                    Probe(25, 'p5 Page.RunModal(Id, Rec, FieldNo)', Results);
                end;
            'reports1':
                begin
                    Probe(41, 'r1 Report.Run(Id)', Results);
                    Probe(42, 'r2 Report.RunModal(Id)', Results);
                    Probe(43, 'r3 Report.Run(Id, true, false, Rec)', Results);
                    Probe(44, 'r4 variable Run', Results);
                    Probe(45, 'r5 variable RunModal', Results);
                    Probe(46, 'r6 Report.RunRequestPage(Id)', Results);
                end;
            'reports2':
                begin
                    Probe(51, 'r7 Report.RunModal(Id, false)', Results);
                    Probe(52, 'r8 processing only Report.RunModal(Id, false)', Results);
                    Probe(53, 'r9 Report.Execute(Id, parameters)', Results);
                    Probe(54, 'r10 Report.Execute(Id, empty)', Results);
                    Probe(55, 'r11 Report.SaveAs(Id, parameters, Xml)', Results);
                    Probe(56, 'r12 Report.SaveAs(Id, empty, Xml)', Results);
                end;
        end;
        Page.SetBackgroundTaskResult(Results);
    end;

    local procedure Probe(Step: Integer; Name: Text; var Results: Dictionary of [Text, Text])
    var
        Answer: Text;
    begin
        ClearLastError();
        Answer := '';
        if TryStep(Step, Answer) then
            Results.Add(Name, 'returned: ' + Answer)
        else
            Results.Add(Name, 'error: ' + GetLastErrorText() + ' code=' + GetLastErrorCode());
    end;

    procedure ParamsText(): Text
    begin
        exit('<?xml version="1.0" standalone="yes"?><ReportParameters name="LT BJ NC2 Data Report" id="' + Format(Report::"LT BJ NC2 Data Report") +
            '"><Options><Field name="Flag">false</Field></Options><DataItems><DataItem name="Rows">VERSION(1) SORTING(Field1)</DataItem></DataItems></ReportParameters>');
    end;

    [TryFunction]
    local procedure TryStep(Step: Integer; var Answer: Text)
    var
        Row: Record "LT BJ NoGui Row";
        Num: Record Integer;
        RecPage: Page "LT BJ NC2 Record Page";
        Rpt: Report "LT BJ NC2 Data Report";
        Note: Notification;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        if Step in [20 .. 25] then
            if Row.FindFirst() then;
        case Step of
            1:
                Answer := Format(CurrentClientType());
            2:
                Answer := Format(CurrentClientType() = ClientType::Background);
            3:
                Answer := Format(CurrentClientType() = ClientType::ChildSession);
            4:
                Answer := Format(CurrentClientType() = ClientType::Web);
            5:
                Answer := Format(CurrentClientType() = ClientType::Api);
            6:
                Answer := Format(CurrentClientType() = ClientType::NAS);
            7:
                begin
                    Note.Message := 'LT BJ NC2 notification';
                    Answer := 'send ' + Format(Note.Send());
                    Answer += ', recall ' + Format(Note.Recall());
                end;
            8:
                begin
                    Note.Message := 'LT BJ NC2 never sent';
                    Answer := Format(Note.Recall());
                end;
            9:
                begin
                    Note.Message := 'LT BJ NC2 recalled twice';
                    Answer := 'send ' + Format(Note.Send());
                    Answer += ', recall ' + Format(Note.Recall());
                    Answer += ', recall ' + Format(Note.Recall());
                end;
            20:
                Answer := Row."No.";
            21:
                begin
                    Page.Run(Page::"LT BJ NC2 Record Page", Row);
                    Answer := 'ran';
                end;
            22:
                Answer := Format(Page.RunModal(Page::"LT BJ NC2 Record Page", Row));
            23:
                begin
                    RecPage.SetRecord(Row);
                    RecPage.Run();
                    Answer := 'ran';
                end;
            24:
                begin
                    RecPage.SetRecord(Row);
                    Answer := Format(RecPage.RunModal());
                end;
            25:
                Answer := Format(Page.RunModal(Page::"LT BJ NC2 Record Page", Row, Row.FieldNo("No.")));
            41:
                begin
                    Report.Run(Report::"LT BJ NC2 Data Report");
                    Answer := 'ran';
                end;
            42:
                begin
                    Report.RunModal(Report::"LT BJ NC2 Data Report");
                    Answer := 'ran';
                end;
            43:
                begin
                    Num.SetRange(Number, 1);
                    Report.Run(Report::"LT BJ NC2 Data Report", true, false, Num);
                    Answer := 'ran';
                end;
            44:
                begin
                    Rpt.UseRequestPage(true);
                    Rpt.Run();
                    Answer := 'ran';
                end;
            45:
                begin
                    Rpt.UseRequestPage(true);
                    Rpt.RunModal();
                    Answer := 'ran';
                end;
            46:
                Answer := Report.RunRequestPage(Report::"LT BJ NC2 Data Report");
            51:
                begin
                    Report.RunModal(Report::"LT BJ NC2 Data Report", false);
                    Answer := 'ran';
                end;
            52:
                begin
                    Report.RunModal(Report::"LT BJ NC Report", false);
                    Answer := 'ran';
                end;
            53:
                begin
                    Report.Execute(Report::"LT BJ NC2 Data Report", ParamsText());
                    Answer := 'ran';
                end;
            54:
                begin
                    Report.Execute(Report::"LT BJ NC2 Data Report", '');
                    Answer := 'ran';
                end;
            55:
                begin
                    TempBlob.CreateOutStream(OutS);
                    Ok := Report.SaveAs(Report::"LT BJ NC2 Data Report", ParamsText(), ReportFormat::Xml, OutS);
                    Answer := Format(Ok) + ', has output ' + Format(TempBlob.Length() > 0);
                end;
            56:
                begin
                    TempBlob.CreateOutStream(OutS);
                    Ok := Report.SaveAs(Report::"LT BJ NC2 Data Report", '', ReportFormat::Xml, OutS);
                    Answer := Format(Ok) + ', has output ' + Format(TempBlob.Length() > 0);
                end;
        end;
    end;
}

page 81976 "LT BJ NC2 Record Page"
{
    PageType = Card;
    SourceTable = "LT BJ NoGui Row";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(No; Rec."No.") { ApplicationArea = All; }
        }
    }
}

report 81977 "LT BJ NC2 Data Report"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Rows; Integer)
        {
            DataItemTableView = where(Number = const(1));

            column(Num; Number) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Flag; Flag) { ApplicationArea = All; }
            }
        }
    }

    var
        Flag: Boolean;
}

codeunit 81978 "LT BJ NC2 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure RunGroup(Group: Text)
    var
        Row: Record "LT BJ NoGui Row";
        Pg: TestPage "LT BJ NoGui Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        ResultKey: Text;
    begin
        Row.DeleteAll();
        Row."No." := 'RUN';
        Row.Insert();
        Commit();
        Pg.OpenView();
        Params.Add('group', Group);
        Results := Pg.RunPageBackgroundTask(Codeunit::"LT BJ NC2 Worker", Params, false);
        foreach ResultKey in Results.Keys() do
            Observer.Observe(ResultKey, Results.Get(ResultKey));
        Pg.Close();
    end;

    [Test]
    procedure RunPageBackgroundTask_ClientTypeAndRecall()
    begin
        RunGroup('client');
        Observer.Finish();
    end;

    [Test]
    procedure RunPageBackgroundTask_PagesWithRecord()
    begin
        RunGroup('pages');
        Observer.Finish();
    end;

    [Test]
    procedure RunPageBackgroundTask_ReportsWithRequestPage()
    begin
        RunGroup('reports1');
        Observer.Finish();
    end;

    [Test]
    procedure RunPageBackgroundTask_ReportsWithoutRequestPage()
    begin
        RunGroup('reports2');
        Observer.Finish();
    end;

    [Test]
    procedure TestSession_ClientType()
    begin
        // For comparison: the same questions in the test session itself.
        Observer.Observe('c1 Format(CurrentClientType())', Format(CurrentClientType()));
        Observer.Observe('c2 = ClientType::Background', Format(CurrentClientType() = ClientType::Background));
        Observer.Observe('c4 = ClientType::Web', Format(CurrentClientType() = ClientType::Web));
        Observer.Observe('GuiAllowed', Format(GuiAllowed()));
        Observer.Finish();
    end;
}

codeunit 81979 "LT BJ NC2 Tests Handlers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerLog: Text;

    local procedure RunGroup(Group: Text)
    var
        Row: Record "LT BJ NoGui Row";
        Pg: TestPage "LT BJ NoGui Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        ResultKey: Text;
        Answers: Text;
    begin
        Row.DeleteAll();
        Row."No." := 'RUN';
        Row.Insert();
        Commit();
        Pg.OpenView();
        Params.Add('group', Group);
        Results := Pg.RunPageBackgroundTask(Codeunit::"LT BJ NC2 Worker", Params, false);
        // Only whether each cell returned or raised: the full values are in the test codeunit without handlers.
        foreach ResultKey in Results.Keys() do
            Answers += CopyStr(ResultKey, 1, StrPos(ResultKey + ' ', ' ') - 1) + ':' + CopyStr(Results.Get(ResultKey), 1, 5) + ';';
        Observer.Observe(Group, Answers);
        Pg.Close();
    end;

    [Test]
    [HandlerFunctions('PageH,ModalH,RequestPageH,SendH,RecallH')]
    procedure RunPageBackgroundTask_WithHandlers()
    var
        Row: Record "LT BJ NoGui Row";
        Note: Notification;
    begin
        HandlerLog := '';
        RunGroup('client');
        RunGroup('pages');
        RunGroup('reports1');
        RunGroup('reports2');
        Observer.Observe('handlers after the tasks', HandlerLog);
        // A declared handler that never runs fails the test, so the test session calls each dialog itself.
        Row.FindFirst();
        Page.Run(Page::"LT BJ NC2 Record Page", Row);
        Page.RunModal(Page::"LT BJ NC2 Record Page", Row);
        Report.Run(Report::"LT BJ NC2 Data Report");
        Note.Message := 'LT BJ NC2 from the test';
        Note.Send();
        Note.Recall();
        Observer.Observe('handlers after the test calls', HandlerLog);
        Observer.Finish();
    end;

    [PageHandler]
    procedure PageH(var RecPage: TestPage "LT BJ NC2 Record Page")
    begin
        HandlerLog += 'page handler: ' + RecPage.No.Value() + ';';
    end;

    [ModalPageHandler]
    procedure ModalH(var RecPage: TestPage "LT BJ NC2 Record Page")
    begin
        HandlerLog += 'modal page handler: ' + RecPage.No.Value() + ';';
        RecPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RequestPageH(var ReqPage: TestRequestPage "LT BJ NC2 Data Report")
    begin
        HandlerLog += 'request page handler;';
        ReqPage.Cancel().Invoke();
    end;

    [SendNotificationHandler]
    procedure SendH(var Note: Notification): Boolean
    begin
        HandlerLog += 'send handler: ' + Note.Message + ';';
        exit(true);
    end;

    [RecallNotificationHandler]
    procedure RecallH(var Note: Notification): Boolean
    begin
        HandlerLog += 'recall handler: ' + Note.Message + ';';
        exit(true);
    end;
}
