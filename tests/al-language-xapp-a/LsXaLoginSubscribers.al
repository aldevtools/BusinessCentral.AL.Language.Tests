// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Probe (al-runner issue 8945; tests: tests/al-language/events/platform-triggers/LsLoginSubscriberTests.al): several
//   "System Initialization".OnAfterLogin subscribers, in one dependency app and across dependency apps, change the same
//   SingleInstance codeunits of this app (XApp A), directly and through this app's "Global Triggers" subscribers.
//   - "LT LS XA Order Memo": every login subscriber appends its tag (order of the subscribers).
//   - "LT LS XA State One": changed by the three plain subscribers of this app (A1, A2, A3); "LT LS XA State Many": changed by
//     one subscriber of each of XApp A, B and C (A1, B1, C1). Each Touch loads a cache once (Boolean flags and a temporary
//     Record filled from a setup table), then sets a Boolean to the same value, a Text to the tag (last writer wins), an Integer
//     to Num * 10 + k and adds a row to a temporary Record log.
//   - "LT LS XA Trig Memo": subscribes to "Global Triggers".GetDatabaseTableTriggerSetup (notes every asked table, fills a
//     temporary Record cache on its first call and answers OnDatabaseInsert/OnDatabaseModify = true for the tables in the cache)
//     and to OnDatabaseInsert/OnDatabaseModify (notes the writes to the cached tables). Every login subscriber puts a marker into
//     the same list before it writes, so the test can tell which asks came before, during and after the partner subscribers.
//   - "LT LS XA Load Memo" (98538): a load-once cache whose GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup subscriber
//     does its one-time load on the first ask whatever table is asked (Checked, Activated, six watched tables from a fixed list) and
//     reads TableId only after that; it notes OnAfterOnDatabaseInsert of the watched tables. No login subscriber calls it.
//   Subscriber codeunit ids interleave across the apps (A 98530, 98533, 98536, 98537; B 98531, 98534; C 98532, 98535); the names
//   of A's three plain subscribers are not in id order (Zulu, Alpha, Mike), and 98537 declares three subscriber procedures
//   in an order that is neither name order nor its reverse (ZuluLogin, AlphaLogin, MikeLogin).
//   The login runs in every session of the corpus run: the subscribers never fail. Rows are written only when GuiAllowed() is
//   true (not in background sessions), the write tables have an AutoIncrement key, the setup rows are inserted with
//   `if Insert() then;`.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

table 98505 "LT LS XA Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Description; Text[30]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 98506 "LT LS XA Write 1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 98507 "LT LS XA Write 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 98508 "LT LS XA Write 3"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 98513 "LT LS XA Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// singleinstance-shared-on-purpose: the probe is what the login subscribers leave in these codeunits for the test session, read by
// two test codeunits (the second one also sees what the first one changed).
codeunit 98509 "LT LS XA Order Memo"
{
    SingleInstance = true;

    var
        Order: List of [Text];
        LoginGui: Text;

    procedure Add(Tag: Text)
    begin
        Order.Add(Tag);
        if LoginGui = '' then
            LoginGui := Format(GuiAllowed());
    end;

    procedure Joined(): Text
    var
        Tag: Text;
        Result: Text;
    begin
        foreach Tag in Order do
            Result += Tag + ';';
        exit(Result);
    end;

    procedure Count(): Integer
    begin
        exit(Order.Count());
    end;

    procedure Occurrences(Tag: Text): Integer
    var
        Entry: Text;
        N: Integer;
    begin
        foreach Entry in Order do
            if Entry = Tag then
                N += 1;
        exit(N);
    end;

    procedure RawLoginGui(): Text
    begin
        exit(LoginGui);
    end;
}

