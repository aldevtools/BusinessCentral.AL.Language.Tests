// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subscribing-to-events
// Scope: in-scope
// Probe (al-runner issue 9021; tests: tests/al-language/events/platform-triggers/LsLoginStateTests.al): what a dependency app's (XApp A,
//   not Microsoft) "System Initialization".OnAfterLogin subscribers leave for the test session. The main app has the same subscribers
//   on its own objects (the app under test); XApp B adds one more (tests/al-language-xapp-b/LsXbLoginState.al).
//   Cells: SingleInstance globals of many types (temporary Record, Record, Dictionary, List of [Enum], Decimal, Date, Guid, a Codeunit
//   variable with its own globals); a SingleInstance codeunit set through a helper the subscriber's codeunit does not name; a
//   SingleInstance cache filled by Global Triggers subscribers when the login inserts rows; three apps' subscribers changing one
//   global in an order-dependent way; an integration event raised at login and answered by the main app; a manual subscriber bound at
//   login; a number sequence, isolated storage (module and company scope) and rows written at login; WorkDate, language and
//   application area as the subscriber saw them.
// Every login subscriber here only writes objects of this probe: it runs in every session of every corpus job.
// Install code is not used here (check-install-triggers.py).
// BC versions: 27 - 29

// singleinstance-shared-on-purpose: the probe is what the login leaves in these SingleInstance codeunits for every reader of the test
// session (the main app's Company Triggers subscriber, the test codeunits' OnRun and their tests); several test codeunits read them.

enum 91055 "LT LS XA Color"
{
    Extensible = false;
    value(0; Red) { }
    value(1; Green) { }
    value(2; Blue) { }
}

table 91056 "LT LS XA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Val; Integer) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}

table 91057 "LT LS XA Row 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 91058 "LT LS XA Box"
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

codeunit 91059 "LT LS XA Types"
{
    SingleInstance = true;

    var
        TempRow: Record "LT LS XA Row" temporary;
        Row: Record "LT LS XA Row";
        Dict: Dictionary of [Text, Text];
        Colors: List of [Enum "LT LS XA Color"];
        Dec: Decimal;
        Dt: Date;
        G: Guid;
        Box: Codeunit "LT LS XA Box";

    // Called after the login subscriber wrote rows A (Val 1) and B (Val 5) of "LT LS XA Row".
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
        Colors.Add("LT LS XA Color"::Green);
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
        Colors.Add("LT LS XA Color"::Blue);
        Dec += 1;
        Dt := Dt + 1;
        Box.Inc();
    end;

    procedure Facts(var L: List of [Text])
    var
        C: Enum "LT LS XA Color";
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

codeunit 91060 "LT LS XA Far"
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
        L.Add('xa far calls=' + Format(Calls));
        L.Add('xa far txt=' + Txt);
    end;
}

// Not SingleInstance; the login subscribers call it, and it sets "LT LS XA Far" (their codeunits do not name it).
codeunit 91061 "LT LS XA Helper"
{
    procedure Touch(Tag: Text)
    var
        Far: Codeunit "LT LS XA Far";
    begin
        Far.Touch(Tag);
    end;
}

// A cache filled by Global Triggers subscribers: every table id the setup is asked for, and the database inserts of the two tables above.
codeunit 91062 "LT LS XA Cache"
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
        if (TableId = Database::"LT LS XA Row") or (TableId = Database::"LT LS XA Row 2") then
            OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    begin
        if RecRef.Number = Database::"LT LS XA Row" then
            Inserts += 1;
        if RecRef.Number = Database::"LT LS XA Row 2" then
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
        L.Add('xa asked row=' + Format(AskedTimes(Database::"LT LS XA Row")));
        L.Add('xa asked row2=' + Format(AskedTimes(Database::"LT LS XA Row 2")));
        L.Add('xa inserts row=' + Format(Inserts));
        L.Add('xa inserts row2=' + Format(Inserts2));
        L.Add('xa asked 130400=' + Format(AskedTimes(130400)));
        L.Add('xa asked 130401=' + Format(AskedTimes(130401)));
    end;
}

codeunit 91063 "LT LS XA Order"
{
    SingleInstance = true;

    var
        Txt: Text;
        N: Integer;

    procedure Step(Name: Text; K: Integer)
    begin
        Txt += Name + ';';
        N := N * 2 + K;
    end;

    procedure Facts(var L: List of [Text])
    begin
        L.Add('order txt=' + Txt);
        L.Add('order n=' + Format(N));
    end;
}

