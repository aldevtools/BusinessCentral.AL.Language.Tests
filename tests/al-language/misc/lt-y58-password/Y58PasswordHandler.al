// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.security.accesscontrol.password-handler
// Scope: in-scope (System Application codeunit "Password Handler", Access = Public, callable from a Cloud app)
// Fixtures used: Probe Observer (69160); self-contained codeunit 93701
// Probe: GenerateSecretPassword() and GenerateSecretPassword(Length), which call the server class
//   Microsoft.Dynamics.Nav.PasswordGenerator.PasswordGenerator.GeneratePassword(Length, 1) until IsPasswordStrong accepts the result
//   (the raw class is probed in tests/al-language-onprem-dotnet/lt-y58-server-helpers/Y58ServerHelpers.al). A Cloud app cannot
//   unwrap the SecretText, so only what it can see is observed: the minimum length, the error below it, and that the result is
//   not empty and strong.
// Facts: the minimum length is 8; a shorter length gives "The password must contain at least 8 characters." (Dialog). Also
//   measured on a SaaS sandbox (BC 29), same values.
// Expected values: corpus CI (Linux containers) BC 27.5, 28.5 and 29.0, batch runs 41332956805, 41336116625, 41336138376.
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
        Observer.Expect('min length', '8');
        Observer.Expect('default: empty', 'No');
        Observer.Expect('default: strong', 'Yes');
        Observer.Expect('8: strong', 'Yes');
        Observer.Expect('40: strong', 'Yes');
        Observer.Verify();
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
        Observer.Expect('length 7|text', 'The password must contain at least 8 characters.');
        Observer.Expect('length 7|code', 'Dialog');
        Observer.Expect('length 0|text', 'The password must contain at least 8 characters.');
        Observer.Expect('length 0|code', 'Dialog');
        Observer.Verify();
    end;
}
