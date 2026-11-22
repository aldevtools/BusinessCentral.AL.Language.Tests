// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); W3 Dataset (codeunit 67703); Temp Blob (System Application); own table 96620,
//   reports 96621-96623, codeunit 96624.
// Probe: from the code-sweep issue al-runner 7634 (report paths that answer with no pin) and the trial report al-runner 6924
//   (EnableExternalImages). The expected values are what the corpus CI legs (BC 27.5, 28.5, 29.0) returned.
// Area:
//   - the decimalformatter and value of a Decimal column whose field has AutoFormatType = 1 with an AutoFormatExpression that names a
//     currency code field (blank, a code no Currency row has), AutoFormatType = 1 beside DecimalPlaces = 0:3, AutoFormatType = 2;
//   - an Option column whose value has a blank caption, and one whose ordinal is past the last member;
//   - the dataset header of a SaveAs Xml, unmasked, up to the data items (TenantEntraId, EnvironmentName, EnvironmentType, the time);
//   - a report with EnableExternalImages = true: SaveAs Xml and Execute;
//   - Report.SaveAs as Pdf, Word, Excel and Html of a report with DefaultLayout = RDLC and no layout file: the answer, the error and its code.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

table 96620 "LT RCF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Currency Code"; Code[10]) { }
        field(3; AmtCur; Decimal) { AutoFormatType = 1; AutoFormatExpression = "Currency Code"; }
        field(4; AmtPlaces; Decimal) { AutoFormatType = 1; DecimalPlaces = 0 : 3; }
        field(5; AmtUnit; Decimal) { AutoFormatType = 2; AutoFormatExpression = "Currency Code"; }
        field(6; Opt; Option) { OptionMembers = Alpha,Beta,Gamma; OptionCaption = 'Alpha,,Gamma'; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 96621 "LT RCF Rpt"
{
    UsageCategory = None;

    dataset
    {
        dataitem(Row; "LT RCF Row")
        {
            column(Id; Id) { }
            column(AmtCur; AmtCur) { }
            column(AmtPlaces; AmtPlaces) { }
            column(AmtUnit; AmtUnit) { }
            column(Opt; Opt) { }
        }
    }
}

report 96622 "LT RCF ExtImg"
{
    UsageCategory = None;
    EnableExternalImages = true;

    dataset
    {
        dataitem(Row; "LT RCF Row")
        {
            column(Id; Id) { }
        }
    }
}

report 96623 "LT RCF NoLayout"
{
    UsageCategory = None;
    DefaultLayout = RDLC;

    dataset
    {
        dataitem(Row; "LT RCF Row")
        {
            column(Id; Id) { }
        }
    }
}

codeunit 96624 "LT RCF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure AddRow(Id: Integer; CurrencyCode: Code[10]; Value: Decimal; OptOrdinal: Integer)
    var
        Row: Record "LT RCF Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row."Currency Code" := CurrencyCode;
        Row.AmtCur := Value;
        Row.AmtPlaces := Value;
        Row.AmtUnit := Value;
        Row.Opt := OptOrdinal;
        Row.Insert();
    end;

    [Test]
    procedure RCF_AutoFormatColumns_AndOptionCaptions()
    var
        Row: Record "LT RCF Row";
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Row.DeleteAll();
        AddRow(1, '', 1234.5, 0);
        AddRow(2, 'XYZ', 1.23456, 1);
        AddRow(3, '', 2, 5);
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT RCF Rpt", '', Xml)));
        Observer.ObserveError('save');
        Observer.Observe('columns', Dataset.ColumnLines(Xml));
        Row.Get(2);
        Observer.Observe('format row 2', Format(Row.AmtCur) + ' / ' + Format(Row.AmtPlaces) + ' / ' + Format(Row.AmtUnit) + ' / [' + Format(Row.Opt) + ']');
        Row.Get(3);
        Observer.Observe('format row 3 opt', '[' + Format(Row.Opt) + ']');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('save|text', '');
        Observer.Expect('save|code', '');
#if BC28PLUS
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="AmtCur" decimalformatter="#,##0.00">1234.5</Column>|<Column name="AmtPlaces" decimalformatter="#,##0.00">1234.5</Column>|<Column name="AmtUnit" decimalformatter="#,##0.00###">1234.5</Column>|<Column name="Opt">Alpha</Column>|<Column name="Id">2</Column>|<Column name="AmtCur" decimalformatter="#,##0.00">1.23456</Column>|<Column name="AmtPlaces" decimalformatter="#,##0.00">1.23456</Column>|<Column name="AmtUnit" decimalformatter="#,##0.00###">1.23456</Column>|<Column name="Opt">Beta</Column>|<Column name="Id">3</Column>|<Column name="AmtCur" decimalformatter="#,##0.00">2</Column>|<Column name="AmtPlaces" decimalformatter="#,##0.00">2</Column>|<Column name="AmtUnit" decimalformatter="#,##0.00###">2</Column>|<Column name="Opt">5</Column>|');
#else
        Observer.Expect('columns', '<Column name="Id">1</Column>|<Column name="AmtCur" decimalformatter="#,##0.00">1234.5</Column>|<Column name="AmtPlaces" decimalformatter="#,##0.###">1234.5</Column>|<Column name="AmtUnit" decimalformatter="#,##0.00###">1234.5</Column>|<Column name="Opt">Alpha</Column>|<Column name="Id">2</Column>|<Column name="AmtCur" decimalformatter="#,##0.00">1.23456</Column>|<Column name="AmtPlaces" decimalformatter="#,##0.###">1.23456</Column>|<Column name="AmtUnit" decimalformatter="#,##0.00###">1.23456</Column>|<Column name="Opt">Beta</Column>|<Column name="Id">3</Column>|<Column name="AmtCur" decimalformatter="#,##0.00">2</Column>|<Column name="AmtPlaces" decimalformatter="#,##0.###">2</Column>|<Column name="AmtUnit" decimalformatter="#,##0.00###">2</Column>|<Column name="Opt">5</Column>|');
#endif
#if BC28PLUS
        Observer.Expect('format row 2', '1.23 / 1.23 / 1.23456 / [Beta]');
#else
        Observer.Expect('format row 2', '1.23 / 1.23456 / 1.23456 / [Beta]');
#endif
        Observer.Expect('format row 3 opt', '[5]');
        Observer.Verify();
    end;

    [Test]
    procedure RCF_DatasetHeader_Unmasked()
    var
        Row: Record "LT RCF Row";
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
        Pos: Integer;
    begin
        Row.DeleteAll();
        AddRow(1, '', 1, 0);
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT RCF Rpt", '', Xml)));
        Pos := StrPos(Xml, '<DataItems>');
        if Pos > 0 then
            Xml := CopyStr(Xml, 1, Pos - 1);
        Observer.Observe('header', Xml);
        Observer.Observe('now', Format(CurrentDateTime(), 0, 9));
        Observer.Expect('saved', 'Yes');
        Observer.Expect('header', '<?xml version="1.0" standalone="yes"?>\n<ReportDataSet name="LT RCF Rpt" id="96621" language="en-US" formatRegion="en-US">\n  <BCReportInformation>x</BCReportInformation>\n  ');
        Observer.Ignore('now');
        Observer.Verify();
    end;

    [Test]
    procedure RCF_EnableExternalImages_SaveAsAndExecute()
    var
        Row: Record "LT RCF Row";
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Xml: Text;
    begin
        Row.DeleteAll();
        AddRow(1, '', 1, 0);
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT RCF ExtImg", '', Xml)));
        Observer.ObserveError('save');
        Observer.Observe('columns', Dataset.ColumnLines(Xml));
        ClearLastError();
        Observer.Observe('execute', Format(TryExecute(Report::"LT RCF ExtImg")));
        Observer.ObserveError('execute');
        Observer.Expect('saved', 'Yes');
        Observer.Expect('save|text', '');
        Observer.Expect('save|code', '');
        Observer.Expect('columns', '<Column name="Id">1</Column>|');
        Observer.Expect('execute', 'No');
        Observer.Expect('execute|text', 'Report 96622 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('execute|code', 'ReportNoLayout');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryExecute(ReportId: Integer)
    begin
        Report.Execute(ReportId, '');
    end;

    local procedure SaveAsFormat(var Observer: Codeunit "Probe Observer"; Name: Text; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Ok: Boolean;
    begin
        ClearLastError();
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(Report::"LT RCF NoLayout", '', Fmt, OutS);
        Observer.Observe(Name + ' ok', Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' length', Format(TempBlob.Length()));
    end;

    [Test]
    procedure RCF_DefaultLayoutWithoutFile_SaveAsFormats()
    var
        Row: Record "LT RCF Row";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        AddRow(1, '', 1, 0);
        SaveAsFormat(Observer, 'pdf', ReportFormat::Pdf);
        SaveAsFormat(Observer, 'word', ReportFormat::Word);
        SaveAsFormat(Observer, 'excel', ReportFormat::Excel);
        SaveAsFormat(Observer, 'html', ReportFormat::Html);
        SaveAsFormat(Observer, 'xml', ReportFormat::Xml);
        Observer.Expect('pdf ok', 'No');
        Observer.Expect('pdf|text', 'Report 96623 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('pdf|code', 'ReportNoLayout');
        Observer.Expect('pdf length', '0');
        Observer.Expect('word ok', 'No');
        Observer.Expect('word|text', 'Report 96623 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('word|code', 'ReportNoLayout');
        Observer.Expect('word length', '0');
        Observer.Expect('excel ok', 'No');
        Observer.Expect('excel|text', 'Report 96623 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('excel|code', 'ReportNoLayout');
        Observer.Expect('excel length', '0');
        Observer.Expect('html ok', 'No');
        Observer.Expect('html|text', 'Report 96623 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('html|code', 'ReportNoLayout');
        Observer.Expect('html length', '0');
        Observer.Expect('xml ok', 'Yes');
        Observer.Expect('xml|text', '');
        Observer.Expect('xml|code', '');
        // The length depends on the dataset header (time stamp, environment): not asserted.
        Observer.Ignore('xml length');
        Observer.Verify();
    end;
}
