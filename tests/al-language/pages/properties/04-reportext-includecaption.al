// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72117 "LT P121 Base IncCap"
{
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {
            column(Id; Id) { }

            trigger OnAfterGetRecord()
            begin
                Log.Add('row ' + Format(Row.Id));
            end;
        }
    }

    var
        Log: Codeunit "LT P121 Log";
}

reportextension 72118 "LT P121 Ext IncCap" extends "LT P121 Base IncCap"
{
    dataset
    {
        add(Row)
        {
            column(Txt; Txt)
            {
                IncludeCaption = true;
            }
            column(Qty; Qty)
            {
                IncludeCaption = false;
            }
        }
    }
}

codeunit 72119 "LT P121 Ext IncCap Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P121_RunExtendedReport()
    var
        Helper: Codeunit "LT P121 Helper";
        Log: Codeunit "LT P121 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Helper.Seed();
        asserterror Report.Run(Report::"LT P121 Base IncCap");
        Observer.ObserveError('af60');
        Observer.Observe('log', Log.Take());
        Observer.Expect('af60|text', 'Report 72117 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('af60|code', 'ReportNoLayout');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
