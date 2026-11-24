// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/LsXaLoginState.al (91055-91069); XApp B
//   tests/al-language-xapp-b/LsXbLoginState.al (91073); the group 1 login filter of tests/al-language-xapp-a/G1sXaInstall.al (table 98474);
//   tables 91024-91026, enum 91051 and codeunits 91027-91048 of this app (below).
// Probe (al-runner issue 9021): what "System Initialization".OnAfterLogin subscribers leave for the test session, the same cells once
//   for subscribers of this app (the app under test) and once for subscribers of dependency apps (XApp A and XApp B, not Microsoft).
//   Each cell is read four ways: by the main app's "Company Triggers".OnCompanyOpenCompleted subscriber (snapshot "open"), by the OnRun
//   trigger of the first test codeunit of this file that runs (snapshot "onrun"), by test 1, and by test 2 after test 1 changed it.
//   Cells: types xa / types ma (SingleInstance globals: temporary Record with two rows, a filter and a position; Record after Get and
//   SetFilter; Dictionary of [Text, Text]; List of [Enum]; Decimal; Date; Guid; a Codeunit variable with its own global); far (a
//   SingleInstance codeunit set through a helper codeunit the subscriber's codeunit does not name, by subscribers of three apps); cache
//   (SingleInstance caches filled by Global Triggers subscribers when the login inserts rows; the number of setup asks per table, among
//   them "AL Test Suite" 130400 and "Test Method Line" 130401); order (four subscribers of three apps on one global, order-dependent:
//   Txt := Txt + name, N := N * 2 + k) and ping (an integration event of XApp A raised by the XApp A and XApp B subscribers, answered by
//   a SingleInstance codeunit of this app, plus this app's own subscriber); session (a manual subscriber bound at login, a number
//   sequence, isolated storage in module and company scope); rows (rows written at login; test 1 deletes one); g1 (a filter in filter
//   group 1 set at login); seen (WorkDate, language and application area at login against the test's).
// Not measured here: a login subscriber that changes WorkDate, the language, the application area, Random's seed or a Microsoft table.
//   Every login subscriber of the corpus runs in every session of every corpus job, so such a change would reach every other test.
// BC versions: 27 - 29
// singleinstance-shared-on-purpose: the probe is what the login leaves in SingleInstance codeunits for every reader of the test session;
//   the snapshot log and the login state are read by every test codeunit of this file.

table 91024 "LT LS MA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Val; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 91025 "LT LS MA Row 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 91026 "LT LS MA G1"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

enum 91051 "LT LS MA Color"
{
    Extensible = false;
    value(0; Red) { }
    value(1; Green) { }
    value(2; Blue) { }
}

codeunit 91027 "LT LS MA Box"
{
    var
        N: Integer;

    procedure SetN(Value: Integer)
    begin
        N := Value;
    end;

    procedure Inc()
    begin
        N += 1;
    end;

    procedure GetN(): Integer
    begin
        exit(N);
    end;
}

codeunit 91028 "LT LS MA Types"
{
    SingleInstance = true;

    var
        TempRow: Record "LT LS MA Row" temporary;
        Row: Record "LT LS MA Row";
        Dict: Dictionary of [Text, Text];
        Colors: List of [Enum "LT LS MA Color"];
        Dec: Decimal;
        Dt: Date;
        G: Guid;
        Box: Codeunit "LT LS MA Box";

    // Called after the login subscriber wrote rows A (Val 1) and B (Val 5) of "LT LS MA Row".
    procedure Fill()
    begin
        TempRow.Reset();
        TempRow.DeleteAll();
        TempRow."Code" := 'A';
        TempRow.Val := 1;
        TempRow.Insert();
        TempRow."Code" := 'B';
        TempRow.Val := 5;
        TempRow.Insert();
        TempRow.SetFilter(Val, '>=%1', 3);
        if TempRow.FindFirst() then;
        Row.Reset();
        if Row.Get('A') then;
        Row.SetFilter(Val, '<%1', 3);
        Clear(Dict);
        Dict.Add('k1', 'v1');
        Clear(Colors);
        Colors.Add("LT LS MA Color"::Green);
        Dec := 1.5;
        Dt := 20240315D;
        Evaluate(G, '{6F3B1C2A-0D4E-4B8F-9A21-3C5D7E9F1A2B}');
        Box.SetN(7);
    end;

    procedure Change()
    begin
        TempRow.SetRange(Val);
        if TempRow.FindLast() then;
        Row.SetRange(Val);
        Dict.Add('k2', 'v2');
        Colors.Add("LT LS MA Color"::Blue);
        Dec += 1;
        Dt := Dt + 1;
        Box.Inc();
    end;

    procedure Facts(var L: List of [Text])
    var
        C: Enum "LT LS MA Color";
        K: Text;
        T: Text;
    begin
        L.Add('tmp count=' + Format(TempRow.Count()));
        L.Add('tmp filters=' + TempRow.GetFilters());
        L.Add('tmp key=' + TempRow."Code");
        L.Add('rec key=' + Row."Code");
        L.Add('rec filters=' + Row.GetFilters());
        L.Add('rec count=' + Format(Row.Count()));
        T := '';
        foreach K in Dict.Keys() do
            T += K + ':' + Dict.Get(K) + ';';
        L.Add('dict=' + T);
        T := '';
        foreach C in Colors do
            T += Format(C) + ';';
        L.Add('colors=' + T);
        L.Add('dec=' + Format(Dec, 0, 9));
        L.Add('date=' + Format(Dt, 0, '<Year4>-<Month,2>-<Day,2>'));
        L.Add('guid=' + Format(G));
        L.Add('box=' + Format(Box.GetN()));
    end;
}

