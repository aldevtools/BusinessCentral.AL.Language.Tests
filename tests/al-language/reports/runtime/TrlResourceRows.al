// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (69160); reports 91851 and 91854 (Y17LayoutExportObjects.al); layout files copied to session/res/trl
// Probe: Tenant Report Layout (draft, observation form).

codeunit 97000 "LT TRL Resource Rows"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Hex(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure DescribeStream(var Observer: Codeunit "Probe Observer"; Name: Text; var Source: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        Crypto: Codeunit "Cryptography Management";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        First: Text;
        i: Integer;
    begin
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, Source);
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        for i := 1 to 4 do
            if i <= TempBlob.Length() then begin
                InS.Read(B);
                First += Hex(B);
            end;
        Observer.Observe(Name + ' first bytes', First);
        TempBlob.CreateInStream(InS);
        Observer.Observe(Name + ' sha256', Crypto.GenerateHash(InS, 2));
    end;

    [TryFunction]
    local procedure TryLayout(Kind: Text; ReportId: Integer; var InS: InStream; var Got: Boolean)
    begin
        case Kind of
            'word':
                Got := Report.WordLayout(ReportId, InS);
            'rdlc':
                Got := Report.RdlcLayout(ReportId, InS);
            'excel':
                Got := Report.ExcelLayout(ReportId, InS);
        end;
    end;

    local procedure DescribeLayoutFor(var Observer: Codeunit "Probe Observer"; Name: Text; Kind: Text; ReportId: Integer; ResourceName: Text)
    var
        InS: InStream;
        Got: Boolean;
    begin
        if not TryLayout(Kind, ReportId, InS, Got) then begin
            Observer.Observe(Name + ' error', GetLastErrorText());
            Observer.Observe(Name + ' code', GetLastErrorCode());
            ClearLastError();
        end else begin
            Observer.Observe(Name + ' returned', Format(Got));
            if Got then
                DescribeStream(Observer, Name + ' report', InS);
        end;
        if ResourceName <> '' then begin
            NavApp.GetResource(ResourceName, InS);
            DescribeStream(Observer, Name + ' file', InS);
        end;
    end;

    [Test]
    procedure FreshTenant_AllRows()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        Line: Text;
    begin
        Observer.Observe('count', Format(Layout.Count()));
        if Layout.FindSet() then
            repeat
                Line += Format(Layout."Report ID") + ':' + Layout.Name + ':' + CopyStr(Format(Layout."App ID"), 1, 9) + ':' + Format(Layout."Layout Format") + ':' + Format(Layout."Company Name" = '') + '|';
            until Layout.Next() = 0;
        Observer.Observe('rows', Line);
        Observer.Expect('count', '0');
        Observer.Expect('rows', '');
        Observer.Verify();
    end;

    [Test]
    procedure WordLayout_Stream_VsFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DescribeLayoutFor(Observer, 'word R1', 'word', Report::"LT Y17 Lay R1", 'trl/Y17LayR1.docx');
        Observer.Expect('word R1 returned', 'Yes');
        Observer.Expect('word R1 report length', '5451');
        Observer.Expect('word R1 report first bytes', '504B0304');
        Observer.Expect('word R1 report sha256', '25B756A06026DA7354BB7B74594C2D18B14B1EB15B644949A5EB46D969B5804E');
        Observer.Expect('word R1 file length', '5451');
        Observer.Expect('word R1 file first bytes', '504B0304');
        Observer.Expect('word R1 file sha256', '25B756A06026DA7354BB7B74594C2D18B14B1EB15B644949A5EB46D969B5804E');
        Observer.Verify();
    end;

    [Test]
    procedure RdlcAndExcelLayout_Stream_VsFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DescribeLayoutFor(Observer, 'rdlc R1', 'rdlc', Report::"LT Y17 Lay R1", 'trl/Y17LayR1.rdl');
        DescribeLayoutFor(Observer, 'excel R4', 'excel', Report::"LT Y17 Lay R4", 'trl/Y17LayR4.xlsx');
        Observer.Expect('rdlc R1 returned', 'Yes');
        Observer.Expect('rdlc R1 report length', '2104');
        Observer.Expect('rdlc R1 report first bytes', 'EFBBBF3C');
        Observer.Expect('rdlc R1 report sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Expect('rdlc R1 file length', '2104');
        Observer.Expect('rdlc R1 file first bytes', 'EFBBBF3C');
        Observer.Expect('rdlc R1 file sha256', 'E28FAC5DB3F79B65DE60707DDBED8F5306BE7605DC4D9A71E1BF2597E440B5EF');
        Observer.Expect('excel R4 returned', 'Yes');
        Observer.Expect('excel R4 report length', '20314');
        Observer.Expect('excel R4 report first bytes', '504B0304');
        Observer.Expect('excel R4 report sha256', 'B7748123A94313033D504A565EBB4C708BFD0B5CB9EBD95BB61223A80148BF0D');
        Observer.Expect('excel R4 file length', '20314');
        Observer.Expect('excel R4 file first bytes', '504B0304');
        Observer.Expect('excel R4 file sha256', 'B7748123A94313033D504A565EBB4C708BFD0B5CB9EBD95BB61223A80148BF0D');
        Observer.Verify();
    end;

    [Test]
    procedure LayoutOfWrongKind_Returned()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DescribeLayoutFor(Observer, 'word R4', 'word', Report::"LT Y17 Lay R4", '');
        DescribeLayoutFor(Observer, 'rdlc R4', 'rdlc', Report::"LT Y17 Lay R4", '');
        DescribeLayoutFor(Observer, 'excel R1', 'excel', Report::"LT Y17 Lay R1", '');
        Observer.Expect('word R4 returned', 'No');
        Observer.Expect('rdlc R4 returned', 'Yes');
        Observer.Expect('rdlc R4 report length', '0');
        Observer.Expect('rdlc R4 report first bytes', '');
        Observer.Expect('rdlc R4 report sha256', '');
        Observer.Expect('excel R1 returned', 'No');
        Observer.Verify();
    end;

    local procedure DoInsert(var Observer: Codeunit "Probe Observer"; Tag: Text; ReportId: Integer; Kind: Option; ResourceName: Text; CustomType: Guid; Fails: Boolean; ViaCopy: Boolean)
    var
        Layout: Record "Tenant Report Layout";
        Reader: Record "Tenant Report Layout";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        LayoutName: Text[250];
        Ok: Boolean;
        InLength: Integer;
    begin
        LayoutName := CopyStr(Delchr(Format(CreateGuid()), '=', '{}'), 1, 250);
        Layout.Init();
        Layout."Report ID" := ReportId;
        Layout.Name := LayoutName;
        Layout."Layout Format" := Kind;
        Layout."Custom Type" := CustomType;
        NavApp.GetResource(ResourceName, InS);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        InLength := TempBlob.Length();
        // ViaCopy: the layout is imported from a copy of the resource bytes; otherwise straight from the resource stream
        if ViaCopy then
            TempBlob.CreateInStream(InS)
        else
            NavApp.GetResource(ResourceName, InS);
        Layout.Layout.ImportStream(InS, 'trl');
        if Fails then begin
            asserterror Layout.Insert();
            Ok := false;
        end else
            Ok := Layout.Insert();
        Observer.Observe(Tag + ' insert', Format(Ok));
        if not Ok then begin
            Observer.Observe(Tag + ' error', GetLastErrorText());
            Observer.Observe(Tag + ' code', GetLastErrorCode());
            ClearLastError();
        end;
        Reader.SetRange(Name, LayoutName);
        Observer.Observe(Tag + ' rows', Format(Reader.Count()));
        if Reader.FindFirst() then begin
            Observer.Observe(Tag + ' stored', Format(Reader."Report ID") + '|' + Format(Reader."Layout Format") + '|' + Format(IsNullGuid(Reader."App ID")) + '|' + Format(IsNullGuid(Reader."Custom Type")) + '|' + Reader."MIME Type" + '|' + Reader.Description + '|' + Format(Reader."Company Name" = ''));
            Observer.Observe(Tag + ' has value', Format(Reader.Layout.HasValue()));
            TempBlob.CreateOutStream(OutS);
            Observer.Observe(Tag + ' export', Format(Reader.Layout.ExportStream(OutS)));
            Observer.Observe(Tag + ' length equals the file', Format(TempBlob.Length() = InLength));
            // the stored layout of a Microsoft report depends on that report's data set: its length is not asserted
            if ReportId >= 90000 then
                Observer.Observe(Tag + ' length', Format(TempBlob.Length()));
            Reader.DeleteAll();
        end;
    end;

    [Test]
    procedure Insert_Word_EmptyBody_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'word', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Word, 'trl/Y67BaseDoc.docx', NoType, false, false);
        Observer.Expect('word insert', 'Yes');
        Observer.Expect('word rows', '1');
        Observer.Expect('word stored', '1305|Word|Yes|Yes|||Yes');
        Observer.Expect('word has value', 'Yes');
        Observer.Expect('word export', 'Yes');
        Observer.Expect('word length equals the file', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Word_Bindings_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'bindings', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Word, 'trl/Y17LayR1.docx', NoType, false, false);
        Observer.Finish();
    end;

    [Test]
    procedure Insert_Word_Bindings_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'own', Report::"LT Y17 Lay R1", Layout."Layout Format"::Word, 'trl/Y17LayR1.docx', NoType, false, false);
        Observer.Expect('own insert', 'Yes');
        Observer.Expect('own rows', '1');
        Observer.Expect('own stored', '91851|Word|Yes|Yes|||Yes');
        Observer.Expect('own has value', 'Yes');
        Observer.Expect('own export', 'Yes');
