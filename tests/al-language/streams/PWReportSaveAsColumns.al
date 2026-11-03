// Probe writer-c, round 2: Report.SaveAs dataset columns not yet pinned (docs/probes-needed.md "Report.SaveAs dataset columns").
// Observe-only; every test records the whole XML dataset text (lines joined with '|').
// Layout: ./ProbeColTypesLayout.rdl of the corpus app (XML SaveAs does not render it).
// Fixtures: table 69761, reports 69762..69765, codeunit 69766.

table 69761 "PW Col Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { Caption = 'Id caption'; }
        field(2; Tm; Time) { }
        field(3; Dtm; DateTime) { }
        field(4; Gd; Guid) { }
        field(5; Dec; Decimal) { }
        field(6; Tm2; Time) { }
        field(7; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

report 69762 "PW Col Undefined Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "PW Col Table")
        {
            column(IdC; Id) { }
            column(TmC; Tm) { }
            column(DtmC; Dtm) { }
            column(GdC; Gd) { }
            column(Tm2C; Tm2) { }
            column(DecC; Dec) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeColTypesLayout.rdl';
        }
    }
}

report 69763 "PW Col Decimal Places Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "PW Col Table")
        {
            column(IdC; Id) { }
            column(DecPlain; Dec) { }
            column(DecOne; Dec * 1.5) { DecimalPlaces = 1; }
            column(DecRange; Dec * 1.5) { DecimalPlaces = 2 : 4; }
            column(DecZero; Dec * 1.5) { DecimalPlaces = 0 : 0; }
            column(DecZeroOne; Dec * 1.5) { DecimalPlaces = 0 : 2; }
            column(DecStored; Dec) { }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeColTypesLayout_2.rdl';
        }
    }
}

report 69764 "PW Col Labels Report"
{
    UsageCategory = None;
    DefaultRenderingLayout = Rdlc;

    dataset
    {
        dataitem(Row; "PW Col Table")
        {
            column(IdC; Id) { IncludeCaption = true; }
            column(TxtC; Txt) { IncludeCaption = true; }
        }
    }

    rendering
    {
        layout(Rdlc)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/ProbeColTypesLayout_3.rdl';
        }
    }
}

report 69765 "PW Col Processing Only"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "PW Col Table")
        {
            column(IdC; Id) { }
        }
    }
}

