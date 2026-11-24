// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Probe (al-runner issue 8945; tests: tests/al-language/events/platform-triggers/LmLoginMemoShapeTests.al): load-once caches in
//   SingleInstance codeunits of a dependency app (XApp A) that are filled by the trigger setup asks of the session's first writes,
//   the first of which can come from Microsoft's own login code ("User Login", 9008) or from a partner login subscriber.
//   - "LT LM XA Ask Log": notes every GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup ask (T<id>) and the markers of the
//     login subscribers below (M<tag>); the last login subscriber takes a snapshot of the facts the test reads.
//   - F1 "LT LM XA Wrapped Memo": reached only through the integration events of a wrapper codeunit ("LT LM XA Wrapper", not
//     SingleInstance) that subscribes to the setup ask and to OnAfterOnDatabaseInsert/Modify; load once on its first event: Checked,
//     Activated from a database read (AllObj), the watched tables from a fixed list.
//   - F2 "LT LM XA Rows Memo": a direct setup subscriber whose load reads Activated and the watched tables from this app's setup rows
//     (code F2) and copies the table ids into a List and a Dictionary global. F12 "LT LM XA Wrapped Rows Memo": the same, rows of
//     code F12, reached through the wrapper.
//   - F3 "LT LM XA First Table": its load keeps the TableId of the ask that triggered it.
//   - F4 "LT LM XA Login Memo": a fixed list that holds "User Login" (9008); notes the inserts and modifies of its tables.
//   - F5 "LT LM XA Changed Memo": loads its rows (code F5) like F2, and keeps the markers that were in the ask log when it loaded.
//     The first login subscriber below adds a row to its list (R1, table 98456) as the first partner write of the login, the second
//     one writes 98456 and adds a second row (R2, 97783), the last one deletes both rows again, so each session starts with the same
//     rows.
//   A load that finds no setup row writes the default rows itself (Setup.Get, else Insert: the first session of a fresh database),
//   only when GuiAllowed() is true, with `if Insert() then;`. The login subscribers write only when GuiAllowed() is true.
//   Object ids of the first login subscriber (98465) lie below every other XApp A login subscriber that writes, so its write is the
//   first partner write of the login.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

table 98454 "LT LM XA Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Activated; Boolean) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 98455 "LT LM XA Watch"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Setup Code"; Code[20]) { }
        field(2; "Table Id"; Integer) { }
    }

    keys { key(PK; "Setup Code", "Table Id") { Clustered = true; } }
}

table 98456 "LT LM XA Write"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// singleinstance-shared-on-purpose: the login subscribers and the setup subscribers of this app fill it; one test codeunit reads it.
codeunit 98457 "LT LM XA Ask Log"
{
    SingleInstance = true;

    var
        Entries: List of [Text];
        Snapped: Boolean;
        SnapKind: Boolean;
        SnapFirstTable: Integer;
        SnapFirstAsk: Integer;
        SnapNineAsked: Boolean;
        SnapLoginWritten: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        Entries.Add('T' + Format(TableId));
    end;

    procedure Mark(Tag: Text)
    begin
        Entries.Add('M' + Tag);
    end;

    procedure EntryCount(): Integer
    begin
        exit(Entries.Count());
    end;

    procedure EntryAt(Index: Integer): Text
    begin
        exit(Entries.Get(Index));
    end;

    // The markers in the log, in order.
    procedure Marks(): Text
    var
        Entry: Text;
        Result: Text;
    begin
        foreach Entry in Entries do
            if Entry.StartsWith('M') then
                Result += Entry.Substring(2) + ';';
        exit(Result);
    end;

    procedure FirstMark(): Integer
    var
        I: Integer;
    begin
        for I := 1 to Entries.Count() do
            if Entries.Get(I).StartsWith('M') then
                exit(I);
        exit(Entries.Count() + 1);
    end;

    // Whether any table was asked before the first login subscriber of this app (the kind of session).
    procedure AskedBeforeFirstMark(): Boolean
    begin
        exit(FirstMark() > 1);
    end;

    // The asks before the first marker (local observation only).
    procedure AsksBeforeFirstMark(): Text
    var
        I: Integer;
        Result: Text;
    begin
        for I := 1 to FirstMark() - 1 do
            Result += Entries.Get(I) + ',';
        exit(Result);
    end;

    // Taken by the last login subscriber of this app.
    procedure Snap()
    var
        First: Codeunit "LT LM XA First Table";
        LoginMemo: Codeunit "LT LM XA Login Memo";
    begin
        Snapped := true;
        SnapKind := AskedBeforeFirstMark();
        SnapFirstTable := First.FirstTable();
        SnapFirstAsk := FirstAsk();
        SnapNineAsked := Entries.Contains('T9008');
        SnapLoginWritten := LoginMemo.RawWritten();
    end;

    // The table of the first ask in the log; 0 when there is none.
    local procedure FirstAsk(): Integer
    var
        Entry: Text;
        TableId: Integer;
    begin
        foreach Entry in Entries do
            if Entry.StartsWith('T') then begin
                Evaluate(TableId, Entry.Substring(2));
                exit(TableId);
            end;
        exit(0);
    end;

    procedure RawSnapped(): Boolean
    begin
        exit(Snapped);
    end;

    procedure RawSnapKind(): Boolean
    begin
        exit(SnapKind);
    end;

    procedure RawSnapFirstTable(): Integer
    begin
        exit(SnapFirstTable);
    end;

    procedure RawSnapFirstAsk(): Integer
    begin
        exit(SnapFirstAsk);
    end;

    procedure RawSnapNineAsked(): Boolean
    begin
        exit(SnapNineAsked);
    end;

    procedure RawSnapLoginWritten(): Text
    begin
        exit(SnapLoginWritten);
    end;
}