#if BC29PLUS
        Observer.Expect('own length equals the file', 'Yes');
#else
#if BC28PLUS
        Observer.Expect('own length equals the file', 'No');
#else
        Observer.Expect('own length equals the file', 'No');
#endif
#endif
#if BC29PLUS
        Observer.Expect('own length', '5451');
#else
#if BC28PLUS
        Observer.Expect('own length', '4463');
#else
        Observer.Expect('own length', '4463');
#endif
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Rdlc_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'rdlc', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::RDLC, 'trl/Y17LayR1.rdl', NoType, false, false);
        Observer.Expect('rdlc insert', 'Yes');
        Observer.Expect('rdlc rows', '1');
        Observer.Expect('rdlc stored', '1305|RDLC|Yes|Yes|||Yes');
        Observer.Expect('rdlc has value', 'Yes');
        Observer.Expect('rdlc export', 'Yes');
        Observer.Expect('rdlc length equals the file', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Rdlc_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'rdlc own', Report::"LT Y17 Lay R1", Layout."Layout Format"::RDLC, 'trl/Y17LayR1.rdl', NoType, false, false);
        Observer.Expect('rdlc own insert', 'Yes');
        Observer.Expect('rdlc own rows', '1');
        Observer.Expect('rdlc own stored', '91851|RDLC|Yes|Yes|||Yes');
        Observer.Expect('rdlc own has value', 'Yes');
        Observer.Expect('rdlc own export', 'Yes');
        Observer.Expect('rdlc own length equals the file', 'No');
        Observer.Expect('rdlc own length', '2022');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Excel_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'excel', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Excel, 'trl/Y17LayR4.xlsx', NoType, false, false);
        Observer.Expect('excel insert', 'Yes');
        Observer.Expect('excel rows', '1');
        Observer.Expect('excel stored', '1305|Excel|Yes|Yes|||Yes');
        Observer.Expect('excel has value', 'Yes');
        Observer.Expect('excel export', 'Yes');
        Observer.Expect('excel length equals the file', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Excel_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'excel own', Report::"LT Y17 Lay R4", Layout."Layout Format"::Excel, 'trl/Y17LayR4.xlsx', NoType, false, false);
        Observer.Expect('excel own insert', 'Yes');
        Observer.Expect('excel own rows', '1');
        Observer.Expect('excel own stored', '91854|Excel|Yes|Yes|||Yes');
        Observer.Expect('excel own has value', 'Yes');
        Observer.Expect('excel own export', 'Yes');
        Observer.Expect('excel own length equals the file', 'No');
