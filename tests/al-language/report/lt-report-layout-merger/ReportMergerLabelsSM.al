// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-labels
// Scope: in-scope
// Fixtures used: Probe Observer (69160), W3 Dataset (67703), LT RptMrg Helper (70835), LT RptMrg Capture (70831), report 70883 of ReportMergerFixtures.al
// Facts: the Labels block and the Column lines of report 70883 (IncludeCaption on an Integer, Decimal, Date and Boolean column; a label with Comment and MaxLength)
// in the dataset: Report.SaveAs Xml output, and the XmlData the OnCustomDocumentMergerEx subscriber gets for Report.SaveAs Pdf, with two rows and with no row.
// The dataset header (BCReportInformation) is not part of the facts.
// BC versions: 27, 28, 29

codeunit 89240 "LT SM RptMrg Labels"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ObserveDataset(var Observer: Codeunit "Probe Observer"; Xml: Text)
    var
        Dataset: Codeunit "W3 Dataset";
    begin
        Observer.Observe('label and column lines', Dataset.ColumnLines(Xml));
    end;

    [Test]
    procedure SaveAs_Xml_TwoRows_LabelsAndColumns()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Helper: Codeunit "LT RptMrg Helper";
        Xml: Text;
    begin
        Helper.SeedRows(2);
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT RptMrg Report", '', Xml)));
        ObserveDataset(Observer, Xml);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('label and column lines', '<Label name="RowIdCaption">Row Id</Label>|<Label name="RowAmountCaption">Row Amount</Label>|<Label name="RowWhenCaption">Row When</Label>|<Label name="RowFlagCaption">Row Flag</Label>|<Label name="TitleLbl">Merger title</Label>|<Label name="NoteLbl">Merger note</Label>|<Column name="RowId">1</Column>|<Column name="RowName">Alpha</Column>|<Column name="RowAmount" decimalformatter="#,##0.00">12.5</Column>|<Column name="RowBig" decimalformatter="#,##0.00">1234567.891</Column>|<Column name="RowWhen">1/31/2024</Column>|<Column name="RowFlag">True</Column>|<Column name="RowKind">Beta cap</Column>|<Column name="RowStamp">1/31/2024 1:45:00 PM</Column>|<Column name="RowClock">1:45:00 PM</Column>|<Column name="RowNote"></Column>|<Column name="ModeColumn">0</Column>|<Column name="RowId">2</Column>|<Column name="RowName">A&amp;B &lt;x&gt; "q" ''s'' é</Column>|<Column name="RowAmount" decimalformatter="#,##0.00">-3.14159</Column>|<Column name="RowBig" decimalformatter="#,##0.00">0</Column>|<Column name="RowWhen"></Column>|<Column name="RowFlag">False</Column>|<Column name="RowKind">Alpha cap</Column>|<Column name="RowStamp"></Column>|<Column name="RowClock"></Column>|<Column name="RowNote">n</Column>|<Column name="ModeColumn">0</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Xml_NoRows_LabelsAndColumns()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Helper: Codeunit "LT RptMrg Helper";
        Xml: Text;
    begin
        Helper.SeedRows(0);
        Observer.Observe('saved', Format(Dataset.Save(Report::"LT RptMrg Report", '', Xml)));
        ObserveDataset(Observer, Xml);
        Observer.Expect('saved', 'Yes');
        Observer.Expect('label and column lines', '<Label name="RowIdCaption">Row Id</Label>|<Label name="RowAmountCaption">Row Amount</Label>|<Label name="RowWhenCaption">Row When</Label>|<Label name="RowFlagCaption">Row Flag</Label>|<Label name="TitleLbl">Merger title</Label>|<Label name="NoteLbl">Merger note</Label>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Pdf_TwoRows_MergerXmlData_LabelsAndColumns()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(2);
        BindSubscription(Cap);
        Observer.Observe('completed', Format(Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved)));
        UnbindSubscription(Cap);
        Observer.Observe('calls', Format(Cap.CallCount()));
        ObserveDataset(Observer, Cap.Item('xml', 1).Replace('<NL>', Dataset.Lf()));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('calls', '1');
        Observer.Expect('label and column lines', '<Label name="RowIdCaption">Row Id</Label>|<Label name="RowAmountCaption">Row Amount</Label>|<Label name="RowWhenCaption">Row When</Label>|<Label name="RowFlagCaption">Row Flag</Label>|<Label name="TitleLbl">Merger title</Label>|<Label name="NoteLbl">Merger note</Label>|<Column name="RowId">1</Column>|<Column name="RowName">Alpha</Column>|<Column name="RowAmount" decimalformatter="#,##0.00">12.5</Column>|<Column name="RowBig" decimalformatter="#,##0.00">1234567.891</Column>|<Column name="RowWhen">1/31/2024</Column>|<Column name="RowFlag">True</Column>|<Column name="RowKind">Beta cap</Column>|<Column name="RowStamp">1/31/2024 1:45:00 PM</Column>|<Column name="RowClock">1:45:00 PM</Column>|<Column name="RowNote"></Column>|<Column name="ModeColumn">0</Column>|<Column name="RowId">2</Column>|<Column name="RowName">A&amp;B &lt;x&gt; "q" ''s'' é</Column>|<Column name="RowAmount" decimalformatter="#,##0.00">-3.14159</Column>|<Column name="RowBig" decimalformatter="#,##0.00">0</Column>|<Column name="RowWhen"></Column>|<Column name="RowFlag">False</Column>|<Column name="RowKind">Alpha cap</Column>|<Column name="RowStamp"></Column>|<Column name="RowClock"></Column>|<Column name="RowNote">n</Column>|<Column name="ModeColumn">0</Column>|');
        Observer.Verify();
    end;

    [Test]
    procedure SaveAs_Pdf_NoRows_MergerXmlData_LabelsAndColumns()
    var
        Observer: Codeunit "Probe Observer";
        Dataset: Codeunit "W3 Dataset";
        Helper: Codeunit "LT RptMrg Helper";
        Cap: Codeunit "LT RptMrg Capture";
        Output: Text;
        Saved: Boolean;
    begin
        Helper.SeedRows(0);
        BindSubscription(Cap);
        Observer.Observe('completed', Format(Helper.TrySaveAs(ReportFormat::Pdf, '', Output, Saved)));
        UnbindSubscription(Cap);
        Observer.Observe('calls', Format(Cap.CallCount()));
        ObserveDataset(Observer, Cap.Item('xml', 1).Replace('<NL>', Dataset.Lf()));
        Observer.Expect('completed', 'Yes');
        Observer.Expect('calls', '1');
        Observer.Expect('label and column lines', '<Label name="RowIdCaption">Row Id</Label>|<Label name="RowAmountCaption">Row Amount</Label>|<Label name="RowWhenCaption">Row When</Label>|<Label name="RowFlagCaption">Row Flag</Label>|<Label name="TitleLbl">Merger title</Label>|<Label name="NoteLbl">Merger note</Label>|');
        Observer.Verify();
    end;
}
