// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/LsXaLoginSubscribers.al (memos 98509-98512, hub 98514,
//   OnAfterLogin subscribers 98530, 98533, 98536, 98537); XApp B tests/al-language-xapp-b/LsXbLoginSubscribers.al (98531, 98534);
//   XApp C tests/al-language-xapp-c/LsXcLoginSubscribers.al (98532, 98535); OnAfterLogin subscriber 97870 of this app (below).
// Probe (al-runner issue 8945): more than two "System Initialization".OnAfterLogin subscribers change the same SingleInstance
//   codeunits of a dependency app before the first test. Cells:
//   A. the order of the subscribers: three plain subscriber codeunits of one app whose names are not in id order, two subscriber
//      procedures in one codeunit, two subscribers in each of three dependency apps with ids interleaved across the apps, and one
//      subscriber of this app (the app under test);
//   B. one SingleInstance codeunit changed by the three subscribers of one app (State One) and by one subscriber of each of three
//      apps (State Many): a cache loaded once (Booleans and a temporary Record filled from setup rows), the same Boolean value set
//      by every subscriber, a Text where the last writer wins, Num := Num * 10 + k, and rows added to a temporary Record;
//   C. a cache that the dependency app's "Global Triggers" subscribers fill while the login subscribers write rows: which tables
//      the session asks GetDatabaseTableTriggerSetup for before, during and after the partner subscribers, the database events
//      raised for the subscribers' rows, and the cache after the login;
//   D. whether the test runner's own tables (130450 "Test Method Line", 130451 "AL Test Suite") are asked after the login, in the
//      first test codeunit and again in the second one.
//   Each cell is read in the first test of codeunit A, again in its second test (after the test changed State One) and in the
//   first test of codeunit B.
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
        Observer.Observe('asks before first mark', Format(First > 1));
        Observer.Observe('checked', TrigMemo.RawChecked());
        Observer.Observe('checked before first mark', Format((TrigMemo.RawCheckedAt() > 0) and (TrigMemo.RawCheckedAt() < First)));
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

    procedure ObserveRaw(var Observer: Codeunit "Probe Observer")
    var
        TrigMemo: Codeunit "LT LS XA Trig Memo";
        I: Integer;
        Before: Text;
        After: Text;
    begin
        for I := 1 to TrigMemo.EntryCount() do
            if I < FirstMark() then
                Before += TrigMemo.EntryAt(I) + ','
            else
                if I > LastMark() then
                    After += TrigMemo.EntryAt(I) + ',';
        Observer.Observe('raw before', Before);
        Observer.Observe('raw after', CopyStr(After, 1, 2000));
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

    // For each marker: the probe's own table asks (T985..) and database events (W..) up to the next marker or, for the last marker, to
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
                if Entry.StartsWith('T985') or Entry.StartsWith('W') then
                    Result += Entry + ',';
        end;
        exit(Result);
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
            if Entry.StartsWith('T985') or Entry.StartsWith('W') then
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
        Observer.Finish();
    end;

    [Test]
    procedure LoginState_OneApp_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveStateOne(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure LoginState_ThreeApps_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveStateMany(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure LoginTriggers_FirstTest()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveTriggers(Observer);
        Observer.Finish();
    end;

    [Test]
    procedure LoginRunnerTables_FirstCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveRunnerTables(Observer, '');
        Observer.Finish();
    end;

    [Test]
    procedure LoginRaw_FirstCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveRaw(Observer);
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure LoginTriggers_SecondCodeunit()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LS Login Reader";
    begin
        Reader.ObserveTriggers(Observer);
        Reader.ObserveRunnerTables(Observer, 'B ');
        Observer.Finish();
    end;
}
