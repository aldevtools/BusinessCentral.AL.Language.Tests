// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Install Event Seed (60832), Install Event Publisher (60833)
//
// A static (non-manual) subscriber to the event the install trigger raises. It
// records WHICH mechanism reached it, so a test can tell "the subscriber ran
// during install" apart from "the subscriber ran later, from test code".
//
// Insert rather than InsertOrModify, guarded by Get: OnInstallAppPerCompany
// fires once per existing company, and a sandbox may hold more than one, so a
// second firing must not fail the install on a duplicate primary key.

codeunit 60834 "Install Event Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Install Event Publisher", 'OnDiscoverInstallEntries', '', false, false)]
    local procedure RecordDiscovery()
    var
        Seed: Record "Install Event Seed";
    begin
        if Seed.Get('FROMEVENT') then
            exit;
        Seed.Init();
        Seed."Code" := 'FROMEVENT';
        Seed."Source" := 'install-trigger';
        Seed.Insert();
    end;
}
