// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getresource-method
// Scope: in-scope
// Fixtures used: none — packaged resources under session/res (see NOTE below)
//
// NOTE: this suite requires app.json to declare a "resourceFolders" entry covering
// session/res (e.g. "resourceFolders": ["session/res"]) so NavApp.GetResource can find
// greeting.txt / sub/nested.txt at compile/package time. That is an app.json change
// outside this migration's scope (the migration task explicitly does not create/edit
// app.json) — flagged for the coordinator to wire up.
//
// NavApp.GetResource / GetResourceAsText against this app's own packaged resources.
// Positive: exact byte/text content round-trips through the InStream.
// Negative: a missing resource name throws BC's real not-found error
// ("A resource matching '{0}' could not be found in app '{1}'."), asserted via its
// stable leading substring — never a silent default or a raw NRE.

codeunit 60382 "Test NavApp GetResource"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure NavApp_GetResource_TopLevelFile_ReturnsExactContent()
    var
        ResourceInStream: InStream;
        Content: Text;
    begin
        Initialize();

        NavApp.GetResource('greeting.txt', ResourceInStream, TextEncoding::UTF8);
        ResourceInStream.ReadText(Content);
        Assert.AreEqual('Hello from packaged resource', Content, 'top-level resource content');
    end;

    [Test]
    procedure NavApp_GetResource_NestedPath_ReturnsExactContent()
    var
        ResourceInStream: InStream;
        Content: Text;
    begin
        Initialize();

        NavApp.GetResource('sub/nested.txt', ResourceInStream, TextEncoding::UTF8);
        ResourceInStream.ReadText(Content);
        Assert.AreEqual('nested-resource-content', Content, 'nested resource content');
    end;

    [Test]
    procedure NavApp_GetResourceAsText_ReturnsExactContent()
    var
        Content: Text;
    begin
        Initialize();

        Content := NavApp.GetResourceAsText('greeting.txt', TextEncoding::UTF8);
        Assert.AreEqual('Hello from packaged resource', Content, 'GetResourceAsText content');
    end;

    [Test]
    procedure NavApp_GetResource_MissingName_ThrowsResourceNotFound()
    var
        ResourceInStream: InStream;
    begin
        Initialize();

        asserterror NavApp.GetResource('missing.txt', ResourceInStream);
        Assert.ExpectedError('A resource matching ''missing.txt'' could not be found in app');
    end;

    [Test]
    procedure NavApp_GetResourceAsText_MissingName_ThrowsResourceNotFound()
    var
        Content: Text;
    begin
        Initialize();

        asserterror Content := NavApp.GetResourceAsText('missing.txt');
        Assert.ExpectedError('A resource matching ''missing.txt'' could not be found in app');
    end;

    local procedure Initialize()
    begin
        // No persistent tables used — packaged resources are read-only.
    end;
}
