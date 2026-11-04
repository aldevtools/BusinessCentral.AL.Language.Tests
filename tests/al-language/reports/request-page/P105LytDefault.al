// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Fixtures used: tables and helper of P105Fix.al; self-contained report 72257 and test codeunit 72258; RISKY: layout member
// Facts: Report.DefaultLayout on a variable and with the report id; unknown id and id 0 errors

report 72257 "LT P105 LytDef Rep"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P105 Row")
        {
            column(Id; Id) { }
            column(Name; Name) { }
        }
    }
}

codeunit 72258 "LT P105 LytDef Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT P105 Helper";

    [Test]
    procedure P105_DefaultLayout_Instance()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT P105 LytDef Rep";
    begin
        Helper.Seed();
        Observer.Observe('instance', Format(Rpt.DefaultLayout()));
        Observer.Observe('instance twice', Format(Rpt.DefaultLayout()));
        Observer.Expect('instance', 'None');
        Observer.Expect('instance twice', 'None');
        Observer.Verify();
    end;

    [Test]
    procedure P105_DefaultLayout_Static()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        Observer.Observe('static', Format(Report.DefaultLayout(Report::"LT P105 LytDef Rep")));
        Observer.Expect('static', 'None');
        Observer.Verify();
    end;
}
