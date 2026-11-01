// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/numbersequence/numbersequence-data-type
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT Y56 Seq Install (93600, SeqCarryInstall.al: creates Y56-I-* from 1, step 1)
// Probe (al-runner issue 6638): under "Test Runner - Isol. Codeunit" (130450) an earlier test codeunit restarts or deletes a number
//   sequence; what do the tests of the same codeunit and the later test codeunits see of it (Exists, Current, Next, a new Insert)?
//   The neighbours: RqIsolationModes.al (lt-qu-commit-isolation) and Y35OnRunStorage.al (al-language-testlibraries).
// Shape: two groups of three codeunits run in id order, D (Delete, delete and insert again, a new Insert, Next) and R (Restart).
//   Every codeunit has an _Act test that changes the sequences, records what it saw in a global and never fails, then a _Report
//   test that observes the record and reads the sequences again (what a later test of the SAME codeunit sees). The test codeunit is
//   one instance for all its tests (RqIsolationModes.al). Every test has [HandlerFunctions] and uses the handler, so the Linux legs
//   do not send the codeunit to the hub (see RqIsolationModes.al).
// Values: State = Exists(Name) | Exists(Name, false) | Current(Name) ('missing' when Exists(Name, false) is false); Next = the number
//   NumberSequence.Next returned.
// BC versions: 27.5, 28.5, 29.0

table 93601 "LT Y56 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Key"; Code[20]) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }
}

codeunit 93602 "LT Y56 Seq Probe"
{
    procedure State(Name: Text): Text
    begin
        if not NumberSequence.Exists(Name, false) then
            exit(Format(NumberSequence.Exists(Name)) + '|No|missing');
        exit(Format(NumberSequence.Exists(Name)) + '|Yes|' + Format(NumberSequence.Current(Name, false)));
    end;

    procedure TakeNext(Name: Text): Text
    begin
        if not NumberSequence.Exists(Name, false) then
            exit('missing');
        exit(Format(NumberSequence.Next(Name, false)));
    end;

    procedure Fresh(Name: Text; Seed: BigInteger)
    begin
        if NumberSequence.Exists(Name, false) then
            NumberSequence.Delete(Name, false);
        NumberSequence.Insert(Name, Seed, 1, false);
    end;

    procedure RowSeen(K: Code[20]): Text
    var
        Row: Record "LT Y56 Row";
    begin
        if not Row.Get(K) then
            exit('missing');
        exit('found/' + Row.Name);
    end;

    // The reporter's later test: insert a row of the app's own table and read it back.
    procedure InsertAndRead(K: Code[20]; N: Text[30]): Text
    var
        Row: Record "LT Y56 Row";
    begin
        if Row.Get(K) then
            Row.Delete();
        Row.Init();
        Row."Key" := K;
        Row.Name := N;
        Row.Insert();
        exit(RowSeen(K));
    end;
}

codeunit 93603 "LT Y56 D1 Deletes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT Y56 Seq Probe";
        Keys: List of [Text];
        Values: List of [Text];


    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure D1_Act()
    begin
        Message('y56');
        Log('start_d', Probe.State('Y56-I-D'));
        Log('start_di', Probe.State('Y56-I-DI'));
        Log('start_n', Probe.State('Y56-I-N'));
        Log('start_tnew', Probe.State('Y56-T-NEW'));
        NumberSequence.Delete('Y56-I-D', false);
        Log('after_delete_d', Probe.State('Y56-I-D'));
        NumberSequence.Delete('Y56-I-DI', false);
        NumberSequence.Insert('Y56-I-DI', 40, 1, false);
        Log('after_reinsert_di', Probe.State('Y56-I-DI'));
        Log('next_n', Probe.TakeNext('Y56-I-N'));
        Probe.Fresh('Y56-T-NEW', 7);
        Log('after_insert_tnew', Probe.State('Y56-T-NEW'));
        Log('next_tnew', Probe.TakeNext('Y56-T-NEW'));
        Log('own_row', Probe.InsertAndRead('D1', 'First'));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure D1_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Replay(Observer);
        Observer.Observe('later_d', Probe.State('Y56-I-D'));
        Observer.Observe('later_di', Probe.State('Y56-I-DI'));
        Observer.Observe('later_n', Probe.State('Y56-I-N'));
        Observer.Observe('later_tnew', Probe.State('Y56-T-NEW'));
        Observer.Finish();
    end;

    local procedure Log(K: Text; V: Text)
    begin
        Keys.Add(K);
        Values.Add(V);
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        for I := 1 to Keys.Count() do
            Observer.Observe(Keys.Get(I), Values.Get(I));
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}

