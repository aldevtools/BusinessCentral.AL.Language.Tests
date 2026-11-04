// Migrated from AL Runner tests/runner-extras/report-saveas-stream (FixtureReport.Report.al).
// Fixture report: one data item over RSS Sample with concrete columns.
// Carries an RDLC layout so the report is NOT processing-only.
report 60872 "RSS Fixture Report"
{
    UsageCategory = None;
    ProcessingOnly = false;
    DefaultRenderingLayout = RdlcFixture;

    dataset
    {
        dataitem(Sample; "RSS Sample")
        {
            column(EntryNo; "Entry No.") { }
            column(Description; Description) { }
            column(Amount; Amount) { }
        }
    }

    rendering
    {
        layout(RdlcFixture)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout.rdlc';
        }
    }
}
