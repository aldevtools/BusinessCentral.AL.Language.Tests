// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-defaultlayout-method
// Scope: in-scope
// Fixtures used: Test Rpt MetaLoader Sample (60547)
//
// Fixture report: one data item over the sample table. Source-compiled in the same bundle
// as the test codeunit below, so its real metadata is captured at emit time — this is the
// case the metadata loader is meant to serve.

report 60548 "Test Rpt MetaLoader Fixture"
{
    UsageCategory = None;
    ProcessingOnly = false;

    dataset
    {
        dataitem(Sample; "Test Rpt MetaLoader Sample")
        {
            column(EntryNo; "Entry No.") { }
            column(SampleDescription; Description) { }
        }
    }
}
