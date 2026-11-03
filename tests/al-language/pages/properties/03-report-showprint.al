// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72112 "LT P121 Rpt ShowPrint"
{
    ShowPrintStatus = false;
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + Format(Row.Id));
            end;
        }
    }

    var
        Log: Codeunit "LT P121 Log";

}

codeunit 72113 "LT P121 Rpt ShowPrint Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_RunReport()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Report.Run(Report::"LT P121 Rpt ShowPrint");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'row 1;row 2;');
        Observer.Verify();
    end;
}
