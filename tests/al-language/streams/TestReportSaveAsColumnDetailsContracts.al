// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained table 69130, reports 69131..69133, codeunit 69134
// Probe: written against a real BC 27.5 service tier on Linux (en-US); every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins more of the SaveAs dataset (see TestReportSaveAsColumnTypesContracts.al):
//  - an undefined Time and DateTime read as empty elements (<Column name="TmC"></Column>); the null Guid reads 00000000-0000-0000-0000-000000000000
//    (NOT blank) and a Guid with hex letters is written in lower case; a one digit hour is not padded ("1:05:00 AM", with U+202F before AM/PM,
//    "1:30:00 PM", DateTime "3/5/2024 1:05:00 AM");
//  - decimalformatter follows DecimalPlaces: "2 : 4" gives #,##0.00##, "0 : 0" gives #,##0, a single number 1 gives #,##0.0 and "0 : 5" gives
//    #,##0.#####; the value is written in full whatever the formatter;
//  - the Labels block is written for IncludeCaption even when the data item has no row at all;
//  - IncludeCaption on a column that is not a named field is a compile error (AL0385), so such a label does not exist;
//  - SaveAs of a ProcessingOnly report with the answer dropped (the statement form) raises "Report 69133 is a processing-only report. Output
//    cannot be rendered and saved to a file." / ReportProcessingOnly.
// BC versions: 27.5

table 69130 "Probe SD Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Id cap'; }
        field(2; Tm; Time) { }
        field(3; Dtm; DateTime) { }
        field(4; Gd; Guid) { }
        field(5; Dec; Decimal) { DecimalPlaces = 2 : 4; }
        field(6; Dec0; Decimal) { DecimalPlaces = 0 : 0; }
        field(7; Dec1; Decimal) { DecimalPlaces = 1; }
        field(8; Dec5; Decimal) { DecimalPlaces = 0 : 5; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 69131 "Probe SD Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "Probe SD Table")
        {
            column(IdC; Id) { IncludeCaption = true; }
            column(TmC; Tm) { }
            column(DtmC; Dtm) { }
            column(GdC; Gd) { }
            column(DecC; Dec) { }
            column(Dec0C; Dec0) { }
            column(Dec1C; Dec1) { }
            column(Dec5C; Dec5) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSdLayout_4.rdl';
            Caption = 'Probe layout';
        }
    }
}

report 69132 "Probe SD Empty Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "Probe SD Table")
        {
            DataItemTableView = where(Id = const(-1));

            column(IdC; Id) { IncludeCaption = true; }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeSdLayout_5.rdl';
            Caption = 'Probe layout';
        }
    }
}

report 69133 "Probe SD Processing Only"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "Probe SD Table")
        {
            column(IdC; Id) { }
        }
    }
}

codeunit 69134 "Probe SaveAs Column Details"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure ColumnLines(ReportId: Integer): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
        InLabels: Boolean;
    begin
        TempBlob.CreateOutStream(OutStr);
        Assert.IsTrue(Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr), 'SaveAs');
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            Line := Line.Trim();
            if Line = '<Labels>' then
                InLabels := true;
            if InLabels or Line.StartsWith('<Column ') then
                Result += Line + '|';
            if Line = '</Labels>' then
                InLabels := false;
        end;
        exit(Result);
    end;

    [Test]
    procedure UndefinedTimesGuidsHoursAndDecimalPlaces()
    var
        SdRec: Record "Probe SD Table";
        Nnbsp: Text[1];
        Lines: Text;
    begin
        Nnbsp[1] := 32; // a plain space: the Windows tier writes no narrow no-break space before AM/PM
        SdRec.DeleteAll();
        SdRec.Id := 1;
        SdRec.Insert();
        SdRec.Id := 2;
        SdRec.Tm := 010500T;
        SdRec.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), 010500T);
        SdRec.Gd := '{ABCDEF01-2345-6789-ABCD-EF0123456789}';
        SdRec.Dec := 1.5;
        SdRec.Dec0 := 12.7;
        SdRec.Dec1 := 3.14159;
        SdRec.Dec5 := 2.5;
        SdRec.Insert();
        SdRec.Id := 3;
        SdRec.Tm := 133000T;
        SdRec.Dtm := CreateDateTime(DMY2Date(15, 12, 2024), 133000T);
        SdRec.Insert();
        Commit();

        Lines := ColumnLines(Report::"Probe SD Report");

        Assert.AreEqual(
            '<Labels>|<Label name="IdCCaption">Id cap</Label>|</Labels>|' +
            '<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|' +
            '<Column name="GdC">00000000-0000-0000-0000-000000000000</Column>|' +
            '<Column name="DecC" decimalformatter="#,##0.00##">0</Column>|<Column name="Dec0C" decimalformatter="#,##0">0</Column>|' +
            '<Column name="Dec1C" decimalformatter="#,##0.0">0</Column>|<Column name="Dec5C" decimalformatter="#,##0.#####">0</Column>|' +
            '<Column name="IdC">2</Column>|<Column name="TmC">1:05:00' + Nnbsp + 'AM</Column>|<Column name="DtmC">3/5/2024 1:05:00' + Nnbsp + 'AM</Column>|' +
            '<Column name="GdC">abcdef01-2345-6789-abcd-ef0123456789</Column>|' +
            '<Column name="DecC" decimalformatter="#,##0.00##">1.5</Column>|<Column name="Dec0C" decimalformatter="#,##0">12.7</Column>|' +
            '<Column name="Dec1C" decimalformatter="#,##0.0">3.14159</Column>|<Column name="Dec5C" decimalformatter="#,##0.#####">2.5</Column>|' +
            '<Column name="IdC">3</Column>|<Column name="TmC">1:30:00' + Nnbsp + 'PM</Column>|<Column name="DtmC">12/15/2024 1:30:00' + Nnbsp + 'PM</Column>|' +
            '<Column name="GdC">abcdef01-2345-6789-abcd-ef0123456789</Column>|' +
            '<Column name="DecC" decimalformatter="#,##0.00##">1.5</Column>|<Column name="Dec0C" decimalformatter="#,##0">12.7</Column>|' +
            '<Column name="Dec1C" decimalformatter="#,##0.0">3.14159</Column>|<Column name="Dec5C" decimalformatter="#,##0.#####">2.5</Column>|',
            Lines, 'columns');
    end;

    [Test]
    procedure LabelsAreWrittenForAnEmptyDataItem()
    begin
        Assert.AreEqual('<Labels>|<Label name="IdCCaption">Id cap</Label>|</Labels>|', ColumnLines(Report::"Probe SD Empty Report"), 'labels only');
    end;

    [Test]
    procedure ProcessingOnlyReport_StatementFormRaises()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        TempBlob.CreateOutStream(OutStr);

        asserterror Report.SaveAs(Report::"Probe SD Processing Only", '', ReportFormat::Xml, OutStr);

        Assert.AreEqual('Report 69133 is a processing-only report. Output cannot be rendered and saved to a file.', GetLastErrorText(), 'text');
        Assert.AreEqual('ReportProcessingOnly', GetLastErrorCode(), 'code');
    end;
}
