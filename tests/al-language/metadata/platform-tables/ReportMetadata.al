// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), layout files ./FixtureLayout.rdlc and ./ProbeSaveAsDatasetLayout.rdl of the app root; own reports 72951-72953
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: every column of Report Metadata (2000000139) read through RecordRef/FieldRef (column name, Format of the value) for a ProcessingOnly report, an RDLC report
// and a report with several layouts; the rows of Report Layout List (2000000234) for the multi-layout report. The App ID is only observed as set/blank.
// The Word report is in P175ReportMetadataWord.al (its layout file is generated at compile time like the other Word fixtures).
// BC versions: 29 (27 and 28 by CI)

codeunit 71578 "LT P175 Meta Helper"
{
    procedure OpenOne(var RR: RecordRef; TableNo: Integer; KeyField: Integer; Id: Integer): Boolean
    var
        FR: FieldRef;
    begin
        RR.Open(TableNo);
        FR := RR.Field(KeyField);
        FR.SetRange(Id);
        exit(RR.FindFirst());
    end;

    // Observes the columns FromIdx..ToIdx (positions, not numbers) of the current row as Prefix + column name.
    procedure DumpRange(var Observer: Codeunit "Probe Observer"; var RR: RecordRef; Prefix: Text; FromIdx: Integer; ToIdx: Integer)
    var
        FR: FieldRef;
        i: Integer;
        Shown: Text;
    begin
        for i := FromIdx to ToIdx do begin
            if i <= RR.FieldCount() then begin
                FR := RR.FieldIndex(i);
                if FR.Name = 'App ID' then
                    Shown := 'blank=' + Format(Format(FR.Value) = '{00000000-0000-0000-0000-000000000000}')
                else
                    Shown := Format(FR.Value);
                Observer.Observe(Prefix + FR.Name, Shown);
            end;
        end;
    end;

    procedure ColumnCount(var RR: RecordRef): Integer
    begin
        exit(RR.FieldCount());
    end;

    procedure NamedValue(var RR: RecordRef; ColumnName: Text): Text
    var
        FR: FieldRef;
        i: Integer;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name = ColumnName then
                exit(Format(FR.Value));
        end;
        exit('nofield');
    end;

    procedure ColumnNames(var RR: RecordRef): Text
    var
        FR: FieldRef;
        i: Integer;
        Result: Text;
    begin
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            Result += FR.Name + ',';
        end;
        exit(Result);
    end;

    // One line per row of Report Layout List for the report: the stable columns only.
    procedure LayoutRows(var Observer: Codeunit "Probe Observer"; Prefix: Text; ReportId: Integer)
    var
        RR: RecordRef;
        FR: FieldRef;
        Info: ModuleInfo;
        Rows: Integer;
        AppIdFieldValue: Text;
        i: Integer;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        RR.Open(2000000234);
        FR := RR.Field(1);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name = 'Report ID' then
                FR.SetRange(ReportId);
        end;
        Observer.Observe(Prefix + 'columns', ColumnNames(RR));
        if RR.FindSet() then
            repeat
                Rows += 1;
                Observer.Observe(Prefix + 'row' + Format(Rows),
                    'name=' + NamedValue(RR, 'Name') + ';caption=' + NamedValue(RR, 'Caption') + ';format=' + NamedValue(RR, 'Layout Format') +
                    ';desc=' + NamedValue(RR, 'Description') + ';obsolete=' + NamedValue(RR, 'IsObsolete'));
                AppIdFieldValue := NamedValue(RR, 'Application ID');
                Observer.Observe(Prefix + 'row' + Format(Rows) + ' app is this app', Format(AppIdFieldValue = Format(Info.Id())));
            until RR.Next() = 0;
        Observer.Observe(Prefix + 'rows', Format(Rows));
    end;
}

report 72951 "LT P175 Rpt Proc"
{
    ProcessingOnly = true;
    Caption = 'LT P175 processing only';

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }
}

report 72952 "LT P175 Rpt Rdlc"
{
    Caption = 'LT P175 rdlc';
    UsageCategory = None;
    DefaultRenderingLayout = OneRdlc;

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
        layout(OneRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_2.rdlc';
            Caption = 'P175 one rdlc';
            Summary = 'P175 rdlc summary';
        }
    }
}

report 72953 "LT P175 Rpt Multi"
{
    Caption = 'LT P175 multi';
    UsageCategory = None;
    DefaultRenderingLayout = SecondRdlc;

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
        layout(FirstRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/FixtureLayout_3.rdlc';
            Caption = 'P175 first';
        }
        layout(SecondRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout_2.rdl';
            Caption = 'P175 second';
            Summary = 'P175 second summary';
        }
    }
}

codeunit 71579 "LT P175 Report Metadata"
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
    procedure P175_Meta_ProcessingOnly_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Rpt Proc", 1, 16);
        Observer.Expect('found', 'Yes');
        Observer.Expect('ID', '72951');
        Observer.Expect('Name', 'LT P175 Rpt Proc');
        Observer.Expect('Caption', 'LT P175 processing only');
        Observer.Expect('UseRequestPage', 'Yes');
        Observer.Expect('UseSystemPrinter', 'No');
        Observer.Expect('EnableExternalImages', 'No');
        Observer.Expect('EnableHyperLinks', 'No');
        Observer.Expect('EnableExternalAssemblies', 'No');
        Observer.Expect('ProcessingOnly', 'Yes');
        Observer.Expect('ShowPrintStatus', 'Yes');
        Observer.Expect('TransactionType', 'UpdateNoLocks');
        Observer.Expect('PaperSourceFirstPage', '0');
        Observer.Expect('PaperSourceDefaultPage', '0');
        Observer.Expect('PaperSourceLastPage', '0');
        Observer.Expect('PreviewMode', 'Normal');
        Observer.Expect('DefaultLayout', 'RDLC');
        Observer.Verify();
    end;

    [Test]
    procedure P175_Meta_Rdlc_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Rpt Rdlc", 1, 16);
        Observer.Expect('found', 'Yes');
        Observer.Expect('ID', '72952');
        Observer.Expect('Name', 'LT P175 Rpt Rdlc');
        Observer.Expect('Caption', 'LT P175 rdlc');
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

    [Test]
    procedure P175_Meta_Multi_Part1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, Report::"LT P175 Rpt Multi", 1, 16);
        Observer.Expect('found', 'Yes');
        Observer.Expect('ID', '72953');
        Observer.Expect('Name', 'LT P175 Rpt Multi');
        Observer.Expect('Caption', 'LT P175 multi');
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

    [Test]
    procedure P175_DefaultLayout_PerReport()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('proc', Format(Report.DefaultLayout(Report::"LT P175 Rpt Proc")));
        Observer.Observe('rdlc', Format(Report.DefaultLayout(Report::"LT P175 Rpt Rdlc")));
        Observer.Observe('multi', Format(Report.DefaultLayout(Report::"LT P175 Rpt Multi")));
        Observer.Expect('proc', 'None');
        Observer.Expect('rdlc', 'RDLC');
        Observer.Expect('multi', 'RDLC');
        Observer.Verify();
    end;
}
