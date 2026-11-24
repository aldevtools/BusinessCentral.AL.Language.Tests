// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-global-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/LmXaMemoShapes.al (setup tables 98454, 98455, write table 98456,
//   ask log 98457, memos 98458 and 98460-98464, wrapper 98459, rows loader 98468, OnAfterLogin subscribers 98465-98467); tables 97782
//   "LT LM Watched" and 97783 "LT LM Fresh" of this app (below).
// Probe (al-runner issue 8945): load-once caches in SingleInstance codeunits of a dependency app, loaded by the first trigger setup ask
//   of the session (GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup). That first ask comes from one of two places, and which
//   one depends on the session: System Application's own login subscriber writes "User Login" (9008) when the user's last login is more
//   than 60 seconds ago or on another day, so 9008 is asked before any partner login subscriber; otherwise the first ask comes from the
//   first partner login subscriber that writes (here XApp A's 98465, which adds a row to the F5 setup rows). Cells:
//   F1. the memo is reached only through the integration events of a wrapper codeunit (not SingleInstance) that subscribes to the setup
//       ask and to OnAfterOnDatabaseInsert/Modify; Activated from a database read, the watched tables from a fixed list;
//   F2. Activated and the watched tables come from the app's own setup rows; the load copies the table ids into a List and a Dictionary;
//       F12 is F2 reached through the wrapper of F1;
//   F3. the load keeps the TableId of the ask that triggered it;
//   F4. the fixed list holds 9008 itself;
//   F5. login subscribers change the rows the load reads: the first partner write of the login adds a row (R1, table 98456), a later
//       subscriber adds another (R2, table 97783), the last one deletes both again.
//   Each memo is read after the login and after a test's first writes to a watched table (97782) and an unwatched one (97783).
// Measured on a local BC 29.0.54011.55816 in 20 sessions: 8 of the kind that asks 9008 first, 12 of the other; with the hub runner
//   (altool) and the websocket runner (run-tests.sh); with the setup rows present and with them deleted before the session (so the
//   load wrote the default rows). Only the "User Login" modify was seen (the user had logged in before); a session on a fresh database
//   inserts 9008. BC 27 and 28 by the CI matrix.
// BC result:
//   F1, F2, F12: the same values in every session: Checked and Activated true, one load, the watched tables, and the insert of the
//      login's write to 98456; the List and the Dictionary hold the rows' table ids in key order. Through the wrapper the values are the
//      same as with a direct subscriber. The load reads whatever rows the database holds: rows left by an earlier session are read as
//      they are (seen locally with rows of an older fixture version), so the values hold only while nothing else writes these rows.
//   F3: differs between the kinds: the first table is 9008 in a session that asks 9008 first and 98455 (the F5 rows table, written by
//      the first partner login subscriber) in the other. Asserted only as relations that hold whatever else Microsoft's login writes
//      first: the kept table is the first table asked in the session, and it is 98455 exactly when nothing was asked before the
//      partner login subscribers.
//   F4: the inserts of 98456 and the test's tables are the same in both kinds; a 9008 write is noted exactly in the sessions that ask
//      9008 first (BC raises OnAfterOnDatabaseModify for it, because the memo loaded inside that ask and its list has 9008). Asserted
//      as: a 9008 write is noted by the end of the login exactly when 9008 was asked during it.
//   F5: R1 and R2 are never in the loaded list, in both kinds. In a session that asks 9008 first the load runs before every partner
//      login subscriber; in the other it runs inside the ask of R1's own insert, before that row is written (the markers present at the
//      load are L1 only). A login subscriber's change of the rows therefore never reaches a load that its own write triggers: a change
//      before the load is not reachable with a write. Writes to 98456 are not noted, and neither is the test's write to 97783 (R2).
//   After a test's first writes: every memo notes the two inserts into 97782 and nothing for 97783, Checked and the load stay.
// BC versions: 27 - 29

table 97782 "LT LM Watched"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