codeunit 91064 "LT LS XA Events"
{
    procedure Ping(Source: Text)
    begin
        OnLsPing(Source);
    end;

    procedure Probe(): Text
    var
        Hits: Text;
    begin
        OnLsProbe(Hits);
        exit(Hits);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLsPing(Source: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLsProbe(var Hits: Text)
    begin
    end;
}

codeunit 91065 "LT LS XA Manual Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT LS XA Events", 'OnLsProbe', '', false, false)]
    local procedure OnLsProbe(var Hits: Text)
    begin
        Hits += 'xa;';
    end;
}

codeunit 91066 "LT LS XA Session"
{
    SingleInstance = true;

    var
        Sub: Codeunit "LT LS XA Manual Sub";
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
        if not NumberSequence.Exists('LT-LS-XA') then
            NumberSequence.Insert('LT-LS-XA', 100, 1);
        Seq := NumberSequence.Next('LT-LS-XA');
        Token := 'login';
        if IsolatedStorage.Set('LT-LS-XA', Token, DataScope::Module) then;
        if IsolatedStorage.Set('LT-LS-XA-C', Token, DataScope::Company) then;
    end;

    procedure Facts(var L: List of [Text])
    var
        V: Text;
    begin
        L.Add('xa logins=' + Format(Logins));
        L.Add('xa bound=' + Format(Bound));
        if NumberSequence.Exists('LT-LS-XA') then
            L.Add('xa seq current at least login=' + Format(NumberSequence.Current('LT-LS-XA') >= Seq))
        else
            L.Add('xa seq current at least login=no sequence');
        V := '';
        if IsolatedStorage.Get('LT-LS-XA', DataScope::Module, V) then;
        L.Add('xa iso module same as login=' + Format((V = Token) and (Token <> '')));
        V := '';
        if IsolatedStorage.Get('LT-LS-XA-C', DataScope::Company, V) then;
        L.Add('xa iso company same as login=' + Format((V = Token) and (Token <> '')));
    end;

    procedure SeenFacts(var L: List of [Text])
    begin
        L.Add('xa workdate same as login=' + Format(SeenWorkDate = WorkDate()));
        L.Add('xa language same as login=' + Format(SeenLanguage = GlobalLanguage()));
        L.Add('xa area same as login=' + Format(SeenArea = ApplicationArea()));
        L.Add('xa area at login empty=' + Format(SeenArea = ''));
    end;
}

codeunit 91067 "LT LS XA Rows"
{
    procedure Write()
    var
        R: Record "LT LS XA Row";
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
    end;

    procedure Facts(var L: List of [Text])
    var
        R: Record "LT LS XA Row";
    begin
        L.Add('xa rows=' + Format(R.Count()));
        if R.Get('A') then
            L.Add('xa row A=' + Format(R.Val))
        else
            L.Add('xa row A=missing');
        if R.Get('B') then
            L.Add('xa row B=' + Format(R.Val))
        else
            L.Add('xa row B=missing');
    end;

    procedure DeleteB()
    var
        R: Record "LT LS XA Row";
    begin
        if R.Get('B') then
            R.Delete(true);
    end;

    procedure InsertRow2(Id: Integer)
    var
        R: Record "LT LS XA Row 2";
    begin
        R.Id := Id;
        if R.Delete(true) then;
        if R.Insert(true) then;
    end;
}

// First of the two XApp A login subscribers (the lower id): rows, types, helper, order step a1, the integration event, session state.
codeunit 91068 "LT LS XA Login 1"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Rows: Codeunit "LT LS XA Rows";
        Types: Codeunit "LT LS XA Types";
        Helper: Codeunit "LT LS XA Helper";
        Order: Codeunit "LT LS XA Order";
        Events: Codeunit "LT LS XA Events";
        Sess: Codeunit "LT LS XA Session";
    begin
        Rows.Write();
        Types.Fill();
        Helper.Touch('xa');
        Order.Step('a1', 1);
        Events.Ping('xa');
        Sess.AtLogin();
    end;
}

codeunit 91069 "LT LS XA Login 2"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure OnAfterLogin()
    var
        Order: Codeunit "LT LS XA Order";
    begin
        Order.Step('a2', 2);
    end;
}