codeunit 93604 "LT Y56 D2 Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT Y56 Seq Probe";
        Keys: List of [Text];
        Values: List of [Text];


    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure D2_Act()
    begin
        Message('y56');
        Log('seen_d', Probe.State('Y56-I-D'));
        Log('seen_di', Probe.State('Y56-I-DI'));
        Log('seen_n', Probe.State('Y56-I-N'));
        Log('seen_tnew', Probe.State('Y56-T-NEW'));
        Log('seen_row_d1', Probe.RowSeen('D1'));
        Log('next_di', Probe.TakeNext('Y56-I-DI'));
        Log('next_n', Probe.TakeNext('Y56-I-N'));
        Log('next_tnew', Probe.TakeNext('Y56-T-NEW'));
        if NumberSequence.Exists('Y56-I-D', false) then
            Log('insert_d', 'exists')
        else begin
            NumberSequence.Insert('Y56-I-D', 300, 1, false);
            Log('insert_d', 'inserted');
        end;
        Log('after_insert_d', Probe.State('Y56-I-D'));
        Log('own_row', Probe.InsertAndRead('D2', 'Second'));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure D2_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Replay(Observer);
        Observer.Observe('later_d', Probe.State('Y56-I-D'));
        Observer.Observe('later_di', Probe.State('Y56-I-DI'));
        Observer.Observe('later_n', Probe.State('Y56-I-N'));
        Observer.Observe('later_tnew', Probe.State('Y56-T-NEW'));
        Observer.Finish();
    end;

    local procedure Log(K: Text; V: Text)
    begin
        Keys.Add(K);
        Values.Add(V);
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        for I := 1 to Keys.Count() do
            Observer.Observe(Keys.Get(I), Values.Get(I));
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}

codeunit 93605 "LT Y56 D3 Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT Y56 Seq Probe";
        Keys: List of [Text];
        Values: List of [Text];


    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure D3_Act()
    begin
        Message('y56');
        Log('seen_d', Probe.State('Y56-I-D'));
        Log('seen_di', Probe.State('Y56-I-DI'));
        Log('seen_n', Probe.State('Y56-I-N'));
        Log('seen_tnew', Probe.State('Y56-T-NEW'));
        Log('seen_row_d2', Probe.RowSeen('D2'));
        Log('next_d', Probe.TakeNext('Y56-I-D'));
        Log('next_di', Probe.TakeNext('Y56-I-DI'));
        Log('next_n', Probe.TakeNext('Y56-I-N'));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure D3_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Replay(Observer);
        Observer.Observe('later_d', Probe.State('Y56-I-D'));
        Observer.Observe('later_di', Probe.State('Y56-I-DI'));
        Observer.Observe('later_n', Probe.State('Y56-I-N'));
        Observer.Observe('later_tnew', Probe.State('Y56-T-NEW'));
        Observer.Finish();
    end;

    local procedure Log(K: Text; V: Text)
    begin
        Keys.Add(K);
        Values.Add(V);
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        for I := 1 to Keys.Count() do
            Observer.Observe(Keys.Get(I), Values.Get(I));
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}

codeunit 93606 "LT Y56 R1 Restarts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT Y56 Seq Probe";
        Keys: List of [Text];
        Values: List of [Text];
        OnRunNext: Text;

    // The test tool's discovery step runs OnRun once more before the run (Y35OnRunStorage.al): OnRun starts its sequence again.
    trigger OnRun()
    begin
        Probe.Fresh('Y56-O-R', 1);
        OnRunNext := Probe.TakeNext('Y56-O-R');
    end;


    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure R1_Act()
    begin
        Message('y56');
        Log('onrun_next_or', OnRunNext);
        Log('start_r', Probe.State('Y56-I-R'));
        Log('start_rs', Probe.State('Y56-I-RS'));
        Log('start_tr', Probe.State('Y56-T-R'));
        Log('start_or', Probe.State('Y56-O-R'));
        Log('start_rn', Probe.State('Y56-I-RN'));
        Log('next_r', Probe.TakeNext('Y56-I-R'));
        Log('next_r2', Probe.TakeNext('Y56-I-R'));
        NumberSequence.Restart('Y56-I-R');
        Log('after_restart_r', Probe.State('Y56-I-R'));
        Log('next_after_restart_r', Probe.TakeNext('Y56-I-R'));
        Log('next_rs', Probe.TakeNext('Y56-I-RS'));
        NumberSequence.Restart('Y56-I-RS', 50);
        Log('after_restart_rs', Probe.State('Y56-I-RS'));
        Probe.Fresh('Y56-T-R', 1);
        Log('next_tr', Probe.TakeNext('Y56-T-R'));
        Log('next_tr2', Probe.TakeNext('Y56-T-R'));
        NumberSequence.Restart('Y56-T-R', 20);
        Log('after_restart_tr', Probe.State('Y56-T-R'));
        NumberSequence.Restart('Y56-O-R', 30);
        Log('after_restart_or', Probe.State('Y56-O-R'));
        Log('own_row', Probe.InsertAndRead('R1', 'First'));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure R1_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Replay(Observer);
        Observer.Observe('later_r', Probe.State('Y56-I-R'));
        Observer.Observe('later_rs', Probe.State('Y56-I-RS'));
        Observer.Observe('later_tr', Probe.State('Y56-T-R'));
        Observer.Observe('later_or', Probe.State('Y56-O-R'));
        Observer.Observe('later_rn', Probe.State('Y56-I-RN'));
        Observer.Finish();
    end;

    local procedure Log(K: Text; V: Text)
    begin
        Keys.Add(K);
        Values.Add(V);
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        for I := 1 to Keys.Count() do
            Observer.Observe(Keys.Get(I), Values.Get(I));
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}

