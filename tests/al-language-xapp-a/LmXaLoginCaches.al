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
//   - M3: the login's first writes load Change Log Management with the setup inactive. No login subscriber of this app writes the
//     change log setup: it is a Microsoft table, and its writes add Change Log Entry rows that stay (writer rule 12). The test
//     activates the setup itself, inside a rolled-back block.
//   The login subscribers write only when GuiAllowed() is true, like those of LmXaMemoShapes.al.
//   - G3 "LT LM XA G3 Memo A" and "LT LM XA G3 Memo B" (75890, 75891, same code): L1's memo with guards before the latch (an empty
//     company name and the setup table's read permission in the ask; an error-reporting call, an OnBefore event with Handled and
//     Disabled and Loaded by var, the Disabled flag and a temporary record in the write path; an OnBefore event and the read permission
//     in the load). Reached through the relay 75889. The login subscriber 75897 writes no table; it drives Memo B's public entry into
//     the Handled, Disabled and temporary exits, then opens the relay's gate for Memo B, so Memo B loads on a later write than Memo A.
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

// G3: an L1-style load-once memo whose paths carry guards before the latch. Memo A and Memo B hold the same code. Their ask path
// exits on an empty company name and on a missing read permission of the setup table, then sets Checked and Activated. Their write
// path calls an error-reporting codeunit (no write), raises its own OnBefore event with Disabled and Loaded by var, then exits on
// Handled, on Disabled and on a temporary record. Only then does it set Loaded and load the temps (an OnBefore event of the load with
// Handled, the read permission of the setup table, then the L1 copy). Memo A's events have no subscriber. Memo B's events have the
// automatic subscriber "LT LM XA G3 B Handled", and its write events reach it only after the login subscriber 75897 opened the gate
// (the relay checks it): before that, 75897 drives Memo B's public entry once into each of the Handled, Disabled and temporary
// exits. The relay and the recorder note which event loaded each memo.
codeunit 75889 "LT LM XA G3 Relay"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Setup: Record "LT LM XA L1 Setup";
        Recorder: Codeunit "LT LM XA G3 Recorder";
    begin
        Recorder.NoteAsk(CompanyName() = '', Setup.ReadPermission());
        OnG3Setup(TableId, OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        Relay('I', RecRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure AfterModify(RecRef: RecordRef)
    begin
        Relay('M', RecRef);
    end;

    local procedure Relay(Kind: Text; RecRef: RecordRef)
    var
        MemoA: Codeunit "LT LM XA G3 Memo A";
        MemoB: Codeunit "LT LM XA G3 Memo B";
        Recorder: Codeunit "LT LM XA G3 Recorder";
        WasLoaded: Boolean;
    begin
        WasLoaded := MemoA.RawLoaded();
        if Kind = 'I' then
            OnG3InsertA(RecRef)
        else
            OnG3ModifyA(RecRef);
        if MemoA.RawLoaded() and not WasLoaded then
            Recorder.NoteLoadA(Kind + Format(RecRef.Number));
        if not Recorder.GateOpen() then
            exit;
        WasLoaded := MemoB.RawLoaded();
        if Kind = 'I' then
            OnG3InsertB(RecRef)
        else
            OnG3ModifyB(RecRef);
        if MemoB.RawLoaded() and not WasLoaded then
            Recorder.NoteLoadB(Kind + Format(RecRef.Number));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnG3Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnG3InsertA(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnG3ModifyA(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnG3InsertB(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnG3ModifyB(RecRef: RecordRef)
    begin
    end;
}

// singleinstance-shared-on-purpose: the relay's database events fill it; the corpus app's reader reads it for both test apps.
codeunit 75890 "LT LM XA G3 Memo A"
{
    SingleInstance = true;

    var
        TempSetup: Record "LT LM XA L1 Setup" temporary;
        TempSub: Record "LT LM XA L1 Sub" temporary;
        Checked: Boolean;
        Activated: Boolean;
        Loaded: Boolean;
        Disabled: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Relay", 'OnG3Setup', '', false, false)]
    local procedure RelaySetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Setup: Record "LT LM XA L1 Setup";
    begin
        if CompanyName() = '' then
            exit;
        if not Setup.ReadPermission() then
            exit;
        if not Checked then begin
            Checked := true;
            Activated := not Setup.IsEmpty();
        end;
        if not Activated then
            exit;
        if not Loaded then begin
            Loaded := true;
            LoadTemps();
        end;
        if TempSetup.Get(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Relay", 'OnG3InsertA', '', false, false)]
    local procedure RelayInsert(RecRef: RecordRef)
    var
        Reporter: Codeunit "LT LM XA G3 Reporter";
        Span: Codeunit "LT LM XA G3 Span";
    begin
        Reporter.StartSpan(Span, 'g3.on-after-insert:' + RecRef.Name);
        LogInsert(RecRef);
        Span.Finish();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Relay", 'OnG3ModifyA', '', false, false)]
    local procedure RelayModify(RecRef: RecordRef)
    var
        Reporter: Codeunit "LT LM XA G3 Reporter";
        Span: Codeunit "LT LM XA G3 Span";
    begin
        Reporter.StartSpan(Span, 'g3.on-after-modify:' + RecRef.Name);
        LogModify(RecRef);
        Span.Finish();
    end;

    procedure LogInsert(RecRef: RecordRef)
    var
        Handled: Boolean;
    begin
        OnBeforeG3Insert(RecRef, Disabled, Loaded, Handled);
        if Handled then
            exit;
        if Disabled then
            exit;
        if RecRef.IsTemporary() then
            exit;
        if not Loaded then begin
            Loaded := true;
            LoadTemps();
        end;
        if not TempSetup.Get(RecRef.Number) then
            exit;
    end;

    procedure LogModify(RecRef: RecordRef)
    var
        Handled: Boolean;
    begin
        OnBeforeG3Modify(RecRef, Disabled, Loaded, Handled);
        if Handled then
            exit;
        if Disabled then
            exit;
        if RecRef.IsTemporary() then
            exit;
        if not Loaded then begin
            Loaded := true;
            LoadTemps();
        end;
        if not TempSetup.Get(RecRef.Number) then
            exit;
    end;

    procedure SetDisabled(Disable: Boolean)
    begin
        Disabled := Disable;
    end;

    local procedure LoadTemps()
    var
        Setup: Record "LT LM XA L1 Setup";
        Sub: Record "LT LM XA L1 Sub";
        Handled: Boolean;
    begin
        OnBeforeG3Load(TempSetup, TempSub, Handled);
        if Handled then
            exit;
        if not Setup.ReadPermission() then
            exit;
        TempSetup.DeleteAll();
        if Setup.FindSet() then
            repeat
                TempSetup.Init();
                TempSetup := Setup;
                TempSetup.Insert();
            until Setup.Next() = 0;
        Clear(TempSub);
        TempSub.SetFilter("Company Name", '=%1', '');
        if Sub.FindSet() then
            repeat
                TempSub.Init();
                TempSub := Sub;
                TempSub.Insert();
            until Sub.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeG3Insert(RecRef: RecordRef; var Disabled: Boolean; var Loaded: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeG3Modify(RecRef: RecordRef; var Disabled: Boolean; var Loaded: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeG3Load(var TempSetup: Record "LT LM XA L1 Setup" temporary; var TempSub: Record "LT LM XA L1 Sub" temporary; var Handled: Boolean)
    begin
    end;

    procedure RawChecked(): Boolean
    begin
        exit(Checked);
    end;

    procedure RawActivated(): Boolean
    begin
        exit(Activated);
    end;

    procedure RawLoaded(): Boolean
    begin
        exit(Loaded);
    end;

    procedure RawDisabled(): Boolean
    begin
        exit(Disabled);
    end;

    // The state without moving it: current keys, filters and row counts (through copies).
    procedure RawState(): Text
    var
        CopySetup: Record "LT LM XA L1 Setup" temporary;
        CopySub: Record "LT LM XA L1 Sub" temporary;
    begin
        CopySetup.Copy(TempSetup, true);
        CopySetup.Reset();
        CopySub.Copy(TempSub, true);
        CopySub.Reset();
        exit(StrSubstNo('checked %1, activated %2, loaded %3, disabled %4; setup rows %5, filters [%6], key %7, note [%8]; sub rows %9, in view %10, filters [%11], key [%12]',
            Checked, Activated, Loaded, Disabled, CopySetup.Count(), TempSetup.GetFilters(), TempSetup."Table Id", TempSetup.Note,
            CopySub.Count(), TempSub.Count(), TempSub.GetFilters(), TempSub.Code + '|' + TempSub."Company Name"));
    end;
}

// singleinstance-shared-on-purpose: the relay's database events fill it; the corpus app's reader reads it for both test apps.
codeunit 75891 "LT LM XA G3 Memo B"
{
    SingleInstance = true;

    var
        TempSetup: Record "LT LM XA L1 Setup" temporary;
        TempSub: Record "LT LM XA L1 Sub" temporary;
        Checked: Boolean;
        Activated: Boolean;
        Loaded: Boolean;
        Disabled: Boolean;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Relay", 'OnG3Setup', '', false, false)]
    local procedure RelaySetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Setup: Record "LT LM XA L1 Setup";
    begin
        if CompanyName() = '' then
            exit;
        if not Setup.ReadPermission() then
            exit;
        if not Checked then begin
            Checked := true;
            Activated := not Setup.IsEmpty();
        end;
        if not Activated then
            exit;
        if not Loaded then begin
            Loaded := true;
            LoadTemps();
        end;
        if TempSetup.Get(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Relay", 'OnG3InsertB', '', false, false)]
    local procedure RelayInsert(RecRef: RecordRef)
    var
        Reporter: Codeunit "LT LM XA G3 Reporter";
        Span: Codeunit "LT LM XA G3 Span";
    begin
        Reporter.StartSpan(Span, 'g3.on-after-insert:' + RecRef.Name);
        LogInsert(RecRef);
        Span.Finish();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Relay", 'OnG3ModifyB', '', false, false)]
    local procedure RelayModify(RecRef: RecordRef)
    var
        Reporter: Codeunit "LT LM XA G3 Reporter";
        Span: Codeunit "LT LM XA G3 Span";
    begin
        Reporter.StartSpan(Span, 'g3.on-after-modify:' + RecRef.Name);
        LogModify(RecRef);
        Span.Finish();
    end;

    procedure LogInsert(RecRef: RecordRef)
    var
        Handled: Boolean;
    begin
        OnBeforeG3Insert(RecRef, Disabled, Loaded, Handled);
        if Handled then
            exit;
        if Disabled then
            exit;
        if RecRef.IsTemporary() then
            exit;
        if not Loaded then begin
            Loaded := true;
            LoadTemps();
        end;
        if not TempSetup.Get(RecRef.Number) then
            exit;
    end;

    procedure LogModify(RecRef: RecordRef)
    var
        Handled: Boolean;
    begin
        OnBeforeG3Modify(RecRef, Disabled, Loaded, Handled);
        if Handled then
            exit;
        if Disabled then
            exit;
        if RecRef.IsTemporary() then
            exit;
        if not Loaded then begin
            Loaded := true;
            LoadTemps();
        end;
        if not TempSetup.Get(RecRef.Number) then
            exit;
    end;

    procedure SetDisabled(Disable: Boolean)
    begin
        Disabled := Disable;
    end;

    local procedure LoadTemps()
    var
        Setup: Record "LT LM XA L1 Setup";
        Sub: Record "LT LM XA L1 Sub";
        Handled: Boolean;
    begin
        OnBeforeG3Load(TempSetup, TempSub, Handled);
        if Handled then
            exit;
        if not Setup.ReadPermission() then
            exit;
        TempSetup.DeleteAll();
        if Setup.FindSet() then
            repeat
                TempSetup.Init();
                TempSetup := Setup;
                TempSetup.Insert();
            until Setup.Next() = 0;
        Clear(TempSub);
        TempSub.SetFilter("Company Name", '=%1', '');
        if Sub.FindSet() then
            repeat
                TempSub.Init();
                TempSub := Sub;
                TempSub.Insert();
            until Sub.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeG3Insert(RecRef: RecordRef; var Disabled: Boolean; var Loaded: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeG3Modify(RecRef: RecordRef; var Disabled: Boolean; var Loaded: Boolean; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeG3Load(var TempSetup: Record "LT LM XA L1 Setup" temporary; var TempSub: Record "LT LM XA L1 Sub" temporary; var Handled: Boolean)
    begin
    end;

    procedure RawChecked(): Boolean
    begin
        exit(Checked);
    end;

    procedure RawActivated(): Boolean
    begin
        exit(Activated);
    end;

    procedure RawLoaded(): Boolean
    begin
        exit(Loaded);
    end;

    procedure RawDisabled(): Boolean
    begin
        exit(Disabled);
    end;

    // The state without moving it: current keys, filters and row counts (through copies).
    procedure RawState(): Text
    var
        CopySetup: Record "LT LM XA L1 Setup" temporary;
        CopySub: Record "LT LM XA L1 Sub" temporary;
    begin
        CopySetup.Copy(TempSetup, true);
        CopySetup.Reset();
        CopySub.Copy(TempSub, true);
        CopySub.Reset();
        exit(StrSubstNo('checked %1, activated %2, loaded %3, disabled %4; setup rows %5, filters [%6], key %7, note [%8]; sub rows %9, in view %10, filters [%11], key [%12]',
            Checked, Activated, Loaded, Disabled, CopySetup.Count(), TempSetup.GetFilters(), TempSetup."Table Id", TempSetup.Note,
            CopySub.Count(), TempSub.Count(), TempSub.GetFilters(), TempSub.Code + '|' + TempSub."Company Name"));
    end;
}

// G3 error reporting: a span that the memos start and finish around each write event. No scope is ever started, so it writes nothing.
codeunit 75892 "LT LM XA G3 Span"
{
    var
        SpanId: Text;
        Description: Text;
        StartedAt: Text;
        FinishedAt: Text;

    procedure Create(NewId: Text; NewDescription: Text)
    begin
        SpanId := NewId;
        Description := NewDescription;
        StartedAt := Format(CurrentDateTime(), 0, 9);
    end;

    procedure Finish()
    begin
        if SpanId = '' then
            exit;
        FinishedAt := Format(CurrentDateTime(), 0, 9);
    end;
}

codeunit 75893 "LT LM XA G3 Reporter"
{
    procedure StartSpan(var Span: Codeunit "LT LM XA G3 Span"; Name: Text)
    var
        Scope: Codeunit "LT LM XA G3 Scope";
    begin
        if not Scope.IsActive() then
            exit;
        Span.Create(Format(CreateGuid()), Name);
    end;
}

// singleinstance-shared-on-purpose: an error-reporting scope that nothing starts; the reporter only reads it.
codeunit 75894 "LT LM XA G3 Scope"
{
    SingleInstance = true;

    var
        Active: Boolean;

    procedure IsActive(): Boolean
    begin
        exit(Active);
    end;
}

// singleinstance-shared-on-purpose: notes for the G3 cell (gate of Memo B's write events, the Handled switch, guard steps, which
// event loaded each memo, the operands of the ask guards); the corpus app's reader reads it for both test apps.
codeunit 75895 "LT LM XA G3 Recorder"
{
    SingleInstance = true;

    var
        Gate: Boolean;
        HandledOn: Boolean;
        Steps: Text;
        LoadA: Text;
        LoadB: Text;
        Asks: Integer;
        CompanyEmptySeen: Boolean;
        NoReadPermissionSeen: Boolean;

    procedure OpenGate()
    begin
        Gate := true;
    end;

    procedure GateOpen(): Boolean
    begin
        exit(Gate);
    end;

    procedure SetHandled(NewHandled: Boolean)
    begin
        HandledOn := NewHandled;
    end;

    procedure HandledSwitch(): Boolean
    begin
        exit(HandledOn);
    end;

    procedure Step(Tag: Text; LoadedAfter: Boolean)
    begin
        Steps += Tag + ' ' + Format(LoadedAfter) + ';';
    end;

    procedure NoteLoadA(Tag: Text)
    begin
        LoadA := Tag;
    end;

    procedure NoteLoadB(Tag: Text)
    begin
        LoadB := Tag;
    end;

    procedure NoteAsk(CompanyEmpty: Boolean; ReadPermission: Boolean)
    begin
        Asks += 1;
        if CompanyEmpty then
            CompanyEmptySeen := true;
        if not ReadPermission then
            NoReadPermissionSeen := true;
    end;

    procedure RawSteps(): Text
    begin
        exit(Steps);
    end;

    procedure RawLoadA(): Text
    begin
        exit(LoadA);
    end;

    procedure RawLoadB(): Text
    begin
        exit(LoadB);
    end;

    procedure RawAsks(): Integer
    begin
        exit(Asks);
    end;

    procedure RawCompanyEmptySeen(): Boolean
    begin
        exit(CompanyEmptySeen);
    end;

    procedure RawNoReadPermissionSeen(): Boolean
    begin
        exit(NoReadPermissionSeen);
    end;
}

// G3: the automatic subscriber of Memo B's OnBefore events. It sets Handled only while the recorder's switch is on (75897 turns it on
// for one call).
codeunit 75896 "LT LM XA G3 B Handled"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Memo B", 'OnBeforeG3Insert', '', false, false)]
    local procedure BeforeInsert(RecRef: RecordRef; var Disabled: Boolean; var Loaded: Boolean; var Handled: Boolean)
    var
        Recorder: Codeunit "LT LM XA G3 Recorder";
    begin
        if Recorder.HandledSwitch() then
            Handled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA G3 Memo B", 'OnBeforeG3Modify', '', false, false)]
    local procedure BeforeModify(RecRef: RecordRef; var Disabled: Boolean; var Loaded: Boolean; var Handled: Boolean)
    var
        Recorder: Codeunit "LT LM XA G3 Recorder";
    begin
        if Recorder.HandledSwitch() then
            Handled := true;
    end;
}

// G3: drives Memo B's public entry into the Handled, Disabled and temporary exits, then opens the gate of its write events. It writes
// no table, so the first partner write of the login stays that of 98465.
codeunit 75897 "LT LM XA G3 Login"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        TempSetup: Record "LT LM XA L1 Setup" temporary;
        MemoA: Codeunit "LT LM XA G3 Memo A";
        MemoB: Codeunit "LT LM XA G3 Memo B";
        Recorder: Codeunit "LT LM XA G3 Recorder";
        RecRef: RecordRef;
    begin
        Recorder.Step('start A', MemoA.RawLoaded());
        Recorder.Step('start B', MemoB.RawLoaded());
        RecRef.Open(Database::"LT LM XA L1 Sub");
        Recorder.SetHandled(true);
        MemoB.LogInsert(RecRef);
        Recorder.SetHandled(false);
        Recorder.Step('handled', MemoB.RawLoaded());
        MemoB.SetDisabled(true);
        MemoB.LogInsert(RecRef);
        MemoB.SetDisabled(false);
        Recorder.Step('disabled', MemoB.RawLoaded());
        RecRef.Close();
        TempSetup."Table Id" := 1;
        TempSetup.Insert();
        RecRef.GetTable(TempSetup);
        MemoB.LogInsert(RecRef);
        Recorder.Step('temporary', MemoB.RawLoaded());
        Recorder.OpenGate();
    end;
}
