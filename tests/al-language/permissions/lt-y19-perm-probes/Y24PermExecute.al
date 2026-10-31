// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y24PermObjects.al (91936-91978); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 (permission enforcement in stages), stage 3 probes, writer Y24:
//   P20 Execute: SetExactPermissionSet of a set with table data grants only (no All Objects): Codeunit.Run, a call on a codeunit
//       variable, a report run, Page.Run, TestPage.OpenView, XmlPort.Export, Query.Open, a table procedure call; then the same from a
//       codeunit the exact set grants Execute on (a Permissions property cannot hold Execute grants: only tabledata entries compile,
//       tests/must-not-compile/cases/2360, 2361);
//   P21 AccessByPermission: page fields guarded by tabledata T = R and = I, an action guarded by codeunit C = X, a request page field
//       guarded by tabledata T = R, under sets that grant and that do not grant;
//   P22 "User Permissions".GetEffectivePermission (System Application; it returns NavUserAccountHelper.GetEffectivePermissionForObject)
//       for TableData, Table, Codeunit, Page and Report under no set, under a narrow set (Set: the set plus All Objects) and under the
//       same set exactly (SetExactPermissionSet).
// Shape: under an exact set nothing but the test codeunit's own code and already created variables runs before the assignment is
//   cleared: each case assigns the set, runs ONE operation inside asserterror ending with 'LT Y24 ok <result>', keeps the error text
//   and code in local variables, clears the assignment, and only then observes.
// BC versions: 27, 28, 29

