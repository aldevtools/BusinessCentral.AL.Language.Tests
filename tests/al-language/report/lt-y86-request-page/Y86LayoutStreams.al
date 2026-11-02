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
            if Lines = 1 then
                Obs.Observe('line 1', Line);
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
        Obs.Finish();
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
        Obs.Finish();
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
        Obs.Finish();
    end;

    [Test]
    procedure Y86_RdlcLayout_NoSuchReport()
    var
        Obs: Codeunit "Probe Observer";
        InS: InStream;
    begin
        asserterror Report.RdlcLayout(94599, InS);
        Obs.ObserveError('unknown report');
        asserterror Report.RdlcLayout(0, InS);
        Obs.ObserveError('report zero');
        Obs.Finish();
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
        Obs.Finish();
    end;
}
