// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

report 72468 "LT P194 SearchTerms Rpt"
{
    ProcessingOnly = true;
    UseRequestPage = false;
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    AdditionalSearchTerms = 'alpha beta,gamma';

    dataset
    {
        dataitem(Row; "LT P194 Gen")
        {
            trigger OnAfterGetRecord()
            var
                Log: Codeunit "LT P194 Log";
            begin
                Log.Add('row ' + Row."Code");
            end;
        }
    }
}

codeunit 72469 "LT P194 SearchTerms Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P194_Report_RunsWithSearchTerms()
    var
        Gen: Record "LT P194 Gen";
        Log: Codeunit "LT P194 Log";
        Observer: Codeunit "Probe Observer";
    begin
        Gen.DeleteAll();
        Log.Wipe();
        Gen."Code" := 'A';
        Gen.Insert();
        Gen."Code" := 'B';
        Gen.Insert();
        Report.Run(Report::"LT P194 SearchTerms Rpt", false, false, Gen);
        Observer.Observe('log', Log.GetAll());
        Observer.Expect('log', 'row A;row B;');
        Observer.Verify();
    end;

    [Test]
    procedure P194_Report_NameInAllObjects()
    var
        AllObj: Record AllObjWithCaption;
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('found', Format(AllObj.Get(AllObj."Object Type"::Report, Report::"LT P194 SearchTerms Rpt")));
        Observer.Observe('name', AllObj."Object Name");
        Observer.Observe('caption', AllObj."Object Caption");
        Observer.Expect('found', 'Yes');
        Observer.Expect('name', 'LT P194 SearchTerms Rpt');
        Observer.Expect('caption', 'LT P194 SearchTerms Rpt');
        Observer.Verify();
    end;
}
