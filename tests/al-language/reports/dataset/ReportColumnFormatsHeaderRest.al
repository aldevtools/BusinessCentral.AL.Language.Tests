// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); W3 Dataset (codeunit 67703); Temp Blob (System Application); own table 96620,
//   reports 96621-96623, codeunit 96624.
// Probe: from the code-sweep issue al-runner 7634 (report paths that answer with no pin) and the trial report al-runner 6924
//   (EnableExternalImages). Observation form: every test ends in Observer.Finish(), so its failure message holds BC's values.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
