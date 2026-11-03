// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-extension-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT P175 Meta Helper (71578), layout files ./FixtureLayout.rdlc and ./ProbeSaveAsDatasetLayout.rdl of the app root
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a report extension with a rendering section (two RDLC layouts) on a base report that declares one layout and DefaultRenderingLayout:
// the Report Layout List rows of the base report (the extension's layouts are listed: pinned for BC 27.5 in record/TestEventSubscriptionColumnsReportLayoutListContracts.al),
// which layout Report Metadata DefaultLayoutName / Report.DefaultLayout names as the default, and a base report without an own rendering section extended by one.
// Report.SaveAsXml is OnPrem scope, so what SaveAsXml shows of the extension's layouts is not testable here (not testable in the Cloud app).
// BC versions: 29 (27 and 28 by CI)

report 72955 "LT P175 Ext Base"
{
    Caption = 'LT P175 ext base';
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
            LayoutFile = './_fixtures/layouts/FixtureLayout_7.rdlc';
            Caption = 'P175 base layout';
        }
    }
}

report 72957 "LT P175 Ext Base NoRender"
{
    Caption = 'LT P175 ext base no rendering';
    UsageCategory = None;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
        }
    }
}

reportextension 72956 "LT P175 Ext Rendering" extends "LT P175 Ext Base"
{
    rendering
    {
        layout(ExtRdlcA)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout_6.rdl';
            Caption = 'P175 ext A';
            Summary = 'P175 ext A summary';
        }
        layout(ExtRdlcB)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_8.rdlc';
            Caption = 'P175 ext B';
        }
    }
}

reportextension 72958 "LT P175 Ext NoRender Ext" extends "LT P175 Ext Base NoRender"
{
    rendering
    {
        layout(ExtOnly)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_9.rdlc';
            Caption = 'P175 ext only';
        }
    }
}

codeunit 71581 "LT P175 Report Ext Render"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Dump(var Observer: Codeunit "Probe Observer"; ReportId: Integer; FromIdx: Integer; ToIdx: Integer)
    var
        Helper: Codeunit "LT P175 Meta Helper";
        RR: RecordRef;
    begin
        Observer.Observe('found', Format(Helper.OpenOne(RR, 2000000139, 1, ReportId)));
        Helper.DumpRange(Observer, RR, '', FromIdx, ToIdx);
        RR.Close();
    end;

    [Test]
    procedure P175_ExtRender_DefaultLayoutOfBase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('base', Format(Report.DefaultLayout(Report::"LT P175 Ext Base")));
        Observer.Observe('norender', Format(Report.DefaultLayout(Report::"LT P175 Ext Base NoRender")));
        Observer.Expect('base', 'RDLC');
        Observer.Expect('norender', 'RDLC');
        Observer.Verify();
    end;

    [Test]
    procedure P175_ExtRender_MetadataBase_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Ext Base", 1, 16);
        Observer.Expect('found', 'Yes');
        Observer.Expect('ID', '72955');
        Observer.Expect('Name', 'LT P175 Ext Base');
        Observer.Expect('Caption', 'LT P175 ext base');
        Observer.Expect('UseRequestPage', 'Yes');
        Observer.Expect('UseSystemPrinter', 'No');
        Observer.Expect('EnableExternalImages', 'No');
        Observer.Expect('EnableHyperLinks', 'No');
        Observer.Expect('EnableExternalAssemblies', 'No');
        Observer.Expect('ProcessingOnly', 'No');
        Observer.Expect('ShowPrintStatus', 'Yes');
        Observer.Expect('TransactionType', 'UpdateNoLocks');
        Observer.Expect('PaperSourceFirstPage', '0');
        Observer.Expect('PaperSourceDefaultPage', '0');
        Observer.Expect('PaperSourceLastPage', '0');
        Observer.Expect('PreviewMode', 'Normal');
        Observer.Expect('DefaultLayout', 'RDLC');
        Observer.Verify();
    end;
}
