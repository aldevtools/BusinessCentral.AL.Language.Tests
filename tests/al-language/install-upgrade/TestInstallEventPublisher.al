// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: none
//
// The integration-event publisher the Subtype=Install codeunit raises from its
// OnInstallAppPerCompany trigger. This is the ordinary AL pattern for letting
// other code contribute setup rows while an app installs, so the question the
// tests ask is simply whether a subscriber is bound and dispatched to at that
// point in the lifecycle.

codeunit 60833 "Install Event Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnDiscoverInstallEntries()
    begin
    end;

    procedure Discover()
    begin
        OnDiscoverInstallEntries();
    end;
}
