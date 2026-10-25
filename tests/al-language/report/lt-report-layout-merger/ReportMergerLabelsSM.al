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
        Observer.Observe('labels block', Dataset.Between(Xml, '<Labels>', '</Labels>').Replace(Dataset.Lf(), '|').Replace(' ', ''));
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Observe('xml info', Cap.Item('xml info', 1));
        ObserveDataset(Observer, Cap.Item('xml', 1).Replace('<NL>', Dataset.Lf()));
        Observer.Finish();
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
        Observer.Finish();
    end;
}
