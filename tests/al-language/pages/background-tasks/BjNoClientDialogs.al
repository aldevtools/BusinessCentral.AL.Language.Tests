// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-guiallowed-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 81680 and page 81682 of BjNoGuiDialogs.al; own worker codeunit 81970, page 81971, report 81972, test codeunits 81973 and 81974
// Probe (observe only): al-runner issue 7564 (a run option for a session without a client). BjNoGuiDialogs.al pins GuiAllowed, Message and Confirm in a page
//   background task worker. This probe asks what every other dialog does there: StrMenu (with and without an instruction), Page.RunModal, Page.Run,
//   Dialog Open/Update/Close, Hyperlink, Notification.Send, Report.RunModal, Report.Run, FilterPageBuilder.RunModal, UploadIntoStream and
//   SessionSettings.RequestSessionUpdate, each in a TryFunction so the error code and text show. A test cannot start a web-service session; the worker
//   is the closest session without a client a test can reach (see BjNoGuiDialogs.al). The second test codeunit also declares handlers and calls each
//   dialog itself afterwards, so a handler that fires for a call of the worker would show in its log.
//   The result per dialog is observed as `<step>` = `returned: <answer>` or `error: <text> code=<code>`.
// BC versions: 27, 28, 29

codeunit 81970 "LT BJ NoClient Worker"
{
    trigger OnRun()
    var
        Results: Dictionary of [Text, Text];
    begin
        Probe(1, '01 StrMenu with instruction', Results);
        Probe(2, '02 StrMenu without instruction', Results);
        Probe(3, '03 Page.RunModal by id', Results);
        Probe(4, '04 Page.Run by id', Results);
        Probe(5, '05 Dialog Open Update Close', Results);
        Probe(6, '06 Hyperlink', Results);
        Probe(7, '07 Notification.Send', Results);
        Probe(8, '08 Report.RunModal', Results);
        Probe(9, '09 Report.Run', Results);
        Probe(10, '10 FilterPageBuilder.RunModal', Results);
        Probe(11, '11 UploadIntoStream', Results);
        Probe(12, '12 SessionSettings.RequestSessionUpdate', Results);
        Probe(13, '13 Page.RunModal on a variable', Results);
        Probe(14, '14 Dialog Open only', Results);
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

    [TryFunction]
    local procedure TryStep(Step: Integer; var Answer: Text)
    var
        Dlg: Dialog;
        DlgPage: Page "LT BJ NC Dialog Page";
        Note: Notification;
        FilterPage: FilterPageBuilder;
        SessSettings: SessionSettings;
        UploadStream: InStream;
        UploadName: Text;
    begin
        case Step of
            1:
                Answer := Format(StrMenu('One,Two', 1, 'LT BJ pick one'));
            2:
                Answer := Format(StrMenu('One,Two', 2));
            3:
                Answer := Format(Page.RunModal(Page::"LT BJ NC Dialog Page"));
            4:
                begin
                    Page.Run(Page::"LT BJ NC Dialog Page");
                    Answer := 'ran';
                end;
            5:
                begin
                    Dlg.Open('LT BJ working #1######');
                    Dlg.Update(1, 5);
                    Dlg.Close();
                    Answer := 'done';
                end;
            6:
                begin
                    Hyperlink('https://example.com/lt-bj-nc');
                    Answer := 'ran';
                end;
            7:
                begin
                    Note.Message := 'LT BJ notification';
                    Answer := Format(Note.Send());
                end;
            8:
                begin
                    Report.RunModal(Report::"LT BJ NC Report");
                    Answer := 'ran';
                end;
            9:
                begin
                    Report.Run(Report::"LT BJ NC Report");
                    Answer := 'ran';
                end;
            10:
                begin
                    FilterPage.AddTable('Rows', Database::"LT BJ NoGui Row");
                    Answer := Format(FilterPage.RunModal());
                end;
            11:
                Answer := Format(UploadIntoStream('LT BJ upload', '', '', UploadName, UploadStream));
            12:
                begin
                    SessSettings.Init();
                    SessSettings.RequestSessionUpdate(false);
                    Answer := 'ran';
                end;
            13:
                Answer := Format(DlgPage.RunModal());
            14:
                begin
                    Dlg.Open('LT BJ open only');
                    Answer := 'open returned';
                end;
        end;
    end;
}

page 81971 "LT BJ NC Dialog Page"
{
    PageType = Card;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Info; InfoText) { ApplicationArea = All; }
        }
    }

    var
        InfoText: Text;
}

report 81972 "LT BJ NC Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

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

