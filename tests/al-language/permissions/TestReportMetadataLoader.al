// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-defaultlayout-method
// Scope: in-scope
// Fixtures used: Assert (60021), Test Rpt MetaLoader Fixture (60548)
//
// Report.DefaultLayout must reach a source-compiled report's real metadata, not throw or
// silently return the platform default.
//
// Uses Report.DefaultLayout rather than Report.WordXmlPart: WordXmlPart additionally
// generates an Office custom XML part, which is a separate, unrelated surface — DefaultLayout
// is the minimal AL surface that isolates just this claim.

codeunit 60549 "Test Report Metadata Loader"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    begin
        // No tables are used by this codeunit.
    end;

    // Positive: DefaultLayout must report the report's REAL declared layout
    // kind — not just "did not throw". A stub/default-returning implementation
    // would report None (BC's zero-value), not RDLC.
    [Test]
    procedure TestReport_DefaultLayout_SourceCompiledReport_ReturnsRealLayoutKind()
    var
        LayoutText: Text;
    begin
        Initialize();

        LayoutText := Format(Report.DefaultLayout(60548));

        Assert.IsSubstring(LayoutText, 'RDLC');
    end;

    // Negative: an unknown report id must still fail loudly, not silently
    // succeed — proves the loader did not turn "no metadata registered" into a
    // silent no-op for objects that genuinely do not exist.
    [Test]
    procedure TestReport_DefaultLayout_UnknownReportId_ThrowsRealError()
    var
        LayoutText: Text;
    begin
        Initialize();

        asserterror LayoutText := Format(Report.DefaultLayout(99999998));
    end;
}
