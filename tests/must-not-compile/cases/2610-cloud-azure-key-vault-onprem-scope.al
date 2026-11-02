// @expect AL0296 | The application object or method 'GetAzureKeyVaultSecret' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'GetAzureKeyVaultSecret' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// @expect AL0296 | The application object or method 'GetAzureKeyVaultCertificate' has scope 'OnPrem' and cannot be used for 'Cloud' development.
// The System Application codeunit "Azure Key Vault" (2200): every procedure has [Scope('OnPrem')], so a Cloud app cannot call
// GetAzureKeyVaultSecret or GetAzureKeyVaultCertificate (Text and SecretText overloads). The OnPrem behavior is pinned by
// tests/al-language-onprem-dotnet/lt-y58-key-vault/Y58AzureKeyVault.al.
codeunit 50000 "MNC Cloud Key Vault"
{
    procedure Read()
    var
        AzureKeyVault: Codeunit "Azure Key Vault";
        Secret: Text;
        SecretValue: SecretText;
        Certificate: Text;
    begin
        AzureKeyVault.GetAzureKeyVaultSecret('a', Secret);
        AzureKeyVault.GetAzureKeyVaultSecret('a', SecretValue);
        AzureKeyVault.GetAzureKeyVaultCertificate('a', Certificate);
    end;
}
