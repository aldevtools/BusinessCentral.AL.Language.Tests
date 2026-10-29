// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-app-key-vault
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 99450
// Probe: the platform type under System Application codeunit 3801 "App Key Vault Secret Pr. Impl.",
// Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultAppSecretProvider, called from this app (no key vault in app.json, no Azure Key
// Vault settings on the server) with the members codeunit 3801 calls: the constructor, InitializeFromCallingAppExceptSystemApplication and
// TryGetAzureKeyVaultSecret (before and after a failed initialization, and on a variable never constructed).
// Also declares System.Drawing.Printing.PrinterSettings for the RunOnClient tests of codeunit 99490 (lt-bg-runonclient/BgRunOnClient.al).
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.AzureKeyVaultClient")
    {
        Culture = 'neutral';
        PublicKeyToken = '31bf3856ad364e35';

        type("Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultAppSecretProvider"; LtTyAkvAppSecretProvider) { }
    }
    assembly("System.Drawing")
    {
        Culture = 'neutral';
        PublicKeyToken = 'b03f5f7f11d50a3a';

        type("System.Drawing.Printing.PrinterSettings"; LtTyPrinterSettings) { }
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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure TY_Akv_TryGetSecret_NotConstructed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Provider);
        GetCase(Observer, 'get');
        Observer.Finish();
    end;
}