// F3: the load keeps the TableId of the ask that triggered it.
codeunit 98458 "LT LM XA First Table"
{
    SingleInstance = true;

    var
        Checked: Boolean;
        FirstTableId: Integer;
        Loads: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if Checked then
            exit;
        Checked := true;
        Loads += 1;
        FirstTableId := TableId;
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawLoads(): Text
    begin
        exit(Format(Loads));
    end;

    procedure FirstTable(): Integer
    begin
        exit(FirstTableId);
    end;
}

// The wrapper: turns the Base Application events into its own integration events. Not SingleInstance, keeps nothing.
codeunit 98459 "LT LM XA Wrapper"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        OnWrapperSetup(TableId, OnDatabaseInsert, OnDatabaseModify);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        OnWrapperWrite('I', RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure AfterModify(RecRef: RecordRef)
    begin
        OnWrapperWrite('M', RecRef.Number);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWrapperSetup(TableId: Integer; var WatchInsert: Boolean; var WatchModify: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnWrapperWrite(Kind: Text; TableId: Integer)
    begin
    end;
}

// F1: reached through the wrapper; Activated from a database read, the watched tables from a fixed list.
codeunit 98460 "LT LM XA Wrapped Memo"
{
    SingleInstance = true;

    var
        Watched: List of [Integer];
        Checked: Boolean;
        Activated: Boolean;
        Loads: Integer;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA Wrapper", 'OnWrapperSetup', '', false, false)]
    local procedure WrapperSetup(TableId: Integer; var WatchInsert: Boolean; var WatchModify: Boolean)
    begin
        if not Checked then begin
            Checked := true;
            Activated := IsActivated();
            if Activated then begin
                Loads += 1;
                Watched.Add(98456); // "LT LM XA Write", written by the second login subscriber
                Watched.Add(97782); // "LT LM Watched" of the corpus app, written by a test only
            end;
        end;
        if Watched.Contains(TableId) then begin
            WatchInsert := true;
            WatchModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA Wrapper", 'OnWrapperWrite', '', false, false)]
    local procedure WrapperWrite(Kind: Text; TableId: Integer)
    begin
        if Watched.Contains(TableId) then
            Written += Kind + Format(TableId) + ';';
    end;

    local procedure IsActivated(): Boolean
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", Database::"LT LM XA Setup");
        exit(not AllObj.IsEmpty());
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure RawLoads(): Text
    begin
        exit(Format(Loads));
    end;

    procedure RawWatched(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.ListText(Watched));
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;
}

// The load from setup rows that F2, F12 and F5 share: Activated from the setup row, the table ids of the watch rows into a List and a
// Dictionary. Writes the default rows when the setup row is missing (GuiAllowed sessions only).
codeunit 98468 "LT LM XA Rows Loader"
{
    procedure Load(SetupCode: Code[20]; var Activated: Boolean; var Watched: List of [Integer]; var WatchedDict: Dictionary of [Integer, Text])
    var
        Setup: Record "LT LM XA Setup";
        Watch: Record "LT LM XA Watch";
    begin
        if not Setup.Get(SetupCode) then begin
            if not GuiAllowed() then
                exit;
            Seed(SetupCode);
            if not Setup.Get(SetupCode) then
                exit;
        end;
        Activated := Setup.Activated;
        if not Activated then
            exit;
        Watch.SetRange("Setup Code", SetupCode);
        if Watch.FindSet() then
            repeat
                Watched.Add(Watch."Table Id");
                WatchedDict.Add(Watch."Table Id", 'T' + Format(Watch."Table Id"));
            until Watch.Next() = 0;
    end;

    local procedure Seed(SetupCode: Code[20])
    var
        Setup: Record "LT LM XA Setup";
    begin
        Setup.Init();
        Setup.Code := SetupCode;
        Setup.Activated := true;
        if Setup.Insert() then;
        if SetupCode <> 'F5' then
            AddWatch(SetupCode, 98456);
        AddWatch(SetupCode, 97782);
    end;

    procedure AddWatch(SetupCode: Code[20]; TableId: Integer)
    var
        Watch: Record "LT LM XA Watch";
    begin
        Watch.Init();
        Watch."Setup Code" := SetupCode;
        Watch."Table Id" := TableId;
        if Watch.Insert() then;
    end;

    procedure RemoveWatch(SetupCode: Code[20]; TableId: Integer)
    var
        Watch: Record "LT LM XA Watch";
    begin
        if Watch.Get(SetupCode, TableId) then
            Watch.Delete();
    end;

    procedure ListText(var Watched: List of [Integer]): Text
    var
        TableId: Integer;
        Result: Text;
    begin
        foreach TableId in Watched do
            Result += Format(TableId) + ';';
        exit(Format(Watched.Count()) + ':' + Result);
    end;

    procedure DictText(var WatchedDict: Dictionary of [Integer, Text]): Text
    var
        TableId: Integer;
        Result: Text;
    begin
        foreach TableId in WatchedDict.Keys() do
            Result += Format(TableId) + '=' + WatchedDict.Get(TableId) + ';';
        exit(Format(WatchedDict.Count()) + ':' + Result);
    end;
}

// F2: a direct setup subscriber that loads from the setup rows of code F2.
codeunit 98461 "LT LM XA Rows Memo"
{
    SingleInstance = true;

    var
        Watched: List of [Integer];
        WatchedDict: Dictionary of [Integer, Text];
        Checked: Boolean;
        Activated: Boolean;
        Loads: Integer;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        if not Checked then begin
            Checked := true;
            Loads += 1;
            Loader.Load('F2', Activated, Watched, WatchedDict);
        end;
        if WatchedDict.ContainsKey(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        if Watched.Contains(RecRef.Number) then
            Written += 'I' + Format(RecRef.Number) + ';';
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure RawLoads(): Text
    begin
        exit(Format(Loads));
    end;

    procedure RawWatched(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.ListText(Watched));
    end;

    procedure RawDict(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.DictText(WatchedDict));
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;
}

// F12: the rows load of F2 (code F12), reached through the wrapper.
codeunit 98462 "LT LM XA Wrapped Rows Memo"
{
    SingleInstance = true;

    var
        Watched: List of [Integer];
        WatchedDict: Dictionary of [Integer, Text];
        Checked: Boolean;
        Activated: Boolean;
        Loads: Integer;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA Wrapper", 'OnWrapperSetup', '', false, false)]
    local procedure WrapperSetup(TableId: Integer; var WatchInsert: Boolean; var WatchModify: Boolean)
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        if not Checked then begin
            Checked := true;
            Loads += 1;
            Loader.Load('F12', Activated, Watched, WatchedDict);
        end;
        if WatchedDict.ContainsKey(TableId) then begin
            WatchInsert := true;
            WatchModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LM XA Wrapper", 'OnWrapperWrite', '', false, false)]
    local procedure WrapperWrite(Kind: Text; TableId: Integer)
    begin
        if Watched.Contains(TableId) then
            Written += Kind + Format(TableId) + ';';
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure RawLoads(): Text
    begin
        exit(Format(Loads));
    end;

    procedure RawWatched(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.ListText(Watched));
    end;

    procedure RawDict(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.DictText(WatchedDict));
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;
}

// F4: a fixed list that holds "User Login" (9008).
codeunit 98463 "LT LM XA Login Memo"
{
    SingleInstance = true;

    var
        Watched: List of [Integer];
        Checked: Boolean;
        Loads: Integer;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if not Checked then begin
            Checked := true;
            Loads += 1;
            Watched.Add(9008); // "User Login" of the System Application
            Watched.Add(98456);
            Watched.Add(97782);
        end;
        if Watched.Contains(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        if Watched.Contains(RecRef.Number) then
            Written += 'I' + Format(RecRef.Number) + ';';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseModify', '', false, false)]
    local procedure AfterModify(RecRef: RecordRef)
    begin
        if Watched.Contains(RecRef.Number) then
            Written += 'M' + Format(RecRef.Number) + ';';
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawLoads(): Text
    begin
        exit(Format(Loads));
    end;

    procedure RawWatched(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.ListText(Watched));
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;

    // The written entries without those of "User Login" (9008).
    procedure WrittenWithout9008(): Text
    var
        Parts: List of [Text];
        Part: Text;
        Result: Text;
    begin
        Parts := Written.Split(';');
        foreach Part in Parts do
            if (Part <> '') and (CopyStr(Part, 2) <> '9008') then
                Result += Part + ';';
        exit(Result);
    end;
}

// F5: loads its rows (code F5), which the login subscribers change, and keeps the markers present when it loaded.
codeunit 98464 "LT LM XA Changed Memo"
{
    SingleInstance = true;

    var
        Watched: List of [Integer];
        WatchedDict: Dictionary of [Integer, Text];
        Checked: Boolean;
        Activated: Boolean;
        Loads: Integer;
        LoadMarks: Text;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Loader: Codeunit "LT LM XA Rows Loader";
        AskLog: Codeunit "LT LM XA Ask Log";
    begin
        if not Checked then begin
            Checked := true;
            Loads += 1;
            LoadMarks := AskLog.Marks();
            Loader.Load('F5', Activated, Watched, WatchedDict);
        end;
        if WatchedDict.ContainsKey(TableId) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        if Watched.Contains(RecRef.Number) then
            Written += 'I' + Format(RecRef.Number) + ';';
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure RawLoads(): Text
    begin
        exit(Format(Loads));
    end;

    procedure RawLoadMarks(): Text
    begin
        exit(LoadMarks);
    end;

    procedure RawWatched(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.ListText(Watched));
    end;

    procedure RawDict(): Text
    var
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        exit(Loader.DictText(WatchedDict));
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;
}

// The first partner write of the login: adds R1 (98456) to the F5 rows.
codeunit 98465 "LT LM XA Login First"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        AskLog: Codeunit "LT LM XA Ask Log";
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        AskLog.Mark('L1');
        if not GuiAllowed() then
            exit;
        Loader.AddWatch('F5', 98456);
    end;
}

// Writes 98456 (watched by F1, F2, F12, F4, and by F5 when its load saw R1), then adds R2 (97783) to the F5 rows.
codeunit 98466 "LT LM XA Login Second"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        AskLog: Codeunit "LT LM XA Ask Log";
        Loader: Codeunit "LT LM XA Rows Loader";
        Row: Record "LT LM XA Write";
    begin
        AskLog.Mark('L2');
        if not GuiAllowed() then
            exit;
        Row.Init();
        Row.Tag := 'L2';
        Row.Insert(true);
        Loader.AddWatch('F5', 97783);
    end;
}

// Deletes R1 and R2 again and takes the snapshot of the ask log.
codeunit 98467 "LT LM XA Login Last"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        AskLog: Codeunit "LT LM XA Ask Log";
        Loader: Codeunit "LT LM XA Rows Loader";
    begin
        AskLog.Mark('L3');
        if GuiAllowed() then begin
            Loader.RemoveWatch('F5', 98456);
            Loader.RemoveWatch('F5', 97783);
        end;
        AskLog.Snap();
    end;
}
