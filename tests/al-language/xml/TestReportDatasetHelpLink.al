// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-contextsensitivehelppage-property
// Scope: in-scope
// Fixtures used: Assert (60021), RSS Sample (60871), RSS Fixture Report (60872); Base Application
//                reports 3 "G/L Register" and 508 "Change Log Setup List"
//
// Report.SaveAs(ReportFormat::Xml) writes a <BCReportInformation><ReportMetadata> block ahead of
// the dataset. Its <ReportHelpLink> element carries the request page's HelpLink. The compiler
// builds that HelpLink from the declaring app's manifest (app.json `contextSensitiveHelpUrl`,
// plus the page's ContextSensitiveHelpPage when stated). It is not a fixed documentation URL.
//
// Two apps whose manifests state no contextSensitiveHelpUrl are measured here:
//   - Base Application, whose shipped NavxManifest.xml has no ContextSensitiveHelpUrl
//     attribute, through its precompiled report 508;
//   - this app, whose app.json states none, through a report it compiles itself.
// Neither report states HelpLink or ContextSensitiveHelpPage on its request page.
//
// The same block carries the request page's AboutTitle and AboutText as AboutThisReportTitle and
// AboutThisReportText. Base Application report 3 "G/L Register" states both on its request page,
// with the same text in every Base Application from 27.0 to 28.5.
//
// The report id is asserted from the same block first, so an empty value cannot come from
// reading the wrong node or a missing one.

codeunit 67250 "Test Report Dataset HelpLink"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure RenderDataset(ReportId: Integer) Dataset: XmlDocument
    var
        TempBlob: Codeunit "Temp Blob";
        DataOut: OutStream;
        DataIn: InStream;
    begin
        TempBlob.CreateOutStream(DataOut);
        Assert.IsTrue(Report.SaveAs(ReportId, '', ReportFormat::Xml, DataOut), 'Report.SaveAs(Xml) must succeed');
        TempBlob.CreateInStream(DataIn);
        XmlDocument.ReadFrom(DataIn, Dataset);
    end;

    local procedure ReportMetadataValue(Dataset: XmlDocument; ElementName: Text): Text
    var
        Node: XmlNode;
    begin
        Assert.IsTrue(
            Dataset.SelectSingleNode('/ReportDataSet/BCReportInformation/ReportMetadata/' + ElementName, Node),
            'The dataset must carry BCReportInformation/ReportMetadata/' + ElementName);
        exit(Node.AsXmlElement().InnerText());
    end;

    local procedure EnsureChangeLogSetup()
    var
        ChangeLogSetup: Record "Change Log Setup";
    begin
        // Report 508's OnPreDataItem reads the singleton setup record with Get().
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert(false);
        end;
    end;

    [Test]
    procedure ReportHelpLink_BaseApplicationReport_ManifestStatesNoHelpUrl_IsEmpty()
    var
        Dataset: XmlDocument;
    begin
        EnsureChangeLogSetup();
        Dataset := RenderDataset(Report::"Change Log Setup List");

        Assert.AreEqual('508', ReportMetadataValue(Dataset, 'ReportId'), 'ReportMetadata/ReportId');
        Assert.AreEqual('', ReportMetadataValue(Dataset, 'ReportHelpLink'),
            'Base Application declares no ContextSensitiveHelpUrl, so its request pages carry no HelpLink');
    end;

    [Test]
    procedure ReportAboutText_BaseApplicationReport_CarriesTheRequestPageAboutTitleAndText()
    var
        Dataset: XmlDocument;
    begin
        Dataset := RenderDataset(Report::"G/L Register");

        Assert.AreEqual('3', ReportMetadataValue(Dataset, 'ReportId'), 'ReportMetadata/ReportId');
        Assert.AreEqual('About G/L Register', ReportMetadataValue(Dataset, 'AboutThisReportTitle'),
            'AboutThisReportTitle is the request page''s AboutTitle');
        Assert.AreEqual(
            'The **G/L Register** report provides a batch-wise list of all posted general ledger entries, including entry numbers, posting dates, user IDs, and source descriptions. Use it for auditing, tracing who posted what and when, and verifying financial transaction integrity by filtering entries by source, user, or date',
            ReportMetadataValue(Dataset, 'AboutThisReportText'),
            'AboutThisReportText is the request page''s AboutText');
    end;

    [Test]
    procedure ReportAboutText_OwnReportStatingNone_IsEmpty()
    var
        Dataset: XmlDocument;
    begin
        Dataset := RenderDataset(Report::"RSS Fixture Report");

        Assert.AreEqual('', ReportMetadataValue(Dataset, 'AboutThisReportTitle'), 'AboutThisReportTitle');
        Assert.AreEqual('', ReportMetadataValue(Dataset, 'AboutThisReportText'), 'AboutThisReportText');
    end;

    [Test]
    procedure ReportHelpLink_OwnReport_ManifestStatesNoHelpUrl_IsEmpty()
    var
        Dataset: XmlDocument;
    begin
        Dataset := RenderDataset(Report::"RSS Fixture Report");

        Assert.AreEqual('60872', ReportMetadataValue(Dataset, 'ReportId'), 'ReportMetadata/ReportId');
        Assert.AreEqual('', ReportMetadataValue(Dataset, 'ReportHelpLink'),
            'This app declares no contextSensitiveHelpUrl, so its request pages carry no HelpLink');
    end;
}
