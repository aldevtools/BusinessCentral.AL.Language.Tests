// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72114 "LT P121 Base CalcF"
{
    ProcessingOnly = true;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; "LT P121 Row")
        {
            trigger OnAfterGetRecord()
            begin
                Log.Add('base row ' + Format(Row.Id) + ' total=' + Format(Row.Total));
            end;
        }
    }

    var
        Log: Codeunit "LT P121 Log";
}

reportextension 72115 "LT P121 Ext CalcF" extends "LT P121 Base CalcF"
{
    dataset
    {
        modify(Row)
        {
            CalcFields = Total;

            trigger OnAfterAfterGetRecord()
            begin
                Log.Add('ext row ' + Format(Row.Id) + ' total=' + Format(Row.Total));
            end;
        }
    }

    var
        Log: Codeunit "LT P121 Log";
}

codeunit 72116 "LT P121 Ext CalcF Test"
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
        Report.Run(Report::"LT P121 Base CalcF");
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'base row 1 total=12;ext row 1 total=12;base row 2 total=0;ext row 2 total=0;');
        Observer.Verify();
    end;
}
