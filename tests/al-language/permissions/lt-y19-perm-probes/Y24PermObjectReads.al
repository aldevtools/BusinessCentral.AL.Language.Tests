// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Y24PermObjects.al (91936-91978); Permissions Mock (131006) from the dependency.
// Probe: al-runtime-rs ADR-062 (permission enforcement in stages), stage 2 probes, writer Y24:
//   P16 Query.Open/Read and XmlPort.Export over a table the set cannot read (no grant, and indirect r), objects without and with
//       Permissions = r (lt-permissions-mock-indirect/RiskyReportQueryXmlport.al covers a set WITH R);
//   P17 Report.SaveAs (Xml dataset) and a processing-only report run without and with its request page, over a table the set cannot
//       read (no grant, and indirect r), reports without and with Permissions = r;
//   P18 TestPage.OpenView/OpenEdit on a page whose source table the set cannot read (with rows), a field read, and a SetValue that
//       writes under a set without M.
// Shape (CpPermLeads.al): each case reseeds (and commits the seed before a request page) with no set assigned, assigns the set (Permissions Mock.Set: the set plus All Objects), runs ONE
//   operation inside asserterror that ends with the own error 'LT Y24 ok <result>', observes text and code, clears the assignment.
// BC versions: 27, 28, 29

codeunit 91976 "LT Y24 Perm Object Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        // One Observer per codeunit: the _More tests raise the rest of a long observation.
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y24 Perm Helper";
        Y19Helper: Codeunit "LT Y19 Perm Helper";
        Mock: Codeunit "Permissions Mock";

    [Test]
    procedure Y24_P16_QueryXmlportNoGrant()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP16(Observer, 'none_', 'LT Y24 None');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P16_QueryXmlportNoGrant_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P16_QueryXmlportNoGrant_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P16_QueryXmlportIndirectRead()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP16(Observer, 'indr_', 'LT Y24 Ind R');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P16_QueryXmlportIndirectRead_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P16_QueryXmlportIndirectRead_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P17_ReportNoRequestPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunP17(Observer, 'none_', 'LT Y24 None');
        RunP17(Observer, 'indr_', 'LT Y24 Ind R');
        RunP17(Observer, 'rimd_', 'LT Y24 RIMD');
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P17_ReportNoRequestPage_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P17_ReportNoRequestPage_More2()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('Y24ProcRepOk')]
    procedure Y24_P17_ReportRequestPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunCase(Observer, 'none_run_reqpage', 'LT Y24 None', 45);
        RunCase(Observer, 'indr_run_reqpage', 'LT Y24 Ind R', 45);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P17_ReportRequestPage_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P17_ReportRequestPage_More2()
    begin
        Observer.More();
    end;

    [Test]
    [HandlerFunctions('Y24ProcRepPermOk')]
    procedure Y24_P17_ReportPermRequestPage()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunCase(Observer, 'none_run_perm_reqpage', 'LT Y24 None', 46);
        RunCase(Observer, 'indr_run_perm_reqpage', 'LT Y24 Ind R', 46);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P17_ReportPermRequestPage_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P17_ReportPermRequestPage_More2()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P18_Pages()
    var
        WasStarted: Boolean;
    begin
        WasStarted := Y19Helper.StartMock(Mock);
        RunCase(Observer, 'none_openview', 'LT Y24 None', 51);
        RunCase(Observer, 'none_openedit', 'LT Y24 None', 52);
        RunCase(Observer, 'none_field_read', 'LT Y24 None', 53);
        RunCase(Observer, 'r_setvalue_close', 'LT Y24 R', 54);
        RunCase(Observer, 'r_setvalue_next', 'LT Y24 R', 55);
        Y19Helper.RestoreMock(Mock, WasStarted);
        Observer.Finish();
    end;

    [Test]
    procedure Y24_P18_Pages_More1()
    begin
        Observer.More();
    end;

    [Test]
    procedure Y24_P18_Pages_More2()
    begin
        Observer.More();
    end;

    local procedure RunP16(var Observer: Codeunit "Probe Observer"; Prefix: Text; SetName: Code[20])
    begin
        RunCase(Observer, Prefix + 'query', SetName, 31);
        RunCase(Observer, Prefix + 'query_perm', SetName, 32);
        RunCase(Observer, Prefix + 'xmlport', SetName, 33);
        RunCase(Observer, Prefix + 'xmlport_perm', SetName, 34);
    end;

    local procedure RunP17(var Observer: Codeunit "Probe Observer"; Prefix: Text; SetName: Code[20])
    begin
        RunCase(Observer, Prefix + 'saveas', SetName, 41);
        RunCase(Observer, Prefix + 'saveas_perm', SetName, 42);
        RunCase(Observer, Prefix + 'run', SetName, 43);
        RunCase(Observer, Prefix + 'run_perm', SetName, 44);
    end;

    local procedure RunCase(var Observer: Codeunit "Probe Observer"; Name: Text; SetName: Code[20]; Which: Integer)
    begin
        Mock.ClearAssignments();
        Helper.Seed();
        // A request page does not open inside a write transaction (first run: "An error occurred and the transaction is stopped.", DB:Ok).
        if Which in [45, 46] then
            Commit();
        Mock.Set(SetName);
        asserterror Op(Which);
        Observer.ObserveError(Name);
        Mock.ClearAssignments();
    end;

    local procedure Op(Which: Integer)
    var
        Row: Record "LT Y24 Row";
        TempRow: Record "LT Y24 Row" temporary;
        Qry: Query "LT Y24 Row Query";
        QryPerm: Query "LT Y24 Row Query Perm";
        ProcRep: Report "LT Y24 Proc Rep";
        ProcRepPerm: Report "LT Y24 Proc Rep Perm";
        Card: TestPage "LT Y24 Row Card";
        OutS: OutStream;
        InS: InStream;
        Result: Text;
        Line: Text;
    begin
        case Which of
            31:
                begin
                    Qry.Open();
                    while Qry.Read() do
                        Result += Format(Qry.Id) + ';';
                end;
            32:
                begin
                    QryPerm.Open();
                    while QryPerm.Read() do
                        Result += Format(QryPerm.Id) + ';';
                end;
            33, 34, 41, 42:
                begin
                    TempRow.Data.CreateOutStream(OutS, TextEncoding::UTF8);
                    case Which of
                        33:
                            Xmlport.Export(Xmlport::"LT Y24 Row Xml", OutS);
                        34:
                            Xmlport.Export(Xmlport::"LT Y24 Row Xml Perm", OutS);
                        41:
                            Result := Format(Report.SaveAs(Report::"LT Y24 Row Rep", '', ReportFormat::Xml, OutS)) + ' ';
                        42:
                            Result := Format(Report.SaveAs(Report::"LT Y24 Row Rep Perm", '', ReportFormat::Xml, OutS)) + ' ';
                    end;
                    // Report.SaveAs returns false instead of raising when the save fails: the reason is the last error.
                    if (Which in [41, 42]) and (Result = 'No ') then
                        Result += GetLastErrorText() + ' ';
                    TempRow.Data.CreateInStream(InS, TextEncoding::UTF8);
                    while not InS.EOS() do begin
                        InS.ReadText(Line);
                        if Which in [33, 34] then
                            Result += Line.Trim()
                        else
                            if Line.Contains('name="IdC"') then
                                Result += 'IdC;';
                    end;
                end;
            43:
                begin
                    ProcRep.UseRequestPage(false);
                    ProcRep.RunModal();
                    Result := ProcRep.Seen();
                end;
            44:
                begin
                    ProcRepPerm.UseRequestPage(false);
                    ProcRepPerm.RunModal();
                    Result := ProcRepPerm.Seen();
                end;
            45:
                begin
                    ProcRep.UseRequestPage(true);
                    ProcRep.RunModal();
                    Result := ProcRep.Seen();
                end;
            46:
                begin
                    ProcRepPerm.UseRequestPage(true);
                    ProcRepPerm.RunModal();
                    Result := ProcRepPerm.Seen();
                end;
            51:
                begin
                    Card.OpenView();
                    Result := 'opened';
                    Card.Close();
                end;
            52:
                begin
                    Card.OpenEdit();
                    Result := 'opened';
                    Card.Close();
                end;
            53:
                begin
                    Card.OpenView();
                    Result := 'value ' + Card.ValueCtl.Value();
                    Card.Close();
                end;
            54, 55:
                begin
                    Card.OpenEdit();
                    Row.Id := 1;
                    Card.GoToRecord(Row);
                    Card.ValueCtl.SetValue(77);
                    if Which = 54 then
                        Card.Close()
                    else begin
                        Card.Next();
                        Card.Close();
                    end;
                    Result := 'closed';
                end;
        end;
        Error('LT Y24 ok %1 rows %2', Result, Helper.DescribeRows());
    end;

    [RequestPageHandler]
    procedure Y24ProcRepOk(var RequestPage: TestRequestPage "LT Y24 Proc Rep")
    begin
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure Y24ProcRepPermOk(var RequestPage: TestRequestPage "LT Y24 Proc Rep Perm")
    begin
        RequestPage.OK().Invoke();
    end;
}
