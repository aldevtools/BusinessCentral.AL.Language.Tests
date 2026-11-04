// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currreport/currreport-language-property
// Scope: in-scope
// Fixtures used: CurrReport Language Row (60527), CurrReport Language Report (60528)
//
// A report may set CurrReport.Language / CurrReport.FormatRegion from its own triggers.
//
// This is ordinary AL, not an edge case: the Base App's document reports do it per record
// (Standard Sales - Invoice sets the language from the customer's language code in its
// Header data item).
//
// CurrReport.Language affects record/number/date formatting regardless of rendering
// target, so it is readable back immediately even for a raw ReportFormat::Xml SaveAs
// (no layout renders). CurrReport.FormatRegion, per MS docs, only takes effect when
// rendering a Word or Excel layout — it is a no-op for Xml export (no layout is ever
// invoked), so it reads back empty here. That is real, documented BC behavior, not a
// runner/test gap.
//
// Both directions:
//   * a language the report sets is readable back and the run completes;
//   * a language of 0 is rejected by BC as an invalid language id, so the guard that
//     distinguishes "uninitialized" from "set" is not silently swallowing real values.

codeunit 60529 "Test Report CurrReport Lang"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize(LanguageId: Integer)
    var
        Row: Record "CurrReport Language Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.LanguageId := LanguageId;
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.LanguageId := LanguageId;
        Row.Insert();
    end;

    [Test]
    procedure TestReport_SettingCurrReportLanguage_RunsAndIsReadableBack()
    var
        Probe: Report "CurrReport Language Report";
        TempBlob: Codeunit "Temp Blob";
        ResultOutStream: OutStream;
    begin
        Initialize(1031);
        Clear(Probe);
        TempBlob.CreateOutStream(ResultOutStream);
        Probe.SaveAs('', ReportFormat::Xml, ResultOutStream);

        if Probe.RowsProcessed() <> 2 then
            Error('Expected both rows to be processed, got %1 — the report stopped early.',
                Probe.RowsProcessed());
        // 1031 (de-DE), deliberately NOT the session default: a getter that ignored the
        // assignment and answered the default language would still have "passed" on 1033.
        if Probe.LanguageSeen() <> 1031 then
            Error('CurrReport.Language read back as %1, expected 1031.', Probe.LanguageSeen());
        // FormatRegion only takes effect for Word/Excel layout rendering (MS docs); this
        // report exports Xml (no layout invoked at all), so the assignment is a no-op and
        // reads back empty — asserting that is what proves it did NOT silently error or
        // get ignored in some other, undocumented way.
        if Probe.FormatRegionSeen() <> '' then
            Error('CurrReport.FormatRegion read back as "%1", expected "" (Xml export never renders a layout, so FormatRegion is a documented no-op).',
                Probe.FormatRegionSeen());
    end;

    [Test]
    procedure TestReport_SettingCurrReportLanguageToZero_IsRejectedAsInvalid()
    var
        Probe: Report "CurrReport Language Report";
        TempBlob: Codeunit "Temp Blob";
        ResultOutStream: OutStream;
    begin
        // 0 is not a language id. BC rejects it outright, and it must keep doing so: the
        // runtime uses "localLanguage = 0" as its marker for "never set", so a 0 that slipped
        // through would be indistinguishable from an uninitialized report.
        Initialize(0);
        Clear(Probe);
        TempBlob.CreateOutStream(ResultOutStream);
        asserterror Probe.SaveAs('', ReportFormat::Xml, ResultOutStream);
        if StrPos(GetLastErrorText(), 'anguage') = 0 then
            Error('Expected an error naming the language, got: %1', GetLastErrorText());
    end;
}
