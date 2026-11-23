// Cross-app fixture E (al-runner issue 8696, cross-app cell): a subscriber of "System Initialization".OnAfterLogin in an app
// that the test app does not depend on. It sets the globals of the SingleInstance codeunit "SIR XE Login State" of the
// AL Internals Test Fixture, which both apps depend on. The probe is tests/al-language/codeunits/SirCrossAppLogin.al.
codeunit 98031 "SIR XE Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        State: Codeunit "SIR XE Login State";
    begin
        State.SetFromLogin();
    end;
}
