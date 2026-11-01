// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al).
//   Every procedure of the System Application codeunit "Azure Key Vault" has [Scope('OnPrem')]: a Cloud app cannot call it at all.
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61457, 61458
// Probe: what a test session gets from the server class Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper, through
//   codeunit "Azure Key Vault" (TryFunction procedures; the implementation is SingleInstance and caches values per name) with
//   the test class MockTest.MockAzureKeyVaultSecret.MockAzureKeyVaultSecretProvider set through "Azure Key Vault Test Library",
//   and with no provider at all: secrets mapped and listed in AllowedApplicationSecrets, mapped but not listed, no list at all,
//   unmapped names, empty and blank values, name case, the cache, certificates; and the helper class called directly.
// Facts: with no provider the helper raises "Azure key vault has not been set up. Please contact your system administrator."
//   (code DotNetInvoke: on 27 and 28, DotNetInvoke:InvalidOperation on 29) and the out value is not changed; AllowedApplicationSecrets
//   is not checked (a mapped name that is not listed is returned); an unmapped, empty or blank secret, and a name in another case, give "The secret %1 is either
//   missing or empty." (Dialog); certificates read through "Azure Key Vault" from the mock give "Unable to initialize certificate!".
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, batch runs 41332956805, 41336116625, 41336138376.
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
#if BC29PLUS
        Observer.Expect('secret, no provider', 'false/unchanged');
        Observer.Expect('secret, no provider error|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret, no provider error|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('secret again, no provider', 'false/unchanged');
        Observer.Expect('secret again, no provider error|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret again, no provider error|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('certificate, no provider', 'false/unchanged');
        Observer.Expect('certificate, no provider error|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultCertificate failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('certificate, no provider error|code', 'DotNetInvoke:InvalidOperation');
#else
        Observer.Expect('secret, no provider', 'false/unchanged');
        Observer.Expect('secret, no provider error|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret, no provider error|code', 'DotNetInvoke:');
        Observer.Expect('secret again, no provider', 'false/unchanged');
        Observer.Expect('secret again, no provider error|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret again, no provider error|code', 'DotNetInvoke:');
        Observer.Expect('certificate, no provider', 'false/unchanged');
        Observer.Expect('certificate, no provider error|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultCertificate failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('certificate, no provider error|code', 'DotNetInvoke:');
#endif
        Observer.Verify();
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
#if BC29PLUS
        Observer.Expect('secret raised, no provider|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret raised, no provider|code', 'DotNetInvoke:InvalidOperation');
#else
        Observer.Expect('secret raised, no provider|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret raised, no provider|code', 'DotNetInvoke:');
#endif
        Observer.Verify();
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
        Observer.Expect('mapped, no AllowedApplicationSecrets', 'true/value-1');
        Observer.Expect('unmapped name', 'false/');
        Observer.Expect('unmapped name error|text', 'The secret lt-y58-unmapped is either missing or empty.');
        Observer.Expect('unmapped name error|code', 'Dialog');
        Observer.Expect('mapped name other case', 'false/');
        Observer.Expect('mapped name other case error|text', 'The secret LT-Y58-SECRET is either missing or empty.');
        Observer.Expect('mapped name other case error|code', 'Dialog');
        Observer.Expect('empty name', 'false/');
        Observer.Expect('empty name error|text', 'The secret  is either missing or empty.');
        Observer.Expect('empty name error|code', 'Dialog');
        Observer.Verify();
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
        Observer.Expect('mapped and listed', 'true/listed-value');
        Observer.Expect('mapped, not listed', 'true/notlisted-value');
        Observer.Expect('listed, not mapped', 'false/');
        Observer.Expect('listed, not mapped error|text', 'The secret lt-y58-unmapped-listed is either missing or empty.');
        Observer.Expect('listed, not mapped error|code', 'Dialog');
        Observer.Expect('the list itself', 'true/lt-y58-listed,lt-y58-unmapped-listed');
        Observer.Verify();
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
        Observer.Expect('empty value', 'false/');
        Observer.Expect('empty value error|text', 'The secret lt-y58-empty is either missing or empty.');
        Observer.Expect('empty value error|code', 'Dialog');
        Observer.Expect('blank value', 'false/   ');
        Observer.Expect('blank value error|text', 'The secret lt-y58-blank is either missing or empty.');
        Observer.Expect('blank value error|code', 'Dialog');
        Observer.Expect('padded value', 'true/  v  ');
        Observer.Verify();
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
        Observer.Expect('mapped returns', 'Yes');
        Observer.Expect('mapped value', 'secret-text-value');
        Observer.Expect('empty returns', 'No');
        Observer.Expect('empty error|text', 'The secret lt-y58-st-empty is either missing or empty.');
        Observer.Expect('empty error|code', 'Dialog');
        Observer.Expect('empty value is empty', 'Yes');
        Observer.Expect('unmapped returns', 'No');
        Observer.Expect('unmapped error|text', 'The secret lt-y58-st-unmapped is either missing or empty.');
        Observer.Expect('unmapped error|code', 'Dialog');
        Observer.Verify();
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
        Observer.Expect('mapped certificate', 'false/unchanged');
        Observer.Expect('mapped certificate error|text', 'Unable to initialize certificate!');
        Observer.Expect('mapped certificate error|code', 'Dialog');
        Observer.Expect('unmapped certificate', 'false/unchanged');
        Observer.Expect('unmapped certificate error|text', 'Unable to initialize certificate!');
        Observer.Expect('unmapped certificate error|code', 'Dialog');
        Observer.Expect('secret name read as certificate', 'false/unchanged');
        Observer.Expect('secret name read as certificate error|text', 'Unable to initialize certificate!');
        Observer.Expect('secret name read as certificate error|code', 'Dialog');
        Observer.Expect('certificate name read as secret', 'true/cert-value');
        Observer.Expect('secrettext certificate returns', 'No');
        Observer.Expect('secrettext certificate value', '');
        Observer.Verify();
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
#if BC29PLUS
        Observer.Expect('secret, provider never set|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret, provider never set|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('certificate, provider never set|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultCertificate failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('certificate, provider never set|code', 'DotNetInvoke:InvalidOperation');
        Observer.Expect('mapped secret', 'x-value');
        Observer.Expect('empty secret', '');
        Observer.Expect('unmapped secret', '');
        Observer.Expect('mapped certificate', 'c-value');
        Observer.Expect('unmapped certificate', '');
#else
        Observer.Expect('secret, provider never set|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultSecret failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('secret, provider never set|code', 'DotNetInvoke:');
        Observer.Expect('certificate, provider never set|text', 'A call to Microsoft.Dynamics.Nav.AzureKeyVaultClient.AzureKeyVaultClientHelper.GetAzureKeyVaultCertificate failed with this message: Azure key vault has not been set up. Please contact your system administrator.');
        Observer.Expect('certificate, provider never set|code', 'DotNetInvoke:');
        Observer.Expect('mapped secret', 'x-value');
        Observer.Expect('empty secret', '');
        Observer.Expect('unmapped secret', '');
        Observer.Expect('mapped certificate', 'c-value');
        Observer.Expect('unmapped certificate', '');
#endif
        Observer.Verify();
    end;
}
