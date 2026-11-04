// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y90PermMoreObjects.al (94880-94899); Y90PermObjects.al; Permissions Mock (131006).
// Probe (owner items 2, 5 and 6): the first touch of each object kind under an exact set that grants table data but no Execute: a procedure of a table, a
//   codeunit variable method, Codeunit.Run, Report.Run, a TestPage open, a query read, an xmlport export. InherentPermissions on a procedure for a table of this
//   app, against a plain procedure (a table of another app does not compile, case 2820); InherentPermissions = X as a codeunit property against a
//   codeunit without it, called under a set without Execute on them.
// BC versions: 27, 28, 29

codeunit 94896 "LT Y90 Perm More1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y90_Exec_TableCodeunit()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('table_proc', 'LT Y90 X Data', 1);
        Run('cu_var', 'LT Y90 X Data', 2);
        Run('cu_run', 'LT Y90 X Data', 3);
        RestoreMock(WasStarted);
        Observer.Expect('table_proc',
            'Sorry, the current permissions prevented the action. (Table 94880 LT Y90 Tbl Exec Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('cu_var',
            'Sorry, the current permissions prevented the action. (CodeUnit 94881 LT Y90 X Cu Var Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('cu_run',
            'Sorry, the current permissions prevented the action. (CodeUnit 94882 LT Y90 X Cu Run Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Exec_ReportPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('page_open', 'LT Y90 X Data', 5);
        RestoreMock(WasStarted);
        // The report run is held in Suspect_Exec_ReportRun_FirstReportInSession below.
        Observer.Expect('page_open',
            'Page LT Y90 X Page has to close. | FormAbort:Permission');
        Observer.Verify();
    end;

    // Held, not a [Test] (order effect): Report.Run under an exact set without Execute is denied on "CodeUnit 44 ReportManagement" only for
    // the first report a session runs (that codeunit is a Microsoft platform codeunit any report run loads); later in a session the denial
    // names the report: "(Report 94883 LT Y90 X Rep Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied". Real BC 27.5 gave the
    // CodeUnit 44 text when the test ran after few other codeunits; bc-linux runs test codeunits in id order in one session and gives the
    // Report text. Expected under a fresh session: 'Sorry, the current permissions prevented the action. (CodeUnit 44 ReportManagement
    // Execute: ) | DB:ExecuteObjDenied'. Waits for a way to run it first in a fresh session.
    procedure Suspect_Exec_ReportRun_FirstReportInSession()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('report_run', 'LT Y90 X Data', 4);
        RestoreMock(WasStarted);
        Observer.Expect('report_run',
            'Sorry, the current permissions prevented the action. (CodeUnit 44 ReportManagement Execute: ) | DB:ExecuteObjDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Exec_QueryXmlPort()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('query_open', 'LT Y90 X Data', 6);
        Run('xmlport_export', 'LT Y90 X Data', 7);
        RestoreMock(WasStarted);
        Observer.Expect('query_open',
            'Sorry, the current permissions prevented the action. (Query 94885 LT Y90 X Query Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Expect('xmlport_export',
            'Sorry, the current permissions prevented the action. (XmlPort 94886 LT Y90 X Xml Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure Y90_Inherent_Procedure()
#else
    // Linux suspect on BC 27: Windows 27.5 gives the asserted value, the Linux 27.5 container does not (hand-off, Fix round 27.5). Not a test on 27.
    procedure Suspect_Inherent_Procedure()
#endif
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('inherent_own', 'LT Y90 I Base', 8);
        Run('plain_own', 'LT Y90 I Base', 9);
        RestoreMock(WasStarted);
        Observer.Expect('inherent_own',
            'LT Y90 ok inserted');
        Observer.Expect('plain_own',
            'Sorry, the current permissions prevented the action. (TableData 94781 LT Y90 Guard Insert: AL Language Coverage Tests) | DB:ClientInsertDenied');
        Observer.Verify();
    end;

    [Test]
    procedure Y90_Inherent_CodeunitProperty()
    var
        WasStarted: Boolean;
    begin
        WasStarted := StartMock();
        Run('prop_yes', 'LT Y90 I Base', 12);
        Run('prop_no', 'LT Y90 I Base', 13);
        RestoreMock(WasStarted);
        Observer.Expect('prop_yes',
            'LT Y90 ok ping');
        Observer.Expect('prop_no',
            'Sorry, the current permissions prevented the action. (CodeUnit 94889 LT Y90 Inh Prop No Execute: AL Language Coverage Tests) | DB:ExecuteObjDenied');
        Observer.Verify();
    end;

    local procedure Run(Tag: Text; SetName: Code[20]; Which: Integer)
    var
        ErrorText: Text;
        ErrorCode: Text;
    begin
        Mock.ClearAssignments();
        if SetName <> '' then
            Mock.SetExactPermissionSet(SetName);
        asserterror Op(Which);
        ErrorText := GetLastErrorText();
        ErrorCode := GetLastErrorCode();
        Mock.ClearAssignments();
        ClearLastError();
        if ErrorText.StartsWith('LT Y90 ok') then
            Observer.Observe(Tag, ErrorText)
        else
            Observer.Observe(Tag, ErrorText + ' | ' + ErrorCode);
    end;

    local procedure Op(Which: Integer)
    var
        Tbl: Record "LT Y90 Tbl Exec";
        CuVar: Codeunit "LT Y90 X Cu Var";
        Inherit: Codeunit "LT Y90 Inherit Proc";
        Yes: Codeunit "LT Y90 Inh Prop Yes";
        No: Codeunit "LT Y90 Inh Prop No";
        Page1: TestPage "LT Y90 X Page";
        Query1: Query "LT Y90 X Query";
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        Result: Text;
    begin
        case Which of
            1:
                Result := Tbl.Ping();
            2:
                Result := CuVar.Ping();
            3:
                begin
                    Codeunit.Run(Codeunit::"LT Y90 X Cu Run");
                    Result := 'ran';
                end;
            4:
                begin
                    Report.Run(Report::"LT Y90 X Rep", false);
                    Result := 'ran';
                end;
            5:
                begin
                    Page1.OpenView();
                    Page1.Close();
                    Result := 'opened';
                end;
            6:
                begin
                    Query1.Open();
                    Result := 'read ' + Format(Query1.Read());
                    Query1.Close();
                end;
            7:
                begin
                    TempBlob.CreateOutStream(OutStr);
                    Xmlport.Export(Xmlport::"LT Y90 X Xml", OutStr);
                    Result := 'exported';
                end;
            8:
                begin
                    Inherit.InsertOwn();
                    Result := 'inserted';
                end;
            9:
                begin
                    Inherit.InsertOwnPlain();
                    Result := 'inserted';
                end;
            12:
                Result := Yes.Ping();
            13:
                Result := No.Ping();
        end;
        Error('LT Y90 ok %1', Result);
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
}
