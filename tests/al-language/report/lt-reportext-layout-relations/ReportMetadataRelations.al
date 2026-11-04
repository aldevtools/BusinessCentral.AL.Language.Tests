// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), layout files ./FixtureLayout.rdlc and ./ProbeSaveAsDatasetLayout.rdl of the app root; own reports 71711-71712; own helper codeunit 71706
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Report Metadata (2000000139) and Report Layout List (2000000234) read through RecordRef/FieldRef as RELATIONS that must hold on every BC version (27, 28, 29), because the exact value dump
// of LT P175 Meta Helper's tests differed on 27/28: the row is found, the column count is above 0, the named columns ID / Name / Caption / ProcessingOnly / DefaultLayout exist (NamedValue is not 'nofield'),
// ID and Name equal the report's own, the default layout column is non-empty for a report with layouts, the Layout List holds as many rows as the report declares layouts.
// NOT DONE: the exact per-column values on BC 27 and 28 cannot be measured on the BC 29 tier used for writing. The CI legs 27.x/28.x have to measure the 'columnNames' observation of
// ReportMeta_ColumnNames (list of all column names in order) and the per-column values of the earlier dump; they are the open part of topic #183 item 2.
// BC versions: 29 (27 and 28 by CI)

codeunit 71706 "LT Meta Rel Helper"
{
    procedure OpenOne(var RR: RecordRef; TableNo: Integer; Id: Integer): Boolean
    var
        FR: FieldRef;
        i: Integer;
    begin
        RR.Open(TableNo);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if (FR.Name = 'ID') or (FR.Name = 'Report ID') then begin
                FR.SetRange(Id);
                exit(RR.FindFirst());
            end;
        end;
        exit(false);
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

    procedure HasColumn(var RR: RecordRef; ColumnName: Text): Boolean
    begin
        exit(NamedValue(RR, ColumnName) <> 'nofield');
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

    procedure LayoutRowCount(ReportId: Integer; LayoutName: Text): Integer
    var
        RR: RecordRef;
        FR: FieldRef;
        i: Integer;
        Rows: Integer;
    begin
        RR.Open(2000000234);
        for i := 1 to RR.FieldCount() do begin
            FR := RR.FieldIndex(i);
            if FR.Name = 'Report ID' then
                FR.SetRange(ReportId);
        end;
        if RR.FindSet() then
            repeat
                if (LayoutName = '') or (NamedValue(RR, 'Name') = LayoutName) then
                    Rows += 1;
            until RR.Next() = 0;
        exit(Rows);
    end;
}

report 71711 "LT Meta Rel Two Layouts"
{
    Caption = 'LT meta rel two layouts';
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
            LayoutFile = './_fixtures/layouts/FixtureLayout_6.rdlc';
            Caption = 'Meta rel first';
        }
        layout(SecondRdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSaveAsDatasetLayout_5.rdl';
            Caption = 'Meta rel second';
        }
    }
}

report 71712 "LT Meta Rel Proc Only"
{
    Caption = 'LT meta rel proc only';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
        }
    }
}