codeunit 98510 "LT LS XA State One"
{
    SingleInstance = true;

    var
        TempSetup: Record "LT LS XA Setup" temporary;
        TempLog: Record "LT LS XA Log" temporary;
        Loaded: Boolean;
        Activated: Boolean;
        Flag: Boolean;
        LoadedBy: Text;
        Txt: Text;
        Num: Integer;
        Touches: Integer;

    procedure Touch(Tag: Text; K: Integer)
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        if not Loaded then begin
            Loaded := true;
            LoadedBy := Tag;
            Activated := Hub.LoadSetup(TempSetup);
        end;
        Touches += 1;
        Flag := true;
        Txt := Tag;
        Num := Num * 10 + K;
        TempLog.Init();
        TempLog."Entry No." := TempLog.Count() + 1;
        TempLog.Tag := CopyStr(Tag, 1, MaxStrLen(TempLog.Tag));
        TempLog.Insert();
    end;

    procedure RawLoaded(): Text
    begin
        exit(Format(Loaded));
    end;

    procedure RawLoadedBy(): Text
    begin
        exit(LoadedBy);
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure SetupKeys(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.SetupKeys(TempSetup));
    end;

    procedure RawFlag(): Text
    begin
        exit(Format(Flag));
    end;

    procedure RawTxt(): Text
    begin
        exit(Txt);
    end;

    procedure RawNum(): Text
    begin
        exit(Format(Num));
    end;

    procedure RawTouches(): Text
    begin
        exit(Format(Touches));
    end;

    procedure LogRows(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.LogRows(TempLog));
    end;
}

codeunit 98511 "LT LS XA State Many"
{
    SingleInstance = true;

    var
        TempSetup: Record "LT LS XA Setup" temporary;
        TempLog: Record "LT LS XA Log" temporary;
        Loaded: Boolean;
        Activated: Boolean;
        Flag: Boolean;
        LoadedBy: Text;
        Txt: Text;
        Num: Integer;
        Touches: Integer;

    procedure Touch(Tag: Text; K: Integer)
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        if not Loaded then begin
            Loaded := true;
            LoadedBy := Tag;
            Activated := Hub.LoadSetup(TempSetup);
        end;
        Touches += 1;
        Flag := true;
        Txt := Tag;
        Num := Num * 10 + K;
        TempLog.Init();
        TempLog."Entry No." := TempLog.Count() + 1;
        TempLog.Tag := CopyStr(Tag, 1, MaxStrLen(TempLog.Tag));
        TempLog.Insert();
    end;

    procedure RawLoaded(): Text
    begin
        exit(Format(Loaded));
    end;

    procedure RawLoadedBy(): Text
    begin
        exit(LoadedBy);
    end;

    procedure RawActivated(): Text
    begin
        exit(Format(Activated));
    end;

    procedure SetupKeys(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.SetupKeys(TempSetup));
    end;

    procedure RawFlag(): Text
    begin
        exit(Format(Flag));
    end;

    procedure RawTxt(): Text
    begin
        exit(Txt);
    end;

    procedure RawNum(): Text
    begin
        exit(Format(Num));
    end;

    procedure RawTouches(): Text
    begin
        exit(Format(Touches));
    end;

    procedure LogRows(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.LogRows(TempLog));
    end;
}

