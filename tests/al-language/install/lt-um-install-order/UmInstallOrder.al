// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Probe Observer (69160); the five install codeunits "LT UM ..." (90431-90435), appended to the already allowed install files
//   install/TestInstallSeeder.al, install/lt-bf-install-probes/BfInstallFixtures.al, record/lt-as-records/AsDtInstaller.al,
//   install/lt-cm-install-leads/CmInstallObjects.al and install/TestInstallStartSessionProbe.al (check-install-triggers.py lists files)
// Probe: ADR-046 probe Q1 (al-runtime-rs), the order in which BC runs several install codeunits of ONE app, the NP Retail shape: every install codeunit
//   appends its name to ONE shared SingleInstance codeunit ("LT UM Install State") and writes one row to "LT UM Install Log" (no company, AutoIncrement).
//   The ids, names and files are chosen so that every rule predicts another order:
//     id          name                file (folder / file)
//     90431       "LT UM Mu Install"  install / TestInstallSeeder.al
//     90432       "LT UM b Install"   install/lt-bf-install-probes / BfInstallFixtures.al
//     90433       "LT UM Cu Install"  record/lt-as-records / AsDtInstaller.al
//     90434       "LT UM Ay Install"  install/lt-cm-install-leads / CmInstallObjects.al
//     90435       "LT UM Zz Install"  install / TestInstallStartSessionProbe.al
//   ascending id: Mu b Cu Ay Zz; descending id: Zz Ay Cu b Mu; ascending name (ordinal): Ay Cu Mu Zz b; descending name: b Zz Mu Cu Ay.
// Install code must never fail: every write is `if Insert() then;` into a DataPerCompany = false table.
// BC versions: 27 - 29
table 90430 "LT UM Install Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Source"; Text[30]) { }
        field(3; "Event Name"; Text[40]) { }
        field(4; "Company"; Text[60]) { }
        field(5; "Session Id"; Integer) { }
        field(6; "Names So Far"; Text[250]) { }
        field(7; "Calls So Far"; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 90436 "LT UM Install State"
{
    SingleInstance = true;

    var
        Names: Text;
        Calls: Integer;

    procedure Append(Name: Text): Text
    begin
        Calls += 1;
        Names += Name + ';';
        exit(Names);
    end;

    procedure CallCount(): Integer
    begin
        exit(Calls);
    end;
}

// Shared by the five install codeunits. No test codeunit uses it.
codeunit 90437 "LT UM Install Writer"
{
    procedure WriteRow(Source: Text; EventName: Text)
    var
        Row: Record "LT UM Install Log";
        State: Codeunit "LT UM Install State";
    begin
        Row.Init();
        Row."Names So Far" := CopyStr(State.Append(Source), 1, MaxStrLen(Row."Names So Far"));
        Row."Calls So Far" := State.CallCount();
        Row."Source" := CopyStr(Source, 1, MaxStrLen(Row."Source"));
        Row."Event Name" := CopyStr(EventName, 1, MaxStrLen(Row."Event Name"));
        Row."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Row."Company"));
        Row."Session Id" := SessionId();
        if Row.Insert() then;
    end;
}

codeunit 90438 "LT UM Install Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    [Test]
    procedure InstallCodeunits_OneApp_RunOrderPerPart()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT UM Install Log";
        Sequence: Text;
        Last: Text;
        Current: Text;
        Sessions: List of [Integer];
        Carry: Text;
    begin
        Row.SetCurrentKey(Id);
        if Row.FindSet() then
            repeat
                Current := Tag(Row."Company") + '/' + Row."Event Name";
                if Current <> Last then begin
                    if Last <> '' then
                        Observer.Observe('sequence ' + Last, Sequence);
                    Sequence := '';
                    Last := Current;
                end;
                Sequence += Row."Source" + ';';
                if not Sessions.Contains(Row."Session Id") then
                    Sessions.Add(Row."Session Id");
                Carry += Row."Names So Far" + '|' + Format(Row."Calls So Far") + ' ';
            until Row.Next() = 0;
        if Last <> '' then
            Observer.Observe('sequence ' + Last, Sequence);
        Observer.Observe('rows', Format(Row.Count()));
        Observer.Observe('sessions', Format(Sessions.Count()));
        Observer.Observe('state as each row saw it', Carry);
        Observer.Finish();
    end;
}
