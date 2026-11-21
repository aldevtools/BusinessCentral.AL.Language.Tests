// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 8239; test: tests/al-language-onprem/session-system/TiIsSaaSLoginMemo.al): a dependency app's (XApp A, not the app
//   under test, not Microsoft) subscriber of "System Initialization".OnAfterLogin calls EnvironmentInformation.IsSaaS(). That call fills the memo
//   globals of the SingleInstance System Application codeunit "Environment Information Impl." in the session the login runs in. The subscriber
//   keeps nothing and never fails.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29
using System.Environment;

codeunit 98488 "LT TI XA IsSaaS Login"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        if EnvironmentInformation.IsSaaS() then
            exit;
    end;
}
