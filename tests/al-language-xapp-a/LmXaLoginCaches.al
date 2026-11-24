// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Probe (al-runner issue 8945; tests: tests/al-language/events/platform-triggers/LmLoginCacheTests.al and
//   tests/al-language-testlibraries/test-framework/login-caches/LmLoginCacheTlTests.al): what load-once caches hold after login
//   subscribers of a dependency app (XApp A) filled them, and whether a test's later read sees the login's value.
//   - L1 "LT LM XA L1 Memo": reached only through the integration events of the wrapper 98459 (LmXaMemoShapes.al). Its setup table is
//     EMPTY. The setup ask sets Checked and Activated (false) and exits. The write event path does not check Activated: on its first
//     event it sets Loaded, empties the temporary setup copy, Clear()s a second temporary record and sets a filter on it, copies the
//     (empty) rows, then calls TempSetup.Get(TableId) on the empty copy, which fails.
//   - E1: two login subscribers of this app in ascending id order: the first calls Environment Information.IsSandbox(), the second
//     IsSaaS(). Each keeps the value it got.
//   - M1 and M2: one login subscriber reads the application areas (Application Area Mgmt. Facade, which fills Application Area Cache)
//     and the current profile (Conf./Personalization Mgt. GetCurrentProfileNoError, which fills its fetched profile), and keeps both.
//   - M3: the login's first writes load Change Log Management (inactive setup). A later login subscriber activates the change log
//     with triggers and the last one puts the setup back the way it was, so every session starts with the same setup.
//   The login subscribers write only when GuiAllowed() is true, like those of LmXaMemoShapes.al. Object ids of the writing login
//   subscribers (98478, 98479) lie above 98465-98467 so 98465 stays the first partner write of the login.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

table 98420 "LT LM XA L1 Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Table Id"; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys { key(PK; "Table Id") { Clustered = true; } }
}

table 98421 "LT LM XA L1 Sub"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Company Name"; Text[30]) { }
    }

    keys { key(PK; "Code", "Company Name") { Clustered = true; } }
}

// singleinstance-shared-on-purpose: the wrapper's events fill it; the corpus app's reader reads it for both test apps.
codeunit 98422 "LT LM XA L1 Memo"
{
    SingleInstance = true;

    var
        TempSetup: Record "LT LM XA L1 Setup" temporary;
        TempSub: Record "LT LM XA L1 Sub" temporary;
        Checked: Boolean;
        Activated: Boolean;
        Loaded: Boolean;
        LoadTable: Integer;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA Wrapper", 'OnWrapperSetup', '', false, false)]
    local procedure WrapperSetup(TableId: Integer; var WatchInsert: Boolean; var WatchModify: Boolean)
    var
        Setup: Record "LT LM XA L1 Setup";
    begin
        if not Checked then begin
            Checked := true;
            Activated := not Setup.IsEmpty();
        end;
        if not Activated then
            exit;
        if TempSetup.Get(TableId) then begin
            WatchInsert := true;
            WatchModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA Wrapper", 'OnWrapperWrite', '', false, false)]
    local procedure WrapperWrite(Kind: Text; TableId: Integer)
    begin
        if not Loaded then begin
            Loaded := true;
            LoadTable := TableId;
            LoadTemps();
        end;
        if not TempSetup.Get(TableId) then
            exit;
        Written += Kind + Format(TableId) + ';';
    end;

    local procedure LoadTemps()
    var
        Setup: Record "LT LM XA L1 Setup";
        Sub: Record "LT LM XA L1 Sub";
    begin
        TempSetup.DeleteAll();
        if Setup.FindSet() then
            repeat
                TempSetup := Setup;
                TempSetup.Insert();
            until Setup.Next() = 0;
        Clear(TempSub);
        TempSub.SetFilter("Company Name", '=%1', '');
        Sub.SetFilter("Company Name", '=%1', '');
        if Sub.FindSet() then
            repeat
                TempSub := Sub;
                TempSub.Insert();
            until Sub.Next() = 0;
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure RawLoaded(): Text
    begin
        exit(Format(Loaded));
    end;

    procedure RawLoadTable(): Integer
    begin
        exit(LoadTable);
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;

    // Reads the globals without moving them: the current record's key and the row counts through copies.
    procedure RawSetupKey(): Integer
    begin
        exit(TempSetup."Table Id");
    end;

    procedure RawSetupNote(): Text
    begin
        exit(TempSetup.Note);
    end;

    procedure RawSetupFilters(): Text
    begin
        exit(TempSetup.GetFilters());
    end;

    procedure RawSetupRows(): Integer
    var
        Copy: Record "LT LM XA L1 Setup" temporary;
    begin
        Copy.Copy(TempSetup, true);
        Copy.Reset();
        exit(Copy.Count());
    end;

    procedure RawSubFilters(): Text
    begin
        exit(TempSub.GetFilters());
    end;

    procedure RawSubKey(): Text
    begin
        exit(TempSub.Code + '|' + TempSub."Company Name");
    end;

    procedure RawSubRows(): Integer
    var
        Copy: Record "LT LM XA L1 Sub" temporary;
    begin
        Copy.Copy(TempSub, true);
        Copy.Reset();
        exit(Copy.Count());
    end;

    procedure RawSubRowsInView(): Integer
    begin
        exit(TempSub.Count());
    end;
}

