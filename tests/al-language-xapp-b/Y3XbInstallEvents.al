// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Probe (see tests/al-language-xapp-a/Y3XaInstallEvents.al): XApp B depends on XApp A. 61148 subscribes to A's integration event OnY3Phase
//   and to OnAfterInsertEvent of A's table 61177 and logs each call with its phase. 61149 (install codeunit of B) logs that it ran, then
//   raises A's event and inserts a row of 61177 itself, per company and per database.
// Install code must never fail (check-install-triggers.py): it writes only `if Insert() then;` into DataPerCompany = false tables.
//   Tests: tests/al-language/install/lt-install-order-subscribers/InstallOrderSubscriberTests.al.
// BC versions: 27 - 29

codeunit 61148 "LT Y3 XB Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y3 XA Events", 'OnY3Phase', '', false, false)]
    local procedure OnPhase(Phase: Text)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('B-sub|' + Phase, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y3 Probe Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnProbeInsert(var Rec: Record "LT Y3 Probe Row"; RunTrigger: Boolean)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('B-tsub|' + Rec."Key", '');
    end;
}

codeunit 61149 "LT Y3 XB Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        Run('b-install-company');
    end;

    trigger OnInstallAppPerDatabase()
    begin
        Run('b-install-database');
    end;

    local procedure Run(Phase: Text)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('B-install|' + Phase, '');
        Events.Raise(Phase);
        Events.InsertProbe(Phase);
    end;
}