codeunit 71698 "LT Report Meta Relations"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ReportMeta_TwoLayouts_RowAndColumnsPresent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Meta Rel Helper";
        RR: RecordRef;
    begin
        Observer.Observe('found', Format(Helper.OpenOne(RR, 2000000139, Report::"LT Meta Rel Two Layouts")));
        Observer.Observe('columnCount > 0', Format(RR.FieldCount() > 0));
        Observer.Observe('has ID', Format(Helper.HasColumn(RR, 'ID')));
        Observer.Observe('has Name', Format(Helper.HasColumn(RR, 'Name')));
        Observer.Observe('has Caption', Format(Helper.HasColumn(RR, 'Caption')));
        Observer.Observe('has ProcessingOnly', Format(Helper.HasColumn(RR, 'ProcessingOnly')));
        Observer.Observe('has DefaultLayout', Format(Helper.HasColumn(RR, 'DefaultLayout')));
        Observer.Observe('has UseRequestPage', Format(Helper.HasColumn(RR, 'UseRequestPage')));
        Observer.Observe('has TransactionType', Format(Helper.HasColumn(RR, 'TransactionType')));
        Observer.Observe('ID equals', Format(Helper.NamedValue(RR, 'ID') = Format(Report::"LT Meta Rel Two Layouts")));
        Observer.Observe('Name equals', Format(Helper.NamedValue(RR, 'Name') = 'LT Meta Rel Two Layouts'));
        Observer.Observe('Caption equals', Format(Helper.NamedValue(RR, 'Caption') = 'LT meta rel two layouts'));
        Observer.Observe('DefaultLayout non-empty', Format(Helper.NamedValue(RR, 'DefaultLayout') <> ''));
        Observer.Observe('ProcessingOnly', Helper.NamedValue(RR, 'ProcessingOnly'));
        RR.Close();
        Observer.Expect('found', 'Yes');
        Observer.Expect('columnCount > 0', 'Yes');
        Observer.Expect('has ID', 'Yes');
        Observer.Expect('has Name', 'Yes');
        Observer.Expect('has Caption', 'Yes');
        Observer.Expect('has ProcessingOnly', 'Yes');
        Observer.Expect('has DefaultLayout', 'Yes');
        Observer.Expect('has UseRequestPage', 'Yes');
        Observer.Expect('has TransactionType', 'Yes');
        Observer.Expect('ID equals', 'Yes');
        Observer.Expect('Name equals', 'Yes');
        Observer.Expect('Caption equals', 'Yes');
        Observer.Expect('DefaultLayout non-empty', 'Yes');
        Observer.Expect('ProcessingOnly', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ReportMeta_ProcessingOnly_RowAndColumnsPresent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Meta Rel Helper";
        RR: RecordRef;
    begin
        Observer.Observe('found', Format(Helper.OpenOne(RR, 2000000139, Report::"LT Meta Rel Proc Only")));
        Observer.Observe('columnCount > 0', Format(RR.FieldCount() > 0));
        Observer.Observe('ID equals', Format(Helper.NamedValue(RR, 'ID') = Format(Report::"LT Meta Rel Proc Only")));
        Observer.Observe('Name equals', Format(Helper.NamedValue(RR, 'Name') = 'LT Meta Rel Proc Only'));
        Observer.Observe('ProcessingOnly', Helper.NamedValue(RR, 'ProcessingOnly'));
        Observer.Observe('DefaultLayout non-empty', Format(Helper.NamedValue(RR, 'DefaultLayout') <> ''));
        RR.Close();
        Observer.Expect('found', 'Yes');
        Observer.Expect('columnCount > 0', 'Yes');
        Observer.Expect('ID equals', 'Yes');
        Observer.Expect('Name equals', 'Yes');
        Observer.Expect('ProcessingOnly', 'Yes');
        Observer.Expect('DefaultLayout non-empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LayoutList_TwoLayouts_RowCountEqualsDeclared()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Meta Rel Helper";
    begin
        Observer.Observe('rows = 2', Format(Helper.LayoutRowCount(Report::"LT Meta Rel Two Layouts", '') = 2));
        Observer.Observe('rows', Format(Helper.LayoutRowCount(Report::"LT Meta Rel Two Layouts", '')));
        Observer.Observe('FirstRdlc rows', Format(Helper.LayoutRowCount(Report::"LT Meta Rel Two Layouts", 'FirstRdlc')));
        Observer.Observe('SecondRdlc rows', Format(Helper.LayoutRowCount(Report::"LT Meta Rel Two Layouts", 'SecondRdlc')));
        Observer.Observe('proc only rows', Format(Helper.LayoutRowCount(Report::"LT Meta Rel Proc Only", '')));
        Observer.Expect('rows = 2', 'Yes');
        Observer.Expect('rows', '2');
        Observer.Expect('FirstRdlc rows', '1');
        Observer.Expect('SecondRdlc rows', '1');
        Observer.Expect('proc only rows', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Report_DefaultLayout_TwoLayouts_IsRdlc()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('DefaultLayout', Format(Report.DefaultLayout(Report::"LT Meta Rel Two Layouts")));
        Observer.Expect('DefaultLayout', 'RDLC');
        Observer.Verify();
    end;
}