codeunit 81973 "LT BJ NoClient Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [Test]
    procedure RunPageBackgroundTask_Dialogs()
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
        Results := Pg.RunPageBackgroundTask(Codeunit::"LT BJ NoClient Worker", Params, false);
        foreach ResultKey in Results.Keys() do
            Observer.Observe(ResultKey, Results.Get(ResultKey));
        Pg.Close();
        Observer.Expect('01 StrMenu with instruction', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to show a selection menu: LT BJ pick one (CodeUnit 81970 LT BJ NoClient Worker). Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('02 StrMenu without instruction', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to show a selection menu:  (CodeUnit 81970 LT BJ NoClient Worker). Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('03 Page.RunModal by id', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81971 LT BJ NC Dialog Page as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('04 Page.Run by id', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81971 LT BJ NC Dialog Page. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('05 Dialog Open Update Close', 'returned: done');
        Observer.Expect('06 Hyperlink', 'returned: ran');
        Observer.Expect('07 Notification.Send', 'returned: Yes');
        Observer.Expect('08 Report.RunModal', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81972 RequestOptionsPage as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('09 Report.Run', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81972 RequestOptionsPage as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('10 FilterPageBuilder.RunModal', 'returned: No');
        Observer.Expect('11 UploadIntoStream', 'returned: No');
        Observer.Expect('12 SessionSettings.RequestSessionUpdate', 'returned: ran');
        Observer.Expect('13 Page.RunModal on a variable', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81971 LT BJ NC Dialog Page as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('14 Dialog Open only', 'returned: open returned');
        Observer.Verify();
    end;
}

codeunit 81974 "LT BJ NoClient Tests Handlers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerLog: Text;

    [Test]
    [HandlerFunctions('StrMenuH,ModalH,HyperlinkH,NotificationH')]
    procedure RunPageBackgroundTask_Dialogs_WithHandlers()
    var
        Row: Record "LT BJ NoGui Row";
        Pg: TestPage "LT BJ NoGui Card";
        DlgPage: Page "LT BJ NC Dialog Page";
        Note: Notification;
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        ResultKey: Text;
        Choice: Integer;
    begin
        Row.DeleteAll();
        Row."No." := 'RUN';
        Row.Insert();
        Commit();
        Pg.OpenView();
        HandlerLog := '';
        Results := Pg.RunPageBackgroundTask(Codeunit::"LT BJ NoClient Worker", Params, false);
        foreach ResultKey in Results.Keys() do
            Observer.Observe(ResultKey, Results.Get(ResultKey));
        Observer.Observe('handlers after the task', HandlerLog);
        // The listed handlers must run or the test fails, so the test session calls each dialog itself.
        Choice := StrMenu('One,Two', 1, 'LT BJ pick from the test');
        DlgPage.RunModal();
        Hyperlink('https://example.com/lt-bj-nc-test');
        Note.Message := 'LT BJ notification from the test';
        Note.Send();
        Observer.Observe('handlers after the test calls', HandlerLog);
        Pg.Close();
        Observer.Expect('01 StrMenu with instruction', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to show a selection menu: LT BJ pick one (CodeUnit 81970 LT BJ NoClient Worker). Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('02 StrMenu without instruction', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to show a selection menu:  (CodeUnit 81970 LT BJ NoClient Worker). Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('03 Page.RunModal by id', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81971 LT BJ NC Dialog Page as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('04 Page.Run by id', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81971 LT BJ NC Dialog Page. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('05 Dialog Open Update Close', 'returned: done');
        Observer.Expect('06 Hyperlink', 'returned: ran');
        Observer.Expect('07 Notification.Send', 'returned: Yes');
        Observer.Expect('08 Report.RunModal', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81972 RequestOptionsPage as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('09 Report.Run', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81972 RequestOptionsPage as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('10 FilterPageBuilder.RunModal', 'returned: No');
        Observer.Expect('11 UploadIntoStream', 'returned: No');
        Observer.Expect('12 SessionSettings.RequestSessionUpdate', 'returned: ran');
        Observer.Expect('13 Page.RunModal on a variable', 'error: Microsoft Dynamics 365 Business Central Server attempted to issue a client callback to run page 81971 LT BJ NC Dialog Page as modal. Client callbacks are not supported on Microsoft Dynamics 365 Business Central Server. code=CallbackNotAllowed');
        Observer.Expect('14 Dialog Open only', 'returned: open returned');
        Observer.Expect('handlers after the task', '');
        Observer.Expect('handlers after the test calls', 'strmenu handler: One,Two|LT BJ pick from the test;modal page handler;hyperlink handler: https://example.com/lt-bj-nc-test;notification handler: LT BJ notification from the test;');
        Observer.Verify();
    end;



    [StrMenuHandler]
    procedure StrMenuH(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        HandlerLog += 'strmenu handler: ' + Options + '|' + Instruction + ';';
        Choice := 1;
    end;

    [ModalPageHandler]
    procedure ModalH(var DlgPage: TestPage "LT BJ NC Dialog Page")
    begin
        HandlerLog += 'modal page handler;';
        DlgPage.OK().Invoke();
    end;

    [HyperlinkHandler]
    procedure HyperlinkH(Link: Text[1024])
    begin
        HandlerLog += 'hyperlink handler: ' + Link + ';';
    end;

    [SendNotificationHandler]
    procedure NotificationH(var Note: Notification): Boolean
    begin
        HandlerLog += 'notification handler: ' + Note.Message + ';';
        exit(true);
    end;
}
