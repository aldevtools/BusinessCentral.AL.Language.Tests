// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72096 "LT P121 Rpt AutoCalc"
{
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {
            column(Id; Id) { }
            column(Total; Total)
            {
                AutoCalcField = true;
            }

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + Format(Row.Id) + ' total=' + Format(Row.Total));
            end;
        }
    }

    var
        Log: Codeunit "LT P121 Log";
}

codeunit 72097 "LT P121 Rpt AutoCalc Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_AutoCalcFieldColumn()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P121 Row";
    begin
        Helper.Seed();
        asserterror Report.Run(Report::"LT P121 Rpt AutoCalc");
        Observer.ObserveError('af47');
        Observer.Observe('log', Log.Take());
        asserterror Row.Get(1);
        Observer.ObserveError('af50');
        Observer.Observe('total_without_calcfields', Format(Row.Total));
        Observer.Expect('af47|text', 'Report 72096 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('af47|code', 'ReportNoLayout');
        Observer.Expect('log', '');
        Observer.Expect('af50|text', 'The LT P121 Row does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af50|code', 'DB:RecordNotFound');
        Observer.Expect('total_without_calcfields', '0');
        Observer.Verify();
    end;
}
