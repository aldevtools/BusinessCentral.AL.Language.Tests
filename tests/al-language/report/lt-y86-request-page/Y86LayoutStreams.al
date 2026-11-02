// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-rdlclayout-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); layout file FixtureLayout_19.rdlc at the app root (2316 bytes, UTF-8 with BOM, CRLF); own report 94587, test codeunit 94588
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
            LayoutFile = './FixtureLayout_19.rdlc';
            Caption = 'Y86 RDLC layout';
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

    local procedure DumpLines(FromLine: Integer; ToLine: Integer)
    var
        Obs: Codeunit "Probe Observer";
        InS: InStream;
        Line: Text;
        N: Integer;
    begin
        Report.RdlcLayout(Report::"LT Y86 Rdlc Report", InS);
        while not InS.EOS() do begin
            InS.ReadText(Line);
            N += 1;
            if (N >= FromLine) and (N <= ToLine) then
                Obs.Observe(Format(N), Line);
        end;
        Obs.Finish();
    end;

    [Test]
    procedure Y86_Dump1()
    begin
        DumpLines(1, 25);
    end;

    [Test]
    procedure Y86_Dump2()
    begin
        DumpLines(26, 50);
    end;

    [Test]
    procedure Y86_Dump3()
    begin
        DumpLines(51, 75);
    end;
}