#if BC29PLUS
        Observer.Expect('excel own length', '20313');
#else
#if BC28PLUS
        Observer.Expect('excel own length', '19696');
#else
        Observer.Expect('excel own length', '19696');
#endif
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Custom_NoType_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'custom no type', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Custom, 'trl/Y67BaseDoc.docx', NoType, false, false);
        Observer.Expect('custom no type insert', 'Yes');
        Observer.Expect('custom no type rows', '1');
        Observer.Expect('custom no type stored', '1305|External|Yes|Yes|||Yes');
        Observer.Expect('custom no type has value', 'Yes');
        Observer.Expect('custom no type export', 'Yes');
        Observer.Expect('custom no type length equals the file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Custom_UnknownType_MsReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'custom unknown type', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Custom, 'trl/Y67BaseDoc.docx', CreateGuid(), false, false);
        Observer.Expect('custom unknown type insert', 'Yes');
        Observer.Expect('custom unknown type rows', '1');
        Observer.Expect('custom unknown type stored', '1305|External|Yes|No|||Yes');
        Observer.Expect('custom unknown type has value', 'Yes');
        Observer.Expect('custom unknown type export', 'Yes');
        Observer.Expect('custom unknown type length equals the file', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ViaCopy_Word_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'copy word own', Report::"LT Y17 Lay R1", Layout."Layout Format"::Word, 'trl/Y17LayR1.docx', NoType, false, true);
        Observer.Expect('copy word own insert', 'Yes');
        Observer.Expect('copy word own rows', '1');
        Observer.Expect('copy word own stored', '91851|Word|Yes|Yes|||Yes');
        Observer.Expect('copy word own has value', 'Yes');
        Observer.Expect('copy word own export', 'Yes');
        Observer.Expect('copy word own length equals the file', 'Yes');
        Observer.Expect('copy word own length', '5451');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ViaCopy_Rdlc_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'copy rdlc own', Report::"LT Y17 Lay R1", Layout."Layout Format"::RDLC, 'trl/Y17LayR1.rdl', NoType, false, true);
        Observer.Expect('copy rdlc own insert', 'Yes');
        Observer.Expect('copy rdlc own rows', '1');
        Observer.Expect('copy rdlc own stored', '91851|RDLC|Yes|Yes|||Yes');
        Observer.Expect('copy rdlc own has value', 'Yes');
        Observer.Expect('copy rdlc own export', 'Yes');
        Observer.Expect('copy rdlc own length equals the file', 'Yes');
        Observer.Expect('copy rdlc own length', '2104');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ViaCopy_Excel_OwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'copy excel own', Report::"LT Y17 Lay R4", Layout."Layout Format"::Excel, 'trl/Y17LayR4.xlsx', NoType, false, true);
        Observer.Expect('copy excel own insert', 'Yes');
        Observer.Expect('copy excel own rows', '1');
        Observer.Expect('copy excel own stored', '91854|Excel|Yes|Yes|||Yes');
        Observer.Expect('copy excel own has value', 'Yes');
        Observer.Expect('copy excel own export', 'Yes');
        Observer.Expect('copy excel own length equals the file', 'Yes');
        Observer.Expect('copy excel own length', '20314');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_ViaCopy_MsReport_AllFormats()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        NoType: Guid;
    begin
        DoInsert(Observer, 'copy word ms', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Word, 'trl/Y67BaseDoc.docx', NoType, false, true);
        DoInsert(Observer, 'copy bindings ms', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Word, 'trl/Y17LayR1.docx', NoType, false, true);
        DoInsert(Observer, 'copy rdlc ms', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::RDLC, 'trl/Y17LayR1.rdl', NoType, false, true);
        DoInsert(Observer, 'copy excel ms', Report::"Standard Sales - Order Conf.", Layout."Layout Format"::Excel, 'trl/Y17LayR4.xlsx', NoType, false, true);
        Observer.Expect('copy word ms insert', 'Yes');
        Observer.Expect('copy word ms rows', '1');
        Observer.Expect('copy word ms stored', '1305|Word|Yes|Yes|||Yes');
        Observer.Expect('copy word ms has value', 'Yes');
        Observer.Expect('copy word ms export', 'Yes');
        Observer.Expect('copy word ms length equals the file', 'No');
        Observer.Expect('copy bindings ms insert', 'Yes');
        Observer.Expect('copy bindings ms rows', '1');
        Observer.Expect('copy bindings ms stored', '1305|Word|Yes|Yes|||Yes');
        Observer.Expect('copy bindings ms has value', 'Yes');
        Observer.Expect('copy bindings ms export', 'Yes');
        Observer.Expect('copy bindings ms length equals the file', 'No');
        Observer.Expect('copy rdlc ms insert', 'Yes');
        Observer.Expect('copy rdlc ms rows', '1');
        Observer.Expect('copy rdlc ms stored', '1305|RDLC|Yes|Yes|||Yes');
        Observer.Expect('copy rdlc ms has value', 'Yes');
        Observer.Expect('copy rdlc ms export', 'Yes');
        Observer.Expect('copy rdlc ms length equals the file', 'No');
        Observer.Expect('copy excel ms insert', 'Yes');
        Observer.Expect('copy excel ms rows', '1');
        Observer.Expect('copy excel ms stored', '1305|Excel|Yes|Yes|||Yes');
        Observer.Expect('copy excel ms has value', 'Yes');
        Observer.Expect('copy excel ms export', 'Yes');
        Observer.Expect('copy excel ms length equals the file', 'Yes');
        Observer.Verify();
    end;
}
