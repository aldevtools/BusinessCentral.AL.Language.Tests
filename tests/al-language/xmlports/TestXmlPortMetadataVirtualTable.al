// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-xmlport-object
// Scope: in-scope
// Fixtures used: ALT XPM Probe (xmlport 67451), ALT Variable XmlPort (xmlport 60025),
//   System Application's "Export Permission Sets System" (xmlport 9862), Assert (60021)
//
// Pins the built-in "XmlPort Metadata" system virtual table (2000000280): one row per xmlport
// object, computed from the xmlport's own metadata rather than stored anywhere. Sibling of
// Query Metadata (TestQueryMetadataVirtualTable.al, codeunit 60913).
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4461, which records that
// the runner serves NO provider for this table -- a table with no provider falls through to
// an empty temp store and answers "no rows" to every read, silently. Nothing here predicts
// the runner's answer.
//
// Each column arm asserts TWO rows that declare different values (the probe and the control),
// so a provider answering one fixed value per column cannot pass. The System Application row
// is the precompiled-dependency case: an xmlport this app only depends on.

codeunit 67450 "Test XmlPort Metadata VT"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Assert";

    local procedure Probe(): Integer
    begin
        exit(XmlPort::"ALT XPM Probe");
    end;

    local procedure Control(): Integer
    begin
        exit(XmlPort::"ALT Variable XmlPort");
    end;

    [Test]
    procedure Record_XmlPortMetadata_ADeclaredXmlPort_HasARowUnderItsObjectId()
    var
        XmlPortMetadata: Record "XmlPort Metadata";
    begin
        Assert.IsTrue(XmlPortMetadata.Get(Probe()), 'The XmlPort Metadata table has a row for a declared xmlport, keyed by its object id.');
        Assert.AreEqual('ALT XPM Probe', XmlPortMetadata.Name, 'The row carries the xmlport''s object name.');
        Assert.AreEqual('ALT XPM Probe Caption', XmlPortMetadata.Caption, 'The row carries the xmlport''s declared caption.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_UnknownId_HasNoRow()
    var
        XmlPortMetadata: Record "XmlPort Metadata";
    begin
        // The control that separates "the provider works" from "the provider answers rows for
        // anything". 67452 is not an xmlport in this app or its dependencies.
        Assert.IsFalse(XmlPortMetadata.Get(67452), 'An object id that is not an xmlport has no XmlPort Metadata row.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_Direction_ReportsTheDeclaredValue()
    var
        ProbeRow: Record "XmlPort Metadata";
        ControlRow: Record "XmlPort Metadata";
    begin
        Assert.IsTrue(ProbeRow.Get(Probe()), 'The probe xmlport has a row.');
        Assert.AreEqual(ProbeRow.Direction::Export, ProbeRow.Direction, 'Direction = Export is reported as Export.');

        Assert.IsTrue(ControlRow.Get(Control()), 'The control xmlport has a row.');
        Assert.AreEqual(ControlRow.Direction::Both, ControlRow.Direction, 'Direction = Both is reported as Both.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_Format_ReportsTheDeclaredValue()
    var
        ProbeRow: Record "XmlPort Metadata";
        ControlRow: Record "XmlPort Metadata";
    begin
        Assert.IsTrue(ProbeRow.Get(Probe()), 'The probe xmlport has a row.');
        Assert.AreEqual(ProbeRow.Format::VariableText, ProbeRow.Format, 'Format = VariableText is reported as VariableText.');

        Assert.IsTrue(ControlRow.Get(Control()), 'The control xmlport has a row.');
        Assert.AreEqual(ControlRow.Format::Xml, ControlRow.Format, 'Format = Xml is reported as Xml.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_UseRequestPage_ReportsTheDeclaredValue()
    var
        ProbeRow: Record "XmlPort Metadata";
        ControlRow: Record "XmlPort Metadata";
    begin
        Assert.IsTrue(ProbeRow.Get(Probe()), 'The probe xmlport has a row.');
        Assert.IsTrue(ProbeRow.UseRequestPage, 'UseRequestPage = true is reported as true.');

        Assert.IsTrue(ControlRow.Get(Control()), 'The control xmlport has a row.');
        Assert.IsFalse(ControlRow.UseRequestPage, 'UseRequestPage = false is reported as false.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_TransactionTypeAndTextEncoding_ReportTheDeclaredValues()
    var
        XmlPortMetadata: Record "XmlPort Metadata";
    begin
        Assert.IsTrue(XmlPortMetadata.Get(Probe()), 'The probe xmlport has a row.');
        Assert.AreEqual(XmlPortMetadata.TransactionType::Browse, XmlPortMetadata.TransactionType, 'TransactionType = Browse is reported as Browse.');
        Assert.AreEqual(XmlPortMetadata.TextEncoding::UTF16, XmlPortMetadata.TextEncoding, 'TextEncoding = UTF16 is reported as UTF16.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_AppId_IsThisExtensionsOwnAppId()
    var
        XmlPortMetadata: Record "XmlPort Metadata";
        ThisModule: ModuleInfo;
    begin
        // Not the empty GUID, which is what a provider that never resolves the owner reports.
        NavApp.GetCurrentModuleInfo(ThisModule);
        Assert.IsTrue(XmlPortMetadata.Get(Probe()), 'The probe xmlport has a row.');
        Assert.AreEqual(ThisModule.Id(), XmlPortMetadata."App ID", 'The row carries the app id of the extension declaring the xmlport.');
    end;

    [Test]
    procedure Record_XmlPortMetadata_ADependencysXmlPort_HasARow()
    var
        XmlPortMetadata: Record "XmlPort Metadata";
    begin
        // 9862 "Export Permission Sets System" ships in the System Application and states
        // Direction = Export in its source (see TestXmlPortPrecompiledObject.al).
        Assert.IsTrue(XmlPortMetadata.Get(XmlPort::"Export Permission Sets System"), 'A dependency''s xmlport has a row.');
        Assert.AreEqual('Export Permission Sets System', XmlPortMetadata.Name, 'The dependency''s row carries its object name.');
        Assert.AreEqual(XmlPortMetadata.Direction::Export, XmlPortMetadata.Direction, 'The dependency''s declared Direction is reported.');
        // The System Application's app id, as this corpus app's own app.json declares the dependency.
        Assert.AreEqual('{63CA2FA4-4F03-4F2B-A480-172FEF340D3F}', Format(XmlPortMetadata."App ID"), 'The dependency''s row carries the app id of the app declaring the xmlport.');
    end;
}
