// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-rdlclayout-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); layout files Y86Layout.rdlc and Y86LayoutColumns.rdlc (copies of one RDLC file: 2316 bytes, UTF-8 with BOM, CRLF, a <Fields> list of four fields); own report 94587, test codeunit 94588
// Probe (writer Y86, al-runtime-rs assumption rdlc-layout-stream-is-the-layout-file): Report.RdlcLayout of a report whose default rendering layout is an
// RDLC file the app holds: the bytes of the stream against the file, a second read, the other layout statements on the same report, a report id that is no report.
// BC versions: 27, 28, 29

report 94587 "LT Y86 Rdlc Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Y86Rdlc;

    dataset
    {
        dataitem(Int; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }

    rendering
    {
        layout(Y86Rdlc)
        {
            Type = RDLC;
            LayoutFile = './report/lt-y86-request-page/Y86Layout.rdlc';
            Caption = 'Y86 RDLC layout';
        }
    }
}

report 94601 "LT Y86 Rdlc Columns Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Y86Rdlc;

    dataset
    {
        dataitem(Int; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(NumberCol; Int.Number) { }
            column(TextCol; 'abc') { }
        }
    }

    rendering
    {
        layout(Y86Rdlc)
        {
            Type = RDLC;
            LayoutFile = './report/lt-y86-request-page/Y86LayoutColumns.rdlc';
            Caption = 'Y86 RDLC layout with columns';
        }
    }
}

codeunit 94588 "LT Y86 Layout Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Head(var InS: InStream): Text
    var
        B: Byte;
        Code: Integer;
        Result: Text;
        I: Integer;
    begin
        for I := 1 to 8 do begin
            if InS.EOS() then
                break;
            InS.Read(B);
            Code := B;
            Result += Format(Code) + ' ';
        end;
        exit(Result);
    end;

    [Test]
    procedure Y86_RdlcLayout_StreamIsTheFile()
    var
        Obs: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Text1: Text;
        Line: Text;
        Lines: Integer;
        Total: Integer;
        Last: Text;
    begin
        Report.RdlcLayout(Report::"LT Y86 Rdlc Report", InS);
        Obs.Observe('eos before read', Format(InS.EOS()));
        Obs.Observe('first six bytes', Head(InS));
        Clear(InS);
        Report.RdlcLayout(Report::"LT Y86 Rdlc Report", InS);
        TempBlob.CreateOutStream(OutS);
        CopyStream(OutS, InS);
        Obs.Observe('length', Format(TempBlob.Length()));
        TempBlob.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            Lines += 1;
            Last := Line;
            if Lines = 2 then
                Text1 := Line;
            if Lines = 3 then
                Obs.Observe('line 3', Line);
            if Lines = 4 then
                Obs.Observe('line 4', Line);
            Total += StrLen(Line);
        end;
        Obs.Observe('chars in all lines', Format(Total));
        Obs.Observe('lines', Format(Lines));
        Obs.Observe('line 2', Text1);
        Obs.Observe('last line', Last);
        Obs.Expect('eos before read', 'No');
        Obs.Expect('first six bytes', '239 187 191 60 63 120 109 108 ');
        Obs.Expect('length', '1917');
        Obs.Expect('line 3', '  <AutoRefresh>0</AutoRefresh>');
        Obs.Expect('line 4', '  <DataSources>');
        Obs.Expect('chars in all lines', '1773');
        Obs.Expect('lines', '73');
        Obs.Expect('line 2', '<Report xmlns="http://schemas.microsoft.com/sqlserver/reporting/2016/01/reportdefinition" xmlns:rd="http://schemas.microsoft.com/SQLServer/reporting/reportdesigner">');
        Obs.Expect('last line', '</Report>');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_RdlcLayout_SecondReadAndTwoStreams()
    var
        Obs: Codeunit "Probe Observer";
        A: InStream;
        B: InStream;
    begin
        Report.RdlcLayout(Report::"LT Y86 Rdlc Report", A);
        Report.RdlcLayout(Report::"LT Y86 Rdlc Report", B);
        Obs.Observe('first stream', Head(A));
        Obs.Observe('second stream', Head(B));
        Report.RdlcLayout(Report::"LT Y86 Rdlc Report", A);
        Obs.Observe('first stream reassigned', Head(A));
        Obs.Expect('first stream', '239 187 191 60 63 120 109 108 ');
        Obs.Expect('second stream', '239 187 191 60 63 120 109 108 ');
        Obs.Expect('first stream reassigned', '239 187 191 60 63 120 109 108 ');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_OtherLayoutStatements_OnRdlcReport()
    var
        Obs: Codeunit "Probe Observer";
        InS: InStream;
    begin
        ClearLastError();
        asserterror Report.WordLayout(Report::"LT Y86 Rdlc Report", InS);
        Obs.ObserveError('word');
        asserterror Report.ExcelLayout(Report::"LT Y86 Rdlc Report", InS);
        Obs.ObserveError('excel');
        Obs.Expect('word|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.');
        Obs.Expect('word|code', 'ReportNoLayout');
        Obs.Expect('excel|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.');
        Obs.Expect('excel|code', 'ReportNoLayout');
        Obs.Verify();
    end;

    [Test]
    procedure Y86_RdlcLayout_NoSuchReport()
    var
        Obs: Codeunit "Probe Observer";
        InS: InStream;
    begin
        asserterror Report.RdlcLayout(94599, InS);
        Obs.Observe('unknown report|code', GetLastErrorCode());
        Obs.Observe('unknown report|names the object and the id', Format((StrPos(GetLastErrorText(), 'Report object with the ID 94599 from the object') > 0) and (StrPos(GetLastErrorText(), 'does not exist in the current application') > 0)));
        ClearLastError();
        asserterror Report.RdlcLayout(0, InS);
        Obs.Observe('report zero|code', GetLastErrorCode());
        ClearLastError();
        Obs.Expect('unknown report|code', 'AL:MetadataNotFound');
        Obs.Expect('unknown report|names the object and the id', 'Yes');
        Obs.Expect('report zero|code', 'AL:MetadataNotFound');
        Obs.Verify();
    end;

    local procedure FieldsSection(ReportId: Integer): Text
    var
        InS: InStream;
        Line: Text;
        All: Text;
        At: Integer;
        Cut: Text;
        EndAt: Integer;
    begin
        Report.RdlcLayout(ReportId, InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            All += Line + '|';
        end;
        At := StrPos(All, '<Fields');
        if At = 0 then
            exit('no Fields element');
        Cut := CopyStr(All, At);
        EndAt := StrPos(Cut, '</Fields>');
        if EndAt = 0 then
            exit(CopyStr(Cut, 1, 12) + ' length=' + Format(StrLen(All)));
        exit(CopyStr(Cut, 1, EndAt + 8) + ' length=' + Format(StrLen(All)));
    end;

    [Test]
    procedure Y86_RdlcLayout_FieldsSectionFollowsTheDataset()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('report without columns', FieldsSection(Report::"LT Y86 Rdlc Report"));
        Obs.Observe('report with columns', FieldsSection(Report::"LT Y86 Rdlc Columns Report"));
        Obs.Expect('report without columns', '<Fields />|  length=1846');
        Obs.Expect('report with columns', '<Fields>|        <Field Name="NumberCol">|          <DataField>NumberCol</DataField>|        </Field>|        <Field Name="TextCol">|          <DataField>TextCol</DataField>|        </Field>|      </Fields> length=2042');
        Obs.Verify();
    end;
}
