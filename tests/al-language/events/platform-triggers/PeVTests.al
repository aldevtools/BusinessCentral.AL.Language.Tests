// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-triggers-and-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT V Subs, LT V Log, LT V Event Log, LT V Row A - I and the LT V reports of PeVFixtures.al
// Platform events probed in one test codeunit (the log is SingleInstance, so it must belong to exactly one test codeunit):
//   1. Global Triggers: when each event fires, its arguments, what changing the mask, the four setup flags or the handed record does. Every scenario uses its own table,
//      because the platform asks for mask and setup once per table.
//   2. Events only a platform action raises (install, upgrade, environment copy, user initialization, company open and close, debugger, SmartList designer, Excel, the ChangeCompany
//      system action). The subscribers also write a row into the table LT V Event Log (no company), so an event raised before the test session started is visible too.
//   3. Reporting Triggers raised by Report.SaveAs / RunRequestPage / Execute, and what a subscriber that changes each var argument does.
// Note: the PDF, Word and Excel renders of Report.SaveAs run on the Linux tier of the CI (the 'Test Report SaveAs Pdf Body' test explains why they can refuse); their rows record what that tier raises.
// Not pinned: the PDF, Word and Excel renders and Report.Execute. The Linux tier of the CI stubs the RDLC renderer (it refuses with 'RDLC report rendering is not implemented on Linux BC'),
// so the events after the refusal are the stub's, not Business Central's. Only the Xml path and the request page are asserted.
// BC versions: 27 - 29

