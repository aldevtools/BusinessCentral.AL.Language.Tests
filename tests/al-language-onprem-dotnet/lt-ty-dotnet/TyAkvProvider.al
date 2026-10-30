// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-key-vault
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99450
// Probe: the platform type under System Application codeunit 3801 "App Key Vault Secret Pr. Impl.",
// Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultAppSecretProvider, called from this app (no key vault in app.json, no Azure Key
// Vault settings on the server) with the members codeunit 3801 calls: the constructor, InitializeFromCallingAppExceptSystemApplication and
// TryGetAzureKeyVaultSecret (before and after a failed initialization, and on a variable never constructed).
// Expected values: corpus CI (Linux containers, MsDyn365Bc.On.Linux) BC 27.5, 28.5 and 29.0, batch runs 40840955706, 40840985427, 40841014789; the same on all three.
// TryGetAzureKeyVaultSecret does not return false when the object is not initialized: it raises "Not initialized." (code AzureKeyVaultAppSecretProvider).
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.AzureKeyVaultClient")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultAppSecretProvider"; LtTyAkvAppSecretProvider) { }
    }
}

codeunit 99450 "LT TY Akv App Secret Provider"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Provider: DotNet LtTyAkvAppSecretProvider;

    [TryFunction]
    local procedure TryConstruct()
    begin
        Provider := Provider.AzureKeyVaultAppSecretProvider();
    end;

    [TryFunction]
    local procedure TryInitialize()
    begin
        Provider.InitializeFromCallingAppExceptSystemApplication();
    end;

    [TryFunction]
    local procedure TryGet(var Ret: Boolean; var Value: Text)
    begin
        Ret := Provider.TryGetAzureKeyVaultSecret('LtTyMissingSecret', Value);
    end;

    local procedure GetCase(var Observer: Codeunit "Probe Observer"; Name: Text)
    var
        Ret: Boolean;
        Value: Text;
    begin
        Ret := true;
        Value := 'untouched';
        if TryGet(Ret, Value) then
            Observer.Observe(Name, 'ok ret=' + Format(Ret))
        else
            Observer.ObserveError(Name);
        Observer.Observe(Name + ' value', Value);
    end;

    [Test]
    procedure TY_Akv_Construct_Initialize()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Provider);
        if TryConstruct() then
            Observer.Observe('construct', 'ok isnull=' + Format(IsNull(Provider)))
        else
            Observer.ObserveError('construct');
        if TryInitialize() then
            Observer.Observe('initialize', 'ok')
        else
            Observer.ObserveError('initialize');
        Observer.Expect('construct', 'ok isnull=No');
        Observer.Expect('initialize|text', 'No key vaults specified for extension ''AL Language Coverage Tests (OnPrem DotNet) by AL Language 1.0.0.0''.');
        Observer.Expect('initialize|code', 'AzureKeyVaultAppSecretProvider');
        Observer.Verify();
    end;

    [Test]
    procedure TY_Akv_TryGetSecret_NoInitialize()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Provider);
        if not TryConstruct() then
            Observer.ObserveError('construct');
        GetCase(Observer, 'get');
        Observer.Expect('get|text', 'Not initialized.');
        Observer.Expect('get|code', 'AzureKeyVaultAppSecretProvider');
        Observer.Expect('get value', 'untouched');
        Observer.Verify();
    end;

    [Test]
    procedure TY_Akv_TryGetSecret_AfterFailedInitialize()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Provider);
        if not TryConstruct() then
            Observer.ObserveError('construct');
        if TryInitialize() then
            Observer.Observe('initialize', 'ok')
        else
            Observer.ObserveError('initialize');
        GetCase(Observer, 'get');
        Observer.Expect('initialize|text', 'No key vaults specified for extension ''AL Language Coverage Tests (OnPrem DotNet) by AL Language 1.0.0.0''.');
        Observer.Expect('initialize|code', 'AzureKeyVaultAppSecretProvider');
        Observer.Expect('get|text', 'Not initialized.');
        Observer.Expect('get|code', 'AzureKeyVaultAppSecretProvider');
        Observer.Expect('get value', 'untouched');
        Observer.Verify();
    end;

    [Test]
    procedure TY_Akv_TryGetSecret_NotConstructed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Provider);
        GetCase(Observer, 'get');
        Observer.Expect('get|text', 'A DotNet variable has not been instantiated. Attempting to call Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultAppSecretProvider.TryGetAzureKeyVaultSecret in CodeUnit LT TY Akv App Secret Provider: TryGet');
        Observer.Expect('get|code', 'DotNetVariableNotCreated');
        Observer.Expect('get value', 'untouched');
        Observer.Verify();
    end;
}