codeunit 91029 "LT LS MA Far"
{
    SingleInstance = true;

    var
        Calls: Integer;
        Txt: Text;

    procedure Touch(Tag: Text)
    begin
        Calls += 1;
        Txt += Tag + ';';
    end;

    procedure Facts(var L: List of [Text])
    begin
        L.Add('ma far calls=' + Format(Calls));
        L.Add('ma far txt=' + Txt);
    end;
}

// Not SingleInstance; the login subscriber calls it, and it sets "LT LS MA Far" (the subscriber's codeunit does not name it).
codeunit 91030 "LT LS MA Helper"
{
    procedure Touch(Tag: Text)
    var
        Far: Codeunit "LT LS MA Far";
    begin
        Far.Touch(Tag);
    end;
}

codeunit 91031 "LT LS MA Cache"
{
    SingleInstance = true;

    var
        Asked: List of [Integer];
        Inserts: Integer;
        Inserts2: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure Setup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        Asked.Add(TableId);
        if (TableId = Database::"LT LS MA Row") or (TableId = Database::"LT LS MA Row 2") then
            OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    begin
        if RecRef.Number = Database::"LT LS MA Row" then
            Inserts += 1;
        if RecRef.Number = Database::"LT LS MA Row 2" then
            Inserts2 += 1;
    end;

    procedure AskedTimes(TableId: Integer): Integer
    var
        I: Integer;
        N: Integer;
    begin
        foreach I in Asked do
            if I = TableId then
                N += 1;
        exit(N);
    end;

    procedure Facts(var L: List of [Text])
    begin
        L.Add('ma asked row=' + Format(AskedTimes(Database::"LT LS MA Row")));
        L.Add('ma asked row2=' + Format(AskedTimes(Database::"LT LS MA Row 2")));
        L.Add('ma inserts row=' + Format(Inserts));
        L.Add('ma inserts row2=' + Format(Inserts2));
        L.Add('ma asked 130400=' + Format(AskedTimes(130400)));
        L.Add('ma asked 130401=' + Format(AskedTimes(130401)));
    end;
}

// Answers XApp A's integration event (raised by the XApp A and XApp B login subscribers); this app's login subscriber adds a step too.
codeunit 91032 "LT LS MA Ping"
{
    SingleInstance = true;

    var
        Txt: Text;
        N: Integer;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LS XA Events", 'OnLsPing', '', false, false)]
    local procedure OnLsPing(Source: Text)
    begin
        Add(Source, StrLen(Source));
    end;

    procedure Add(Name: Text; K: Integer)
    begin
        Txt += Name + ';';
        N := N * 2 + K;
    end;

    procedure Facts(var L: List of [Text])
    begin
        L.Add('ping txt=' + Txt);
        L.Add('ping n=' + Format(N));
    end;
}

codeunit 91033 "LT LS MA Manual Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LS XA Events", 'OnLsProbe', '', false, false)]
    local procedure OnLsProbe(var Hits: Text)
    begin
        Hits += 'ma;';
    end;
}

