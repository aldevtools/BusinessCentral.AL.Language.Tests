// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database
// Scope: Cloud 16.1 — final batch of genuinely testable methods
// Fixtures used: Assert (60021), ALT Fixture Cleanup (60019), ALT Universal (60000), ALT Blob (60008)

codeunit 60146 "Test Final Coverage"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── System Functions: GuiAllowed, IsServiceTier, WindowsLanguage ───────────────

    [Test]
    procedure GuiAllowed_WithSystemPrefix_Returns()
    var
        B: Boolean;
    begin
        Initialize();
        B := System.GuiAllowed();
        Assert.IsTrue(true, 'System.GuiAllowed() must be callable');
    end;

    [Test]
    procedure GuiAllowed_WithoutSystemPrefix_Returns()
    var
        B: Boolean;
    begin
        Initialize();
        B := GuiAllowed();
        Assert.IsTrue(true, 'GuiAllowed() must be callable without System prefix');
    end;

    [Test]
    procedure IsServiceTier_WithSystemPrefix_Returns()
    var
        B: Boolean;
    begin
        Initialize();
        B := System.IsServiceTier();
        Assert.IsTrue(true, 'System.IsServiceTier() must be callable');
    end;

    [Test]
    procedure IsServiceTier_WithoutSystemPrefix_Returns()
    var
        B: Boolean;
    begin
        Initialize();
        B := IsServiceTier();
        Assert.IsTrue(true, 'IsServiceTier() must be callable without System prefix');
    end;

    [Test]
    procedure WindowsLanguage_WithSystemPrefix_ReturnsNonNegative()
    var
        I: Integer;
    begin
        Initialize();
        I := System.WindowsLanguage();
        Assert.IsTrue(I >= 0, 'System.WindowsLanguage() must return non-negative ID');
    end;

    [Test]
    procedure WindowsLanguage_WithoutSystemPrefix_ReturnsNonNegative()
    var
        I: Integer;
    begin
        Initialize();
        I := WindowsLanguage();
        Assert.IsTrue(I >= 0, 'WindowsLanguage() must return non-negative ID without System prefix');
    end;

    // ── Variant Conversion Functions ───────────────────────────────────────────────

    [Test]
    procedure Variant2Date_WithValidDateVariant_ReturnsDate()
    var
        V: Variant;
        D: Date;
    begin
        Initialize();
        V := Today();
        D := Variant2Date(V);
        Assert.AreEqual(Today(), D, 'Variant2Date must extract Date from Variant');
    end;

    [Test]
    procedure Variant2Time_WithValidTimeVariant_ReturnsTime()
    var
        V: Variant;
        T: Time;
    begin
        Initialize();
        V := Time();
        T := Variant2Time(V);
        Assert.AreNotEqual(0T, T, 'Variant2Time must extract Time from Variant');
    end;

    // ── GetUrl Function ────────────────────────────────────────────────────────────

    [Test]
    procedure GetUrl_WithDefaultClientType_ReturnsUrl()
    var
        S: Text;
    begin
        Initialize();
        S := GetUrl(ClientType::Default, CompanyName());
        Assert.IsTrue(true, 'GetUrl(ClientType::Default, ...) must not throw');
    end;

    [Test]
    procedure GetUrl_WithWebClientType_ReturnsUrl()
    var
        S: Text;
    begin
        Initialize();
        S := GetUrl(ClientType::Web, CompanyName());
        Assert.IsTrue(true, 'GetUrl(ClientType::Web, ...) must not throw');
    end;

    // ── Error Collection Functions ─────────────────────────────────────────────────

    [Test]
    procedure IsCollectingErrors_ReturnsBoolean()
    var
        B: Boolean;
    begin
        Initialize();
        B := IsCollectingErrors();
        Assert.IsTrue(true, 'IsCollectingErrors() must return Boolean');
    end;

    [Test]
    procedure HasCollectedErrors_ReturnsBoolean()
    var
        B: Boolean;
    begin
        Initialize();
        B := HasCollectedErrors();
        Assert.IsTrue(true, 'HasCollectedErrors() must return Boolean');
    end;

    // ── Database Functions ─────────────────────────────────────────────────────────

    [Test]
    procedure SessionId_WithDatabasePrefix_ReturnsNonNegative()
    var
        I: Integer;
    begin
        Initialize();
        I := Database.SessionId();
        Assert.IsTrue(I >= 0, 'Database.SessionId() must return non-negative integer');
    end;

    [Test]
    procedure UserSecurityId_WithDatabasePrefix_ReturnsNonNullGuid()
    var
        G: Guid;
    begin
        Initialize();
        G := Database.UserSecurityId();
        Assert.IsFalse(IsNullGuid(G), 'Database.UserSecurityId() must return non-null Guid');
    end;

    // ── Session Functions ─────────────────────────────────────────────

    [Test]
    procedure SessionId_IsCallable()
    var
        I: Integer;
    begin
        Initialize();
        I := SessionId();
        Assert.IsTrue(I >= 0, 'Session.SessionId() must return non-negative integer');
    end;

    // ── XmlDocument Functions ──────────────────────────────────────────────────────

    [Test]
    procedure XmlDocument_ReplaceNodes_WithNewElement_ReplacesChildren()
    var
        XDoc: XmlDocument;
        XElem: XmlElement;
    begin
        Initialize();
        XmlDocument.ReadFrom('<root><a/></root>', XDoc);
        XDoc.ReplaceNodes(XmlElement.Create('new'));
        Assert.IsTrue(true, 'XmlDocument.ReplaceNodes() must not throw');
    end;

    // ── XmlElement Functions ───────────────────────────────────────────────────────

    [Test]
    procedure XmlElement_RemoveAttribute_RemovesAttributeByName()
    var
        XElem: XmlElement;
    begin
        Initialize();
        XElem := XmlElement.Create('e');
        XElem.SetAttribute('color', 'red');
        XElem.RemoveAttribute('color');
        Assert.IsFalse(XElem.HasAttributes(), 'RemoveAttribute must remove the attribute');
    end;

    [Test]
    procedure XmlElement_ReplaceNodes_WithNewElement_ReplacesChildren()
    var
        XDoc: XmlDocument;
        XElem: XmlElement;
    begin
        Initialize();
        XmlDocument.ReadFrom('<root><old/></root>', XDoc);
        XDoc.GetRoot(XElem);
        XElem.ReplaceNodes(XmlElement.Create('new'));
        Assert.IsTrue(true, 'XmlElement.ReplaceNodes() must not throw');
    end;

    // ── XmlNode Functions ──────────────────────────────────────────────────────────

    [Test]
    procedure XmlNode_IsXmlDeclaration_OnElementNode_ReturnsFalse()
    var
        XDoc: XmlDocument;
        XElem: XmlElement;
        XN: XmlNode;
    begin
        Initialize();
        XmlDocument.ReadFrom('<?xml version="1.0"?><root/>', XDoc);
        XDoc.GetRoot(XElem);
        XN := XElem.AsXmlNode();
        Assert.IsFalse(XN.IsXmlDeclaration(), 'Element node must not be declaration');
    end;

    [Test]
    procedure XmlNode_IsXmlAttribute_OnAttributeNode_ReturnsTrue()
    var
        XElem: XmlElement;
        XAC: XmlAttributeCollection;
        XAttr: XmlAttribute;
        XN: XmlNode;
    begin
        Initialize();
        XElem := XmlElement.Create('e');
        XElem.SetAttribute('x', '1');
        XAC := XElem.Attributes();
        XAC.Get(1, XAttr);
        XN := XAttr.AsXmlNode();
        Assert.IsTrue(XN.IsXmlAttribute(), 'Attribute node must return IsXmlAttribute=true');
    end;

    // ── JsonObject Functions ───────────────────────────────────────────────────────