codeunit 91977 "LT Y24 Perm Execute"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // One Observer per codeunit: the _More tests raise the rest of a long observation.
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y24 Perm Helper";
        Mock: Codeunit "Permissions Mock";
        GuardVisible: Text;

    [Test]
    procedure Y24_P20_ExecuteTableDataOnly()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact(Observer, 'tdonly_codeunit_run', 'LT Y24 TD Only', 1);
        RunExact(Observer, 'tdonly_codeunit_var', 'LT Y24 TD Only', 2);
        RunExact(Observer, 'tdonly_report_run', 'LT Y24 TD Only', 3);
        RunExact(Observer, 'tdonly_testpage_openview', 'LT Y24 TD Only', 5);
        RunExact(Observer, 'tdonly_xmlport_export', 'LT Y24 TD Only', 6);
        RunExact(Observer, 'tdonly_query_open', 'LT Y24 TD Only', 7);
        RunExact(Observer, 'tdonly_table_procedure', 'LT Y24 TD Only', 8);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P20_ExecuteTableDataOnly_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P20_ExecuteTableDataOnly_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P20_ExecuteThroughGranter()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact(Observer, 'granter_codeunit_run', 'LT Y24 TD Granter', 11);
        RunExact(Observer, 'granter_codeunit_var', 'LT Y24 TD Granter', 12);
        RunExact(Observer, 'granter_report_run', 'LT Y24 TD Granter', 13);
        RunExact(Observer, 'granter_xmlport_export', 'LT Y24 TD Granter', 16);
        RunExact(Observer, 'granter_query_open', 'LT Y24 TD Granter', 17);
        RunExact(Observer, 'granter_table_procedure', 'LT Y24 TD Granter', 18);
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P20_ExecuteThroughGranter_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P20_ExecuteThroughGranter_More2()
    begin
        Observer.More();
    end;

    // Page.Run needs a page handler; the last call runs with no set so that the handler is always used once.
    [Test]
    [HandlerFunctions('Y24RowCardHandler')]
    procedure Y24_P20_ExecutePageRun()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        RunExact(Observer, 'tdonly_page_run', 'LT Y24 TD Only', 4);
        RunExact(Observer, 'granter_page_run', 'LT Y24 TD Granter', 14);
        Mock.ClearAssignments();
        asserterror Op(4);
        Observer.ObserveError('noset_page_run');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P20_ExecutePageRun_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P20_ExecutePageRun_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P21_AccessByPermissionPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Helper.Seed();
        Mock.Set('LT Y24 ABP Grant');
        ObserveControls(Observer, 'grant: ');
        Mock.Set('LT Y24 RIMD');
        ObserveControls(Observer, 'no_grant: ');
        Mock.SetExactPermissionSet('LT Y24 ABP Exact X');
        ObserveControls(Observer, 'exact_x: ');
        Mock.SetExactPermissionSet('LT Y24 ABP Exact NoX');
        ObserveControls(Observer, 'exact_no_x: ');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P21_AccessByPermissionPage_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P21_AccessByPermissionPage_More2()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('Y24ProcRepGuard')]
    procedure Y24_P21_AccessByPermissionRequestPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Helper.Seed();
        // A request page does not open inside a write transaction.
        Commit();
        Mock.Set('LT Y24 ABP Grant');
        RunRequestPage(Observer, 'grant');
        Mock.Set('LT Y24 RIMD');
        RunRequestPage(Observer, 'no_grant');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P21_AccessByPermissionRequestPage_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P21_AccessByPermissionRequestPage_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P22_EffectivePermission()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Mock.ClearAssignments();
        ObserveRights(Observer, 'noset ');
        Mock.Set('LT Y24 R');
        ObserveRights(Observer, 'set ');
        Mock.SetExactPermissionSet('LT Y24 R');
        ObserveRights(Observer, 'exact ');
        RestoreMock(WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P22_EffectivePermission_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P22_EffectivePermission_More2()
    begin
        Observer.More();
    end;

    local procedure StartMock() WasStarted: Boolean
    begin
        WasStarted := Mock.IsStarted();
        if not WasStarted then
            Mock.Start();
    end;

    local procedure RestoreMock(WasStarted: Boolean)
    begin
        Mock.ClearAssignments();
        if not WasStarted then
            Mock.Stop();
    end;

    local procedure RunExact(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Which: Integer)
    var
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        Helper.Seed();
        Mock.SetExactPermissionSet(SetName);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        Observer.Observe(Name + '|text', ErrorText);
        Observer.Observe(Name + '|code', ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        Row: Record "LT Y24 Row";
        TempRow: Record "LT Y24 Row" temporary;
        Target: Codeunit "LT Y24 Exec Target";
        Granter: Codeunit "LT Y24 Exec Granter";
        ProcRep: Report "LT Y24 Proc Rep";
        Qry: Query "LT Y24 Row Query";
        Card: TestPage "LT Y24 Row Card";
        OutS: OutStream;
        Result: Text;
    begin
        case Which of
            1:
                begin
                    Codeunit.Run(Codeunit::"LT Y24 Exec Target");
                    Result := 'run';
                end;
            2:
                Result := Target.Ping();
            3:
                begin
                    ProcRep.UseRequestPage(false);
                    ProcRep.RunModal();
                    Result := ProcRep.Seen();
                end;
            4:
                begin
                    Page.Run(Page::"LT Y24 Row Card");
                    Result := 'page';
                end;
            5:
                begin
                    Card.OpenView();
                    Result := 'opened';
                    Card.Close();
                end;
            6:
                begin
                    TempRow.Data.CreateOutStream(OutS);
                    Xmlport.Export(Xmlport::"LT Y24 Row Xml", OutS);
                    Result := 'xml ' + Format(TempRow.Data.Length());
                end;
            7:
                begin
                    Qry.Open();
                    Result := 'query ' + Format(Qry.Read());
                end;
            8:
                Result := Row.Describe();
            11, 12, 13, 14, 16, 17, 18:
                Result := Granter.Run(Which - 10);
        end;
        Error('LT Y24 ok %1', Result);
    end;

    local procedure ObserveControls(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Facts: TestPage "LT Y24 ABP Card";
    begin
        if not TryOpen(Facts) then begin
            Observer.Observe(Prefix + 'open', 'error: ' + GetLastErrorText());
            Observer.Observe(Prefix + 'open code', GetLastErrorCode());
            ClearLastError();
            exit;
        end;
        Observer.Observe(Prefix + 'plain value', ControlOutcome(Facts, 'plain value'));
        Observer.Observe(Prefix + 'guard r value', ControlOutcome(Facts, 'guard r value'));
        Observer.Observe(Prefix + 'guard r visible', ControlOutcome(Facts, 'guard r visible'));
        Observer.Observe(Prefix + 'guard i visible', ControlOutcome(Facts, 'guard i visible'));
        Observer.Observe(Prefix + 'plain action visible', ControlOutcome(Facts, 'plain action visible'));
        Observer.Observe(Prefix + 'guard x action visible', ControlOutcome(Facts, 'guard x action visible'));
        Observer.Observe(Prefix + 'guard x action enabled', ControlOutcome(Facts, 'guard x action enabled'));
        Facts.Close();
    end;

    local procedure ControlOutcome(var Facts: TestPage "LT Y24 ABP Card"; What: Text): Text
    var
        Result: Text;
    begin
        if TryControl(Facts, What, Result) then
            exit(Result);
        Result := 'error: ' + GetLastErrorText();
        ClearLastError();
        exit(Result);
    end;

    [TryFunction]
    local procedure TryOpen(var Facts: TestPage "LT Y24 ABP Card")
    begin
        Facts.OpenView();
        Facts.First();
    end;

    [TryFunction]
    local procedure TryControl(var Facts: TestPage "LT Y24 ABP Card"; What: Text; var Result: Text)
    begin
        case What of
            'plain value':
                Result := Facts.PlainCtl.Value();
            'guard r value':
                Result := Facts.GuardRCtl.Value();
            'guard r visible':
                Result := Format(Facts.GuardRCtl.Visible());
            'guard i visible':
                Result := Format(Facts.GuardICtl.Visible());
            'plain action visible':
                Result := Format(Facts.PlainAct.Visible());
            'guard x action visible':
                Result := Format(Facts.GuardXAct.Visible());
            'guard x action enabled':
                Result := Format(Facts.GuardXAct.Enabled());
        end;
    end;

    local procedure RunRequestPage(var Observer: Codeunit "Probe Observer"; Tag: Text)
    begin
        GuardVisible := '';
        asserterror RunProcRepWithRequestPage();
        Observer.ObserveError(Tag + ' run');
        Observer.Observe(Tag + ' request page', GuardVisible);
    end;

    local procedure RunProcRepWithRequestPage()
    var
        ProcRep: Report "LT Y24 Proc Rep";
    begin
        ProcRep.UseRequestPage(true);
        ProcRep.RunModal();
        Error('LT Y24 ok %1', ProcRep.Seen());
    end;

    local procedure ObserveRights(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Kinds: List of [Integer];
        Ids: List of [Integer];
        Names: List of [Text];
        Results: List of [Text];
        Result: Text;
        Index: Integer;
    begin
        Kinds.Add(0);
        Ids.Add(Database::"LT Y24 Row");
        Names.Add('tabledata');
        Kinds.Add(1);
        Ids.Add(Database::"LT Y24 Row");
        Names.Add('table');
        Kinds.Add(5);
        Ids.Add(Codeunit::"LT Y24 Exec Target");
        Names.Add('codeunit');
        Kinds.Add(8);
        Ids.Add(Page::"LT Y24 Row Card");
        Names.Add('page');
        Kinds.Add(3);
        Ids.Add(Report::"LT Y24 Proc Rep");
        Names.Add('report');
        for Index := 1 to Kinds.Count() do begin
            if TryRights(Kinds.Get(Index), Ids.Get(Index), Result) then
                Results.Add(Result)
            else
                Results.Add('error: ' + GetLastErrorText() + ' code ' + GetLastErrorCode());
            ClearLastError();
        end;
        Mock.ClearAssignments();
        for Index := 1 to Kinds.Count() do
            Observer.Observe(Prefix + Names.Get(Index), Results.Get(Index));
    end;

    [TryFunction]
    local procedure TryRights(Kind: Integer; ObjectId: Integer; var Result: Text)
    var
        UserPermissions: Codeunit "User Permissions";
        Expanded: Record "Expanded Permission" temporary;
    begin
        Expanded := UserPermissions.GetEffectivePermission(Kind, ObjectId);
        Result := Format(Expanded."Read Permission") + ',' + Format(Expanded."Insert Permission") + ',' + Format(Expanded."Modify Permission") + ',' +
            Format(Expanded."Delete Permission") + ',' + Format(Expanded."Execute Permission");
    end;

    [PageHandler]
    procedure Y24RowCardHandler(var Card: TestPage "LT Y24 Row Card")
    begin
        Card.Close();
    end;

    [RequestPageHandler]
    procedure Y24ProcRepGuard(var RequestPage: TestRequestPage "LT Y24 Proc Rep")
    var
        Plain: Text;
        Guard: Text;
    begin
        if TryRequestControl(RequestPage, false, Plain) then;
        if not TryRequestControl(RequestPage, true, Guard) then
            Guard := 'error: ' + GetLastErrorText();
        ClearLastError();
        GuardVisible := 'plain ' + Plain + ' guard ' + Guard;
        RequestPage.OK().Invoke();
    end;

    [TryFunction]
    local procedure TryRequestControl(var RequestPage: TestRequestPage "LT Y24 Proc Rep"; Guarded: Boolean; var Result: Text)
    begin
        if Guarded then
            Result := Format(RequestPage.GuardROpt.Visible())
        else
            Result := Format(RequestPage.PlainOpt.Visible());
    end;
}