codeunit 93607 "LT Y56 R2 Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT Y56 Seq Probe";
        Keys: List of [Text];
        Values: List of [Text];


    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure R2_Act()
    begin
        Message('y56');
        Log('seen_r', Probe.State('Y56-I-R'));
        Log('seen_rs', Probe.State('Y56-I-RS'));
        Log('seen_tr', Probe.State('Y56-T-R'));
        Log('seen_or', Probe.State('Y56-O-R'));
        Log('seen_rn', Probe.State('Y56-I-RN'));
        Log('seen_row_r1', Probe.RowSeen('R1'));
        Log('next_r', Probe.TakeNext('Y56-I-R'));
        Log('next_rs', Probe.TakeNext('Y56-I-RS'));
        Log('next_tr', Probe.TakeNext('Y56-T-R'));
        Log('next_or', Probe.TakeNext('Y56-O-R'));
        Log('next_rn', Probe.TakeNext('Y56-I-RN'));
        NumberSequence.Restart('Y56-I-RN', 70);
        Log('after_restart_rn', Probe.State('Y56-I-RN'));
        Log('own_row', Probe.InsertAndRead('R2', 'Second'));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure R2_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Replay(Observer);
        Observer.Observe('later_r', Probe.State('Y56-I-R'));
        Observer.Observe('later_rs', Probe.State('Y56-I-RS'));
        Observer.Observe('later_tr', Probe.State('Y56-T-R'));
        Observer.Observe('later_or', Probe.State('Y56-O-R'));
        Observer.Observe('later_rn', Probe.State('Y56-I-RN'));
        Observer.Finish();
    end;

    local procedure Log(K: Text; V: Text)
    begin
        Keys.Add(K);
        Values.Add(V);
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        for I := 1 to Keys.Count() do
            Observer.Observe(Keys.Get(I), Values.Get(I));
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}

codeunit 93608 "LT Y56 R3 Reads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Probe: Codeunit "LT Y56 Seq Probe";
        Keys: List of [Text];
        Values: List of [Text];


    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure R3_Act()
    begin
        Message('y56');
        Log('seen_r', Probe.State('Y56-I-R'));
        Log('seen_rs', Probe.State('Y56-I-RS'));
        Log('seen_tr', Probe.State('Y56-T-R'));
        Log('seen_or', Probe.State('Y56-O-R'));
        Log('seen_rn', Probe.State('Y56-I-RN'));
        Log('next_r', Probe.TakeNext('Y56-I-R'));
        Log('next_rs', Probe.TakeNext('Y56-I-RS'));
        Log('next_or', Probe.TakeNext('Y56-O-R'));
        Log('next_rn', Probe.TakeNext('Y56-I-RN'));
    end;

    [Test]
    [HandlerFunctions('Y56MsgHandler')]
    procedure R3_Report()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message('y56');
        Replay(Observer);
        Observer.Observe('later_r', Probe.State('Y56-I-R'));
        Observer.Observe('later_rs', Probe.State('Y56-I-RS'));
        Observer.Observe('later_tr', Probe.State('Y56-T-R'));
        Observer.Observe('later_or', Probe.State('Y56-O-R'));
        Observer.Observe('later_rn', Probe.State('Y56-I-RN'));
        Observer.Finish();
    end;

    local procedure Log(K: Text; V: Text)
    begin
        Keys.Add(K);
        Values.Add(V);
    end;

    local procedure Replay(var Observer: Codeunit "Probe Observer")
    var
        I: Integer;
    begin
        for I := 1 to Keys.Count() do
            Observer.Observe(Keys.Get(I), Values.Get(I));
    end;

    [MessageHandler]
    procedure Y56MsgHandler(Msg: Text)
    begin
    end;
}