codeunit 91034 "LT LS MA Session"
{
    SingleInstance = true;

    var
        Sub: Codeunit "LT LS MA Manual Sub";
        Bound: Boolean;
        Seq: BigInteger;
        Token: Text;
        SeenWorkDate: Date;
        SeenLanguage: Integer;
        SeenArea: Text;
        Logins: Integer;

    procedure AtLogin()
    begin
        Logins += 1;
        SeenWorkDate := WorkDate();
        SeenLanguage := GlobalLanguage();
        SeenArea := ApplicationArea();
        if not Bound then
            Bound := BindSubscription(Sub);
        if not NumberSequence.Exists('LT-LS-MA') then
            NumberSequence.Insert('LT-LS-MA', 100, 1);
        Seq := NumberSequence.Next('LT-LS-MA');
        Token := 'login';
        if IsolatedStorage.Set('LT-LS-MA', Token, DataScope::Module) then;
        if IsolatedStorage.Set('LT-LS-MA-C', Token, DataScope::Company) then;
    end;

    procedure Facts(var L: List of [Text])
    var
        V: Text;
    begin
        L.Add('ma logins=' + Format(Logins));
        L.Add('ma bound=' + Format(Bound));
        if NumberSequence.Exists('LT-LS-MA') then
            L.Add('ma seq current at least login=' + Format(NumberSequence.Current('LT-LS-MA') >= Seq))
        else
            L.Add('ma seq current at least login=no sequence');
        V := '';
        if IsolatedStorage.Get('LT-LS-MA', DataScope::Module, V) then;
        L.Add('ma iso module same as login=' + Format((V = Token) and (Token <> '')));
        V := '';
        if IsolatedStorage.Get('LT-LS-MA-C', DataScope::Company, V) then;
        L.Add('ma iso company same as login=' + Format((V = Token) and (Token <> '')));
    end;

    procedure SeenFacts(var L: List of [Text])
    begin
        L.Add('ma workdate same as login=' + Format(SeenWorkDate = WorkDate()));
        L.Add('ma language same as login=' + Format(SeenLanguage = GlobalLanguage()));
        L.Add('ma area same as login=' + Format(SeenArea = ApplicationArea()));
        L.Add('ma area at login empty=' + Format(SeenArea = ''));
    end;
}

codeunit 91035 "LT LS MA Rows"
{
    procedure Write()
    var
        R: Record "LT LS MA Row";
        G1: Record "LT LS MA G1";
    begin
        R.Init();
        R."Code" := 'A';
        if R.Delete(true) then;
        R.Val := 1;
        if not R.Insert(true) then
            if R.Modify(true) then;
        R.Init();
        R."Code" := 'B';
        if R.Delete(true) then;
        R.Val := 5;
        if not R.Insert(true) then
            if R.Modify(true) then;
        G1.Init();
        G1."Code" := 'X';
        G1.Qty := 1;
        if not G1.Insert() then
            G1.Modify();
        G1.Init();
        G1."Code" := 'Y';
        G1.Qty := 5;
        if not G1.Insert() then
            G1.Modify();
    end;

    // Sets Qty >= 3 in filter group 1 on a local record and leaves it set.
    procedure FilterG1()
    var
        G1: Record "LT LS MA G1";
    begin
        G1.FilterGroup(1);
        G1.SetFilter(Qty, '>=%1', 3);
        G1.FilterGroup(0);
    end;

    procedure Facts(var L: List of [Text])
    var
        R: Record "LT LS MA Row";
    begin
        L.Add('ma rows=' + Format(R.Count()));
        if R.Get('A') then
            L.Add('ma row A=' + Format(R.Val))
        else
            L.Add('ma row A=missing');
        if R.Get('B') then
            L.Add('ma row B=' + Format(R.Val))
        else
            L.Add('ma row B=missing');
    end;

    procedure G1Facts(var L: List of [Text])
    var
        G1: Record "LT LS MA G1";
        XaG1: Record "LT G1S Login Item";
    begin
        L.Add('ma g1 count=' + Format(G1.Count()));
        G1.FilterGroup(1);
        L.Add('ma g1 group 1 filter=' + G1.GetFilter(Qty));
        L.Add('xa g1 count=' + Format(XaG1.Count()));
        XaG1.FilterGroup(1);
        L.Add('xa g1 group 1 filter=' + XaG1.GetFilter(Qty));
    end;

    procedure DeleteB()
    var
        R: Record "LT LS MA Row";
    begin
        if R.Get('B') then
            R.Delete(true);
    end;

    procedure InsertRow2(Id: Integer)
    var
        R: Record "LT LS MA Row 2";
    begin
        R.Id := Id;
        if R.Delete(true) then;
        if R.Insert(true) then;
    end;
}

// The app under test's login subscriber: the twin of XApp A's, plus an order step on XApp A's global and a call of XApp A's helper.
codeunit 91036 "LT LS MA Login"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Rows: Codeunit "LT LS MA Rows";
        Types: Codeunit "LT LS MA Types";
        Helper: Codeunit "LT LS MA Helper";
        XaHelper: Codeunit "LT LS XA Helper";
        Order: Codeunit "LT LS XA Order";
        Ping: Codeunit "LT LS MA Ping";
        Sess: Codeunit "LT LS MA Session";
    begin
        Rows.Write();
        Rows.FilterG1();
        Types.Fill();
        Helper.Touch('ma');
        XaHelper.Touch('ma');
        Order.Step('m', 4);
        Ping.Add('m', 4);
        Sess.AtLogin();
    end;
}