codeunit 69852 "LT V Platform Event Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT V Log";


    local procedure Cycle(TableNo: Integer; Observer: Codeunit "Probe Observer")
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(TableNo);
        RecRef.DeleteAll();
        Observer.Observe('open_and_deleteall', Log.Take());
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Value := 'a';
        RecRef.Field(3).Value := 1.5;
        RecRef.Insert(true);
        Observer.Observe('insert', Log.Take());
        RecRef.Field(2).Value := 'b';
        RecRef.Field(3).Value := 2.5;
        RecRef.Modify(true);
        Observer.Observe('modify', Log.Take());
        RecRef.Rename(2);
        Observer.Observe('rename', Log.Take());
        RecRef.Delete(true);
        Observer.Observe('delete', Log.Take());
        RecRef.Close();
        Log.Stop();
    end;

    [Test]
    procedure GlobalTriggers_SubscriberLeavesDefaults_RowA()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row A", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69841,in=0);Setup(69841);');
        Observer.Expect('insert', '');
        Observer.Expect('modify', '');
        Observer.Expect('rename', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_MaskFifteenAndAllSetupFlagsFalse_RowB()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row B", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69842,in=0);Setup(69842);');
        Observer.Expect('insert', '');
        Observer.Expect('modify', '');
        Observer.Expect('rename', 'GR(2/b/2.5 was 1/b/2.5);');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_MaskZeroAndAllSetupFlagsTrue_RowC()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row C", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69843,in=0);Setup(69843);');
        Observer.Expect('insert', 'DI(1/a/1.5);');
        Observer.Expect('modify', 'DM(1/b/2.5);');
        Observer.Expect('rename', 'DR(2/b/2.5 was 1/b/2.5);');
        Observer.Expect('delete', 'DD(2/b/2.5);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_MaskFifteenAndAllSetupFlagsTrue_Arguments_RowD()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row D", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69844,in=0);Setup(69844);');
        Observer.Expect('insert', 'DI(1/a/1.5);');
        Observer.Expect('modify', 'DM(1/b/2.5);');
        Observer.Expect('rename', 'GR(2/b/2.5 was 1/b/2.5);DR(2/b/2.5 was 1/b/2.5);');
        Observer.Expect('delete', 'DD(2/b/2.5);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_OnlyInsertFlag_RowE()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row E", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69845,in=0);Setup(69845);');
        Observer.Expect('insert', 'DI(1/a/1.5);');
        Observer.Expect('modify', '');
        Observer.Expect('rename', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_OnlyModifyFlag_RowF()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row F", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69846,in=0);Setup(69846);');
        Observer.Expect('insert', '');
        Observer.Expect('modify', 'DM(1/b/2.5);');
        Observer.Expect('rename', '');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_OnlyDeleteFlag_RowG()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row G", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69847,in=0);Setup(69847);');
        Observer.Expect('insert', '');
        Observer.Expect('modify', '');
        Observer.Expect('rename', '');
        Observer.Expect('delete', 'DD(2/b/2.5);');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_OnlyRenameFlag_RowH()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Start();
        Cycle(Database::"LT V Row H", Observer);
        Observer.Expect('open_and_deleteall', 'Mask(69848,in=0);Setup(69848);');
        Observer.Expect('insert', '');
        Observer.Expect('modify', '');
        Observer.Expect('rename', 'DR(2/b/2.5 was 1/b/2.5);');
        Observer.Expect('delete', '');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_SubscriberChangesTheRecordItIsHanded_RowI()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Check: Record "LT V Row I";
    begin
        Log.Start();
        RecRef.Open(Database::"LT V Row I");
        RecRef.DeleteAll();
        Observer.Observe('open_and_deleteall', Log.Take());
        RecRef.Init();
        RecRef.Field(1).Value := 1;
        RecRef.Field(2).Value := 'a';
        RecRef.Field(3).Value := 1.5;
        RecRef.Insert(true);
        Observer.Observe('insert_log', Log.Take());
        Observer.Observe('variable_after_insert', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        Observer.Observe('found', Format(Check.Get(1)));
        Observer.Observe('stored_after_insert', Check.Name + '/' + Format(Check.Amount));
        RecRef.Field(2).Value := 'b';
        RecRef.Field(3).Value := 2.5;
        RecRef.Modify(true);
        Observer.Observe('modify_log', Log.Take());
        Observer.Observe('variable_after_modify', Format(RecRef.Field(2).Value) + '/' + Format(RecRef.Field(3).Value));
        Observer.Observe('found_again', Format(Check.Get(1)));
        Observer.Observe('stored_after_modify', Check.Name + '/' + Format(Check.Amount));
        RecRef.Close();
        Log.Stop();
        Observer.Expect('open_and_deleteall', 'Mask(69849,in=0);Setup(69849);');
        Observer.Expect('insert_log', 'DI(1/a/1.5);');
        Observer.Expect('variable_after_insert', 'dbmut/1.5');
        Observer.Expect('found', 'Yes');
        Observer.Expect('stored_after_insert', 'dbmut/1.5');
        Observer.Expect('modify_log', 'DM(1/b/2.5);');
        Observer.Expect('variable_after_modify', 'dbmod/2.5');
        Observer.Expect('found_again', 'Yes');
        Observer.Expect('stored_after_modify', 'dbmod/2.5');
        Observer.Verify();
    end;

    [Test]
    procedure GlobalTriggers_InsertWithoutTrigger_DoesNotAskOrRaise()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Row D";
    begin
        // Row D was asked in the test above, so this checks the raise, not the ask: Insert(false) and Modify(false) run no trigger and raise no event.
        Log.Start();
        Row.Id := 5;
        Row.Name := 'quiet';
        Row.Insert(false);
        Observer.Observe('insert_false', Log.Take());
        Row.Name := 'quiet2';
        Row.Modify(false);
        Observer.Observe('modify_false', Log.Take());
        Row.Delete(false);
        Observer.Observe('delete_false', Log.Take());
        Row.Id := 6;
        Row.Insert(true);
        Observer.Observe('insert_true', Log.Take());
        Row.Delete(true);
        Observer.Observe('delete_true', Log.Take());
        Log.Stop();
        Observer.Expect('insert_false', 'DI(5/quiet/0);');
        Observer.Expect('modify_false', 'DM(5/quiet2/0);');
        Observer.Expect('delete_false', 'DD(5/quiet2/0);');
        Observer.Expect('insert_true', 'DI(6/quiet2/0);');
        Observer.Expect('delete_true', 'DD(6/quiet2/0);');
        Observer.Verify();
    end;


    local procedure RowsOf(EventName: Text): Integer
    var
        Row: Record "LT V Event Log";
    begin
        Row.SetRange("Event Name", EventName);
        exit(Row.Count());
    end;

    local procedure RowsOfSession(EventName: Text; Session: Integer): Integer
    var
        Row: Record "LT V Event Log";
    begin
        Row.SetRange("Event Name", EventName);
        Row.SetRange("Session Id", Session);
        exit(Row.Count());
    end;

    [Test]
    procedure EventLog_RowsWrittenBeforeTheTestSessionStarted()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Event Log";
        Names: List of [Text];
        N: Text;
    begin
        Names.Add('OnInstallAppPerCompany');
        Names.Add('OnInstallAppPerDatabase');
        Names.Add('OnUpgradePerCompany');
        Names.Add('OnUpgradePerDatabase');
        Names.Add('OnValidateUpgradePerCompany');
        Names.Add('OnValidateUpgradePerDatabase');
        Names.Add('OnAfterUpgradeCommitPerCompany');
        Names.Add('OnAfterUpgradeCommitPerDatabase');
        Names.Add('OnAfterCopyEnvironmentPerCompany');
        Names.Add('OnAfterCopyEnvironmentPerDatabase');
        Names.Add('OnAfterCopyEnvironmentToSandbox');
        Names.Add('OnAfterCopyEnvironmentToSandboxPerCompany');
        Names.Add('OnAfterUserInitialization');
        foreach N in Names do
            Observer.Observe('rows ' + N, Format(RowsOf(N)));
        Observer.Observe('early entries of the test session', Log.Early());
        Observer.Observe('total rows', Format(Row.Count()));
        Observer.Expect('rows OnInstallAppPerCompany', '2');
        Observer.Expect('rows OnInstallAppPerDatabase', '1');
        Observer.Expect('rows OnUpgradePerCompany', '0');
        Observer.Expect('rows OnUpgradePerDatabase', '0');
        Observer.Expect('rows OnValidateUpgradePerCompany', '0');
        Observer.Expect('rows OnValidateUpgradePerDatabase', '0');
        Observer.Expect('rows OnAfterUpgradeCommitPerCompany', '0');
        Observer.Expect('rows OnAfterUpgradeCommitPerDatabase', '0');
        Observer.Expect('rows OnAfterCopyEnvironmentPerCompany', '0');
        Observer.Expect('rows OnAfterCopyEnvironmentPerDatabase', '0');
        Observer.Expect('rows OnAfterCopyEnvironmentToSandbox', '0');
        Observer.Expect('rows OnAfterCopyEnvironmentToSandboxPerCompany', '0');
        Observer.Expect('rows OnAfterUserInitialization', '0');
        Observer.Expect('early entries of the test session', 'OnCompanyOpen(<Company>);OnCompanyOpenCompleted(<Company>);');
        Observer.Expect('total rows', '3');
        Observer.Verify();
    end;

    [Test]
    procedure EventLog_InstallRowCompany()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Event Log";
    begin
        Row.SetRange("Event Name", 'OnInstallAppPerCompany');
        if Row.FindSet() then
            repeat
                Observer.Observe('install per company #' + Format(Row.Id) + ' info is the company of the test session', Format(Row.Info = CompanyName()));
            until Row.Next() = 0;
        Observer.Expect('install per company #1 info is the company of the test session', 'Yes');
        Observer.Expect('install per company #2 info is the company of the test session', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InSession_NothingRaisesTheOtherEvents()
    var
        Observer: Codeunit "Probe Observer";
        Child: Record "Probe Rep Child";
    begin
        Log.Start();
        Child.Id := 90001;
        Child.Insert(true);
        Commit();
        Child.Delete(true);
        Commit();
        Observer.Observe('log after write and commit', Log.Take());
        Log.Stop();
        Observer.Expect('log after write and commit', '');
        Observer.Verify();
    end;

    [Test]
    procedure StartSession_IsRefusedInATestSession()
    var
        Observer: Codeunit "Probe Observer";
        Session: Integer;
        Started: Boolean;
    begin
        // A new session would show OnCompanyOpen and OnCompanyOpenCompleted to the worker; the test session cannot start one.
        asserterror Started := StartSession(Session, Codeunit::"LT V Session Worker", CompanyName());
        Observer.ObserveError('start session');
        Observer.Observe('started', Format(Started));
        Observer.Expect('start session|text', 'Sessions can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled.');
        Observer.Expect('start session|code', 'TestStartSessionNotAllowed');
        Observer.Expect('started', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeCompany_RecordChangeCompanyDoesNotRaiseTheSystemActionEvent()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT V Row A";
    begin
        Log.Start();
        Log.SetValue('change', 'ChangeCompany');
        Log.SetValue('company', 'LT V No Such Company');
        Row.ChangeCompany(CompanyName());
        Observer.Observe('log', Log.Take());
        Observer.Observe('company of the variable', Row.CurrentCompany());
        Observer.Observe('count in the other company', Format(Row.Count()));
        Log.Stop();
        Observer.Expect('log', '');
        Observer.Expect('company of the variable', '<Company>');
        Observer.Expect('count in the other company', '0');
        Observer.Verify();
    end;


    local procedure Seed()
    var
        Parent: Record "Probe Rep Parent";
        Child: Record "Probe Rep Child";
    begin
        Child.DeleteAll();
        Parent.DeleteAll();
        Parent.Id := 1;
        Parent.Name := 'one';
        Parent.Insert();
        Child.Id := 10;
        Child.ParentId := 1;
        Child.Code := 'a';
        Child.Insert();
        Commit();
    end;

    [TryFunction]
    local procedure TrySaveAs(ReportId: Integer; Fmt: ReportFormat; var Saved: Boolean; var Length: Integer; var Head: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        Saved := Report.SaveAs(ReportId, '', Fmt, OutStr);
        Length := TempBlob.Length();
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        if Length > 0 then
            InStr.ReadText(Head, 60);
    end;

    local procedure Run(Observer: Codeunit "Probe Observer"; Tag: Text; ReportId: Integer; Fmt: ReportFormat)
    var
        Saved: Boolean;
        Length: Integer;
        Head: Text;
        Ok: Boolean;
    begin
        Ok := TrySaveAs(ReportId, Fmt, Saved, Length, Head);
        if not Ok then
            Observer.ObserveError(Tag + ' error');
        if Head.StartsWith('%PDF') then
            Head := '%PDF';
        if Head.Contains('<ReportDataSet') then
            Head := CopyStr(Head, StrPos(Head, '<ReportDataSet'));
        Observer.Observe(Tag, Format(Ok) + '|saved=' + Format(Saved) + '|data=' + Format(Length > 0) + '|head=' + Head + '|' + Log.Take());
    end;

    [Test]
    procedure SaveAs_Xml_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Log.Start();
        Run(Observer, 'xml', Report::"LT V Report A", ReportFormat::Xml);
        Log.Stop();
        Observer.Expect('xml', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunRequestPage(var Parameters: Text)
    begin
        Parameters := Report.RunRequestPage(Report::"LT V Report A");
    end;

    [RequestPageHandler]
    procedure RequestPageA(var Request: TestRequestPage "LT V Report A")
    begin
        Request.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure RunRequestPage_RaisedEvents()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Log.Start();
        Observer.Observe('request page ok', Format(TryRunRequestPage(Parameters)));
        Observer.ObserveError('request page error');
        Observer.Observe('request page log', Log.Take());
        Log.Stop();
        Observer.Expect('request page ok', 'Yes');
        Observer.Expect('request page error|text', '');
        Observer.Expect('request page error|code', '');
        // Client-services sessions (Microsoft pipelines, the Linux runner) raise SetupPrinters(in=0) once on Report.RunRequestPage after SubstituteReport(...,ParametersOnly); web client sessions do not (bc-linux #168).
        Observer.Expect('request page log', 'SubstituteReport(69860,ParametersOnly,in=-1);SetupPrinters(in=0);');
        Observer.Verify();
    end;

    local procedure ChangeOne(Observer: Codeunit "Probe Observer"; EventName: Text; Fmt: ReportFormat)
    begin
        Log.Start();
        Log.SetValue('change', EventName);
        Run(Observer, EventName, Report::"LT V Report A", Fmt);
        Log.Stop();
    end;

    [Test]
    procedure SubstituteReport_SubscriberChangesTheReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'SubstituteReport', ReportFormat::Xml);
        Observer.Expect('SubstituteReport', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69861,in=No);');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_First()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'HasCustomLayout', ReportFormat::Xml);
        ChangeOne(Observer, 'SelectedBuiltinLayoutType', ReportFormat::Xml);
        ChangeOne(Observer, 'SelectReportLayoutCode', ReportFormat::Xml);
        Observer.Expect('HasCustomLayout', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('SelectedBuiltinLayoutType', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('SelectReportLayoutCode', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_Second()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'FetchReportLayoutByCode', ReportFormat::Xml);
        ChangeOne(Observer, 'CustomDocumentMergerEx', ReportFormat::Xml);
        ChangeOne(Observer, 'OnDocumentReady', ReportFormat::Xml);
        Observer.Expect('FetchReportLayoutByCode', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('CustomDocumentMergerEx', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('OnDocumentReady', 'Yes|saved=Yes|data=Yes|head=LTV ready|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_Third()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'OnIntermediateDocumentReady', ReportFormat::Xml);
        ChangeOne(Observer, 'OnDocumentPrintReady', ReportFormat::Xml);
        ChangeOne(Observer, 'OnDocumentDownload', ReportFormat::Xml);
        ChangeOne(Observer, 'GetPrinterName', ReportFormat::Xml);
        Observer.Expect('OnIntermediateDocumentReady', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('OnDocumentPrintReady', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('OnDocumentDownload', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('GetPrinterName', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeVarArguments_XmlSaveAs_Fourth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        ChangeOne(Observer, 'GetPaperTrayForReport', ReportFormat::Xml);
        ChangeOne(Observer, 'ScheduleReport', ReportFormat::Xml);
        ChangeOne(Observer, 'SetupPrinters', ReportFormat::Xml);
        ChangeOne(Observer, 'SelectReportLayoutUI', ReportFormat::Xml);
        ChangeOne(Observer, 'ApplicationReportMergeStrategy', ReportFormat::Xml);
        ChangeOne(Observer, 'WordDocumentMergerAppMode', ReportFormat::Xml);
        Observer.Expect('GetPaperTrayForReport', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('ScheduleReport', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('SetupPrinters', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('SelectReportLayoutUI', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('ApplicationReportMergeStrategy', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('WordDocumentMergerAppMode', 'Yes|saved=Yes|data=Yes|head=<?xml version="1.0" standalone="yes"?>|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Verify();
    end;
    // ---- Writer PW: which Reporting Triggers events the other report calls raise (trust-refusals probe list: Report.Run, RunModal, Execute,
    // the variable SaveAs, non-Xml formats; docs/probes-needed.md "Report runs and SaveAs": SubstituteReport and OnDocumentReady on calls
    // other than the pinned static Xml SaveAs, the RequestPageXml and RecordRef arguments, the OnDocumentReady payload keys and stream). ----

    [TryFunction]
    local procedure PwTryCall(Which: Text; var Parameters: Text)
    var
        Rep: Report "LT V Report A";
        ProcOnly: Report "LT PW V ProcOnly";
        Parent: Record "Probe Rep Parent";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        case Which of
            'requestpage static':
                Parameters := Report.RunRequestPage(Report::"LT V Report A");
            'saveas var xml':
                Rep.SaveAs('', ReportFormat::Xml, OutStr);
            'saveas static params xml':
                Report.SaveAs(Report::"LT V Report A", Parameters, ReportFormat::Xml, OutStr);
            'saveas static record xml':
                begin
                    Parent.SetRange(Id, 1);
                    RecRef.GetTable(Parent);
                    Report.SaveAs(Report::"LT V Report A", '', ReportFormat::Xml, OutStr, RecRef);
                end;
            'saveas static html':
                Report.SaveAs(Report::"LT V Report A", '', ReportFormat::Html, OutStr);
            'run static nopage':
                Report.Run(Report::"LT V Report A", false);
            'runmodal static nopage':
                Report.RunModal(Report::"LT V Report A", false);
            'run var nopage':
                begin
                    Rep.UseRequestPage(false);
                    Rep.Run();
                end;
            'runmodal var nopage':
                begin
                    Rep.UseRequestPage(false);
                    Rep.RunModal();
                end;
            'execute static':
                Report.Execute(Report::"LT V Report A", Parameters);
            'execute var':
                Rep.Execute(Parameters);
            'saveas static pdf':
                Report.SaveAs(Report::"LT V Report A", '', ReportFormat::Pdf, OutStr);
            'saveas static word':
                Report.SaveAs(Report::"LT V Report A", '', ReportFormat::Word, OutStr);
            'saveas static excel':
                Report.SaveAs(Report::"LT V Report A", '', ReportFormat::Excel, OutStr);
            'procOnly run nopage':
                Report.Run(Report::"LT PW V ProcOnly", false);
            'procOnly execute var':
                ProcOnly.Execute('');
            'procOnly execute static':
                Report.Execute(Report::"LT PW V ProcOnly", '');
            'procOnly runmodal nopage':
                Report.RunModal(Report::"LT PW V ProcOnly", false);
            'procOnly run var nopage':
                begin
                    ProcOnly.UseRequestPage(false);
                    ProcOnly.Run();
                end;
            'procOnly runmodal var nopage':
                begin
                    ProcOnly.UseRequestPage(false);
                    ProcOnly.RunModal();
                end;
            'procOnly saveas xml':
                Report.SaveAs(Report::"LT PW V ProcOnly", '', ReportFormat::Xml, OutStr);
        end;
    end;

    local procedure PwCall(var Observer: Codeunit "Probe Observer"; Which: Text; var Parameters: Text)
    var
        Ok: Boolean;
        Err: Text;
    begin
        Log.Start();
        Ok := PwTryCall(Which, Parameters);
        if not Ok then
            Err := ' error=' + GetLastErrorCode() + ':' + CopyStr(GetLastErrorText(), 1, 120);
        ClearLastError();
        Observer.Observe(Which, Format(Ok) + Err + '|' + Log.Take());
        Log.Stop();
    end;

    // Report.Run and RunModal of LT V Report A (an RDLC layout) end in the Linux tier's RDLC stub ('RDLC report rendering is not implemented on
    // Linux BC'): they are asserted with the Windows values in the held tests PW_RaisedEvents_RunRunModal, _Execute and _OtherFormats below;
    // the processing-only report has no layout to render.
    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure PW_RaisedEvents_RequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        // Execute of this RDLC report also ends in the Linux tier's RDLC stub (windows-queue.md).
        PwCall(Observer, 'requestpage static', Parameters);
        // Client-services sessions (Microsoft pipelines, the Linux runner) raise SetupPrinters(in=0) once on Report.RunRequestPage after SubstituteReport(...,ParametersOnly); web client sessions do not (bc-linux #168).
        Observer.Expect('requestpage static', 'Yes|SubstituteReport(69860,ParametersOnly,in=-1);SetupPrinters(in=0);');
        Observer.Verify();
    end;

    [Test]
    procedure PW_RaisedEvents_ProcessingOnlyRuns()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        PwCall(Observer, 'procOnly run nopage', Parameters);
        PwCall(Observer, 'procOnly runmodal nopage', Parameters);
        PwCall(Observer, 'procOnly run var nopage', Parameters);
        PwCall(Observer, 'procOnly runmodal var nopage', Parameters);
        PwCall(Observer, 'procOnly execute var', Parameters);
        PwCall(Observer, 'procOnly execute static', Parameters);
        Observer.Expect('procOnly run nopage', 'Yes|SubstituteReport(86147,Normal,in=-1);');
        Observer.Expect('procOnly runmodal nopage', 'Yes|SubstituteReport(86147,RunModal,in=-1);');
        Observer.Expect('procOnly run var nopage', 'Yes|');
        Observer.Expect('procOnly runmodal var nopage', 'Yes|');
        Observer.Expect('procOnly execute var', 'Yes|');
        Observer.Expect('procOnly execute static', 'Yes|SubstituteReport(86147,Execute,in=-1);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure PW_RaisedEvents_SaveAsForms()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        PwCall(Observer, 'saveas var xml', Parameters);
        PwCall(Observer, 'requestpage static', Parameters);
        PwCall(Observer, 'saveas static params xml', Parameters);
        PwCall(Observer, 'saveas static record xml', Parameters);
        PwCall(Observer, 'procOnly run nopage', Parameters);
        PwCall(Observer, 'procOnly execute var', Parameters);
        PwCall(Observer, 'procOnly saveas xml', Parameters);
        // Client-services sessions (Microsoft pipelines, the Linux runner) raise SetupPrinters(in=0) once on Report.RunRequestPage after SubstituteReport(...,ParametersOnly); web client sessions do not (bc-linux #168).
        Observer.Expect('saveas var xml', 'Yes|OnDocumentReady(69860,in=No);');
        Observer.Expect('requestpage static', 'Yes|SubstituteReport(69860,ParametersOnly,in=-1);SetupPrinters(in=0);');
        Observer.Expect('saveas static params xml', 'Yes|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('saveas static record xml', 'Yes|SubstituteReport(69860,SaveAs,in=-1);OnDocumentReady(69860,in=No);');
        Observer.Expect('procOnly run nopage', 'Yes|SubstituteReport(86147,Normal,in=-1);');
        Observer.Expect('procOnly execute var', 'Yes|');
        Observer.Expect('procOnly saveas xml', 'No error=ReportProcessingOnly:Report 86147 is a processing-only report. Output cannot be rendered and saved to a file.|SubstituteReport(86147,SaveAs,in=-1);');
        Observer.Verify();
    end;

    [Test]
    procedure PW_RaisedEvents_HtmlFormat()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        // Pdf, Word and Excel of this RDLC report end in the Linux tier's RDLC stub (windows-queue.md); Html is refused by BC itself.
        PwCall(Observer, 'saveas static html', Parameters);
        Observer.Expect('saveas static html', 'No error=ReportUnsupportedFormat:The Html output format is not supported by the current report layout format.|SubstituteReport(69860,SaveAs,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);ApplicationReportMergeStrategy(69860,Rdlc,in=No);');
        Observer.Verify();
    end;

#if BC28PLUS
    // Report.Run, RunModal and Execute of the RDLC report LT V Report A (no request page), and SaveAs Pdf/Word/Excel: the Reporting Triggers
    // events BC raises, from Windows BC 28.5 and 29.0 (Windows checks 2026-10-20; 29.0 gives the same values). Before the bc-linux fixes
    // the Linux image ended these calls in its RDLC stub or renderer error (bc-linux #144; BC 29.0: renderer off at boot, bc-linux #143).
    // BC 27.5 through the TestRunnerHub ends Run/RunModal/Execute with CallbackNotAllowed (a client callback to download the file), so 27
    // depends on the test runner and is not asserted.
    [Test]
    procedure PW_RaisedEvents_RunRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        PwCall(Observer, 'run static nopage', Parameters);
        PwCall(Observer, 'runmodal static nopage', Parameters);
        PwCall(Observer, 'run var nopage', Parameters);
        PwCall(Observer, 'runmodal var nopage', Parameters);
        Observer.Expect('run static nopage', 'Yes|SubstituteReport(69860,Normal,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);GetPrinterName(69860,in=);GetPaperTrayForReport(69860,in=0/0/0);ApplicationReportMergeStrategy(69860,Rdlc,in=No);SetupPrinters(in=0);OnDocumentReady(69860,in=No);OnDocumentDownload(69860,in=No);');
        Observer.Expect('runmodal static nopage', 'Yes|SubstituteReport(69860,RunModal,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);GetPrinterName(69860,in=);GetPaperTrayForReport(69860,in=0/0/0);ApplicationReportMergeStrategy(69860,Rdlc,in=No);SetupPrinters(in=0);OnDocumentReady(69860,in=No);OnDocumentDownload(69860,in=No);');
        Observer.Expect('run var nopage', 'Yes|SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);GetPrinterName(69860,in=);GetPaperTrayForReport(69860,in=0/0/0);ApplicationReportMergeStrategy(69860,Rdlc,in=No);SetupPrinters(in=0);OnDocumentReady(69860,in=No);OnDocumentDownload(69860,in=No);');
        Observer.Expect('runmodal var nopage', 'Yes|SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);GetPrinterName(69860,in=);GetPaperTrayForReport(69860,in=0/0/0);ApplicationReportMergeStrategy(69860,Rdlc,in=No);SetupPrinters(in=0);OnDocumentReady(69860,in=No);OnDocumentDownload(69860,in=No);');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure PW_RaisedEvents_Execute()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        PwCall(Observer, 'requestpage static', Parameters);
        PwCall(Observer, 'execute static', Parameters);
        PwCall(Observer, 'execute var', Parameters);
        // Client-services sessions (Microsoft pipelines, the Linux runner) raise SetupPrinters(in=0) once on Report.RunRequestPage after SubstituteReport(...,ParametersOnly); web client sessions do not (bc-linux #168).
        Observer.Expect('requestpage static', 'Yes|SubstituteReport(69860,ParametersOnly,in=-1);SetupPrinters(in=0);');
        Observer.Expect('execute static', 'Yes|SubstituteReport(69860,Execute,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);GetPrinterName(69860,in=);GetPaperTrayForReport(69860,in=0/0/0);ApplicationReportMergeStrategy(69860,Rdlc,in=No);SetupPrinters(in=0);OnDocumentReady(69860,in=No);OnDocumentDownload(69860,in=No);');
        Observer.Expect('execute var', 'Yes|SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);GetPrinterName(69860,in=);GetPaperTrayForReport(69860,in=0/0/0);ApplicationReportMergeStrategy(69860,Rdlc,in=No);SetupPrinters(in=0);OnDocumentReady(69860,in=No);OnDocumentDownload(69860,in=No);');
        Observer.Verify();
    end;

    [Test]
    procedure PW_RaisedEvents_OtherFormats()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        PwCall(Observer, 'saveas static pdf', Parameters);
        PwCall(Observer, 'saveas static word', Parameters);
        PwCall(Observer, 'saveas static excel', Parameters);
        Observer.Expect('saveas static pdf', 'Yes|SubstituteReport(69860,SaveAs,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);ApplicationReportMergeStrategy(69860,Rdlc,in=No);OnDocumentReady(69860,in=No);');
        Observer.Expect('saveas static word', 'Yes|SubstituteReport(69860,SaveAs,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);ApplicationReportMergeStrategy(69860,Rdlc,in=No);OnDocumentReady(69860,in=No);');
        Observer.Expect('saveas static excel', 'Yes|SubstituteReport(69860,SaveAs,in=-1);SelectReportLayoutCode(69860,in=/None/No);HasCustomLayout(Report,69860,in=None);SelectedBuiltinLayoutType(69860,in=None);ApplicationReportMergeStrategy(69860,Rdlc,in=No);OnDocumentReady(69860,in=No);');
        Observer.Verify();
    end;
#endif

    local procedure PwArgs(var Observer: Codeunit "Probe Observer"; Which: Text; var Parameters: Text)
    var
        ArgSubs: Codeunit "LT PW V Arg Subs";
        Ok: Boolean;
    begin
        BindSubscription(ArgSubs);
        Log.Start();
        Log.SetValue('pwcollect', 'yes');
        Ok := PwTryCall(Which, Parameters);
        if not Ok then
            Observer.Observe(Which + ' error', GetLastErrorCode() + ':' + CopyStr(GetLastErrorText(), 1, 120));
        ClearLastError();
        Observer.Observe(Which, Format(Ok) + '|' + Log.GetValue('pwargs'));
        Log.Take();
        Log.Stop();
        UnbindSubscription(ArgSubs);
    end;

    [Test]
    [HandlerFunctions('RequestPageA')]
    procedure PW_SubstituteReport_Arguments_And_DocumentReadyPayload()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Seed();
        Parameters := '';
        PwArgs(Observer, 'saveas var xml', Parameters);
        PwArgs(Observer, 'requestpage static', Parameters);
        PwArgs(Observer, 'saveas static params xml', Parameters);
        PwArgs(Observer, 'saveas static record xml', Parameters);
        Observer.Expect('saveas var xml', 'Yes|Ready(keys=filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid, documenttype=text/xml head=Ù‹<?xml version="1.0" standalone="yes"?);');
        Observer.Expect('requestpage static', 'Yes|Sub(ParametersOnly,xmlLen>0=No,xmlHasDataItem=No,xmlHasPrefix=No,recNo=0);');
        Observer.Expect('saveas static params xml', 'Yes|Sub(SaveAs,xmlLen>0=Yes,xmlHasDataItem=Yes,xmlHasPrefix=Yes,recNo=0);Ready(keys=filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid, documenttype=text/xml head=Ù‹<?xml version="1.0" standalone="yes"?);');
        Observer.Expect('saveas static record xml', 'Yes|Sub(SaveAs,xmlLen>0=No,xmlHasDataItem=No,xmlHasPrefix=No,recNo=68300);Ready(keys=filterviews,version,objectname,objectid,documenttype,invokedby,invokeddatetime,companyname,printername,duplex,color,defaultcopies,papertray,intent,layoutmodel,layoutname,layoutmimetype,layoutapplicationid,reportrunid, documenttype=text/xml head=Ù‹<?xml version="1.0" standalone="yes"?);');
        Observer.Verify();
    end;
}

// Writer PW: a second subscriber to SubstituteReport and OnDocumentReady that records the arguments the LT V Subs subscribers do not log.
// It writes only into the 'pwargs' setting of LT V Log, only while bound (manual subscription) by a PW test that set 'pwcollect'.
codeunit 86146 "LT PW V Arg Subs"
{
    EventSubscriberInstance = Manual;

    var
        Log: Codeunit "LT V Log";

    local procedure Append(Entry: Text)
    begin
        Log.SetValue('pwargs', Log.GetValue('pwargs') + Entry + ';');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'SubstituteReport', '', false, false)]
    local procedure PwSubstitute(ReportId: Integer; RunMode: Option Normal,ParametersOnly,Execute,Print,SaveAs,RunModal; RequestPageXml: Text; RecordRef: RecordRef; var NewReportId: Integer)
    begin
        if not Log.Has('pwcollect') then
            exit;
        Append('Sub(' + Format(RunMode) + ',xmlLen>0=' + Format(StrLen(RequestPageXml) > 0) + ',xmlHasDataItem=' + Format(RequestPageXml.Contains('<DataItem')) +
            ',xmlHasPrefix=' + Format(RequestPageXml.Contains('Prefix')) + ',recNo=' + Format(RecordRef.Number()) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reporting Triggers", 'OnDocumentReady', '', false, false)]
    local procedure PwDocumentReady(ObjectId: Integer; ObjectPayload: JsonObject; DocumentStream: InStream; var TargetStream: OutStream; var Success: Boolean)
    var
        Keys: Text;
        K: Text;
        Head: Text;
        Tok: JsonToken;
        DocType: Text;
    begin
        if not Log.Has('pwcollect') then
            exit;
        foreach K in ObjectPayload.Keys() do
            Keys += K + ',';
        if ObjectPayload.Get('documenttype', Tok) then
            DocType := Tok.AsValue().AsText();
        DocumentStream.ReadText(Head, 40);
        Append('Ready(keys=' + Keys + ' documenttype=' + DocType + ' head=' + Head + ')');
    end;
}

// Writer PW: a processing-only report with a request page, for the Reporting Triggers probes.
report 86147 "LT PW V ProcOnly"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(P; "Probe Rep Parent")
        {
        }
    }
}
