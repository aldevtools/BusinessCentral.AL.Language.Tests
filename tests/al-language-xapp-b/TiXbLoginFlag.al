// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8239; test: tests/al-language/events/platform-triggers/TiXbLoginFlagTests.al): a second dependency app (XApp B, not the
//   app under test, not Microsoft) has its own SingleInstance codeunit with one Boolean global; its "System Initialization".OnAfterLogin
//   subscriber sets it to true. Which value does the first test of the main app read?
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

// singleinstance-shared-on-purpose: the probe is what a SingleInstance codeunit of a dependency app carries from the login into the test session.
codeunit 98476 "LT TI XB Login Flag"
{
    SingleInstance = true;

    var
        Flag: Boolean;

    procedure SetFlag(NewFlag: Boolean)
    begin
        Flag := NewFlag;
    end;

    procedure GetFlag(): Boolean
    begin
        exit(Flag);
    end;
}

codeunit 98477 "LT TI XB Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        LoginFlag: Codeunit "LT TI XB Login Flag";
    begin
        LoginFlag.SetFlag(true);
    end;
}