// singleinstance-shared-on-purpose: the login subscribers below fill it; the corpus app's reader reads it for both test apps.
codeunit 98423 "LT LM XA Cache Snap"
{
    SingleInstance = true;

    var
        SandboxAtLogin: Text;
        SaasAtLogin: Text;
        AreasAtLogin: Text;
        ProfileAtLogin: Text;
        ProfileFoundAtLogin: Text;
        ChangeLogInserted: Boolean;
        ChangeLogWasActive: Boolean;
        ChangeLogTouched: Boolean;
        ChangeLogRestored: Text;

    procedure SetSandbox(Value: Boolean)
    begin
        SandboxAtLogin := Format(Value);
    end;

    procedure SetSaas(Value: Boolean)
    begin
        SaasAtLogin := Format(Value);
    end;

    procedure SetAreas(Value: Text)
    begin
        AreasAtLogin := Value;
    end;

    procedure SetProfile(Value: Text; Found: Boolean)
    begin
        ProfileAtLogin := Value;
        ProfileFoundAtLogin := Format(Found);
    end;

    procedure SetChangeLogTouched(Inserted: Boolean; WasActive: Boolean)
    begin
        ChangeLogTouched := true;
        ChangeLogInserted := Inserted;
        ChangeLogWasActive := WasActive;
    end;

    procedure ChangeLogWasTouched(var Inserted: Boolean; var WasActive: Boolean): Boolean
    begin
        Inserted := ChangeLogInserted;
        WasActive := ChangeLogWasActive;
        exit(ChangeLogTouched);
    end;

    procedure SetChangeLogRestored(Value: Text)
    begin
        ChangeLogRestored := Value;
    end;

    procedure RawSandbox(): Text
    begin
        exit(SandboxAtLogin);
    end;

    procedure RawSaas(): Text
    begin
        exit(SaasAtLogin);
    end;

    procedure RawAreas(): Text
    begin
        exit(AreasAtLogin);
    end;

    procedure RawProfile(): Text
    begin
        exit(ProfileAtLogin);
    end;

    procedure RawProfileFound(): Text
    begin
        exit(ProfileFoundAtLogin);
    end;

    procedure RawChangeLogRestored(): Text
    begin
        exit(ChangeLogRestored);
    end;
}

// E1, first of two: the Sandbox pair of Environment Information Impl.
codeunit 98424 "LT LM XA Login Sandbox"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Snap: Codeunit "LT LM XA Cache Snap";
    begin
        Snap.SetSandbox(EnvironmentInformation.IsSandbox());
    end;
}

// E1, second of two: the SaaS pair.
codeunit 98425 "LT LM XA Login Saas"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Snap: Codeunit "LT LM XA Cache Snap";
    begin
        Snap.SetSaas(EnvironmentInformation.IsSaaS());
    end;
}

// M1 and M2: reads the application areas and the current profile at login.
codeunit 98469 "LT LM XA Login Caches"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        AllProfile: Record "All Profile";
        ApplicationAreaMgmtFacade: Codeunit "Application Area Mgmt. Facade";
        ConfPersonalizationMgt: Codeunit "Conf./Personalization Mgt.";
        Snap: Codeunit "LT LM XA Cache Snap";
        Found: Boolean;
    begin
        Snap.SetAreas(ApplicationAreaMgmtFacade.GetApplicationAreaSetup());
        Found := ConfPersonalizationMgt.GetCurrentProfileNoError(AllProfile);
        Snap.SetProfile(AllProfile."Profile ID", Found);
    end;
}

// M3: activates the change log with triggers, after the login's first writes loaded Change Log Management.
codeunit 98478 "LT LM XA Login ChangeLog On"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        ChangeLogSetup: Record "Change Log Setup";
        Snap: Codeunit "LT LM XA Cache Snap";
    begin
        if not GuiAllowed() then
            exit;
        if CompanyName() = '' then
            exit;
        if not ChangeLogSetup.Get() then begin
            Snap.SetChangeLogTouched(true, false);
            ChangeLogSetup.Init();
            ChangeLogSetup."Change Log Activated" := true;
            ChangeLogSetup.Insert(true);
            exit;
        end;
        Snap.SetChangeLogTouched(false, ChangeLogSetup."Change Log Activated");
        ChangeLogSetup."Change Log Activated" := true;
        ChangeLogSetup.Modify(true);
    end;
}

// M3: puts the change log setup back the way 98478 found it.
codeunit 98479 "LT LM XA Login ChangeLog Off"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        ChangeLogSetup: Record "Change Log Setup";
        Snap: Codeunit "LT LM XA Cache Snap";
        Inserted: Boolean;
        WasActive: Boolean;
    begin
        if not Snap.ChangeLogWasTouched(Inserted, WasActive) then
            exit;
        if not ChangeLogSetup.Get() then
            exit;
        if Inserted then begin
            ChangeLogSetup.Delete(true);
            Snap.SetChangeLogRestored('deleted');
            exit;
        end;
        ChangeLogSetup."Change Log Activated" := WasActive;
        ChangeLogSetup.Modify(true);
        Snap.SetChangeLogRestored('modified');
    end;
}
