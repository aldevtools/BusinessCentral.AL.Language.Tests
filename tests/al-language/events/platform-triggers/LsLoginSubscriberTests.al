// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/LsXaLoginSubscribers.al (memos 98509-98512, hub 98514,
//   OnAfterLogin subscribers 98530, 98533, 98536, 98537); XApp B tests/al-language-xapp-b/LsXbLoginSubscribers.al (98531, 98534);
//   XApp C tests/al-language-xapp-c/LsXcLoginSubscribers.al (98532, 98535); OnAfterLogin subscriber 97870 of this app (below).
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
//      first test codeunit and again in the second one.
//   Each cell is read in the first tests of codeunit A, again in its last test (after the test changed State One) and in the
//   first tests of codeunit B.
// Measured on a local BC 29.0.54011.55816 with the hybrid test runner (hub transport); BC 27 and 28 by the CI matrix.
// BC result:
//   A. The login raises the subscribers once per test session, before the first test, in this order: the subscriber codeunits of
//      XApp A in ascending codeunit id (98530 Zulu, 98533 Alpha, 98536 Mike, 98537), the three procedures of 98537 in procedure
//      name order (AlphaLogin, MikeLogin, ZuluLogin; declared Zulu, Alpha, Mike), then XApp B (98531, 98534), XApp C (98532,
//      98535) and last this app (97870), although 97870 is the lowest id: apps in dependency order, ascending codeunit id inside
//      an app. Codeunit B sees the same list (11 entries, A1 once): the login does not run again for the second codeunit.
//   B. State One (A1, A2, A3) and State Many (A1, B1, C1) each end with Loaded and Activated true, loaded by the first subscriber
//      (A1), the setup cache holding both seeded rows, three touches, the Boolean true, the Text of the last subscriber (A3, C1),
//      Num 123 and the temporary log rows in subscriber order. A change made by a test (Txt T, Num 1239, a fourth log row) is
//      seen by the second test codeunit.
//   C. Each login subscriber's first write to its table asks GetDatabaseTableTriggerSetup for that table and then raises
//      OnDatabaseInsert, inside that subscriber (before the next one starts); none of these tables is asked before the first
//      subscriber. The trigger cache is loaded once (Checked true, five tables) and is still the same in codeunit B. Not asserted
//      (it depends on the history of the database): in the first session after the apps were published, one Microsoft table
//      (9008) was asked before the first partner subscriber, so the cache was loaded by Microsoft's login code; in the sessions
//      after it no table was asked before the first subscriber, and the cache was loaded by the first subscriber's write. The
//      setup table 98505 is asked only in the session that seeds its rows.
//   D. Neither 130450 "Test Method Line" nor 130451 "AL Test Suite" is asked in the test session, before or after the login, in
//      codeunit A or in codeunit B: the runner does not write those rows in the test session (hub runner; the websocket runner of
//      BC 27 is measured by CI).
// BC versions: 27 - 29

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
        Observer.Observe(Prefix + Format(TableId) + ' asked after login', Format(After));
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
        Observer.Expect('130450 asked after login', '0');
        Observer.Expect('130451 asked before login', '0');
        Observer.Expect('130451 asked after login', '0');
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
        Observer.Expect('B 130450 asked after login', '0');
        Observer.Expect('B 130451 asked before login', '0');
        Observer.Expect('B 130451 asked after login', '0');
        Observer.Verify();
    end;
}