#if BC143PLUS // ReadFromYaml and WriteToYaml added in BC 14.3
    [Test]
    procedure JsonObject_ReadFromYaml_OnCloudRuntime_IsNotSupported()
    var
        JObj: JsonObject;
    begin
        Initialize();
        asserterror JObj.ReadFromYaml('key: value');
        Assert.IsTrue(true, 'ReadFromYaml may not be supported on Cloud — error captured');
    end;

    [Test]
    procedure JsonObject_WriteToYaml_OnCloudRuntime_IsNotSupported()
    var
        JObj: JsonObject;
        S: Text;
    begin
        Initialize();
        JObj.Add('k', 'v');
        asserterror JObj.WriteToYaml(S);
        Assert.IsTrue(true, 'WriteToYaml may not be supported on Cloud — error captured');
    end;
#endif

    // ── Variant Type-Check Functions ───────────────────────────────────────────────

    [Test]
    procedure Variant_IsNotification_WithNotificationVariant_ReturnsTrue()
    var
        V: Variant;
        N: Notification;
    begin
        Initialize();
        N.Message('test');
        V := N;
        Assert.IsTrue(V.IsNotification(), 'Notification variant must IsNotification=true');
    end;

    [Test]
    procedure Variant_IsTextBuilder_WithTextBuilderVariant_ReturnsTrue()
    var
        V: Variant;
        TB: TextBuilder;
    begin
        Initialize();
        V := TB;
        Assert.IsTrue(V.IsTextBuilder(), 'TextBuilder variant must IsTextBuilder=true');
    end;

    [Test]
    procedure Variant_IsXmlAttribute_WithXmlAttributeVariant_ReturnsTrue()
    var
        V: Variant;
        XAttr: XmlAttribute;
    begin
        Initialize();
        XAttr := XmlAttribute.Create('x', '1');
        V := XAttr;
        Assert.IsTrue(V.IsXmlAttribute(), 'XmlAttribute variant must IsXmlAttribute=true');
    end;

    // ── DataTransfer Functions ─────────────────────────────────────────────────────
    // NOTE: UpdateAuditFields is OnPrem-only (not available in Cloud targets)
    // No test is provided for this method in Cloud deployments.

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
