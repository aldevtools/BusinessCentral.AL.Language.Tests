// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); report 91230 "LT SC Meta Report" (ScReportMetadataViews.al, RDLC layout FixtureLayout_19.rdlc); own test codeunit 91312
// Probe: written against BC 29 and checked on the corpus CI matrix (27, 28, 29); every literal asserted below is what BC produced.
// Facts: the platform table Tenant Report Layout: whether the tenant holds rows for an app's own report before anything is inserted (all
//   companies and the current one), and Insert of a row for that report whose Layout holds the report's own RDLC layout (Report.RdlcLayout):
//   the answer of Insert, the row count of the report after it, the stored fields read back by Get, and Delete. ScReportMetadataViews.al pins
//   Insert of a blank row and of a row with an empty RDLC layout.
// BC versions: 27, 28, 29
codeunit 91312 "LT Y6 Tenant Report Layout"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure FreshTenant_RowsOfOwnReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
    begin
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('own report rows', Format(Layout.Count()));
        Layout.SetRange("Company Name", CompanyName());
        Observer.Observe('own report rows current company', Format(Layout.Count()));
        Layout.Reset();
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('own report findfirst', Format(Layout.FindFirst()));
        Observer.Finish();
    end;

    [Test]
    procedure Insert_WithRdlcLayoutOfTheReport()
    var
        Observer: Codeunit "Probe Observer";
        Layout: Record "Tenant Report Layout";
        ReadBack: Record "Tenant Report Layout";
        InS: InStream;
        Ok: Boolean;
    begin
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Layout.DeleteAll();
        Layout.Reset();
        Layout.Init();
        Layout."Report ID" := Report::"LT SC Meta Report";
        Layout.Name := 'LT Y6 Probe Layout';
        Layout."Layout Format" := Layout."Layout Format"::RDLC;
        Layout.Description := 'Y6 probe';
        Report.RdlcLayout(Report::"LT SC Meta Report", InS);
        Layout.Layout.ImportStream(InS, 'Y6 probe layout');
        Observer.Observe('layout has value before insert', Format(Layout.Layout.HasValue()));
        Ok := Layout.Insert();
        Observer.Observe('insert answer', Format(Ok));
        Layout.SetRange("Report ID", Report::"LT SC Meta Report");
        Observer.Observe('rows after insert', Format(Layout.Count()));
        if Layout.FindFirst() then
            Observer.Observe('stored', Layout.Name + '|' + Layout."Company Name" + '|' + Format(Layout."Layout Format") + '|' + Layout.Description + '|' + Layout."MIME Type" + '|' + Format(IsNullGuid(Layout."App ID")) + '|' + Format(Layout.Layout.HasValue()));
        ReadBack.SetRange("Report ID", Report::"LT SC Meta Report");
        ReadBack.SetRange(Name, 'LT Y6 Probe Layout');
        Observer.Observe('found by name', Format(ReadBack.FindFirst()));
        Ok := Layout.Insert();
        Observer.Observe('second insert answer', Format(Ok));
        Layout.DeleteAll();
        Observer.Observe('rows after delete', Format(Layout.Count()));
        Observer.Finish();
    end;
}