// Reads one cell of the login state. Called live by the tests and by the snapshots below.
codeunit 91037 "LT LS Facts"
{
    procedure Collect(Cell: Text; var L: List of [Text])
    var
        XaTypes: Codeunit "LT LS XA Types";
        MaTypes: Codeunit "LT LS MA Types";
        XaFar: Codeunit "LT LS XA Far";
        MaFar: Codeunit "LT LS MA Far";
        XaCache: Codeunit "LT LS XA Cache";
        MaCache: Codeunit "LT LS MA Cache";
        Order: Codeunit "LT LS XA Order";
        Ping: Codeunit "LT LS MA Ping";
        XaSess: Codeunit "LT LS XA Session";
        MaSess: Codeunit "LT LS MA Session";
        Events: Codeunit "LT LS XA Events";
        XaRows: Codeunit "LT LS XA Rows";
        MaRows: Codeunit "LT LS MA Rows";
    begin
        case Cell of
            'types xa':
                XaTypes.Facts(L);
            'types ma':
                MaTypes.Facts(L);
            'far':
                begin
                    XaFar.Facts(L);
                    MaFar.Facts(L);
                end;
            'cache':
                begin
                    XaCache.Facts(L);
                    MaCache.Facts(L);
                end;
            'order':
                begin
                    Order.Facts(L);
                    Ping.Facts(L);
                end;
            'session':
                begin
                    XaSess.Facts(L);
                    MaSess.Facts(L);
                    L.Add('manual subscribers hit=' + Events.Probe());
                end;
            'rows':
                begin
                    XaRows.Facts(L);
                    MaRows.Facts(L);
                end;
            'g1':
                MaRows.G1Facts(L);
            'seen':
                begin
                    XaSess.SeenFacts(L);
                    MaSess.SeenFacts(L);
                end;
        end;
    end;

    procedure Change(Cell: Text)
    var
        XaTypes: Codeunit "LT LS XA Types";
        MaTypes: Codeunit "LT LS MA Types";
        XaHelper: Codeunit "LT LS XA Helper";
        MaHelper: Codeunit "LT LS MA Helper";
        Order: Codeunit "LT LS XA Order";
        Ping: Codeunit "LT LS MA Ping";
        XaRows: Codeunit "LT LS XA Rows";
        MaRows: Codeunit "LT LS MA Rows";
    begin
        case Cell of
            'types xa':
                XaTypes.Change();
            'types ma':
                MaTypes.Change();
            'far':
                begin
                    XaHelper.Touch('t');
                    MaHelper.Touch('t');
                end;
            'cache':
                begin
                    XaRows.InsertRow2(1);
                    MaRows.InsertRow2(1);
                end;
            'order':
                begin
                    Order.Step('t', 5);
                    Ping.Add('t', 5);
                end;
            'rows':
                begin
                    XaRows.DeleteB();
                    MaRows.DeleteB();
                end;
        end;
    end;

    // Test 1: the live state, then the change of the cell. Test 2: the live state after the change.
    procedure ReportLive(Observer: Codeunit "Probe Observer"; Cell: Text; ThenChange: Boolean)
    var
        L: List of [Text];
    begin
        Collect(Cell, L);
        Emit(Observer, L);
        if ThenChange then
            Change(Cell);
    end;

    procedure ReportSnap(Observer: Codeunit "Probe Observer"; Cell: Text; Stage: Text)
    var
        Log: Codeunit "LT LS Log";
        L: List of [Text];
    begin
        if Stage = 'onrun' then
            Observer.Observe('onrun snapshot taken', Format(Log.Calls(Stage) >= 1))
        else
            Observer.Observe(Stage + ' snapshots', Format(Log.Calls(Stage)));
        if Log.Get(Stage, Cell, L) then
            Emit(Observer, L);
    end;

    local procedure Emit(Observer: Codeunit "Probe Observer"; L: List of [Text])
    var
        F: Text;
        P: Integer;
    begin
        foreach F in L do begin
            P := StrPos(F, '=');
            Observer.Observe(CopyStr(F, 1, P - 1), CopyStr(F, P + 1));
        end;
    end;
}

