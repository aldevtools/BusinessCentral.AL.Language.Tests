// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al).
//   Every procedure of the System Application codeunit "Azure Key Vault" has [Scope('OnPrem')]: a Cloud app cannot call it at all.
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61457, 61458
// Probe: what a test session gets from the server class Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper, through
//   codeunit "Azure Key Vault" (TryFunction procedures; the implementation is SingleInstance and caches values per name) with
//   the test class MockTest.MockAzureKeyVaultSecret.MockAzureKeyVaultSecretProvider set through "Azure Key Vault Test Library",
//   and with no provider at all: secrets mapped and listed in AllowedApplicationSecrets, mapped but not listed, no list at all,
//   unmapped names, empty and blank values, name case, the cache, certificates; and the helper class called directly.
// BC versions: 27, 28, 29
dotnet
{
    assembly("MockTest")
    {
        type("MockTest.MockAzureKeyVaultSecret.MockAzureKeyVaultSecretProvider"; LtY58MockKvProvider) { }
    }
    assembly("Microsoft.Dynamics.Nav.AzureKeyVaultClient")
    {
        type("Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper"; LtY58KvClientHelper) { }
    }
}

codeunit 61457 "LT Y58 Azure Key Vault"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        AzureKeyVaultTestLibrary: Codeunit "Azure Key Vault Test Library";

    local procedure ObserveSecret(Observer: Codeunit "Probe Observer"; Name: Text; SecretName: Text)
    var
        Secret: Text;
    begin
        ClearLastError();
        Secret := 'unchanged';
        if AzureKeyVault.GetAzureKeyVaultSecret(SecretName, Secret) then
            Observer.Observe(Name, 'true/' + Secret)
        else begin
            Observer.Observe(Name, 'false/' + Secret);
            Observer.ObserveError(Name + ' error');
        end;
    end;

    local procedure ObserveCertificate(Observer: Codeunit "Probe Observer"; Name: Text; CertificateName: Text)
    var
        Certificate: Text;
    begin
        ClearLastError();
        Certificate := 'unchanged';
        if AzureKeyVault.GetAzureKeyVaultCertificate(CertificateName, Certificate) then
            Observer.Observe(Name, 'true/' + Certificate)
        else begin
            Observer.Observe(Name, 'false/' + Certificate);
            Observer.ObserveError(Name + ' error');
        end;
    end;

    local procedure UseProvider(var Provider: DotNet LtY58MockKvProvider)
    begin
        AzureKeyVaultTestLibrary.SetAzureKeyVaultSecretProvider(Provider);
    end;

    [Test]
    procedure KeyVault_NoProvider()
    var
        Observer: Codeunit "Probe Observer";
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        ObserveSecret(Observer, 'secret, no provider', 'lt-y58-any');
        ObserveSecret(Observer, 'secret again, no provider', 'lt-y58-any');
        ObserveCertificate(Observer, 'certificate, no provider', 'lt-y58-cert');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [Test]
    procedure KeyVault_NoProvider_Raised()
    var
        Observer: Codeunit "Probe Observer";
        Secret: Text;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        asserterror AzureKeyVault.GetAzureKeyVaultSecret('lt-y58-any', Secret);
        Observer.ObserveError('secret raised, no provider');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [Test]
    procedure KeyVault_Mapped_NoAllowedList()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddSecretMapping('lt-y58-secret', 'value-1');
        UseProvider(Provider);
        ObserveSecret(Observer, 'mapped, no AllowedApplicationSecrets', 'lt-y58-secret');
        ObserveSecret(Observer, 'unmapped name', 'lt-y58-unmapped');
        ObserveSecret(Observer, 'mapped name other case', 'LT-Y58-SECRET');
        ObserveSecret(Observer, 'empty name', '');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [Test]
    procedure KeyVault_Mapped_AllowedList()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddSecretMapping('lt-y58-listed', 'listed-value');
        Provider.AddSecretMapping('lt-y58-notlisted', 'notlisted-value');
        Provider.AddSecretMapping('AllowedApplicationSecrets', 'lt-y58-listed,lt-y58-unmapped-listed');
        UseProvider(Provider);
        ObserveSecret(Observer, 'mapped and listed', 'lt-y58-listed');
        ObserveSecret(Observer, 'mapped, not listed', 'lt-y58-notlisted');
        ObserveSecret(Observer, 'listed, not mapped', 'lt-y58-unmapped-listed');
        ObserveSecret(Observer, 'the list itself', 'AllowedApplicationSecrets');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [Test]
    procedure KeyVault_EmptyAndBlankValues()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddSecretMapping('lt-y58-empty', '');
        Provider.AddSecretMapping('lt-y58-blank', '   ');
        Provider.AddSecretMapping('lt-y58-padded', '  v  ');
        UseProvider(Provider);
        ObserveSecret(Observer, 'empty value', 'lt-y58-empty');
        ObserveSecret(Observer, 'blank value', 'lt-y58-blank');
        ObserveSecret(Observer, 'padded value', 'lt-y58-padded');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [Test]
    procedure KeyVault_SecretText()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
        Secret: SecretText;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddSecretMapping('lt-y58-st', 'secret-text-value');
        Provider.AddSecretMapping('lt-y58-st-empty', '');
        UseProvider(Provider);
        Observer.Observe('mapped returns', Format(AzureKeyVault.GetAzureKeyVaultSecret('lt-y58-st', Secret)));
        Observer.Observe('mapped value', Secret.Unwrap());
        ClearLastError();
        Observer.Observe('empty returns', Format(AzureKeyVault.GetAzureKeyVaultSecret('lt-y58-st-empty', Secret)));
        Observer.ObserveError('empty error');
        Observer.Observe('empty value is empty', Format(Secret.IsEmpty()));
        ClearLastError();
        Observer.Observe('unmapped returns', Format(AzureKeyVault.GetAzureKeyVaultSecret('lt-y58-st-unmapped', Secret)));
        Observer.ObserveError('unmapped error');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [TryFunction]
    local procedure TryAddMapping(var Provider: DotNet LtY58MockKvProvider; Name: Text; Value: Text)
    begin
        Provider.AddSecretMapping(Name, Value);
    end;

    [Test]
    procedure KeyVault_Cache()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
        Second: DotNet LtY58MockKvProvider;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddSecretMapping('lt-y58-cache', 'first');
        UseProvider(Provider);
        ObserveSecret(Observer, 'first read', 'lt-y58-cache');
        if TryAddMapping(Provider, 'lt-y58-cache', 'second') then
            Observer.Observe('second mapping of the same name', 'ok')
        else
            Observer.ObserveError('second mapping of the same name');
        Provider.AddSecretMapping('lt-y58-late', 'late');
        ObserveSecret(Observer, 'name mapped after the first read', 'lt-y58-late');
        Second := Second.MockAzureKeyVaultSecretProvider();
        Second.AddSecretMapping('lt-y58-cache', 'from second provider');
        UseProvider(Second);
        ObserveSecret(Observer, 'read after a new provider', 'lt-y58-cache');
        ObserveSecret(Observer, 'name of the old provider only, after a new provider', 'lt-y58-late');
        AzureKeyVaultTestLibrary.ClearSecrets();
        ObserveSecret(Observer, 'read after ClearSecrets', 'lt-y58-cache');
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;

    [Test]
    procedure KeyVault_Certificates()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
        Certificate: SecretText;
    begin
        AzureKeyVaultTestLibrary.ClearSecrets();
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddCertificateMapping('lt-y58-cert', 'cert-value');
        Provider.AddSecretMapping('lt-y58-secret-not-cert', 'secret-value');
        UseProvider(Provider);
        ObserveCertificate(Observer, 'mapped certificate', 'lt-y58-cert');
        ObserveCertificate(Observer, 'unmapped certificate', 'lt-y58-cert-unmapped');
        ObserveCertificate(Observer, 'secret name read as certificate', 'lt-y58-secret-not-cert');
        ObserveSecret(Observer, 'certificate name read as secret', 'lt-y58-cert');
        Observer.Observe('secrettext certificate returns', Format(AzureKeyVault.GetAzureKeyVaultCertificate('lt-y58-cert', Certificate)));
        Observer.Observe('secrettext certificate value', Certificate.Unwrap());
        AzureKeyVaultTestLibrary.ClearSecrets();
        Observer.Finish();
    end;
}

