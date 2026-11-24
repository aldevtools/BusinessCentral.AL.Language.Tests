// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/LsXaLoginSubscribers.al (memos 98509-98512 and 98538,
//   hub 98514, OnAfterLogin subscribers 98530, 98533, 98536, 98537); XApp B tests/al-language-xapp-b/LsXbLoginSubscribers.al (98531, 98534);
//   XApp C tests/al-language-xapp-c/LsXcLoginSubscribers.al (98532, 98535); OnAfterLogin subscriber 97870 and tables 97877, 97878 of
//   this app (below).
// Probe (al-runner issue 8945): more than two "System Initialization".OnAfterLogin subscribers change the same SingleInstance
//   codeunits of a dependency app before the first test. Cells:
//   A. the order of the subscribers: three plain subscriber codeunits of one app whose names are not in id order, three subscriber
//      procedures in one codeunit, two subscribers in each of three dependency apps with ids interleaved across the apps, and one
//      subscriber of this app (the app under test);
//   B. one SingleInstance codeunit changed by the three subscribers of one app (State One) and by one subscriber of each of three
//      apps (State Many): a cache loaded once (Booleans and a temporary Record filled from setup rows), the same Boolean value set
//      by every subscriber, a Text where the last writer wins, Num := Num * 10 + k, and rows added to a temporary Record;
//   C. a cache that the dependency app's "Global Triggers" subscribers fill while the login subscribers write rows: which of the
//      subscribers' tables the session asks GetDatabaseTableTriggerSetup for before and during the partner subscribers, the
//      database events raised for the subscribers' rows, and the cache after the login;
//   D. whether the test runner's own tables (130450 "Test Method Line", 130451 "AL Test Suite") are asked after the login, in the
//      first test codeunit and again in the second one;
//   E. a load-once cache (XApp A's "LT LS XA Load Memo") whose GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup
//      subscriber does its one-time load on the first ask whatever table is asked (Checked, Activated from a database read, six
//      watched tables from a fixed list), reads TableId only after that and notes OnAfterOnDatabaseInsert of the watched tables;
//      no login subscriber calls it, it is changed only by the asks the login writes cause. Read after the login in codeunit A, around
//      a test's DeleteAll and inserts on an unwatched table (97877) and on a watched one (97878), and in codeunit B.
//   Each cell is read in the first tests of codeunit A, again in its last test (after the test changed State One) and in the
//   first tests of codeunit B.
// Measured on a local BC 29.0.54011.55816 with the hybrid test runner (hub transport), cells D and E also with the websocket runner;
//   cell E in 18 sessions: 8 of the kind that asks 9008 first, 10 of the other (below);
//   BC 27 and 28 by the CI matrix.
// BC result:
//   A. The login raises the subscribers once per test session, before the first test, in this order: the subscriber codeunits of
//      XApp A in ascending codeunit id (98530 Zulu, 98533 Alpha, 98536 Mike, 98537), the three procedures of 98537 in procedure
//      name order (AlphaLogin, MikeLogin, ZuluLogin; declared Zulu, Alpha, Mike), then XApp B (98531, 98534), XApp C (98532,
//      98535) and last this app (97870), although 97870 is the lowest id: apps in dependency order, ascending codeunit id inside
//      an app. Codeunit B sees the same list (11 entries, A1 once): the login does not run again for the second codeunit.
//      Not told apart by this setup: dependency order vs publish order (CI publishes A, B, C in dependency order), and XApps A, B,
//      C ordered by their lowest subscriber id (98530 < 98531 < 98532); this app's 97870 rules out lowest id for the app under test.
//   B. State One (A1, A2, A3) and State Many (A1, B1, C1) each end with Loaded and Activated true, loaded by the first subscriber
//      (A1), the setup cache holding both seeded rows, three touches, the Boolean true, the Text of the last subscriber (A3, C1),
//      Num 123 and the temporary log rows in subscriber order. A change made by a test (Txt T, Num 1239, a fourth log row) is
//      seen by the second test codeunit.
//   C. Each login subscriber's first write to its table asks GetDatabaseTableTriggerSetup for that table and then raises
//      OnDatabaseInsert, inside that subscriber (before the next one starts); none of these tables is asked before the first
//      subscriber. The trigger cache is loaded once (Checked true, five tables) and is still the same in codeunit B. Not asserted
//      (it differs between sessions): in one session one Microsoft table (9008) was asked before the first partner subscriber, so
//      Microsoft's login code loaded the cache; in the later sessions no table was asked before the first subscriber, and the
//      first subscriber's write loaded it. Which kind a session is follows System Application's own OnAfterLogin subscriber
//      (CreateOrUpdateLoginInfo): it writes "User Login" (9008) only for a client session whose last login is more than 60 seconds
//      ago or on another day. Measured: every session started more than 60 seconds after the previous one asked 9008 before the
//      first partner subscriber, every session started within 60 seconds did not, with both runners. The setup table 98505 is
//      asked only in the session that seeds its rows.
//   D. Neither 130450 "Test Method Line" nor 130451 "AL Test Suite" is asked before the login. After the login it depends on the
//      test runner: with the hub runner (altool) neither is asked in the test session; with the websocket runner (run-tests.sh)
//      130450 is asked once, after the login and before the first test of codeunit A (seen with a local copy that reads the list in
//      its first test), and not again in codeunit B; 130451 is not asked. Only that bound (at most once, never before the login) is
//      asserted, so the test holds on both runners.
//   E. After the login the load-once cache has Checked and Activated true, one load, the six watched tables and the inserts of the
//      five login subscribers' rows in subscriber order. The values are the same in both kinds of session (9008 asked before the
//      first partner subscriber, so the load ran inside Microsoft's login subscriber; or not, so the load ran at A1's first write),
//      in the first test of codeunit A, after the websocket runner's ask of 130450 and in codeunit B; only the number of asks
//      differs (one more in a session that asks 9008, one more with the websocket runner), so it is not asserted. A test's first
//      write to a table in the session asks once, already for a DeleteAll on an empty table, and its inserts after that do not ask
//      again: for the unwatched table nothing else changes; for the watched table each insert raises OnAfterOnDatabaseInsert
//      (two inserts noted), Checked and the load stay as they were. Codeunit B sees the two inserts of codeunit A's test.
//      Not measured: an ask for 130451 (no runner asks it) and a session whose first ask comes from a table this probe watches
//      before any login subscriber ran.
// BC versions: 27 - 29

