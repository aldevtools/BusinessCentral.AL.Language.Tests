// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 70357, report 70358, helper codeunit 70359, test codeunits 70360 and 70361
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the first 4000 bytes of the Report.SaveAs Xml dataset of an own report, line by line: index, indentation (leading spaces), content and line end (CR and LF in order, as <CR> <LF> markers).
//   Test codeunit 70360 observes the totals (bytes read, CR and LF counts, number of lines, the first bytes); test codeunit 70361 observes the lines of one 500 byte window per test
//   (a line belongs to the window that contains its first byte), so each failure message stays under the 1800 characters an Observer keeps.
// Risky: Report.SaveAs may need the OnPrem scope on the Cloud app; the whole file is one unit.
// BC versions: 29 (27 and 28 by CI)

table 70357 "LT P152 Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 70358 "LT P152 Header Report"
{
    ProcessingOnly = false;

    dataset
    {
        dataitem(Row; "LT P152 Row")
        {
            column(Id; Id) { }
        }
    }
}

codeunit 70359 "LT Hdr Dump"
{
    procedure Seed()
    var
        Row: Record "LT P152 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'one';
        Row.Insert();
        Commit();
    end;

    // Reads the first 4000 bytes of the Xml dataset. Lines.Get(i) = indentation|content|line end ; Starts.Get(i) = byte offset of the first byte of line i.
    procedure Build(var Lines: List of [Text]; var Starts: List of [Integer]; var Total: Integer; var Crs: Integer; var Lfs: Integer; var FirstBytes: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        B: Byte;
        Ch: Text[1];
        Content: Text;
        Ends: Text;
        Indent: Integer;
        InLeading: Boolean;
        InEnds: Boolean;
        LineStart: Integer;
        HasLine: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        Report.SaveAs(Report::"LT P152 Header Report", '', ReportFormat::Xml, OutS);
        TempBlob.CreateInStream(InS);
        InLeading := true;
        while (not InS.EOS()) and (Total < 4000) do begin
            InS.Read(B);
            if Total < 4 then
                FirstBytes += Format(B) + ' ';
            if B = 13 then begin
                Crs += 1;
                if not InEnds then
                    InEnds := true;
                Ends += '<CR>';
            end else
                if B = 10 then begin
                    Lfs += 1;
                    InEnds := true;
                    Ends += '<LF>';
                end else begin
                    if InEnds then begin
                        Lines.Add(Format(Indent) + '|' + Content + '|' + Ends);
                        Starts.Add(LineStart);
                        Content := '';
                        Ends := '';
                        Indent := 0;
                        InLeading := true;
                        InEnds := false;
                        HasLine := false;
                    end;
                    if not HasLine then begin
                        LineStart := Total;
                        HasLine := true;
                    end;
                    if InLeading and (B = 32) then
                        Indent += 1
                    else begin
                        InLeading := false;
                        Ch[1] := B;
                        Content += Ch;
                    end;
                end;
            if (B = 13) or (B = 10) then
                if not HasLine then begin
                    LineStart := Total;
                    HasLine := true;
                end;
            Total += 1;
        end;
        if HasLine then begin
            if Ends = '' then
                Ends := '<none, cut at 4000>';
            Lines.Add(Format(Indent) + '|' + Content + '|' + Ends);
            Starts.Add(LineStart);
        end;
    end;

    // Observes the lines whose first byte lies in [FromByte, FromByte + 500). A line over 700 characters is split into parts a, b, c...
    procedure ObserveWindow(var Observer: Codeunit "Probe Observer"; FromByte: Integer)
    var
        Lines: List of [Text];
        Starts: List of [Integer];
        Total: Integer;
        Crs: Integer;
        Lfs: Integer;
        FirstBytes: Text;
        i: Integer;
        Line: Text;
        Part: Integer;
        Name: Text;
    begin
        Build(Lines, Starts, Total, Crs, Lfs, FirstBytes);
        Observer.Observe('window from', Format(FromByte));
        for i := 1 to Lines.Count() do
            if (Starts.Get(i) >= FromByte) and (Starts.Get(i) < FromByte + 500) then begin
                Line := Lines.Get(i);
                Name := 'line ' + Format(i);
                if StrLen(Line) <= 700 then
                    Observer.Observe(Name, Line)
                else begin
                    Part := 0;
                    while Line <> '' do begin
                        Observer.Observe(Name + ' part ' + Format(Part), CopyStr(Line, 1, 700));
                        Line := CopyStr(Line, 701);
                        Part += 1;
                    end;
                end;
            end;
    end;
}

codeunit 70361 "LT Hdr Lines"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Lines_Window1()
    var
        Observer: Codeunit "Probe Observer";
        Dump: Codeunit "LT Hdr Dump";
    begin
        Dump.Seed();
        Dump.ObserveWindow(Observer, 0);
        Observer.Expect('window from', '0');
        Observer.Expect('line 1', '0|Ù‹<?xml version="1.0" standalone="yes"?>|<CR><LF>');
        Observer.Expect('line 2', '0|<ReportDataSet name="LT P152 Header Report" id="70358" language="en-US" formatRegion="en-US">|<CR><LF>');
        Observer.Expect('line 4', '4|<ReportMetadata>|<CR><LF>');
        Observer.Expect('line 5', '6|<ExtensionId>a1b2c3d4-e5f6-7890-abcd-ef1234567890</ExtensionId>|<CR><LF>');
        Observer.Expect('line 6', '6|<ExtensionName>AL Language Coverage Tests by AL Language</ExtensionName>|<CR><LF>');
        Observer.Expect('line 7', '6|<ExtensionPublisher>AL Language</ExtensionPublisher>|<CR><LF>');
        Observer.Expect('line 8', '6|<ExtensionVersion>x</ExtensionVersion>|<CR><LF>');
        Observer.Expect('line 9', '6|<ReportId>70358</ReportId>|<CR><LF>');
        Observer.Expect('line 10', '6|<ReportName>LT P152 Header Report</ReportName>|<CR><LF>');
        Observer.Ignore('line 3'); // a dump or environment data: observed, not asserted
        Observer.Verify();
    end;

    [Test]
    procedure Lines_Window2()
    var
        Observer: Codeunit "Probe Observer";
        Dump: Codeunit "LT Hdr Dump";
    begin
        Dump.Seed();
        Dump.ObserveWindow(Observer, 500);
        Observer.Expect('window from', '500');
#if BC29PLUS
        Observer.Expect('line 11', '6|<ReportCaption>LT P152 Header Report</ReportCaption>|<CR><LF>');
#else
        Observer.Expect('line 11', '6|<AboutThisReportTitle></AboutThisReportTitle>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 12', '6|<AboutThisReportTitle></AboutThisReportTitle>|<CR><LF>');
#else
        Observer.Expect('line 12', '6|<AboutThisReportText></AboutThisReportText>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 13', '6|<AboutThisReportText></AboutThisReportText>|<CR><LF>');
#else
        Observer.Expect('line 13', '6|<ReportHelpLink></ReportHelpLink>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 14', '6|<ReportHelpLink></ReportHelpLink>|<CR><LF>');
#else
        Observer.Expect('line 14', '4|</ReportMetadata>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 15', '4|</ReportMetadata>|<CR><LF>');
#else
        Observer.Expect('line 15', '4|<ReportRequest>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 16', '4|<ReportRequest>|<CR><LF>');
#else
        Observer.Expect('line 16', '6|<TenantEntraId>x</TenantEntraId>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 17', '6|<TenantEntraId>x</TenantEntraId>|<CR><LF>');
#else
        Observer.Expect('line 17', '6|<EnvironmentName>x</EnvironmentName>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 18', '6|<EnvironmentName>x</EnvironmentName>|<CR><LF>');
#else
        Observer.Expect('line 18', '6|<EnvironmentType>x</EnvironmentType>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 19', '6|<EnvironmentType>x</EnvironmentType>|<CR><LF>');
#else
        Observer.Expect('line 19', '6|<CompanyName>x</CompanyName>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 20', '6|<CompanyName>x</CompanyName>|<CR><LF>');
#else
        Observer.Expect('line 20', '6|<CompanyDisplayName>x</CompanyDisplayName>|<CR><LF>');
#endif
#if BC29PLUS
        Observer.Expect('line 21', '6|<CompanyDisplayName>x</CompanyDisplayName>|<CR><LF>');
#else
        Observer.Expect('line 21', '6|<CompanyId>x</CompanyId>|<CR><LF>');
#endif
        Observer.Verify();
    end;
}