codeunit 69766 "PW Report SaveAs Columns Probe"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Rows(Seeded: Boolean)
    var
        R: Record "PW Col Table";
    begin
        R.DeleteAll();
        if not Seeded then
            exit;
        R.Init();
        R.Id := 1;
        R.Insert();
        R.Init();
        R.Id := 2;
        R.Tm := 090000T;
        R.Tm2 := 123456T;
        R.Dtm := CreateDateTime(DMY2Date(5, 3, 2024), 090000T);
        R.Gd := '{ABCDEF01-2345-6789-ABCD-EF0123456789}';
        R.Dec := 12.3;
        R.Txt := 'text';
        R.Insert();
        Commit();
    end;

    local procedure Dataset(ReportId: Integer; var Saved: Boolean): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
        InStr: InStream;
        Line: Text;
        Result: Text;
    begin
        TempBlob.CreateOutStream(OutStr);
        ClearLastError();
        Saved := Report.SaveAs(ReportId, '', ReportFormat::Xml, OutStr);
        TempBlob.CreateInStream(InStr, TextEncoding::UTF8);
        while not InStr.EOS() do begin
            InStr.ReadText(Line);
            // Only the columns, labels and data item markers are kept: the header and the attributes of the data items differ between builds.
            Line := Line.Trim();
            if Line.StartsWith('<Column ') or Line.StartsWith('<Label ') then
                Result += Line + '|'
            else
                if Line.StartsWith('<DataItem ') then
                    Result += '<DataItem>|'
                else
                    if Line.StartsWith('<DataItems') then
                        Result += '<DataItems>|';
        end;
        exit(Result);
    end;

    [Test]
    procedure Undefined_TimeDateTime_SingleDigitHour_GuidWithHexLetters()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Rows(true);
        Text := Dataset(Report::"PW Col Undefined Report", Saved);
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('dataset', Text);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('dataset', '<DataItems>|<DataItem>|<Column name="IdC">1</Column>|<Column name="TmC"></Column>|<Column name="DtmC"></Column>|<Column name="GdC">00000000-0000-0000-0000-000000000000</Column>|<Column name="Tm2C"></Column>|<Column name="DecC" decimalformatter="#,##0.00">0</Column>|<DataItem>|<Column name="IdC">2</Column>|<Column name="TmC">9:00:00 AM</Column>|<Column name="DtmC">3/5/2024 9:00:00 AM</Column>|<Column name="GdC">abcdef01-2345-6789-abcd-ef0123456789</Column>|<Column name="Tm2C">12:34:56 PM</Column>|<Column name="DecC" decimalformatter="#,##0.00">12.3</Column>|');
        Observer.Verify();
    end;




    [Test]
    procedure DecimalPlaces_SingleNumberRangeAndZero()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Rows(true);
        Text := Dataset(Report::"PW Col Decimal Places Report", Saved);
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('error', GetLastErrorText());
        Observer.Observe('dataset', Text);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('error', '');
        Observer.Expect('dataset', '<DataItems>|<DataItem>|<Column name="IdC">1</Column>|<Column name="DecPlain" decimalformatter="#,##0.00">0</Column>|<Column name="DecOne" decimalformatter="#,##0.0">0</Column>|<Column name="DecRange" decimalformatter="#,##0.00##">0</Column>|<Column name="DecZero" decimalformatter="#,##0">0</Column>|<Column name="DecZeroOne" decimalformatter="#,##0.##">0</Column>|<Column name="DecStored" decimalformatter="#,##0.00">0</Column>|<DataItem>|<Column name="IdC">2</Column>|<Column name="DecPlain" decimalformatter="#,##0.00">12.3</Column>|<Column name="DecOne" decimalformatter="#,##0.0">18.45</Column>|<Column name="DecRange" decimalformatter="#,##0.00##">18.45</Column>|<Column name="DecZero" decimalformatter="#,##0">18.45</Column>|<Column name="DecZeroOne" decimalformatter="#,##0.##">18.45</Column>|<Column name="DecStored" decimalformatter="#,##0.00">12.3</Column>|');
        Observer.Verify();
    end;




    [Test]
    procedure Labels_RowReachesTheColumn()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Rows(true);
        Text := Dataset(Report::"PW Col Labels Report", Saved);
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('dataset', Text);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('dataset', '<Label name="IdCCaption">Id caption</Label>|<Label name="TxtCCaption">Txt</Label>|<DataItems>|<DataItem>|<Column name="IdC">1</Column>|<Column name="TxtC"></Column>|<DataItem>|<Column name="IdC">2</Column>|<Column name="TxtC">text</Column>|');
        Observer.Verify();
    end;




    [Test]
    procedure Labels_NoRowAtAll()
    var
        Saved: Boolean;
        Text: Text;
    begin
        Rows(false);
        Text := Dataset(Report::"PW Col Labels Report", Saved);
        Observer.Observe('saved', Format(Saved));
        Observer.Observe('dataset', Text);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('dataset', '<Label name="IdCCaption">Id caption</Label>|<Label name="TxtCCaption">Txt</Label>|<DataItems>|');
        Observer.Verify();
    end;

    // ProcessingOnly with the answer dropped. One of the two tests below fails with the answer in its message:
    // the first when SaveAs raises instead of returning false, the second when it does not raise.
    [Test]
    procedure ProcessingOnly_AnswerDropped_AsserterrorForm()
    var
        TempBlob: Codeunit "Temp Blob";
        OutStr: OutStream;
    begin
        Rows(true);
        TempBlob.CreateOutStream(OutStr);
        asserterror Report.SaveAs(Report::"PW Col Processing Only", '', ReportFormat::Xml, OutStr);
        Observer.ObserveError('statement_form_error');
        Observer.Expect('statement_form_error|text', 'Report 69765 is a processing-only report. Output cannot be rendered and saved to a file.');
        Observer.Expect('statement_form_error|code', 'ReportProcessingOnly');
        Observer.Verify();
    end;
}
