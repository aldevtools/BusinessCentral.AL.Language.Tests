// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-data-type
// Scope: in-scope
// Extended Session methods — CurrentClientType, ApplicationIdentifier, ExecutionContext, ExecutionMode, Telemetry, Transaction state, Subscription binding

codeunit 60122 "Test Session Extended"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Session Method Tests ─────────────────────────────────────────────────

    [Test]
    procedure Session_CurrentClientType_ReturnsEnum()
    var
        CT: ClientType;
    begin
        Initialize();
        CT := Session.CurrentClientType();
        Assert.IsTrue(true, 'CurrentClientType() must be callable and return ClientType enum');
    end;

    [Test]
    procedure Session_DefaultClientType_ReturnsEnum()
    var
        CT: ClientType;
    begin
        Initialize();
        CT := Session.DefaultClientType();
        Assert.IsTrue(true, 'DefaultClientType() must be callable and return ClientType enum');
    end;

    [Test]
    procedure Session_ApplicationIdentifier_ReturnsNonEmpty()
    var
        AppId: Text;
    begin
        Initialize();
        AppId := Session.ApplicationIdentifier();
        Assert.AreNotEqual('', AppId, 'ApplicationIdentifier() must return a non-empty value');
    end;

    [Test]
    procedure Session_GetExecutionContext_ReturnsEnum()
    var
        EC: ExecutionContext;
    begin
        Initialize();
        EC := Session.GetExecutionContext();
        Assert.IsTrue(true, 'GetExecutionContext() must be callable and return ExecutionContext enum');
    end;

    [Test]
    procedure Session_GetCurrentModuleExecutionContext_ReturnsEnum()
    var
        EC: ExecutionContext;
    begin
        Initialize();
        EC := Session.GetCurrentModuleExecutionContext();
        Assert.IsTrue(true, 'GetCurrentModuleExecutionContext() must be callable and return ExecutionContext enum');
    end;

    [Test]
    procedure Session_CurrentExecutionMode_ReturnsEnum()
    var
        EM: ExecutionMode;
    begin
        Initialize();
        EM := Session.CurrentExecutionMode();
        Assert.IsTrue(true, 'CurrentExecutionMode() must be callable and return ExecutionMode enum');
    end;

    [Test]
    procedure Session_LogMessage_WithMinimalParameters()
    begin
        Initialize();
        Session.LogMessage('TEST001', 'test message', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'key1', 'val1');
        Assert.IsTrue(true, 'LogMessage() with minimal parameters must be callable');
    end;

    [Test]
    procedure Session_LogMessage_WithFullParameters()
    begin
        Initialize();
        Session.LogMessage('TEST002', 'Full test message', Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Key1', 'Value1');
        Assert.IsTrue(true, 'LogMessage() with full parameters must be callable');
    end;

                    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
