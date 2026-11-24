// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/LmXaLoginCaches.al (L1 setup 98420, L1 sub 98421, L1 memo
//   98422, login snapshot 98423, OnAfterLogin subscribers 98424, 98425, 98469, 98478, 98479) and the wrapper 98459 of
//   tests/al-language-xapp-a/LmXaMemoShapes.al; tables 97700-97703 and codeunits 97704-97708 of this app (below). The same reader runs
//   in the Tests-TestLibraries job: tests/al-language-testlibraries/test-framework/login-caches/LmLoginCacheTlTests.al.
// Probe (al-runner issue 8945): load-once caches that login subscribers of a dependency app fill, and what a test reads later.
//   L1. A partner memo reached through a wrapper's integration events, setup table empty: the ask sets Checked and Activated (false);
//       the first write event sets Loaded, loads the empty setup into a temporary record, Clear()s a second temporary record and filters
//       it on an empty Company Name, then calls Get(TableId) on the empty setup copy. Read: the Booleans, the temporary records' current
//       key, filters and row counts; then the test adds a setup row and writes a table it names.
//   E1. Environment Information Impl. filled by two login subscribers of one app (IsSandbox, then IsSaaS): the test's reads against
//       the values the subscribers got.
//   M1. Application Area Cache filled at login: the test's read against the login's; then the test adds a user row to Application
//       Area Setup (rolled back) and reads again.
//   M2. Conf./Personalization Mgt. filled at login: the test's read against the login's; then the test changes the user's User
//       Personalization row (rolled back) and reads again.
//   M3. Change Log Management loaded inactive by the login's first writes; a later login subscriber activates the change log with
//       triggers and the last one puts it back. The test activates the setup without InitChangeLog, adds a Change Log Setup (Table) row
//       for a table and inserts into it; then calls InitChangeLog and does the same for a second table (all rolled back).
//   M4. API Webhook Notification Mgt.: whether a test's database insert asks Graph Mgt - General Tools for the API subscription
//       setting again (counted by a bound subscriber of OnGetAPISubscriptionsEnabled), with a bound subscriber that answers the value
//       and one that does not; Reset() as the control.
// Measured on a local BC 29.0 with Tests-TestLibraries installed (the shape of the Tests-TestLibraries job), in both kinds of session
//   (the first table asked is "User Login" 9008, or the first partner write 98455), hub and websocket runners. Same values in both kinds.
//   The plain job (no Backup Management) is measured by the CI matrix.
// BC result:
//   L1: Checked Yes, Activated No, Loaded Yes; the setup copy holds 0 rows, no filter and key 0 after the failed Get (also when the
//       load came from 9008: the failed Get leaves the key at its initial value, not the asked id); the second temporary record holds
//       0 rows, keeps the filter "Company Name: ''" and an empty key. A setup row the test adds is not seen: the test's write is not
//       noted (the load ran once). Same in the second codeunit.
//   E1: both subscribers keep a value; the test's IsSandbox() and IsSaaS() equal the values they got.
//   M1: the test reads the login's areas. After the test adds a user row the read gives the new areas (the insert event clears the
//       cache). After the rollback the cache still holds the rolled-back areas (a read differs from the login's) until the next
//       Application Area Setup event clears it.
//   M2: the test reads the login's profile; after the test changes its User Personalization row the read still gives the login's
//       profile (the fetched profile is kept for the session).
//   M3: activating the setup without InitChangeLog logs nothing for a table set up for insertion (0 entries); after InitChangeLog
//       the insert into a second table set up the same way writes 2 entries.
//   M4: the test's inserts do not ask for the subscription setting (the login's database events loaded the cache), with an answering
//       subscriber and with a counting one; after Reset() the next insert asks once and the one after does not.
// BC versions: 27 - 29

table 97700 "LT LM L1 Watched"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 97701 "LT LM CL Probe"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 97702 "LT LM CL Control"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 97703 "LT LM API Probe"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// Turns on the insert event of "LT LM API Probe" only, so its inserts reach API Webhook Notification Mgt. in every job.
codeunit 97704 "LT LM API Setup Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId = Database::"LT LM API Probe" then
            OnDatabaseInsert := true;
    end;
}