codeunit 61458 "LT Y58 Key Vault Helper"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: DotNet LtY58KvClientHelper;

    [TryFunction]
    local procedure TryGetSecret(Name: Text; var Value: Text)
    begin
        Value := Helper.GetAzureKeyVaultSecret(Name);
    end;

    [TryFunction]
    local procedure TryGetCertificate(Name: Text; var Value: Text)
    begin
        Value := Helper.GetAzureKeyVaultCertificate(Name);
    end;

    local procedure ObserveTry(Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; Value: Text)
    begin
        if Ok then
            Observer.Observe(Name, Value)
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure KvHelper_Direct()
    var
        Observer: Codeunit "Probe Observer";
        Provider: DotNet LtY58MockKvProvider;
        Value: Text;
    begin
        Helper := Helper.AzureKeyVaultClientHelper();
        ObserveTry(Observer, 'secret, provider never set', TryGetSecret('lt-y58-x', Value), Value);
        ObserveTry(Observer, 'certificate, provider never set', TryGetCertificate('lt-y58-x', Value), Value);
        Provider := Provider.MockAzureKeyVaultSecretProvider();
        Provider.AddSecretMapping('lt-y58-x', 'x-value');
        Provider.AddSecretMapping('lt-y58-empty', '');
        Provider.AddCertificateMapping('lt-y58-c', 'c-value');
        Helper.SetAzureKeyVaultProvider(Provider);
        ObserveTry(Observer, 'mapped secret', TryGetSecret('lt-y58-x', Value), Value);
        ObserveTry(Observer, 'empty secret', TryGetSecret('lt-y58-empty', Value), Value);
        ObserveTry(Observer, 'unmapped secret', TryGetSecret('lt-y58-unmapped', Value), Value);
        ObserveTry(Observer, 'mapped certificate', TryGetCertificate('lt-y58-c', Value), Value);
        ObserveTry(Observer, 'unmapped certificate', TryGetCertificate('lt-y58-unmapped', Value), Value);
        Observer.Finish();
    end;
}
