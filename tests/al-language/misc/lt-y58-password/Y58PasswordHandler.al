// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.security.accesscontrol.password-handler
// Scope: in-scope (System Application codeunit "Password Handler", Access = Public, callable from a Cloud app)
// Fixtures used: Probe Observer (69160); self-contained codeunit 93701
// Probe: GenerateSecretPassword() and GenerateSecretPassword(Length), which call the server class
//   Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword(Length, 1) until IsPasswordStrong accepts the result
//   (the raw class is probed in tests/al-language-onprem-dotnet/lt-y58-server-helpers/Y58ServerHelpers.al). A Cloud app cannot
//   unwrap the SecretText, so only what it can see is observed: the minimum length, the error below it, and that the result is
//   not empty and strong.
// BC versions: 27, 28, 29
codeunit 93701 "LT Y58 Password Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure PasswordHandler_Generate()
    var
        Observer: Codeunit "Probe Observer";
        PasswordHandler: Codeunit "Password Handler";
        Password: SecretText;
    begin
        Observer.Observe('min length', Format(PasswordHandler.GetPasswordMinLength()));
        Password := PasswordHandler.GenerateSecretPassword();
        Observer.Observe('default: empty', Format(Password.IsEmpty()));
        Observer.Observe('default: strong', Format(PasswordHandler.IsPasswordStrong(Password)));
        Password := PasswordHandler.GenerateSecretPassword(8);
        Observer.Observe('8: strong', Format(PasswordHandler.IsPasswordStrong(Password)));
        Password := PasswordHandler.GenerateSecretPassword(40);
        Observer.Observe('40: strong', Format(PasswordHandler.IsPasswordStrong(Password)));
        Observer.Finish();
    end;

    [Test]
    procedure PasswordHandler_Generate_TooShort()
    var
        Observer: Codeunit "Probe Observer";
        PasswordHandler: Codeunit "Password Handler";
        Password: SecretText;
    begin
        asserterror Password := PasswordHandler.GenerateSecretPassword(7);
        Observer.ObserveError('length 7');
        asserterror Password := PasswordHandler.GenerateSecretPassword(0);
        Observer.ObserveError('length 0');
        Observer.Finish();
    end;
}
