// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-key-vault
// Scope: in-scope (System Application codeunit 3800 "App Key Vault Secret Provider", called the way an app calls it)
// Fixtures used: Probe Observer (69160); self-contained codeunit 90190
// Probe: App Key Vault Secret Provider in a test session of an app whose app.json names no key vault, on a server with no Azure Key Vault
// settings. TryInitializeFromCurrentApp (twice on one instance), GetSecret (Text and SecretText overloads, directly and through the
// "Secret Provider v2" interface) before and after a failed initialization: return values, the out value, error text and code.
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
