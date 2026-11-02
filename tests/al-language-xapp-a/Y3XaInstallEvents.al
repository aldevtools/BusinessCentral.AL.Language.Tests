// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Probe: which subscribers run while an app's install code runs, when the subscribers live in an app that depends on it (XApp B) and is
//   installed later. 61179 (install codeunit of XApp A) logs, per company and per database: that it ran, whether it sees XApp B
//   (NavApp.GetModuleInfo), then raises its own integration event (61178 OnY3Phase) and inserts a row into
//   61177 (platform event OnAfterInsertEvent). Subscribers in A (61108), B (tests/al-language-xapp-b/Y3XbInstallEvents.al) and the
//   main app (tests/al-language/install/lt-install-order-subscribers/) log each call with the phase they were raised in.
// Install code must never fail (check-install-triggers.py): it writes only `if Insert() then;` into DataPerCompany = false tables.
//   Tests: tests/al-language/install/lt-install-order-subscribers/InstallOrderSubscriberTests.al.
// BC versions: 27 - 29

table 61176 "LT Y3 Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Entry; Text[200]) { }
        field(2; Detail; Text[250]) { }
    }

    keys { key(PK; Entry) { Clustered = true; } }
}

table 61177 "LT Y3 Probe Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "Key"; Text[100]) { }
    }

    keys { key(PK; "Key") { Clustered = true; } }
}

codeunit 61178 "LT Y3 XA Events"
{
    procedure Raise(Phase: Text)
    begin
        OnY3Phase(Phase);
    end;

    procedure Log(Entry: Text; Detail: Text)
    var
        L: Record "LT Y3 Install Log";
    begin
        L.Entry := CopyStr(Entry, 1, MaxStrLen(L.Entry));
        L.Detail := CopyStr(Detail, 1, MaxStrLen(L.Detail));
        if L.Insert() then;
    end;

    procedure InsertProbe(Phase: Text)
    var
        P: Record "LT Y3 Probe Row";
    begin
        P."Key" := CopyStr(Phase, 1, MaxStrLen(P."Key"));
        if P.Insert(true) then;
    end;

    procedure SeesB(Phase: Text)
    var
        Info: ModuleInfo;
        BId: Guid;
        Found: Boolean;
        Detail: Text;
    begin
        BId := 'c87ced6d-11a6-4ad2-87c7-ac10083d0a2f';
        Found := NavApp.GetModuleInfo(BId, Info);
        Detail := 'getModuleInfo=' + Format(Found);
        if Found then
            Detail += ';dataMajor=' + Format(Info.DataVersion().Major()) + ';appMajor=' + Format(Info.AppVersion().Major());
        Log('A-seesB|' + Phase, Detail);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnY3Phase(Phase: Text)
    begin
    end;
}

codeunit 61179 "LT Y3 XA Install"
{
    Subtype = Install;

    trigger OnInstallAppPerCompany()
    begin
        Run('a-install-company');
    end;

    trigger OnInstallAppPerDatabase()
    begin
        Run('a-install-database');
    end;

    local procedure Run(Phase: Text)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('A-install|' + Phase, '');
        Events.SeesB(Phase);
        Events.Raise(Phase);
        Events.InsertProbe(Phase);
    end;
}

codeunit 61108 "LT Y3 XA Self Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y3 XA Events", 'OnY3Phase', '', false, false)]
    local procedure OnPhase(Phase: Text)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('A-sub|' + Phase, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y3 Probe Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnProbeInsert(var Rec: Record "LT Y3 Probe Row"; RunTrigger: Boolean)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('A-tsub|' + Rec."Key", '');
    end;
}