codeunit 98512 "LT LS XA Trig Memo"
{
    SingleInstance = true;

    var
        TempCache: Record "LT LS XA Setup" temporary;
        TempWritten: Record "LT LS XA Log" temporary;
        Entries: List of [Text];
        Checked: Boolean;
        CheckedAt: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean)
    begin
        Entries.Add('T' + Format(TableId));
        if not Checked then begin
            Checked := true;
            CheckedAt := Entries.Count();
            FillCache();
        end;
        if TempCache.Get('T' + Format(TableId)) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    begin
        NoteWrite('I', RecRef.Number);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure OnModify(RecRef: RecordRef)
    begin
        NoteWrite('M', RecRef.Number);
    end;

    local procedure FillCache()
    begin
        AddCache(Database::"LT LS XA Write 1");
        AddCache(Database::"LT LS XA Write 2");
        AddCache(Database::"LT LS XA Write 3");
        AddCache(98515); // "LT LS XB Write" of XApp B (this app does not depend on B)
        AddCache(98520); // "LT LS XC Write" of XApp C
    end;

    local procedure AddCache(TableId: Integer)
    begin
        TempCache.Init();
        TempCache.Code := CopyStr('T' + Format(TableId), 1, MaxStrLen(TempCache.Code));
        TempCache.Insert();
    end;

    local procedure NoteWrite(Kind: Text; TableId: Integer)
    begin
        if not TempCache.Get('T' + Format(TableId)) then
            exit;
        Entries.Add('W' + Kind + Format(TableId));
        TempWritten.Init();
        TempWritten."Entry No." := TempWritten.Count() + 1;
        TempWritten.Tag := CopyStr(Kind + Format(TableId), 1, MaxStrLen(TempWritten.Tag));
        TempWritten.Insert();
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

    // First index after After whose entry is Entry; 0 when there is none.
    procedure IndexOf(Entry: Text; After: Integer): Integer
    var
        I: Integer;
    begin
        for I := After + 1 to Entries.Count() do
            if Entries.Get(I) = Entry then
                exit(I);
        exit(0);
    end;

    procedure Occurrences(Entry: Text): Integer
    var
        E: Text;
        N: Integer;
    begin
        foreach E in Entries do
            if E = Entry then
                N += 1;
        exit(N);
    end;

    procedure RawChecked(): Text
    begin
        exit(Format(Checked));
    end;

    procedure RawCheckedAt(): Integer
    begin
        exit(CheckedAt);
    end;

    procedure CacheKeys(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.SetupKeys(TempCache));
    end;

    procedure WrittenRows(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.LogRows(TempWritten));
    end;
}

// A load-once cache in the shape of a data-log cache: its GlobalTriggerManagement setup subscriber does the one-time load on the
// first ask, whatever table is asked (Checked, Activated from a database read, the watched tables from a fixed list), and reads
// TableId only after that. No login subscriber calls it: it is changed only by the setup asks the login subscribers' writes cause
// (and by the ask Microsoft's own login code causes in some sessions).
codeunit 98538 "LT LS XA Load Memo"
{
    SingleInstance = true;

    var
        TempWatched: Record "LT LS XA Setup" temporary;
        Checked: Boolean;
        Activated: Boolean;
        WatchedLoaded: Boolean;
        Loads: Integer;
        Asks: Integer;
        Written: Text;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        Asks += 1;
        if not Checked then begin
            Checked := true;
            Activated := IsActivated();
        end;
        if not Activated then
            exit;
        if not WatchedLoaded then begin
            WatchedLoaded := true;
            Loads += 1;
            LoadWatched();
        end;
        if TempWatched.Get('T' + Format(TableId)) then begin
            OnDatabaseInsert := true;
            OnDatabaseModify := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterInsert(RecRef: RecordRef)
    begin
        if TempWatched.Get('T' + Format(RecRef.Number)) then
            Written += Format(RecRef.Number) + ';';
    end;

    // A database read that does not depend on the history of the database: the setup table of this app exists.
    local procedure IsActivated(): Boolean
    var
        AllObj: Record AllObj;
    begin
        AllObj.SetRange("Object Type", AllObj."Object Type"::Table);
        AllObj.SetRange("Object ID", Database::"LT LS XA Setup");
        exit(not AllObj.IsEmpty());
    end;

    local procedure LoadWatched()
    begin
        AddWatched(Database::"LT LS XA Write 1");
        AddWatched(Database::"LT LS XA Write 2");
        AddWatched(Database::"LT LS XA Write 3");
        AddWatched(98515); // "LT LS XB Write" of XApp B (this app does not depend on B)
        AddWatched(98520); // "LT LS XC Write" of XApp C
        AddWatched(97878); // "LT LS Watched Write" of the corpus app, written by a test only
    end;

    local procedure AddWatched(TableId: Integer)
    begin
        TempWatched.Init();
        TempWatched.Code := CopyStr('T' + Format(TableId), 1, MaxStrLen(TempWatched.Code));
        TempWatched.Insert();
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

    procedure Watched(): Text
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        exit(Hub.SetupKeys(TempWatched));
    end;

    procedure RawWritten(): Text
    begin
        exit(Written);
    end;

    procedure AskCount(): Integer
    begin
        exit(Asks);
    end;
}

