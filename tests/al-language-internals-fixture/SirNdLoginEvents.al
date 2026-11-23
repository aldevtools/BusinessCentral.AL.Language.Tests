// Fixture for al-runner issue 8696 (login without a dependency): an integration event of this app, which cross-app
// fixtures B and E both depend on. XApp E (tests/al-language-xapp-e/SirNdLoginSubs.al) raises it in its OnAfterLogin
// subscriber; XApp B (tests/al-language-xapp-b/SirNdXbEventState.al) subscribes to it with a SingleInstance codeunit.
// XApp E does not depend on XApp B. The probe is tests/al-language/codeunits/SirLoginNoDep.al.
codeunit 61098 "SIR ND Login Events"
{
    procedure Raise()
    begin
        OnLoginRaised();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoginRaised()
    begin
    end;
}
