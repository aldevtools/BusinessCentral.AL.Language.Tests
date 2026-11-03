// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-key-vault
// Scope: in-scope (System Application codeunit 3800 "App Key Vault Secret Provider", called the way an app calls it)
// Fixtures used: Probe Observer (69160); self-contained codeunit 90190
// Probe: App Key Vault Secret Provider in a test session of an app whose app.json names no key vault, on a server with no Azure Key Vault
// settings. TryInitializeFromCurrentApp (twice on one instance), GetSecret (Text and SecretText overloads, directly and through the
// "Secret Provider v2" interface) before and after a failed initialization: return values, the out value, error text and code.
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, batch runs 40838964177, 40838990056, 40839014628; the same on all three.
// GetLastErrorText keeps the label's backslashes as written (\\ and \-), and the code is Dialog.
// BC versions: 27, 28, 29
codeunit 90190 "LT TY App Key Vault"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGetText(var Provider: Codeunit "App Key Vault Secret Provider"; var Ret: Boolean; var Value: Text)
    begin
        Ret := Provider.GetSecret('LtTyMissingSecret', Value);
    end;

    [TryFunction]
    local procedure TryGetSecretText(var Provider: Codeunit "App Key Vault Secret Provider"; var Ret: Boolean; var Value: SecretText)
    begin
        Ret := Provider.GetSecret('LtTyMissingSecret', Value);
    end;

    [TryFunction]
    local procedure TryGetIface(Provider: Interface "Secret Provider v2"; var Ret: Boolean; var Value: Text)
    begin
        Ret := Provider.GetSecret('LtTyMissingSecret', Value);
    end;

    [Test]
    procedure TY_AppKv_TryInitialize_NoKeyVault()
    var
        Observer: Codeunit "Probe Observer";
        Provider: Codeunit "App Key Vault Secret Provider";
    begin
        ClearLastError();
        if Provider.TryInitializeFromCurrentApp() then
            Observer.Observe('init1', 'true')
        else
            Observer.ObserveError('init1');
        if Provider.TryInitializeFromCurrentApp() then
            Observer.Observe('init2', 'true')
        else
            Observer.ObserveError('init2');
        Observer.Expect('init1|text', 'Couldn''t initialize the App Key Vault Secret Provider.\\Common reasons include:\- The extension doesn''t specify a key vault in its app.json file.\- The extension wasn''t published with a PublisherAzureActiveDirectoryTenantId and the server requires it\- The server''s Azure Key Vault settings are incorrect\- The server lacks permission to the private key of Azure Key Vault client certificate\\Please check the Event Log or Application Insights for more details.');
        Observer.Expect('init1|code', 'Dialog');
        Observer.Expect('init2|text', 'Couldn''t initialize the App Key Vault Secret Provider.\\Common reasons include:\- The extension doesn''t specify a key vault in its app.json file.\- The extension wasn''t published with a PublisherAzureActiveDirectoryTenantId and the server requires it\- The server''s Azure Key Vault settings are incorrect\- The server lacks permission to the private key of Azure Key Vault client certificate\\Please check the Event Log or Application Insights for more details.');
        Observer.Expect('init2|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure TY_AppKv_GetSecret_NotInitialized()
    var
        Observer: Codeunit "Probe Observer";
        Provider: Codeunit "App Key Vault Secret Provider";
        Ret: Boolean;
        Value: Text;
    begin
        Ret := true;
        Value := 'untouched';
        if TryGetText(Provider, Ret, Value) then
            Observer.Observe('get', 'ok ret=' + Format(Ret))
        else
            Observer.ObserveError('get');
        Observer.Observe('get value', Value);
        Observer.Expect('get|text', 'Cannot get secrets because the App Key Vault Secret Provider has not been initialized.');
        Observer.Expect('get|code', 'Dialog');
        Observer.Expect('get value', 'untouched');
        Observer.Verify();
    end;

    [Test]
    procedure TY_AppKv_GetSecret_AfterFailedInit()
    var
        Observer: Codeunit "Probe Observer";
        Provider: Codeunit "App Key Vault Secret Provider";
        Ret: Boolean;
        Value: Text;
    begin
        Observer.Observe('init', Format(Provider.TryInitializeFromCurrentApp()));
        ClearLastError();
        Ret := true;
        Value := 'untouched';
        if TryGetText(Provider, Ret, Value) then
            Observer.Observe('get', 'ok ret=' + Format(Ret))
        else
            Observer.ObserveError('get');
        Observer.Observe('get value', Value);
        Observer.Expect('init', 'No');
        Observer.Expect('get|text', 'Cannot get secrets because the App Key Vault Secret Provider has not been initialized.');
        Observer.Expect('get|code', 'Dialog');
        Observer.Expect('get value', 'untouched');
        Observer.Verify();
    end;

    [Test]
    procedure TY_AppKv_GetSecret_SecretText_NotInitialized()
    var
        Observer: Codeunit "Probe Observer";
        Provider: Codeunit "App Key Vault Secret Provider";
        Ret: Boolean;
        Value: SecretText;
    begin
        Ret := true;
        if TryGetSecretText(Provider, Ret, Value) then
            Observer.Observe('get', 'ok ret=' + Format(Ret))
        else
            Observer.ObserveError('get');
        Observer.Observe('get value empty', Format(Value.IsEmpty()));
        Observer.Expect('get|text', 'Cannot get secrets because the App Key Vault Secret Provider has not been initialized.');
        Observer.Expect('get|code', 'Dialog');
        Observer.Expect('get value empty', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TY_AppKv_GetSecret_Interface_NotInitialized()
    var
        Observer: Codeunit "Probe Observer";
        Provider: Codeunit "App Key Vault Secret Provider";
        Ret: Boolean;
        Value: Text;
    begin
        Ret := true;
        Value := 'untouched';
        if TryGetIface(Provider, Ret, Value) then
            Observer.Observe('get', 'ok ret=' + Format(Ret))
        else
            Observer.ObserveError('get');
        Observer.Observe('get value', Value);
        Observer.Expect('get|text', 'Cannot get secrets because the App Key Vault Secret Provider has not been initialized.');
        Observer.Expect('get|code', 'Dialog');
        Observer.Expect('get value', 'untouched');
        Observer.Verify();
    end;

    [Test]
    procedure TY_AppKv_GetSecret_NotInitialized_Uncaught()
    var
        Observer: Codeunit "Probe Observer";
        Provider: Codeunit "App Key Vault Secret Provider";
        Value: Text;
    begin
        asserterror Provider.GetSecret('LtTyMissingSecret', Value);
        Observer.ObserveError('asserterror');
        Observer.Expect('asserterror|text', 'Cannot get secrets because the App Key Vault Secret Provider has not been initialized.');
        Observer.Expect('asserterror|code', 'Dialog');
        Observer.Verify();
    end;
}
