// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-isolated-storage
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-integer-table-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT CU Row (85300), LT CU Other (85301), LT CU Row List (85302), LT CU Inserter (85303),
//   LT CU TableNo Run (85305), LT CU Report (85306), LT CU Named Run (85308, namespace LTCU.Probe)
// Corpus #670 items 37, 42, 45: what IsolatedStorage.Set leaves behind for Page.RunModal, a guarded Codeunit.Run and Report.RunModal;
// Codeunit.Run of a TableNo codeunit with a record of another table, and by an unknown name; Report.Run with a request page right after a write.
// BC versions: 27.5, 28.5, 29.0

codeunit 85312 "LT CU Write Tx Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerLog: Text;

    local procedure Initialize()
    var
        Row: Record "LT CU Row";
    begin
        Row.DeleteAll();
        Commit();
        ClearLastError();
        HandlerLog := '';
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT CU Row";
        Ids: Text;
    begin
        if Row.FindSet() then
            repeat
                Ids += Format(Row.Id) + ';';
            until Row.Next() = 0;
        exit('[' + Ids + ']');
    end;

    local procedure InsertPending(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := Id;
        Row.Insert();
    end;

    [ModalPageHandler]
    procedure RowListHandler(var Page: TestPage "LT CU Row List")
    begin
        HandlerLog += 'modal;';
        Page.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReportHandler(var RequestPage: TestRequestPage "LT CU Report")
    begin
        HandlerLog += 'requestpage;';
        RequestPage.OK().Invoke();
    end;

    // ---------------------------------------------------------------- item 37
    [Test]
    [HandlerFunctions('RowListHandler')]
    procedure IsolatedStorageSet_ThenPageRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w1', 'v', DataScope::User);
        Page.RunModal(Page::"LT CU Row List");
        Observer.Observe('handler', HandlerLog);
        IsolatedStorage.Delete('LTCU_w1', DataScope::User);
        Observer.Expect('handler', 'modal;');
        Observer.Verify();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_User()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w2', 'v', DataScope::User);
        asserterror Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.ObserveError('run');
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        Observer.Observe('stored after', Format(IsolatedStorage.Contains('LTCU_w2', DataScope::User)));
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows', '[]');
        Observer.Expect('stored after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_Module()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w3', 'v', DataScope::Module);
        asserterror Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.ObserveError('run');
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        Observer.Observe('stored after', Format(IsolatedStorage.Contains('LTCU_w3', DataScope::Module)));
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows', '[]');
        Observer.Expect('stored after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_Company()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w4', 'v', DataScope::Company);
        asserterror Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.ObserveError('run');
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        Observer.Observe('stored after', Format(IsolatedStorage.Contains('LTCU_w4', DataScope::Company)));
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows', '[]');
        Observer.Expect('stored after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenGuardedCodeunitRun_CompanyAndUser()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w5', 'v', DataScope::CompanyAndUser);
        asserterror Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.ObserveError('run');
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        Observer.Observe('stored after', Format(IsolatedStorage.Contains('LTCU_w5', DataScope::CompanyAndUser)));
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows', '[]');
        Observer.Expect('stored after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsolatedStorageSet_Commit_ThenGuardedCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w6', 'v', DataScope::User);
        Commit();
        Ok := Codeunit.Run(Codeunit::"LT CU Inserter");
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows', Rows());
        IsolatedStorage.Delete('LTCU_w6', DataScope::User);
        Observer.Expect('ok', 'Yes');
        Observer.Expect('rows', '[100;]');
        Observer.Verify();
    end;

    [Test]
    procedure IsolatedStorageSet_ThenReportRunModal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        IsolatedStorage.Set('LTCU_w7', 'v', DataScope::User);
        asserterror Report.RunModal(Report::"LT CU Report", true);
        Observer.ObserveError('runmodal');
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        Observer.Observe('stored after', Format(IsolatedStorage.Contains('LTCU_w7', DataScope::User)));
        Observer.Expect('runmodal|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('runmodal|code', 'DB:Ok');
        Observer.Expect('handler', '');
        Observer.Expect('rows', '[]');
        Observer.Expect('stored after', 'No');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 42
    [Test]
    procedure CodeunitRun_TableNo_RecordOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "LT CU Other";
    begin
        Initialize();
        Other.Id := 1;
        asserterror Codeunit.Run(Codeunit::"LT CU TableNo Run", Other);
        Observer.ObserveError('statement');
        Observer.Expect('statement|text', 'Record(85301) is not compatible with Codeunit.Run(Record(85300)).');
        Observer.Expect('statement|code', 'InvalidType');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_TableNo_RecordOfAnotherTable_Guarded()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "LT CU Other";
        Ok: Boolean;
    begin
        Initialize();
        Other.Id := 1;
        asserterror Ok := Codeunit.Run(Codeunit::"LT CU TableNo Run", Other);
        Observer.ObserveError('guarded');
        Observer.Observe('ok', Format(Ok));
        Observer.Expect('guarded|text', 'Record(85301) is not compatible with Codeunit.Run(Record(85300)).');
        Observer.Expect('guarded|code', 'InvalidType');
        Observer.Expect('ok', 'No');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure CodeunitRun_ByName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        Row.Id := 1;
        RunByName(Observer, 'LT CU TableNo Run', Row);
        RunByName(Observer, 'LT CU No Such Codeunit', Row);
        RunByName(Observer, 'LTCU.Probe.LT CU No Such Codeunit', Row);
        RunByName(Observer, 'NoSuch.Namespace.LT CU Named Run', Row);
        Observer.Expect('LT CU TableNo Run|ok', 'No');
        Observer.Expect('LT CU TableNo Run|name', '');
        Observer.Expect('LT CU TableNo Run|text', 'The provided object name is not fully qualified.');
        Observer.Expect('LT CU TableNo Run|code', 'InvalidOperation');
        Observer.Expect('LT CU No Such Codeunit|ok', 'No');
        Observer.Expect('LT CU No Such Codeunit|name', '');
        Observer.Expect('LT CU No Such Codeunit|text', 'The provided object name is not fully qualified.');
        Observer.Expect('LT CU No Such Codeunit|code', 'InvalidOperation');
        Observer.Expect('LTCU.Probe.LT CU No Such Codeunit|ok', 'No');
        Observer.Expect('LTCU.Probe.LT CU No Such Codeunit|name', '');
        Observer.Expect('LTCU.Probe.LT CU No Such Codeunit|text', 'A codeunit with full name LTCU.Probe.LT CU No Such Codeunit could not be found.');
        Observer.Expect('LTCU.Probe.LT CU No Such Codeunit|code', 'InvalidMetadata');
        Observer.Expect('NoSuch.Namespace.LT CU Named Run|ok', 'No');
        Observer.Expect('NoSuch.Namespace.LT CU Named Run|name', '');
        Observer.Expect('NoSuch.Namespace.LT CU Named Run|text', 'A codeunit with full name NoSuch.Namespace.LT CU Named Run could not be found.');
        Observer.Expect('NoSuch.Namespace.LT CU Named Run|code', 'InvalidMetadata');
        Observer.Verify();
    end;

    // Codeunit.Run(Text) with the namespace-qualified name of codeunit 85308 (namespace LTCU.Probe, CuNamedRun.al), plain and with the
    // object name quoted: Windows BC 28.5 and 29.0 (Windows BC 29.0 check 2026-10-20) run the codeunit for both spellings (OnRun sets
    // Rec.Name to 'x'). Was held on Linux for bc-linux #159 (the Linux image, BC 29.0, answered 'A codeunit with full
    // name LTCU.Probe.LT CU Named Run could not be found.', InvalidMetadata); the bc-linux maintainer cannot reproduce it on the current image.
    [Test]
    procedure CodeunitRun_ByQualifiedName()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
        Named: Codeunit LTCU.Probe."LT CU Named Run"; // not called: names the codeunit for the CI test selection
    begin
        Initialize();
        Row.Id := 1;
        RunByName(Observer, 'LTCU.Probe.LT CU Named Run', Row);
        RunByName(Observer, 'LTCU.Probe."LT CU Named Run"', Row);
        Observer.Expect('LTCU.Probe.LT CU Named Run|ok', 'Yes');
        Observer.Expect('LTCU.Probe.LT CU Named Run|name', 'x');
        Observer.Expect('LTCU.Probe.LT CU Named Run|text', '');
        Observer.Expect('LTCU.Probe.LT CU Named Run|code', '');
        Observer.Expect('LTCU.Probe."LT CU Named Run"|ok', 'Yes');
        Observer.Expect('LTCU.Probe."LT CU Named Run"|name', 'x');
        Observer.Expect('LTCU.Probe."LT CU Named Run"|text', '');
        Observer.Expect('LTCU.Probe."LT CU Named Run"|code', '');
        Observer.Verify();
    end;


    local procedure RunByName(var Observer: Codeunit "Probe Observer"; Name: Text; var Row: Record "LT CU Row")
    begin
        Row.Name := '';
        ClearLastError();
        Observer.Observe(Name + '|ok', Format(TryRunByName(Name, Row)));
        Observer.Observe(Name + '|name', Row.Name);
        Observer.ObserveError(Name);
    end;

    [TryFunction]
    local procedure TryRunByName(Name: Text; var Row: Record "LT CU Row")
    begin
        Codeunit.Run(Name, Row);
    end;
#endif

    // ---------------------------------------------------------------- item 45
    [Test]
    procedure ReportRun_RequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        asserterror Report.Run(Report::"LT CU Report", true, true, Row);
        Observer.ObserveError('report');
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        Observer.Expect('report|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('report|code', 'DB:Ok');
        Observer.Expect('handler', '');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRun_NoRequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        Report.Run(Report::"LT CU Report", false, false, Row);
        Observer.Observe('rows', Rows());
        Observer.Expect('rows', '[1;900;]');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRunModal_RequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        asserterror Report.RunModal(Report::"LT CU Report", true, true, Row);
        Observer.ObserveError('report');
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        Observer.Expect('report|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('report|code', 'DB:Ok');
        Observer.Expect('handler', '');
        Observer.Expect('rows', '[]');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ReportHandler')]
    procedure ReportRun_RequestPage_NoPendingWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        Row.SetRange(Id, 1);
        Report.Run(Report::"LT CU Report", true, true, Row);
        Observer.Observe('handler', HandlerLog);
        Observer.Observe('rows', Rows());
        Observer.Expect('handler', 'requestpage;');
        Observer.Expect('rows', '[900;]');
        Observer.Verify();
    end;

    [Test]
    procedure ReportRunModal_NoRequestPage_AfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CU Row";
    begin
        Initialize();
        InsertPending(1);
        Row.SetRange(Id, 1);
        Report.RunModal(Report::"LT CU Report", false, false, Row);
        Observer.Observe('rows', Rows());
        Observer.Expect('rows', '[1;900;]');
        Observer.Verify();
    end;
}
