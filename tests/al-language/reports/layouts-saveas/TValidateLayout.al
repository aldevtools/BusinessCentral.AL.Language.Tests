// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-validateandpreparelayout-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (System Application), layout file ./FixtureLayout.rdlc of the app root; self-contained report 69367, test codeunit 69366
// Facts: Report.ValidateAndPrepareLayout, static (report id) and on a Report variable: the return value and the prepared stream for the report's own RDLC layout, and the error for a layout of the wrong type and for an unknown report id.
// BC versions: 27.0 and later

report 69367 "LT T Layout Rpt"
{
    UseRequestPage = false;
    DefaultRenderingLayout = TRdlc;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));

            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(TRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout.rdlc';
        }
    }
}

codeunit 69366 "LT T Validate Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HolderBlob: Codeunit "Temp Blob";

    local procedure ReadAll(var Content: InStream): Text
    var
        Line: Text;
        Result: Text;
    begin
        while not Content.EOS() do begin
            Content.ReadText(Line);
            Result += Line + '\n';
        end;
        exit(Result);
    end;

    local procedure TextStream(Content: Text; var TempBlob: Codeunit "Temp Blob"; var Stream: InStream)
    var
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);
        OutStr.WriteText(Content);
        TempBlob.CreateInStream(Stream, TextEncoding::UTF8);
    end;

    local procedure OwnLayout(var Stream: InStream)
    var
        Raw: InStream;
        OutStr: OutStream;
    begin
        Report.RdlcLayout(Report::"LT T Layout Rpt", Raw);
        Clear(HolderBlob);
        HolderBlob.CreateOutStream(OutStr);
        CopyStream(OutStr, Raw);
        HolderBlob.CreateInStream(Stream, TextEncoding::UTF8);
    end;

    [TryFunction]
    local procedure TryAtEnd(var Stream: InStream; var AtEnd: Boolean)
    begin
        AtEnd := Stream.EOS();
    end;

    local procedure Describe(Tag: Text; Ok: Boolean; var Prepared: InStream; Original: Text)
    var
        Text1: Text;
        AtEnd: Boolean;
    begin
        Observer.Observe(Tag + ' ok', Format(Ok));
        Observer.Observe(Tag + ' error', GetLastErrorText());
        if not TryAtEnd(Prepared, AtEnd) then
            Observer.Observe(Tag + ' prepared', 'not initialized')
        else if AtEnd then
            Observer.Observe(Tag + ' prepared', 'EOS')
        else begin
            Text1 := ReadAll(Prepared);
            Observer.Observe(Tag + ' prepared is xml', Format(Text1.Contains('<Report')));
        end;
        ClearLastError();
    end;

    [Test]
    procedure Validate_Static_OwnRdlcLayout()
    var
        Layout: InStream;
        Again: InStream;
        Prepared: InStream;
        Original: Text;
        Ok: Boolean;
    begin
        OwnLayout(Again);
        Original := ReadAll(Again);
        OwnLayout(Layout);
        // The last error of an earlier test carries over on Windows: clear it so 'static rdlc error' only sees this call.
        ClearLastError();
        Ok := Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::RDLC);
        Describe('static rdlc', Ok, Prepared, Original);
        Observer.Expect('static rdlc ok', 'Yes');
        Observer.Expect('static rdlc error', '');
        Observer.Expect('static rdlc prepared is xml', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Static_WrongLayoutType_Errors()
    var
        Layout: InStream;
        Prepared: InStream;
    begin
        OwnLayout(Layout);
        asserterror Report.ValidateAndPrepareLayout(Report::"LT T Layout Rpt", Layout, Prepared, ReportLayoutType::Word);
        Observer.ObserveError('static rdlc content as word');
        Observer.Expect('static rdlc content as word|text', 'File contains corrupted data.');
        Observer.Expect('static rdlc content as word|code', 'AL:FileFormat');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Static_UnknownReport_Errors()
    var
        Layout: InStream;
        Prepared: InStream;
    begin
        OwnLayout(Layout);
        asserterror Report.ValidateAndPrepareLayout(71999, Layout, Prepared, ReportLayoutType::RDLC);
        Observer.ObserveError('static unknown report');
        OwnLayout(Layout);
        asserterror Report.ValidateAndPrepareLayout(0, Layout, Prepared, ReportLayoutType::RDLC);
        Observer.ObserveError('static report 0');
#if LT_HELD_BCLINUX_166
        // Windows BC 27.5, 28.5 and 29.0 (Windows runs 2026-10-20) name the test codeunit. 28.5 passed the whole test and the Windows BC 29.0
        // check 2026-10-20 (bump 34 queue) gave both texts; 27.5 reported only the first difference, so 'static report 0|text' is asserted
        // on 28 and 29. Held on Linux under bc-linux #166: the image
        // at dbee8022 names 'Test Runner - Mgt.' on 27.5, 28.5 and 29.0 (PR run 39475237141); at 16116688 it did so on 27.5.
        Observer.Expect('static unknown report|text', 'You tried to invoke the Report object with the ID 71999 from the object LT T Validate Layout Tests. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('static unknown report|code', 'AL:MetadataNotFound');
#if BC28PLUS
        Observer.Expect('static report 0|text', 'You tried to invoke the Report object with the ID 0 from the object LT T Validate Layout Tests. An object with that ID does not exist in the current application compiled with emit version n.');
#else
        Observer.Ignore('static report 0|text');
#endif
        Observer.Expect('static report 0|code', 'AL:MetadataNotFound');
        Observer.Verify();
#else
        Observer.Ignore('static unknown report|text');
        Observer.Expect('static unknown report|code', 'AL:MetadataNotFound');
        Observer.Ignore('static report 0|text');
        Observer.Expect('static report 0|code', 'AL:MetadataNotFound');
        Observer.Verify();
#endif
    end;

    [Test]
    procedure Validate_Instance_OwnRdlcLayout()
    var
        Rpt: Report "LT T Layout Rpt";
        Layout: InStream;
        Again: InStream;
        Prepared: InStream;
        Original: Text;
        Ok: Boolean;
    begin
        OwnLayout(Again);
        Original := ReadAll(Again);
        OwnLayout(Layout);
        Ok := Rpt.ValidateAndPrepareLayout(Layout, Prepared, ReportLayoutType::RDLC);
        Describe('instance rdlc', Ok, Prepared, Original);
        Observer.Expect('instance rdlc ok', 'Yes');
        Observer.Expect('instance rdlc error', '');
        Observer.Expect('instance rdlc prepared is xml', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Instance_WrongLayoutType_Errors()
    var
        Rpt: Report "LT T Layout Rpt";
        Layout: InStream;
        Prepared: InStream;
    begin
        OwnLayout(Layout);
        asserterror Rpt.ValidateAndPrepareLayout(Layout, Prepared, ReportLayoutType::Word);
        Observer.ObserveError('instance rdlc content as word');
        Observer.Expect('instance rdlc content as word|text', 'File contains corrupted data.');
        Observer.Expect('instance rdlc content as word|code', 'AL:FileFormat');
        Observer.Verify();
    end;
}
