// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-rdlclayout-method
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Probe Observer (codeunit 69160); own objects 70809-70810; RISKY: Report.RdlcLayout / WordLayout / ExcelLayout may need OnPrem scope
// Facts: Report.RdlcLayout, Report.WordLayout, Report.ExcelLayout on an own layout-less report (RISKY, own file)

report 70809 "LT P117 LayoutStreams"
{
    ProcessingOnly = true;
    UsageCategory = None;
}

codeunit 70810 "LT P117 Layout Stream Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P117_RdlcLayout_NoLayoutReport()
    var
        Observer: Codeunit "Probe Observer";
        InStr: InStream;
    begin
        asserterror Report.RdlcLayout(Report::"LT P117 LayoutStreams", InStr);
        Observer.ObserveError('rdlc layout');
        asserterror Report.WordLayout(Report::"LT P117 LayoutStreams", InStr);
        Observer.ObserveError('word layout');
        asserterror Report.ExcelLayout(Report::"LT P117 LayoutStreams", InStr);
        Observer.ObserveError('excel layout');
        Observer.Expect('rdlc layout|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.');
        Observer.Expect('rdlc layout|code', 'ReportNoLayout');
        Observer.Expect('word layout|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.');
        Observer.Expect('word layout|code', 'ReportNoLayout');
        Observer.Expect('excel layout|text', 'Exception of type ''Microsoft.Dynamics.Nav.Types.Exceptions.NavNCLReportNoLayoutException'' was thrown.');
        Observer.Expect('excel layout|code', 'ReportNoLayout');
        Observer.Verify();
    end;
}
