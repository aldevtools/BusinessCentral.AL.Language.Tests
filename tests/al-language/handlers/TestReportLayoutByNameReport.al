// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-layout-name
// Scope: in-scope
// Fixtures used: Report Layout ByName Sample (60530)
//
// Fixture report declaring TWO named rendering layouts of DIFFERENT Type.
//
//   LayoutOne — Type = RDLC   (the report's DefaultRenderingLayout)
//   LayoutTwo — Type = Custom (never selected unless chosen BY NAME)
//
// The differing Type is deliberate: it is the observable that distinguishes
// "the by-name selection actually resolved LayoutTwo" from "the runtime fell
// back to the report default". The RDLC fork is external rendering (out of
// scope, throws report-rendering-external); the Custom fork is the in-scope
// custom-document-merger path. Same report, same SaveAs call, different layout
// NAME => different fork.

report 60531 "Report Layout ByName Fixture"
{
    UsageCategory = None;
    ProcessingOnly = false;
    DefaultRenderingLayout = LayoutOne;

    dataset
    {
        dataitem(Sample; "Report Layout ByName Sample")
        {
            column(EntryNo; "Entry No.") { }
            column(Description; Description) { }
        }
    }

    rendering
    {
        layout(LayoutOne)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/TestReportLayoutByNameOne.rdlc';
            Caption = 'Layout one (RDLC default)';
            Summary = 'The report default rendering layout.';
        }
        layout(LayoutTwo)
        {
            Type = Custom;
            LayoutFile = './_fixtures/layouts/TestReportLayoutByNameTwo.rlblayout';
            MimeType = 'application/x-rlb-layout';
            Caption = 'Layout two (custom, non-default)';
            Summary = 'Only reachable by selecting it by name.';
        }
    }
}