codeunit 98514 "LT LS XA Login Hub"
{
    // What every login subscriber does first: its tag into the order memo and its marker into the trigger memo.
    procedure Enter(Tag: Text)
    var
        OrderMemo: Codeunit "LT LS XA Order Memo";
        TrigMemo: Codeunit "LT LS XA Trig Memo";
    begin
        OrderMemo.Add(Tag);
        TrigMemo.Mark(Tag);
    end;

    procedure CanWrite(): Boolean
    begin
        exit(GuiAllowed());
    end;

    // Seeds the setup rows (S1, S2) when the session may write, then reports whether the setup table has rows and copies them.
    procedure LoadSetup(var TempSetup: Record "LT LS XA Setup" temporary): Boolean
    var
        Setup: Record "LT LS XA Setup";
    begin
        if CanWrite() then begin
            SeedOne('S1');
            SeedOne('S2');
        end;
        TempSetup.Reset();
        TempSetup.DeleteAll();
        if Setup.FindSet() then
            repeat
                TempSetup := Setup;
                TempSetup.Insert();
            until Setup.Next() = 0;
        exit(not Setup.IsEmpty());
    end;

    local procedure SeedOne(SetupCode: Code[20])
    var
        Setup: Record "LT LS XA Setup";
    begin
        if Setup.Get(SetupCode) then
            exit;
        Setup.Init();
        Setup.Code := SetupCode;
        Setup.Description := 'seeded by the login';
        if Setup.Insert() then;
    end;

    procedure SetupKeys(var TempSetup: Record "LT LS XA Setup" temporary): Text
    var
        Result: Text;
    begin
        TempSetup.Reset();
        if TempSetup.FindSet() then
            repeat
                Result += TempSetup.Code + ';';
            until TempSetup.Next() = 0;
        exit(Format(TempSetup.Count()) + ':' + Result);
    end;

    procedure LogRows(var TempLog: Record "LT LS XA Log" temporary): Text
    var
        Result: Text;
    begin
        TempLog.Reset();
        if TempLog.FindSet() then
            repeat
                Result += Format(TempLog."Entry No.") + '=' + TempLog.Tag + ';';
            until TempLog.Next() = 0;
        exit(Result);
    end;

    procedure WriteRow1(Tag: Text)
    var
        Row: Record "LT LS XA Write 1";
    begin
        if not CanWrite() then
            exit;
        Row.Init();
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        Row.Insert(true);
    end;

    procedure WriteRow2(Tag: Text)
    var
        Row: Record "LT LS XA Write 2";
    begin
        if not CanWrite() then
            exit;
        Row.Init();
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        Row.Insert(true);
    end;

    procedure WriteRow3(Tag: Text)
    var
        Row: Record "LT LS XA Write 3";
    begin
        if not CanWrite() then
            exit;
        Row.Init();
        Row.Tag := CopyStr(Tag, 1, MaxStrLen(Row.Tag));
        Row.Insert(true);
    end;
}

codeunit 98530 "LT LS XA Zulu Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
        One: Codeunit "LT LS XA State One";
        Many: Codeunit "LT LS XA State Many";
    begin
        Hub.Enter('A1');
        One.Touch('A1', 1);
        Many.Touch('A1', 1);
        Hub.WriteRow1('A1');
    end;
}

codeunit 98533 "LT LS XA Alpha Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
        One: Codeunit "LT LS XA State One";
    begin
        Hub.Enter('A2');
        One.Touch('A2', 2);
        Hub.WriteRow2('A2');
    end;
}

codeunit 98536 "LT LS XA Mike Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
        One: Codeunit "LT LS XA State One";
    begin
        Hub.Enter('A3');
        One.Touch('A3', 3);
        Hub.WriteRow3('A3');
    end;
}

codeunit 98537 "LT LS XA Two Procs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure ZuluLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        Hub.Enter('A4z');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AlphaLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        Hub.Enter('A4a');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure MikeLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        Hub.Enter('A4m');
    end;
}