table 97783 "LT LM Fresh"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; Tag; Text[30]) { }
    }

    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 97781 "LT LM Memo Reader"
{
    procedure ObserveWrapped(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA Wrapped Memo";
    begin
        Observer.Observe(Prefix + 'F1 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'F1 activated', Memo.RawActivated());
        Observer.Observe(Prefix + 'F1 loads', Memo.RawLoads());
        Observer.Observe(Prefix + 'F1 watched', Memo.RawWatched());
        Observer.Observe(Prefix + 'F1 written', Memo.RawWritten());
    end;

    procedure ObserveRows(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA Rows Memo";
    begin
        Observer.Observe(Prefix + 'F2 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'F2 activated', Memo.RawActivated());
        Observer.Observe(Prefix + 'F2 loads', Memo.RawLoads());
        Observer.Observe(Prefix + 'F2 list', Memo.RawWatched());
        Observer.Observe(Prefix + 'F2 dictionary', Memo.RawDict());
        Observer.Observe(Prefix + 'F2 written', Memo.RawWritten());
    end;

    procedure ObserveWrappedRows(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA Wrapped Rows Memo";
    begin
        Observer.Observe(Prefix + 'F12 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'F12 activated', Memo.RawActivated());
        Observer.Observe(Prefix + 'F12 loads', Memo.RawLoads());
        Observer.Observe(Prefix + 'F12 list', Memo.RawWatched());
        Observer.Observe(Prefix + 'F12 dictionary', Memo.RawDict());
        Observer.Observe(Prefix + 'F12 written', Memo.RawWritten());
    end;

    procedure ObserveFirstTable(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA First Table";
        AskLog: Codeunit "LT LM XA Ask Log";
    begin
        Observer.Observe(Prefix + 'F3 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'F3 loads', Memo.RawLoads());
        Observer.Observe(Prefix + 'F3 same table as at the login', Format(Memo.FirstTable() = AskLog.RawSnapFirstTable()));
        Observer.Observe(Prefix + 'F3 first table is the first table asked in the session', Format(Memo.FirstTable() = AskLog.RawSnapFirstAsk()));
        Observer.Observe(Prefix + 'F3 first table is the first login write exactly when nothing was asked before the login subscribers', Format((Memo.FirstTable() = 98455) = (not AskLog.RawSnapKind())));
    end;

    procedure ObserveLoginMemo(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA Login Memo";
        AskLog: Codeunit "LT LM XA Ask Log";
    begin
        Observer.Observe(Prefix + 'F4 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'F4 loads', Memo.RawLoads());
        Observer.Observe(Prefix + 'F4 watched', Memo.RawWatched());
        Observer.Observe(Prefix + 'F4 written without 9008', Memo.WrittenWithout9008());
        Observer.Observe(Prefix + 'F4 9008 noted at the login exactly when 9008 was asked at the login', Format((StrPos(AskLog.RawSnapLoginWritten(), '9008') > 0) = AskLog.RawSnapNineAsked()));
    end;

    procedure ObserveChanged(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    var
        Memo: Codeunit "LT LM XA Changed Memo";
    begin
        Observer.Observe(Prefix + 'F5 checked', Memo.RawChecked());
        Observer.Observe(Prefix + 'F5 activated', Memo.RawActivated());
        Observer.Observe(Prefix + 'F5 loads', Memo.RawLoads());
        Observer.Observe(Prefix + 'F5 list', Memo.RawWatched());
        Observer.Observe(Prefix + 'F5 dictionary', Memo.RawDict());
        Observer.Observe(Prefix + 'F5 written', Memo.RawWritten());
    end;

    // Local observation only: which kind of session this is and the raw values that differ between the kinds.
    procedure ObserveKind(var Observer: Codeunit "Probe Observer")
    var
        AskLog: Codeunit "LT LM XA Ask Log";
        Changed: Codeunit "LT LM XA Changed Memo";
        LoginMemo: Codeunit "LT LM XA Login Memo";
    begin
        Observer.Observe('kind asked before L1', AskLog.AsksBeforeFirstMark());
        Observer.Observe('kind snap', Format(AskLog.RawSnapKind()));
        Observer.Observe('kind marks', AskLog.Marks());
        Observer.Observe('raw F3 first table', Format(AskLog.RawSnapFirstTable()));
        Observer.Observe('raw F4 written at login', AskLog.RawSnapLoginWritten());
        Observer.Observe('raw F4 written now', LoginMemo.RawWritten());
        Observer.Observe('raw F5 load marks', Changed.RawLoadMarks());
    end;
}

codeunit 97780 "LT LM Memo Shape Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure WrapperMemo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
    begin
        Reader.ObserveWrapped(Observer, '');
        Observer.Expect('F1 checked', 'Yes');
        Observer.Expect('F1 activated', 'Yes');
        Observer.Expect('F1 loads', '1');
        Observer.Expect('F1 watched', '2:98456;97782;');
        Observer.Expect('F1 written', 'I98456;');
        Observer.Verify();
    end;

    [Test]
    procedure RowsMemo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
    begin
        Reader.ObserveRows(Observer, '');
        Reader.ObserveWrappedRows(Observer, '');
        Observer.Expect('F2 checked', 'Yes');
        Observer.Expect('F2 activated', 'Yes');
        Observer.Expect('F2 loads', '1');
        Observer.Expect('F2 list', '2:97782;98456;');
        Observer.Expect('F2 dictionary', '2:97782=T97782;98456=T98456;');
        Observer.Expect('F2 written', 'I98456;');
        Observer.Expect('F12 checked', 'Yes');
        Observer.Expect('F12 activated', 'Yes');
        Observer.Expect('F12 loads', '1');
        Observer.Expect('F12 list', '2:97782;98456;');
        Observer.Expect('F12 dictionary', '2:97782=T97782;98456=T98456;');
        Observer.Expect('F12 written', 'I98456;');
        Observer.Verify();
    end;

    [Test]
    procedure FirstTableMemo_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
    begin
        Reader.ObserveFirstTable(Observer, '');
        Observer.Expect('F3 checked', 'Yes');
        Observer.Expect('F3 loads', '1');
        Observer.Expect('F3 same table as at the login', 'Yes');
        Observer.Expect('F3 first table is the first table asked in the session', 'Yes');
        Observer.Expect('F3 first table is the first login write exactly when nothing was asked before the login subscribers', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UserLoginWatched_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
    begin
        Reader.ObserveLoginMemo(Observer, '');
        Observer.Expect('F4 checked', 'Yes');
        Observer.Expect('F4 loads', '1');
        Observer.Expect('F4 watched', '3:9008;98456;97782;');
        Observer.Expect('F4 written without 9008', 'I98456;');
        Observer.Expect('F4 9008 noted at the login exactly when 9008 was asked at the login', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ChangedRows_AfterLogin()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
    begin
        Reader.ObserveChanged(Observer, '');
        Observer.Expect('F5 checked', 'Yes');
        Observer.Expect('F5 activated', 'Yes');
        Observer.Expect('F5 loads', '1');
        Observer.Expect('F5 list', '1:97782;');
        Observer.Expect('F5 dictionary', '1:97782=T97782;');
        Observer.Expect('F5 written', '');
        Observer.Verify();
    end;

    [Test]
    procedure AllMemos_TestFirstWrites()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
        Watched: Record "LT LM Watched";
        Fresh: Record "LT LM Fresh";
    begin
        Fresh.DeleteAll();
        Fresh.Init();
        Fresh.Tag := 'F1';
        Fresh.Insert();
        Watched.DeleteAll();
        Watched.Init();
        Watched.Tag := 'W1';
        Watched.Insert();
        Watched.Init();
        Watched."Entry No." := 0;
        Watched.Tag := 'W2';
        Watched.Insert();
        Reader.ObserveWrapped(Observer, 'after: ');
        Reader.ObserveRows(Observer, 'after: ');
        Reader.ObserveWrappedRows(Observer, 'after: ');
        Fresh.DeleteAll();
        Watched.DeleteAll();
        Observer.Expect('after: F1 checked', 'Yes');
        Observer.Expect('after: F1 activated', 'Yes');
        Observer.Expect('after: F1 loads', '1');
        Observer.Expect('after: F1 watched', '2:98456;97782;');
        Observer.Expect('after: F1 written', 'I98456;I97782;I97782;');
        Observer.Expect('after: F2 checked', 'Yes');
        Observer.Expect('after: F2 activated', 'Yes');
        Observer.Expect('after: F2 loads', '1');
        Observer.Expect('after: F2 list', '2:97782;98456;');
        Observer.Expect('after: F2 dictionary', '2:97782=T97782;98456=T98456;');
        Observer.Expect('after: F2 written', 'I98456;I97782;I97782;');
        Observer.Expect('after: F12 checked', 'Yes');
        Observer.Expect('after: F12 activated', 'Yes');
        Observer.Expect('after: F12 loads', '1');
        Observer.Expect('after: F12 list', '2:97782;98456;');
        Observer.Expect('after: F12 dictionary', '2:97782=T97782;98456=T98456;');
        Observer.Expect('after: F12 written', 'I98456;I97782;I97782;');
        Observer.Verify();
    end;

    // Runs after AllMemos_TestFirstWrites: the memos keep what that test's writes noted.
    [Test]
    procedure AllMemos_AfterTestFirstWrites()
    var
        Observer: Codeunit "Probe Observer";
        Reader: Codeunit "LT LM Memo Reader";
    begin
        Reader.ObserveFirstTable(Observer, 'after: ');
        Reader.ObserveLoginMemo(Observer, 'after: ');
        Reader.ObserveChanged(Observer, 'after: ');
        Observer.Expect('after: F3 checked', 'Yes');
        Observer.Expect('after: F3 loads', '1');
        Observer.Expect('after: F3 same table as at the login', 'Yes');
        Observer.Expect('after: F3 first table is the first table asked in the session', 'Yes');
        Observer.Expect('after: F3 first table is the first login write exactly when nothing was asked before the login subscribers', 'Yes');
        Observer.Expect('after: F4 checked', 'Yes');
        Observer.Expect('after: F4 loads', '1');
        Observer.Expect('after: F4 watched', '3:9008;98456;97782;');
        Observer.Expect('after: F4 written without 9008', 'I98456;I97782;I97782;');
        Observer.Expect('after: F4 9008 noted at the login exactly when 9008 was asked at the login', 'Yes');
        Observer.Expect('after: F5 checked', 'Yes');
        Observer.Expect('after: F5 activated', 'Yes');
        Observer.Expect('after: F5 loads', '1');
        Observer.Expect('after: F5 list', '1:97782;');
        Observer.Expect('after: F5 dictionary', '1:97782=T97782;');
        Observer.Expect('after: F5 written', 'I97782;I97782;');
        Observer.Verify();
    end;
}
