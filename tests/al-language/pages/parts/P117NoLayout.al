// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: Probe Observer (codeunit 69160); own objects 70806-70808; RISKY: dataset report without any layout
// Facts: report with a dataset and no layout file at all: DefaultLayout, Run (RISKY: may not compile; own file)

table 70806 "LT P117 NoLayRow"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 70807 "LT P117 NoLayoutData"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT P117 NoLayRow")
        {
            column(Id; Id) { }
        }
    }
}

codeunit 70808 "LT P117 NoLayout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P117_DefaultLayout_DatasetReport()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P117 NoLayRow";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Commit();
        Observer.Observe('default layout', Format(Report.DefaultLayout(Report::"LT P117 NoLayoutData")));
        asserterror Report.Run(Report::"LT P117 NoLayoutData", false, false);
        Observer.ObserveError('run without layout');
        Observer.Expect('default layout', 'RDLC');
        Observer.Expect('run without layout|text', 'Report 70807 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('run without layout|code', 'ReportNoLayout');
        Observer.Verify();
    end;
}
