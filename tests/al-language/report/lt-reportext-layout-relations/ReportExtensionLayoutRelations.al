// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-extension-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Meta Rel Helper (71706, in ReportMetadataRelations.al), layout files ./FixtureLayout.rdlc and ./ProbeSaveAsDatasetLayout.rdl of the app root
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a reportextension with a rendering section (two RDLC layouts) on a base report with one layout and DefaultRenderingLayout: RELATIONS only, because the exact observations of
// LT P175 Report Ext Render (report/lt-reportext-rendering) differed on BC 27/28 legs: the Report Layout List rows of the base report contain the extension's layouts (row count = base + extension layouts,
// each extension layout name exactly once), Report.DefaultLayout of the base report, Report Metadata DefaultLayout is non-empty.
// NOT TESTABLE in the Cloud app: which layout Report.SaveAs (OnPrem scope) uses, and which layout Report.Run renders (no observable output without a UI handler/printer);
// the reportextension object has no DefaultRenderingLayout property, so the extension cannot change the default layout; whether SaveAs picks an extension layout needs the OnPrem app.
// BC versions: 29 (27 and 28 by CI)

report 71713 "LT RepExt Rel Base"
{
    Caption = 'LT repext rel base';
    UsageCategory = None;
    DefaultRenderingLayout = BaseRdlc;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }

    rendering
    {
        layout(BaseRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_4.rdlc';
            Caption = 'RepExt rel base';
        }
    }
}

reportextension 71714 "LT RepExt Rel Ext" extends "LT RepExt Rel Base"
{
    rendering
    {
        layout(RelExtA)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout_4.rdl';
            Caption = 'RepExt rel ext A';
        }
        layout(RelExtB)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_5.rdlc';
            Caption = 'RepExt rel ext B';
        }
    }
}

codeunit 71699 "LT RepExt Layout Rel"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LayoutList_BaseWithExtension_ContainsExtensionLayouts()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Meta Rel Helper";
    begin
        Observer.Observe('base rows', Format(Helper.LayoutRowCount(Report::"LT RepExt Rel Base", 'BaseRdlc')));
        Observer.Observe('ext A rows', Format(Helper.LayoutRowCount(Report::"LT RepExt Rel Base", 'RelExtA')));
        Observer.Observe('ext B rows', Format(Helper.LayoutRowCount(Report::"LT RepExt Rel Base", 'RelExtB')));
        Observer.Observe('all rows', Format(Helper.LayoutRowCount(Report::"LT RepExt Rel Base", '')));
        Observer.Observe('all rows = 3', Format(Helper.LayoutRowCount(Report::"LT RepExt Rel Base", '') = 3));
        Observer.Expect('base rows', '1');
        Observer.Expect('ext A rows', '1');
        Observer.Expect('ext B rows', '1');
        Observer.Expect('all rows', '3');
        Observer.Expect('all rows = 3', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DefaultLayout_BaseWithExtension_IsRdlc()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Meta Rel Helper";
        RR: RecordRef;
    begin
        Observer.Observe('Report.DefaultLayout', Format(Report.DefaultLayout(Report::"LT RepExt Rel Base")));
        Observer.Observe('metadata found', Format(Helper.OpenOne(RR, 2000000139, Report::"LT RepExt Rel Base")));
        Observer.Observe('metadata DefaultLayout non-empty', Format(Helper.NamedValue(RR, 'DefaultLayout') <> ''));
        Observer.Observe('metadata DefaultLayout equals Report.DefaultLayout', Format(Helper.NamedValue(RR, 'DefaultLayout') = Format(Report.DefaultLayout(Report::"LT RepExt Rel Base"))));
        RR.Close();
        Observer.Expect('Report.DefaultLayout', 'RDLC');
        Observer.Expect('metadata found', 'Yes');
        Observer.Expect('metadata DefaultLayout non-empty', 'Yes');
        Observer.Expect('metadata DefaultLayout equals Report.DefaultLayout', 'Yes');
        Observer.Verify();
    end;
}