// Bound by the M4 tests: answers IsApiEnabled (so the subscription setting is asked) and counts the asks for the subscription setting.
codeunit 97705 "LT LM API Bound"
{
    EventSubscriberInstance = Manual;

    var
        Asks: Integer;
        Answer: Boolean;

    procedure SetAnswer(NewAnswer: Boolean)
    begin
        Answer := NewAnswer;
    end;

    procedure TakeAsks(): Text
    var
        Result: Integer;
    begin
        Result := Asks;
        Asks := 0;
        exit(Format(Result));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetIsAPIEnabled', '', false, false)]
    local procedure IsApiEnabled(var Handled: Boolean; var IsAPIEnabled: Boolean)
    begin
        Handled := true;
        IsAPIEnabled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Graph Mgt - General Tools", 'OnGetAPISubscriptionsEnabled', '', false, false)]
    local procedure SubscriptionsEnabled(var Handled: Boolean; var APISubscriptionsEnabled: Boolean)
    begin
        Asks += 1;
        if Answer then begin
            Handled := true;
            APISubscriptionsEnabled := false;
        end;
    end;
}

codeunit 97706 "LT LM Cache Reader"
{
    procedure ObserveL1(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA L1 Memo";
    begin
        Observer.Observe(Prefix + 'L1 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'L1 activated', Memo.RawActivated());
        Observer.Observe(Prefix + 'L1 loaded', Memo.RawLoaded());
        Observer.Observe(Prefix + 'L1 setup rows', Format(Memo.RawSetupRows()));
        Observer.Observe(Prefix + 'L1 setup filters', Memo.RawSetupFilters());
        Observer.Observe(Prefix + 'L1 setup key', Format(Memo.RawSetupKey()));
        Observer.Observe(Prefix + 'L1 setup key is the load table', Format(Memo.RawSetupKey() = Memo.RawLoadTable()));
        Observer.Observe(Prefix + 'L1 setup note', Memo.RawSetupNote());
        Observer.Observe(Prefix + 'L1 sub rows', Format(Memo.RawSubRows()));
        Observer.Observe(Prefix + 'L1 sub rows in view', Format(Memo.RawSubRowsInView()));
        Observer.Observe(Prefix + 'L1 sub filters', Memo.RawSubFilters());
        Observer.Observe(Prefix + 'L1 sub key', Memo.RawSubKey());
        Observer.Observe(Prefix + 'L1 written', Memo.RawWritten());
    end;

    procedure L1AddSetupAndWrite(var Observer: Codeunit "Probe Observer")
    var
        Setup: Record "LT LM XA L1 Setup";
        Watched: Record "LT LM L1 Watched";
    begin
        Setup.DeleteAll();
        Watched.DeleteAll();
        Setup.Init();
        Setup."Table Id" := Database::"LT LM L1 Watched";
        Setup.Insert();
        Watched.Init();
        Watched.Tag := 'W1';
        Watched.Insert();
        ObserveL1(Observer, 'after setup row: ');
        Setup.DeleteAll();
        Watched.DeleteAll();
    end;

    procedure ObserveEnv(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Snap: Codeunit "LT LM XA Cache Snap";
    begin
        Observer.Observe(Prefix + 'E1 sandbox kept by the first subscriber', Format(Snap.RawSandbox() <> ''));
        Observer.Observe(Prefix + 'E1 saas kept by the second subscriber', Format(Snap.RawSaas() <> ''));
        Observer.Observe(Prefix + 'E1 IsSandbox equals the login value', Format(Format(EnvironmentInformation.IsSandbox()) = Snap.RawSandbox()));
        Observer.Observe(Prefix + 'E1 IsSaaS equals the login value', Format(Format(EnvironmentInformation.IsSaaS()) = Snap.RawSaas()));
    end;

    procedure ObserveAreas(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        Snap: Codeunit "LT LM XA Cache Snap";
    begin
        Observer.Observe(Prefix + 'M1 areas equal the login value', Format(ApplicationAreaMgmtFacade.GetApplicationAreaSetup() = Snap.RawAreas()));
    end;

    procedure AreasChange(var Observer: Codeunit "Probe Observer")
    var
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        Snap: Codeunit "LT LM XA Cache Snap";
        Changed: Text;
    begin
        // A user row of Application Area Setup with only Basic, against the login's areas; rolled back by the error.
        asserterror begin
            AddUserAreaRow();
            Changed := ApplicationAreaMgmtFacade.GetApplicationAreaSetup();
            Error('LT LM rollback');
        end;
        Observer.Observe('M1 change rolled back', GetLastErrorText());
        Observer.Observe('M1 read after the change differs from the login value', Format(Changed <> Snap.RawAreas()));
        Observer.Observe('M1 read after the change', Changed);
        Observer.Observe('M1 read after the rollback equals the login value', Format(ApplicationAreaMgmtFacade.GetApplicationAreaSetup() = Snap.RawAreas()));
        // Clears the cache again (insert event of Application Area Setup), rolled back, so later tests read the database's areas.
        asserterror begin
            AddCompanyAreaRow();
            Error('LT LM rollback');
        end;
        Observer.Observe('M1 read after the clear equals the login value', Format(ApplicationAreaMgmtFacade.GetApplicationAreaSetup() = Snap.RawAreas()));
    end;

    local procedure AddUserAreaRow()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        if ApplicationAreaSetup.Get('', '', UserId()) then
            ApplicationAreaSetup.Delete();
        ApplicationAreaSetup.Init();
        ApplicationAreaSetup."User ID" := CopyStr(UserId(), 1, MaxStrLen(ApplicationAreaSetup."User ID"));
        ApplicationAreaSetup.Basic := true;
        ApplicationAreaSetup.Insert();
    end;

    local procedure AddCompanyAreaRow()
    var
        ApplicationAreaSetup: Record "Application Area Setup";
    begin
        ApplicationAreaSetup.Init();
        ApplicationAreaSetup."Company Name" := 'LT LM NO COMPANY';
        ApplicationAreaSetup.Basic := true;
        if ApplicationAreaSetup.Insert() then;
    end;

    procedure ObserveProfile(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        AllProfile: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Snap: Codeunit "LT LM XA Cache Snap";
        Found: Boolean;
    begin
        Found := ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        Observer.Observe(Prefix + 'M2 profile equals the login value', Format(AllProfile."Profile ID" = Snap.RawProfile()));
        Observer.Observe(Prefix + 'M2 found equals the login value', Format(Format(Found) = Snap.RawProfileFound()));
    end;

    procedure ProfileChange(var Observer: Codeunit "Probe Observer")
    var
        AllProfile: Record "All Profile";
        Other: Record "All Profile";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Snap: Codeunit "LT LM XA Cache Snap";
        HasOther: Boolean;
        ReadProfile: Text;
    begin
        Other.SetFilter("Profile ID", '<>%1', Snap.RawProfile());
        HasOther := Other.FindFirst();
        Observer.Observe('M2 another profile exists', Format(HasOther));
        if not HasOther then
            exit;
        // The user's User Personalization row names another profile; rolled back by the error.
        asserterror begin
            SetUserProfile(Other);
            ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
            ReadProfile := AllProfile."Profile ID";
            Error('LT LM rollback');
        end;
        Observer.Observe('M2 change rolled back', GetLastErrorText());
        Observer.Observe('M2 read after the change equals the login value', Format(ReadProfile = Snap.RawProfile()));
        Observer.Observe('M2 read after the change is the other profile', Format(ReadProfile = Other."Profile ID"));
    end;

    local procedure SetUserProfile(AllProfile: Record "All Profile")
    var
        UserPersonalization: Record "User Personalization";
    begin
        if UserPersonalization.Get(UserSecurityId()) then begin
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Modify();
        end else begin
            UserPersonalization.Init();
            UserPersonalization."User SID" := UserSecurityId();
            UserPersonalization."Profile ID" := AllProfile."Profile ID";
            UserPersonalization.Scope := AllProfile.Scope;
            UserPersonalization."App ID" := AllProfile."App ID";
            UserPersonalization.Insert();
        end;
    end;

    procedure ObserveChangeLog(var Observer: Codeunit "Probe Observer")
    var
        ChangeLogMgt: Codeunit "Change Log Management";
        Snap: Codeunit "LT LM XA Cache Snap";
        Stale: Text;
        Control: Text;
    begin
        Observer.Observe('M3 login put the setup back', Format(Snap.RawChangeLogRestored() <> ''));
        asserterror begin
            ActivateFor(Database::"LT LM CL Probe");
            ActivateFor(Database::"LT LM CL Control");
            InsertProbe(Database::"LT LM CL Probe");
            Stale := Format(EntryCount(Database::"LT LM CL Probe"));
            ChangeLogMgt.InitChangeLog();
            InsertProbe(Database::"LT LM CL Control");
            Control := Format(EntryCount(Database::"LT LM CL Control"));
            Error('LT LM rollback');
        end;
        Observer.Observe('M3 change rolled back', GetLastErrorText());
        // Read the rolled-back (inactive) setup again, so later tests of the session log nothing.
        ChangeLogMgt.InitChangeLog();
        Observer.Observe('M3 entries without InitChangeLog', Stale);
        Observer.Observe('M3 entries after InitChangeLog', Control);
    end;

    local procedure ActivateFor(TableId: Integer)
    var
        ChangeLogSetup: Record "Change Log Setup";
        ChangeLogSetupTable: Record "Change Log Setup (Table)";
    begin
        if not ChangeLogSetup.Get() then begin
            ChangeLogSetup.Init();
            ChangeLogSetup.Insert();
        end;
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify();
        if ChangeLogSetupTable.Get(TableId) then
            ChangeLogSetupTable.Delete();
        ChangeLogSetupTable.Init();
        ChangeLogSetupTable."Table No." := TableId;
        ChangeLogSetupTable."Log Insertion" := ChangeLogSetupTable."Log Insertion"::"All Fields";
        ChangeLogSetupTable.Insert();
    end;

    local procedure InsertProbe(TableId: Integer)
    var
        ClProbe: Record "LT LM CL Probe";
        ClControl: Record "LT LM CL Control";
    begin
        if TableId = Database::"LT LM CL Probe" then begin
            ClProbe.DeleteAll();
            ClProbe."Entry No." := 1;
            ClProbe.Tag := 'P1';
            ClProbe.Insert();
        end else begin
            ClControl.DeleteAll();
            ClControl."Entry No." := 1;
            ClControl.Tag := 'C1';
            ClControl.Insert();
        end;
    end;

    local procedure EntryCount(TableId: Integer): Integer
    var
        ChangeLogEntry: Record "Change Log Entry";
    begin
        ChangeLogEntry.SetRange("Table No.", TableId);
        exit(ChangeLogEntry.Count());
    end;

    // M4: Answer = true binds a subscriber that answers the subscription setting (false); otherwise it only counts.
    procedure ObserveApi(var Observer: Codeunit "Probe Observer"; Prefix: Text; Answer: Boolean)
    var
        ApiProbe: Record "LT LM API Probe";
        Bound: Codeunit "LT LM API Bound";
        APIWebhookNotificationMgt: Codeunit "API Webhook Notification Mgt.";
    begin
        Bound.SetAnswer(Answer);
        BindSubscription(Bound);
        ApiProbe.DeleteAll();
        Bound.TakeAsks();
        InsertApi(1);
        Observer.Observe(Prefix + 'M4 asks on the first insert', Bound.TakeAsks());
        InsertApi(2);
        Observer.Observe(Prefix + 'M4 asks on the second insert', Bound.TakeAsks());
        APIWebhookNotificationMgt.Reset();
        InsertApi(3);
        Observer.Observe(Prefix + 'M4 asks on the insert after Reset', Bound.TakeAsks());
        InsertApi(4);
        Observer.Observe(Prefix + 'M4 asks on the next insert', Bound.TakeAsks());
        UnbindSubscription(Bound);
        // Load the cache again without the bound subscriber, as the login did, for the later tests of the session.
        APIWebhookNotificationMgt.Reset();
        InsertApi(5);
        ApiProbe.DeleteAll();
    end;

    local procedure InsertApi(EntryNo: Integer)
    var
        ApiProbe: Record "LT LM API Probe";
    begin
        ApiProbe.Init();
        ApiProbe."Entry No." := EntryNo;
        ApiProbe.Tag := 'A' + Format(EntryNo);
        ApiProbe.Insert();
    end;
}

codeunit 97707 "LT LM Login Cache Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure L1Memo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveL1(Observer, '');
        Observer.Expect('L1 checked', 'Yes');
        Observer.Expect('L1 activated', 'No');
        Observer.Expect('L1 loaded', 'Yes');
        Observer.Expect('L1 setup rows', '0');
        Observer.Expect('L1 setup filters', '');
        Observer.Expect('L1 setup key', '0');
        Observer.Expect('L1 setup key is the load table', 'No');
        Observer.Expect('L1 setup note', '');
        Observer.Expect('L1 sub rows', '0');
        Observer.Expect('L1 sub rows in view', '0');
        Observer.Expect('L1 sub filters', 'Company Name: ''''');
        Observer.Expect('L1 sub key', '|');
        Observer.Expect('L1 written', '');
        Observer.Verify();
    end;

    [Test]
    procedure EnvInfo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveEnv(Observer, '');
        Observer.Expect('E1 sandbox kept by the first subscriber', 'Yes');
        Observer.Expect('E1 saas kept by the second subscriber', 'Yes');
        Observer.Expect('E1 IsSandbox equals the login value', 'Yes');
        Observer.Expect('E1 IsSaaS equals the login value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure AppAreas_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveAreas(Observer, '');
        Reader.AreasChange(Observer);
        Observer.Expect('M1 areas equal the login value', 'Yes');
        Observer.Expect('M1 change rolled back', 'LT LM rollback');
        Observer.Expect('M1 read after the change differs from the login value', 'Yes');
        Observer.Expect('M1 read after the change', '#Basic');
        Observer.Expect('M1 read after the rollback equals the login value', 'No');
        Observer.Expect('M1 read after the clear equals the login value', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Profile_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveProfile(Observer, '');
        Reader.ProfileChange(Observer);
        Observer.Expect('M2 profile equals the login value', 'Yes');
        Observer.Expect('M2 found equals the login value', 'Yes');
        Observer.Expect('M2 another profile exists', 'Yes');
        Observer.Expect('M2 change rolled back', 'LT LM rollback');
        Observer.Expect('M2 read after the change equals the login value', 'Yes');
        Observer.Expect('M2 read after the change is the other profile', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ChangeLog_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveChangeLog(Observer);
        Observer.Expect('M3 login put the setup back', 'Yes');
        Observer.Expect('M3 change rolled back', 'LT LM rollback');
        Observer.Expect('M3 entries without InitChangeLog', '0');
        Observer.Expect('M3 entries after InitChangeLog', '2');
        Observer.Verify();
    end;

    [Test]
    procedure ApiCache_CountingSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveApi(Observer, '', false);
        Observer.Expect('M4 asks on the first insert', '0');
        Observer.Expect('M4 asks on the second insert', '0');
        Observer.Expect('M4 asks on the insert after Reset', '1');
        Observer.Expect('M4 asks on the next insert', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ApiCache_AnsweringSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveApi(Observer, '', true);
        Observer.Expect('M4 asks on the first insert', '0');
        Observer.Expect('M4 asks on the second insert', '0');
        Observer.Expect('M4 asks on the insert after Reset', '1');
        Observer.Expect('M4 asks on the next insert', '0');
        Observer.Verify();
    end;

    // Runs last in this codeunit: the test adds a setup row and writes the table it names.
    [Test]
    procedure L1Memo_TestAddsSetupRow()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.L1AddSetupAndWrite(Observer);
        Observer.Expect('after setup row: L1 checked', 'Yes');
        Observer.Expect('after setup row: L1 activated', 'No');
        Observer.Expect('after setup row: L1 loaded', 'Yes');
        Observer.Expect('after setup row: L1 setup rows', '0');
        Observer.Expect('after setup row: L1 setup filters', '');
        Observer.Expect('after setup row: L1 setup key', '0');
        Observer.Expect('after setup row: L1 setup key is the load table', 'No');
        Observer.Expect('after setup row: L1 setup note', '');
        Observer.Expect('after setup row: L1 sub rows', '0');
        Observer.Expect('after setup row: L1 sub rows in view', '0');
        Observer.Expect('after setup row: L1 sub filters', 'Company Name: ''''');
        Observer.Expect('after setup row: L1 sub key', '|');
        Observer.Expect('after setup row: L1 written', '');
        Observer.Verify();
    end;
}

// The first test of a second codeunit in the same session.
codeunit 97708 "LT LM Login Cache Tests B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AllCaches_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Cache Reader";
    begin
        Reader.ObserveL1(Observer, 'B: ');
        Reader.ObserveEnv(Observer, 'B: ');
        Reader.ObserveAreas(Observer, 'B: ');
        Reader.ObserveProfile(Observer, 'B: ');
        Observer.Expect('B: L1 checked', 'Yes');
        Observer.Expect('B: L1 activated', 'No');
        Observer.Expect('B: L1 loaded', 'Yes');
        Observer.Expect('B: L1 setup rows', '0');
        Observer.Expect('B: L1 setup filters', '');
        Observer.Expect('B: L1 setup key', '0');
        Observer.Expect('B: L1 setup key is the load table', 'No');
        Observer.Expect('B: L1 setup note', '');
        Observer.Expect('B: L1 sub rows', '0');
        Observer.Expect('B: L1 sub rows in view', '0');
        Observer.Expect('B: L1 sub filters', 'Company Name: ''''');
        Observer.Expect('B: L1 sub key', '|');
        Observer.Expect('B: L1 written', '');
        Observer.Expect('B: E1 sandbox kept by the first subscriber', 'Yes');
        Observer.Expect('B: E1 saas kept by the second subscriber', 'Yes');
        Observer.Expect('B: E1 IsSandbox equals the login value', 'Yes');
        Observer.Expect('B: E1 IsSaaS equals the login value', 'Yes');
        Observer.Expect('B: M1 areas equal the login value', 'Yes');
        Observer.Expect('B: M2 profile equals the login value', 'Yes');
        Observer.Expect('B: M2 found equals the login value', 'Yes');
        Observer.Verify();
    end;
}