table 97877 "LT LS Fresh Write"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 97878 "LT LS Watched Write"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

// singleinstance-shared-on-purpose: both test codeunits read the XApp A memos; what the second one sees of the first one's change is the probe.
codeunit 97870 "LT LS Main Login Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Hub: Codeunit "LT LS XA Login Hub";
    begin
        Hub.Enter('M');
    end;
}

codeunit 97873 "LT LS Login Reader"
{
    procedure ObserveOrder(var Observer: Codeunit "Probe Observer")
    var
        OrderMemo: Codeunit "LT LS XA Order Memo";
    begin
        Observer.Observe('order', OrderMemo.Joined());
        Observer.Observe('order count', Format(OrderMemo.Count()));
        Observer.Observe('A1 runs', Format(OrderMemo.Occurrences('A1')));
        Observer.Observe('login GuiAllowed', OrderMemo.RawLoginGui());
    end;

    procedure ObserveStateOne(var Observer: Codeunit "Probe Observer")
    var
        One: Codeunit "LT LS XA State One";
    begin
        Observer.Observe('one loaded', One.RawLoaded());
        Observer.Observe('one loaded by', One.RawLoadedBy());
        Observer.Observe('one activated', One.RawActivated());
        Observer.Observe('one setup', One.SetupKeys());
        Observer.Observe('one touches', One.RawTouches());
        Observer.Observe('one flag', One.RawFlag());
        Observer.Observe('one txt', One.RawTxt());
        Observer.Observe('one num', One.RawNum());
        Observer.Observe('one log', One.LogRows());
    end;

    procedure ObserveStateMany(var Observer: Codeunit "Probe Observer")
    var
        Many: Codeunit "LT LS XA State Many";
    begin
        Observer.Observe('many loaded', Many.RawLoaded());
        Observer.Observe('many loaded by', Many.RawLoadedBy());
        Observer.Observe('many activated', Many.RawActivated());
        Observer.Observe('many setup', Many.SetupKeys());
        Observer.Observe('many touches', Many.RawTouches());
        Observer.Observe('many flag', Many.RawFlag());
        Observer.Observe('many txt', Many.RawTxt());
        Observer.Observe('many num', Many.RawNum());
        Observer.Observe('many log', Many.LogRows());
    end;

    procedure ObserveTriggers(var Observer: Codeunit "Probe Observer")
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        First: Integer;
    begin
        First := FirstMark();
        Observer.Observe('marks', Marks());
        Observer.Observe('checked', TrigMemo.RawChecked());
        Observer.Observe('probe tables asked before first mark', ProbeEntries(0, First));
        Observer.Observe('windows', Windows());
        Observer.Observe('written', TrigMemo.WrittenRows());
        Observer.Observe('cache', TrigMemo.CacheKeys());
    end;

    procedure ObserveLoadMemo(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        LoadMemo: Codeunit "LT LS XA Load Memo";
    begin
        Observer.Observe(Prefix + 'load checked', LoadMemo.RawChecked());
        Observer.Observe(Prefix + 'load activated', LoadMemo.RawActivated());
        Observer.Observe(Prefix + 'load loads', LoadMemo.RawLoads());
        Observer.Observe(Prefix + 'load watched', LoadMemo.Watched());
        Observer.Observe(Prefix + 'load written', LoadMemo.RawWritten());
    end;

    // Which kind of session this is: whether any table was asked before the first login subscriber of the probe (Microsoft's login
    // code writes its own table in some sessions only). Not asserted: used by local observation runs only.
    procedure ObserveSessionKind(var Observer: Codeunit "Probe Observer")
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        LoadMemo: Codeunit "LT LS XA Load Memo";
        I: Integer;
        Result: Text;
    begin
        for I := 1 to FirstMark() - 1 do
            Result += TrigMemo.EntryAt(I) + ',';
        Observer.Observe('kind asked before first mark', Result);
        Observer.Observe('kind asks', Format(LoadMemo.AskCount()));
    end;

    procedure AskedBeforeFirstMark(): Boolean
    begin
        exit(FirstMark() > 1);
    end;

    procedure LoadAsks(): Integer
    var
        LoadMemo: Codeunit "LT LS XA Load Memo";
    begin
        exit(LoadMemo.AskCount());
    end;

    procedure ObserveRunnerTables(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        ObserveTable(Observer, Prefix, 130450);
        ObserveTable(Observer, Prefix, 130451);
    end;

    local procedure ObserveTable(var Observer: Codeunit "Probe Observer"; Prefix: Text; TableId: Integer)
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        Entry: Text;
        First: Integer;
        Last: Integer;
        I: Integer;
        Before: Integer;
        After: Integer;
    begin
        Entry := 'T' + Format(TableId);
        First := FirstMark();
        Last := LastMark();
        for I := 1 to TrigMemo.EntryCount() do
            if TrigMemo.EntryAt(I) = Entry then
                if I < First then
                    Before += 1
                else
                    if I > Last then
                        After += 1;
        Observer.Observe(Prefix + Format(TableId) + ' asked before login', Format(Before));
        // How often depends on the test runner (0 with the hub runner, 1 for 130450 with the websocket runner): only the bound is asserted.
        Observer.Observe(Prefix + Format(TableId) + ' asked after login at most once', Format(After <= 1));
    end;


    // The markers of the login subscribers, in the order they were put into the trigger memo.
    local procedure Marks(): Text
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        I: Integer;
        Entry: Text;
        Result: Text;
    begin
        for I := 1 to TrigMemo.EntryCount() do begin
            Entry := TrigMemo.EntryAt(I);
            if Entry.StartsWith('M') then
                Result += Entry.Substring(2) + ';';
        end;
        exit(Result);
    end;

    // For each marker: the probe's own table asks and database events (IsProbeEntry) up to the next marker or, for the last marker, to
    // the end of the list.
    local procedure Windows(): Text
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        I: Integer;
        Entry: Text;
        Result: Text;
    begin
        for I := FirstMark() to TrigMemo.EntryCount() do begin
            Entry := TrigMemo.EntryAt(I);
            if Entry.StartsWith('M') then
                Result += '|' + Entry.Substring(2) + ':'
            else
                if IsProbeEntry(Entry) then
                    Result += Entry + ',';
        end;
        exit(Result);
    end;

    // The asks for the five tables the login subscribers write (98506-98508 of XApp A, 98515 of XApp B, 98520 of XApp C) and the
    // database events for them (noted only for those tables). Every other table is left out: the setup table 98505 is written only
    // by the session that seeds its rows, Microsoft's login code writes its own tables in some sessions only, and other tests of
    // the same session write theirs, so those asks depend on the history of the database and of the session.
    local procedure IsProbeEntry(Entry: Text): Boolean
    begin
        exit((Entry in ['T98506', 'T98507', 'T98508', 'T98515', 'T98520']) or Entry.StartsWith('W'));
    end;

    local procedure ProbeEntries(From: Integer; Before: Integer): Text
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        I: Integer;
        Entry: Text;
        Result: Text;
    begin
        for I := From + 1 to Before - 1 do begin
            Entry := TrigMemo.EntryAt(I);
            if IsProbeEntry(Entry) then
                Result += Entry + ',';
        end;
        exit(Result);
    end;

    local procedure FirstMark(): Integer
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        I: Integer;
    begin
        for I := 1 to TrigMemo.EntryCount() do
            if TrigMemo.EntryAt(I).StartsWith('M') then
                exit(I);
        exit(TrigMemo.EntryCount() + 1);
    end;

    local procedure LastMark(): Integer
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        I: Integer;
    begin
        for I := TrigMemo.EntryCount() downto 1 do
            if TrigMemo.EntryAt(I).StartsWith('M') then
                exit(I);
        exit(0);
    end;
}

codeunit 97871 "LT LS Login Subs A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LoginOrder_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveOrder(Observer);
        Observer.Expect('order', 'A1;A2;A3;A4a;A4m;A4z;B1;B2;C1;C2;M;');
        Observer.Expect('order count', '11');
        Observer.Expect('A1 runs', '1');
        Observer.Expect('login GuiAllowed', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoginState_OneApp_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveStateOne(Observer);
        Observer.Expect('one loaded', 'Yes');
        Observer.Expect('one loaded by', 'A1');
        Observer.Expect('one activated', 'Yes');
        Observer.Expect('one setup', '2:S1;S2;');
        Observer.Expect('one touches', '3');
        Observer.Expect('one flag', 'Yes');
        Observer.Expect('one txt', 'A3');
        Observer.Expect('one num', '123');
        Observer.Expect('one log', '1=A1;2=A2;3=A3;');
        Observer.Verify();
    end;

    [Test]
    procedure LoginState_ThreeApps_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveStateMany(Observer);
        Observer.Expect('many loaded', 'Yes');
        Observer.Expect('many loaded by', 'A1');
        Observer.Expect('many activated', 'Yes');
        Observer.Expect('many setup', '2:S1;S2;');
        Observer.Expect('many touches', '3');
        Observer.Expect('many flag', 'Yes');
        Observer.Expect('many txt', 'C1');
        Observer.Expect('many num', '123');
        Observer.Expect('many log', '1=A1;2=B1;3=C1;');
        Observer.Verify();
    end;

    [Test]
    procedure LoginTriggers_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveTriggers(Observer);
        Observer.Expect('marks', 'A1;A2;A3;A4a;A4m;A4z;B1;B2;C1;C2;M;');
        Observer.Expect('checked', 'Yes');
        Observer.Expect('probe tables asked before first mark', '');
        Observer.Expect('windows', '|A1:T98506,WI98506,|A2:T98507,WI98507,|A3:T98508,WI98508,|A4a:|A4m:|A4z:|B1:T98515,WI98515,|B2:|C1:T98520,WI98520,|C2:|M:');
        Observer.Expect('written', '1=I98506;2=I98507;3=I98508;4=I98515;5=I98520;');
        Observer.Expect('cache', '5:T98506;T98507;T98508;T98515;T98520;');
        Observer.Verify();
    end;

    [Test]
    procedure LoginRunnerTables_FirstCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveRunnerTables(Observer, '');
        Observer.Expect('130450 asked before login', '0');
        Observer.Expect('130450 asked after login at most once', 'Yes');
        Observer.Expect('130451 asked before login', '0');
        Observer.Expect('130451 asked after login at most once', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoginState_SecondTest_ThenTestTouches()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
        One: Codeunit "LT LS XA State One";
    begin
        Reader.ObserveOrder(Observer);
        Reader.ObserveStateOne(Observer);
        One.Touch('T', 9);
        Observer.Observe('one txt after test touch', One.RawTxt());
        Observer.Observe('one num after test touch', One.RawNum());
        Observer.Expect('order', 'A1;A2;A3;A4a;A4m;A4z;B1;B2;C1;C2;M;');
        Observer.Expect('order count', '11');
        Observer.Expect('A1 runs', '1');
        Observer.Expect('login GuiAllowed', 'Yes');
        Observer.Expect('one loaded', 'Yes');
        Observer.Expect('one loaded by', 'A1');
        Observer.Expect('one activated', 'Yes');
        Observer.Expect('one setup', '2:S1;S2;');
        Observer.Expect('one touches', '3');
        Observer.Expect('one flag', 'Yes');
        Observer.Expect('one txt', 'A3');
        Observer.Expect('one num', '123');
        Observer.Expect('one log', '1=A1;2=A2;3=A3;');
        Observer.Expect('one txt after test touch', 'T');
        Observer.Expect('one num after test touch', '1239');
        Observer.Verify();
    end;

    [Test]
    procedure LoadMemo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveLoadMemo(Observer, '');
        Observer.Expect('load checked', 'Yes');
        Observer.Expect('load activated', 'Yes');
        Observer.Expect('load loads', '1');
        Observer.Expect('load watched', '6:T97878;T98506;T98507;T98508;T98515;T98520;');
        Observer.Expect('load written', '98506;98507;98508;98515;98520;');
        Observer.Verify();
    end;

    [Test]
    procedure LoadMemo_TestWritesFresh()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
        Fresh: Record "LT LS Fresh Write";
        Before: Integer;
    begin
        Before := Reader.LoadAsks();
        Fresh.DeleteAll();
        Observer.Observe('asks by fresh DeleteAll', Format(Reader.LoadAsks() - Before));
        Before := Reader.LoadAsks();
        Fresh.Init();
        Fresh."Entry No." := 0;
        Fresh.Tag := 'F1';
        Fresh.Insert();
        Observer.Observe('asks by fresh first insert', Format(Reader.LoadAsks() - Before));
        Before := Reader.LoadAsks();
        Fresh.Init();
        Fresh."Entry No." := 0;
        Fresh.Tag := 'F2';
        Fresh.Insert();
        Observer.Observe('asks by fresh second insert', Format(Reader.LoadAsks() - Before));
        Reader.ObserveLoadMemo(Observer, 'after fresh: ');
        Fresh.DeleteAll();
        Observer.Expect('asks by fresh DeleteAll', '1');
        Observer.Expect('asks by fresh first insert', '0');
        Observer.Expect('asks by fresh second insert', '0');
        Observer.Expect('after fresh: load checked', 'Yes');
        Observer.Expect('after fresh: load activated', 'Yes');
        Observer.Expect('after fresh: load loads', '1');
        Observer.Expect('after fresh: load watched', '6:T97878;T98506;T98507;T98508;T98515;T98520;');
        Observer.Expect('after fresh: load written', '98506;98507;98508;98515;98520;');
        Observer.Verify();
    end;

    [Test]
    procedure LoadMemo_TestWritesWatched()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
        Watched: Record "LT LS Watched Write";
        Before: Integer;
    begin
        Before := Reader.LoadAsks();
        Watched.DeleteAll();
        Observer.Observe('asks by watched DeleteAll', Format(Reader.LoadAsks() - Before));
        Before := Reader.LoadAsks();
        Watched.Init();
        Watched."Entry No." := 0;
        Watched.Tag := 'W1';
        Watched.Insert();
        Observer.Observe('asks by watched first insert', Format(Reader.LoadAsks() - Before));
        Before := Reader.LoadAsks();
        Watched.Init();
        Watched."Entry No." := 0;
        Watched.Tag := 'W2';
        Watched.Insert();
        Observer.Observe('asks by watched second insert', Format(Reader.LoadAsks() - Before));
        Reader.ObserveLoadMemo(Observer, 'after watched: ');
        Watched.DeleteAll();
        Observer.Expect('asks by watched DeleteAll', '1');
        Observer.Expect('asks by watched first insert', '0');
        Observer.Expect('asks by watched second insert', '0');
        Observer.Expect('after watched: load checked', 'Yes');
        Observer.Expect('after watched: load activated', 'Yes');
        Observer.Expect('after watched: load loads', '1');
        Observer.Expect('after watched: load watched', '6:T97878;T98506;T98507;T98508;T98515;T98520;');
        Observer.Expect('after watched: load written', '98506;98507;98508;98515;98520;97878;97878;');
        Observer.Verify();
    end;
}

codeunit 97872 "LT LS Login Subs B"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure LoginOrderAndState_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveOrder(Observer);
        Reader.ObserveStateOne(Observer);
        Reader.ObserveStateMany(Observer);
        Observer.Expect('order', 'A1;A2;A3;A4a;A4m;A4z;B1;B2;C1;C2;M;');
        Observer.Expect('order count', '11');
        Observer.Expect('A1 runs', '1');
        Observer.Expect('login GuiAllowed', 'Yes');
        Observer.Expect('one loaded', 'Yes');
        Observer.Expect('one loaded by', 'A1');
        Observer.Expect('one activated', 'Yes');
        Observer.Expect('one setup', '2:S1;S2;');
        Observer.Expect('one touches', '4');
        Observer.Expect('one flag', 'Yes');
        Observer.Expect('one txt', 'T');
        Observer.Expect('one num', '1239');
        Observer.Expect('one log', '1=A1;2=A2;3=A3;4=T;');
        Observer.Expect('many loaded', 'Yes');
        Observer.Expect('many loaded by', 'A1');
        Observer.Expect('many activated', 'Yes');
        Observer.Expect('many setup', '2:S1;S2;');
        Observer.Expect('many touches', '3');
        Observer.Expect('many flag', 'Yes');
        Observer.Expect('many txt', 'C1');
        Observer.Expect('many num', '123');
        Observer.Expect('many log', '1=A1;2=B1;3=C1;');
        Observer.Verify();
    end;

    [Test]
    procedure LoginTriggers_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveTriggers(Observer);
        Reader.ObserveRunnerTables(Observer, 'B ');
        Observer.Expect('marks', 'A1;A2;A3;A4a;A4m;A4z;B1;B2;C1;C2;M;');
        Observer.Expect('checked', 'Yes');
        Observer.Expect('probe tables asked before first mark', '');
        Observer.Expect('windows', '|A1:T98506,WI98506,|A2:T98507,WI98507,|A3:T98508,WI98508,|A4a:|A4m:|A4z:|B1:T98515,WI98515,|B2:|C1:T98520,WI98520,|C2:|M:');
        Observer.Expect('written', '1=I98506;2=I98507;3=I98508;4=I98515;5=I98520;');
        Observer.Expect('cache', '5:T98506;T98507;T98508;T98515;T98520;');
        Observer.Expect('B 130450 asked before login', '0');
        Observer.Expect('B 130450 asked after login at most once', 'Yes');
        Observer.Expect('B 130451 asked before login', '0');
        Observer.Expect('B 130451 asked after login at most once', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure LoadMemo_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveLoadMemo(Observer, 'B ');
        Observer.Expect('B load checked', 'Yes');
        Observer.Expect('B load activated', 'Yes');
        Observer.Expect('B load loads', '1');
        Observer.Expect('B load watched', '6:T97878;T98506;T98507;T98508;T98515;T98520;');
        Observer.Expect('B load written', '98506;98507;98508;98515;98520;97878;97878;');
        Observer.Verify();
    end;
}
