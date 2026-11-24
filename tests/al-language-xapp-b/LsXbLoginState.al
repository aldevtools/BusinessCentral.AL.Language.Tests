// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 9021; tests: tests/al-language/events/platform-triggers/LsLoginStateTests.al): a second dependency app's
//   (XApp B) "System Initialization".OnAfterLogin subscriber changes state of XApp A (tests/al-language-xapp-a/LsXaLoginState.al):
//   one order step on "LT LS XA Order" (with the two XApp A subscribers and the main app's), a call of XApp A's helper that sets
//   "LT LS XA Far", and XApp A's integration event that the main app answers with a SingleInstance codeunit of its own.
// It only writes objects of this probe: it runs in every session of every corpus job. Install code is not used here.
// BC versions: 27 - 29

codeunit 91073 "LT LS XB Login"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Order: Codeunit "LT LS XA Order";
        Helper: Codeunit "LT LS XA Helper";
        Events: Codeunit "LT LS XA Events";
    begin
        Order.Step('b', 3);
        Helper.Touch('xb');
        Events.Ping('xb');
    end;
}