// Snapshots of every cell: the first call per stage is kept, later calls only count.
codeunit 91038 "LT LS Log"
{
    SingleInstance = true;

    var
        Snaps: Dictionary of [Text, List of [Text]];
        CallCount: Dictionary of [Text, Integer];

    procedure Snap(Stage: Text)
    var
        Facts: Codeunit "LT LS Facts";
        Cells: List of [Text];
        Cell: Text;
        N: Integer;
    begin
        if CallCount.Get(Stage, N) then;
        CallCount.Set(Stage, N + 1);
        if N > 0 then
            exit;
        Cells.AddRange('types xa', 'types ma', 'far', 'cache', 'order', 'session', 'rows', 'g1', 'seen');
        foreach Cell in Cells do
            Keep(Stage, Cell, Facts);
    end;

    local procedure Keep(Stage: Text; Cell: Text; Facts: Codeunit "LT LS Facts")
    var
        L: List of [Text];
    begin
        Facts.Collect(Cell, L);
        Snaps.Set(Stage + '|' + Cell, L);
    end;

    procedure Calls(Stage: Text): Integer
    var
        N: Integer;
    begin
        if CallCount.Get(Stage, N) then;
        exit(N);
    end;

    procedure Get(Stage: Text; Cell: Text; var L: List of [Text]): Boolean
    begin
        exit(Snaps.Get(Stage + '|' + Cell, L));
    end;
}

codeunit 91039 "LT LS MA Open Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure OnCompanyOpenCompleted()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('open');
    end;
}

codeunit 91040 "LT LS Types XA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure TypesXa_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'types xa', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure TypesXa_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('types xa');
    end;

    [Test]
    procedure TypesXa_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'types xa', false);
        Observer.Finish();
    end;

    [Test]
    procedure TypesXa_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'types xa', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure TypesXa_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'types xa', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91041 "LT LS Types MA Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure TypesMa_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'types ma', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure TypesMa_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('types ma');
    end;

    [Test]
    procedure TypesMa_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'types ma', false);
        Observer.Finish();
    end;

    [Test]
    procedure TypesMa_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'types ma', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure TypesMa_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'types ma', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91042 "LT LS Far Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure Far_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'far', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure Far_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('far');
    end;

    [Test]
    procedure Far_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'far', false);
        Observer.Finish();
    end;

    [Test]
    procedure Far_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'far', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure Far_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'far', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91043 "LT LS Cache Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure Cache_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'cache', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure Cache_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('cache');
    end;

    [Test]
    procedure Cache_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'cache', false);
        Observer.Finish();
    end;

    [Test]
    procedure Cache_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'cache', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure Cache_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'cache', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91044 "LT LS Order Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure Order_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'order', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure Order_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('order');
    end;

    [Test]
    procedure Order_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'order', false);
        Observer.Finish();
    end;

    [Test]
    procedure Order_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'order', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure Order_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'order', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91045 "LT LS Session Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure Session_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'session', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure Session_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('session');
    end;

    [Test]
    procedure Session_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'session', false);
        Observer.Finish();
    end;

    [Test]
    procedure Session_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'session', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure Session_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'session', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91046 "LT LS Rows Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure Rows_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'rows', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure Rows_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('rows');
    end;

    [Test]
    procedure Rows_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'rows', false);
        Observer.Finish();
    end;

    [Test]
    procedure Rows_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'rows', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure Rows_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'rows', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91047 "LT LS G1 Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure G1_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'g1', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure G1_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('g1');
    end;

    [Test]
    procedure G1_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'g1', false);
        Observer.Finish();
    end;

    [Test]
    procedure G1_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'g1', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure G1_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'g1', 'onrun');
        Observer.Finish();
    end;
}

codeunit 91048 "LT LS Seen Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    var
        Log: Codeunit "LT LS Log";
    begin
        Log.Snap('onrun');
    end;

    [Test]
    procedure Seen_T1_Live()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'seen', false);
        Observer.Finish();
    end;

    // A passing test of its own, so the change is committed the same way in the observing and in the asserting run.
    [Test]
    procedure Seen_T1_Change()
    var
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.Change('seen');
    end;

    [Test]
    procedure Seen_T2_LiveAfterChange()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportLive(Observer, 'seen', false);
        Observer.Finish();
    end;

    [Test]
    procedure Seen_CompanyOpenSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'seen', 'open');
        Observer.Finish();
    end;

    [Test]
    procedure Seen_OnRunSnapshot()
    var
        Observer: Codeunit "Probe Observer";
        Facts: Codeunit "LT LS Facts";
    begin
        Facts.ReportSnap(Observer, 'seen', 'onrun');
        Observer.Finish();
    end;
}
