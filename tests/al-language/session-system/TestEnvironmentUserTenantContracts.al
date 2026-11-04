// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-userid-function
// Scope: in-scope
// Fixtures used: shared Assert (60021); self-contained tables 68311, 68314, 68315, codeunits 68310 (tests), 68312 (log),
//                68313 (subscriber)
// Probe: written against a real BC 27.5 service tier started by bc-linux (sandbox, W1 localization,
// user BCRUNNER, tenant "default"); every literal below is what that tier produced. Other BC versions
// and other hosts were not measured.
//
// Pins what the System Application wrappers around the server's own classes answer in a test:
// "Environment Information" (environment type, name, application family), "Tenant Information",
// "Azure AD Tenant", "User Permissions", "Azure AD User Management", a few System functions
// (UserId, CompanyName, ProductName, TaskScheduler.CanCreateTask, session identifiers), and what
// Base Application decides when the platform asks which database table events to raise
// (Codeunit "Global Triggers", GetDatabaseTableTriggerSetup and GetGlobalTableTriggerMask).
//
// The members of "Server Setting" and "Environment Information".GetEnvironmentSetting are scoped
// OnPrem and are pinned in the OnPrem app (tests/al-language-onprem/session).
// Global Triggers: what the flags hold depends on the apps installed. Where the Microsoft app Tests-TestLibraries
// is installed (a full local bc-linux container), its codeunit "Backup Management" sets all four flags for the tables
// of this app; where it is not (CI), only Base Application's own rules apply (Change Log setup, Dataverse
// mapping, API webhook subscription, data synchronization). The tests below read that app's presence and expect
// either answer, and pin the Change Log rule and the platform's reaction to a flag.
// BC versions: 27.5, 28.5, 29.0 (IsSaaSInfrastructure is false on 29.0; see its test)

table 68311 "Probe GT Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68314 "Probe GT Changelog Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68316 "Probe GT Temp Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 68315 "Probe GT Own Table"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 68312 "Probe GT Log"
{
    SingleInstance = true;

    var
        Log: Text;

    procedure Add(Entry: Text)
    begin
        Log += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Log;
        Log := '';
        exit(Result);
    end;
}

codeunit 68313 "Probe GT Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(TableId) then
            exit;
        GtLog.Add('Setup(' + Format(TableId) + ' ins=' + Format(OnDatabaseInsert) + ' mod=' + Format(OnDatabaseModify) + ' del=' + Format(OnDatabaseDelete) + ' ren=' + Format(OnDatabaseRename) + ')');
        if TableId in [Database::"Probe GT Own Table", Database::"Probe GT Temp Table"] then
            OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure Mask(TableId: Integer; var TableTriggerMask: Integer)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(TableId) then
            exit;
        GtLog.Add('Mask(' + Format(TableId) + ' mask=' + Format(TableTriggerMask) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure DatabaseInsert(RecRef: RecordRef)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(RecRef.Number) then
            exit;
        GtLog.Add('OnDatabaseInsert(' + Format(RecRef.Number) + ')');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure GlobalInsert(RecRef: RecordRef)
    var
        GtLog: Codeunit "Probe GT Log";
    begin
        if not Watched(RecRef.Number) then
            exit;
        GtLog.Add('OnGlobalInsert(' + Format(RecRef.Number) + ')');
    end;

    local procedure Watched(TableId: Integer): Boolean
    begin
        exit(TableId in [Database::"Probe GT Table", Database::"Probe GT Changelog Table", Database::"Probe GT Own Table", Database::"Probe GT Temp Table"]);
    end;
}

codeunit 68310 "Probe Environment Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure EnvironmentInformation_Answers()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.IsTrue(EnvironmentInformation.IsSandbox(), 'IsSandbox');
        Assert.IsFalse(EnvironmentInformation.IsProduction(), 'IsProduction');
        Assert.IsTrue(EnvironmentInformation.IsSaaS(), 'IsSaaS');
        Assert.IsTrue(EnvironmentInformation.IsOnPrem(), 'IsOnPrem is true at the same time as IsSaaS');
        Assert.IsFalse(EnvironmentInformation.IsFinancials(), 'IsFinancials');
    end;

    [Test]
    procedure EnvironmentInformation_IsSaaSInfrastructure_DiffersBetween28And29()
    // Measured: true on the 27.5 and 28.5 runs, false on the 29.0 run (same container setup, bc-linux).
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
#if BC29PLUS
        Assert.IsFalse(EnvironmentInformation.IsSaaSInfrastructure(), 'IsSaaSInfrastructure');
