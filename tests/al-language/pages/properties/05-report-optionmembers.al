// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72120 "LT P121 Rpt OptMembers"
{
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {
            column(Id; Id) { }
            column(OptCol; OptVar)
            {
                OptionMembers = Alpha,Beta,Gamma;
            }

            trigger OnAfterGetRecord()
            begin
                OptVar := OptVar::Beta;
                Log.Add('opt=' + Format(OptVar));
            end;
        }
    }

    var
        OptVar: Option Alpha,Beta,Gamma;
        Log: Codeunit "LT P121 Log";
}

codeunit 72121 "LT P121 Rpt OptMembers Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_OptionColumn()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        asserterror Report.Run(Report::"LT P121 Rpt OptMembers");
        Observer.ObserveError('af48');
        Observer.Observe('log', Log.Take());
        Observer.Expect('af48|text', 'Report 72120 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('af48|code', 'ReportNoLayout');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