#else
        Assert.IsTrue(EnvironmentInformation.IsSaaSInfrastructure(), 'IsSaaSInfrastructure');
#endif
    end;

    [Test]
    procedure EnvironmentInformation_Name_AndApplicationFamily()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.AreEqual('Sandbox', EnvironmentInformation.GetEnvironmentName(), 'GetEnvironmentName');
        Assert.AreEqual('W1', EnvironmentInformation.GetApplicationFamily(), 'GetApplicationFamily');
    end;

    [Test]
    procedure EnvironmentInformation_CanStartSession_AndPowerPlatformEnvironment()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.IsFalse(EnvironmentInformation.CanStartSession(), 'CanStartSession');
        Assert.AreEqual('', EnvironmentInformation.GetLinkedPowerPlatformEnvironmentId(), 'GetLinkedPowerPlatformEnvironmentId');
    end;

    [Test]
    procedure EnvironmentInformation_VersionInstalled_OfTheNullAppId()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        NoGuid: Guid;
    begin
        Assert.IsTrue(EnvironmentInformation.VersionInstalled(NoGuid) >= 27, 'VersionInstalled of the null app id is the installed application major version');
    end;

    [Test]
    procedure TenantAndAzureAd_Answers()
    var
        TenantInformation: Codeunit "Tenant Information";
        AzureAdTenant: Codeunit "Azure AD Tenant";
    begin
        Assert.AreEqual('default', TenantInformation.GetTenantId(), 'Tenant Information.GetTenantId');
        Assert.AreEqual('default', TenantId(), 'TenantId()');
        Assert.AreEqual('', TenantInformation.GetTenantDisplayName(), 'GetTenantDisplayName');
        Assert.AreEqual('common', AzureAdTenant.GetAadTenantId(), 'GetAadTenantId');
        Assert.AreEqual('', AzureAdTenant.GetAadTenantDomainName(), 'GetAadTenantDomainName');
        Assert.AreEqual('', AzureAdTenant.GetCountryLetterCode(), 'GetCountryLetterCode');
        Assert.AreEqual('', AzureAdTenant.GetPreferredLanguage(), 'GetPreferredLanguage');
    end;

    [Test]
    procedure UserPermissions_And_AzureAdUserManagement_Answers()
    var
        UserPermissions: Codeunit "User Permissions";
        AzureAdUserManagement: Codeunit "Azure AD User Management";
    begin
        Assert.AreEqual('BCRUNNER', UserId(), 'UserId');
        Assert.IsFalse(IsNullGuid(UserSecurityId()), 'UserSecurityId is set');
        Assert.IsTrue(UserPermissions.IsSuper(UserSecurityId()), 'IsSuper');
        Assert.IsTrue(UserPermissions.CanManageUsersOnTenant(UserSecurityId()), 'CanManageUsersOnTenant');
        Assert.IsFalse(AzureAdUserManagement.IsUserTenantAdmin(), 'IsUserTenantAdmin');
        Assert.IsTrue(AzureAdUserManagement.ArePermissionsCustomized(UserSecurityId()), 'ArePermissionsCustomized');
        Assert.IsFalse(AzureAdUserManagement.IsUserDelegated(UserSecurityId()), 'IsUserDelegated');
    end;

    [Test]
    procedure SystemFunctions_Answers()
    var
        ModuleInfo: ModuleInfo;
    begin
        Assert.AreEqual('CRONUS International Ltd.', CompanyName(), 'CompanyName');
        Assert.AreEqual('Dynamics 365 Business Central', ProductName.Full(), 'ProductName.Full');
        Assert.AreEqual('Business Central', ProductName.Short(), 'ProductName.Short');
        Assert.AreEqual('Microsoft Dynamics 365 Business Central', ProductName.Marketing(), 'ProductName.Marketing');
        Assert.AreEqual(1033, GlobalLanguage(), 'GlobalLanguage');
        Assert.IsFalse(TaskScheduler.CanCreateTask(), 'TaskScheduler.CanCreateTask');
        Assert.AreEqual('NAV', Session.ApplicationIdentifier(), 'ApplicationIdentifier');
        Assert.AreEqual('Normal', Format(Session.GetCurrentModuleExecutionContext()), 'GetCurrentModuleExecutionContext');
        Assert.AreEqual('Normal', Format(Session.GetExecutionContext()), 'GetExecutionContext');
        Assert.AreEqual('Standard', Format(CurrentExecutionMode()), 'CurrentExecutionMode');
        Assert.IsTrue(SessionId() > 0, 'SessionId');
        Assert.IsTrue(ServiceInstanceId() > 0, 'ServiceInstanceId');
        NavApp.GetCurrentModuleInfo(ModuleInfo);
        Assert.AreEqual('AL Language Coverage Tests', ModuleInfo.Name(), 'module name');
        Assert.AreEqual('AL Language', ModuleInfo.Publisher(), 'module publisher');
    end;

    local procedure TestLibrariesInstalled(): Boolean
    var
        InstalledApp: Record "NAV App Installed App";
    begin
        // "Tests-TestLibraries" (Microsoft, app id below) holds the codeunit "Backup Management" (130011).
        // It is subscribed to GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup and sets all
        // four flags to true for every table with an id in 1..99999 and 150000..1999999999 (so for the
        // tables of this app) whenever a company is open. A full local bc-linux container has the app; a
        // container with a selective app set (the CI one) does not.
        exit(InstalledApp.Get('{5D86850B-0D76-4ECA-BD7B-951AD998E997}'));
    end;

    local procedure YesNo(Value: Boolean): Text
    begin
        if Value then
            exit('Yes');
        exit('No');
    end;

    [Test]
    procedure GlobalTriggers_PlainTable_FlagsAreSetOnlyBySubscribersOfTheOnAfterEvent()
    // CLAIM: Base Application's own subscribers set no flag for a table that nothing configures (no change log, no Dataverse mapping, no API webhook subscription, no data synchronization). The only subscriber that does is Backup Management of the Tests-TestLibraries app, where that app is installed. GetGlobalTableTriggerMask holds 0. OnDatabaseInsert is raised only when a flag is set, and OnGlobalInsert never.
    var
        GtLog: Codeunit "Probe GT Log";
        GtTable: Record "Probe GT Table";
        Flag: Text;
        InsertEvent: Text;
    begin
        Flag := YesNo(TestLibrariesInstalled());
        InsertEvent := '';
        if TestLibrariesInstalled() then
            InsertEvent := 'OnDatabaseInsert(68311);';

        GtTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68311 mask=0);Setup(68311 ins=' + Flag + ' mod=' + Flag + ' del=' + Flag + ' ren=' + Flag + ');', GtLog.Take(), 'the first write to the table asks for the setup once');

        GtTable.Id := 1;
        GtTable.Insert(true);
        Assert.AreEqual(InsertEvent, GtLog.Take(), 'Insert(true)');

        GtTable.Id := 2;
        GtTable.Insert(false);
        Assert.AreEqual(InsertEvent, GtLog.Take(), 'Insert(false)');
    end;

    local procedure ChangeLogSummary(): Text
    var
        ChangeLogEntry: Record "Change Log Entry";
        Result: Text;
    begin
        ChangeLogEntry.SetRange("Table No.", Database::"Probe GT Changelog Table");
        if ChangeLogEntry.FindSet() then
            repeat
                Result += Format(ChangeLogEntry."Type of Change") + ' field ' + Format(ChangeLogEntry."Field No.") + ' [' + ChangeLogEntry."Old Value" + '>' + ChangeLogEntry."New Value" + '];';
            until ChangeLogEntry.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure GlobalTriggers_ChangeLogSetup_LogsOnlyTheKindsOfChangeTheTableIsSetUpFor()
    // CLAIM: Base Application's GlobalTriggerManagement.GetDatabaseTableTriggerSetup calls "Change Log Management".GetDatabaseTableTriggerSetup in the Normal execution context. With "Change Log Setup"."Change Log Activated" and a "Change Log Setup (Table)" row, that call turns on the database event for each kind of change whose log column is not blank, and the change log then writes entries only for those kinds: here Log Insertion and Log Deletion are All Fields and Log Modification is blank, so an insert and a delete write entries and a modify writes none. "Change Log Management" is SingleInstance and caches the setup for the session, so the test calls InitChangeLog after changing it (without that call no entry is written). The flags a Global Triggers subscriber is handed are NOT pinned for this table: the CI run handed No on every flag even with the setup in place, which fits the cache above (the platform asks once per table and the cached setup was still the inactive one), and the local run handed Yes only because Tests-TestLibraries sets every flag there. The entries do not depend on either.
    var
        GtTable: Record "Probe GT Changelog Table";
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
        ChangeLogEntry: Record "Change Log Entry";
        ChangeLogMgt: Codeunit "Change Log Management";
        GtLog: Codeunit "Probe GT Log";
        AfterInsert: Text;
        AfterModify: Text;
        AfterDelete: Text;
    begin
        // The original change log setup is put back at the end.
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert();
        end;
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify();
        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := Database::"Probe GT Changelog Table";
        ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"All Fields";
        ChangeLogSetupTable."Log Deletion" := ChangeLogSetupTable."Log Deletion"::"All Fields";
        ChangeLogSetupTable.Insert();
        Commit();
        // "Change Log Management" is SingleInstance and keeps the setup it read first for the whole session;
        // InitChangeLog drops that cache (the Change Log Setup pages call it after a change).
        ChangeLogMgt.InitChangeLog();

        ChangeLogEntry.SetRange("Table No.", Database::"Probe GT Changelog Table");
        ChangeLogEntry.DeleteAll();
        GtTable.DeleteAll();
        Commit();

        GtTable.Id := 1;
        GtTable.Txt := 'a';
        GtTable.Insert(true);
        AfterInsert := ChangeLogSummary();
        GtTable.Txt := 'b';
        GtTable.Modify(true);
        AfterModify := ChangeLogSummary();
        GtTable.Delete(true);
        AfterDelete := ChangeLogSummary();

        // Put the change log back the way it was.
        ChangeLogEntry.DeleteAll();
        ChangeLogSetupTable.Get(Database::"Probe GT Changelog Table");
        ChangeLogSetupTable.Delete();
        ChangeLogSetup.Get();
        ChangeLogSetup."Change Log Activated" := false;
        ChangeLogSetup.Modify();
        Commit();
        ChangeLogMgt.InitChangeLog();
        GtLog.Take();

        Assert.AreEqual('Insertion field 1 [>1];Insertion field 2 [>a];', AfterInsert, 'after the insert');
        Assert.AreEqual(AfterInsert, AfterModify, 'a modify adds no entry');
        Assert.AreEqual('Insertion field 1 [>1];Insertion field 2 [>a];Deletion field 1 [1>];Deletion field 2 [b>];', AfterDelete, 'after the delete');
    end;

    [Test]
    procedure GlobalTriggers_SubscriberSetsInsertFlag_RaisesOnDatabaseInsertForBothInsertForms()
    // CLAIM: a subscriber of Codeunit "Global Triggers".GetDatabaseTableTriggerSetup that sets OnDatabaseInsert makes the platform raise OnDatabaseInsert for Insert(true) and Insert(false). The flags it was handed are the ones the other subscribers left (see the plain table test).
    var
        GtLog: Codeunit "Probe GT Log";
        GtTable: Record "Probe GT Own Table";
        Flag: Text;
    begin
        Flag := YesNo(TestLibrariesInstalled());

        GtTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68315 mask=0);Setup(68315 ins=' + Flag + ' mod=' + Flag + ' del=' + Flag + ' ren=' + Flag + ');', GtLog.Take(), 'flags handed to the subscriber');

        GtTable.Id := 1;
        GtTable.Insert(true);
        Assert.AreEqual('OnDatabaseInsert(68315);', GtLog.Take(), 'Insert(true)');

        GtTable.Id := 2;
        GtTable.Insert(false);
        Assert.AreEqual('OnDatabaseInsert(68315);', GtLog.Take(), 'Insert(false)');
    end;

    [Test]
    procedure GlobalTriggers_TemporaryRecord_RaisesNoDatabaseEventAndAsksNoSetup()
    // CLAIM: writes to a temporary record neither ask for the table's trigger setup nor raise OnDatabaseInsert, also after a write to the real table has asked for the setup and a subscriber enabled the insert flag.
    var
        GtLog: Codeunit "Probe GT Log";
        TempTable: Record "Probe GT Temp Table" temporary;
        RealTable: Record "Probe GT Temp Table";
        Flag: Text;
    begin
        GtLog.Take();

        TempTable.DeleteAll();
        TempTable.Id := 1;
        TempTable.Insert(true);
        Assert.AreEqual('', GtLog.Take(), 'a temporary record asks nothing and raises nothing');

        Flag := YesNo(TestLibrariesInstalled());
        RealTable.DeleteAll();
        Commit();
        Assert.AreEqual('Mask(68316 mask=0);Setup(68316 ins=' + Flag + ' mod=' + Flag + ' del=' + Flag + ' ren=' + Flag + ');', GtLog.Take(), 'the real table asks once');

        TempTable.Id := 2;
        TempTable.Insert(true);
        TempTable.Id := 3;
        TempTable.Insert(false);
        Assert.AreEqual('', GtLog.Take(), 'no event for a temporary record although the insert flag is set');

        RealTable.Id := 1;
        RealTable.Insert();
        Assert.AreEqual('OnDatabaseInsert(68316);', GtLog.Take(), 'the real table does raise it');
    end;
}
