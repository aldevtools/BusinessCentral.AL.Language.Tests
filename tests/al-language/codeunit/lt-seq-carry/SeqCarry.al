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
// Values: State = 'false/' + Current(Name, false) when Exists(Name, false), else 'short/' + Current(Name) when Exists(Name), else
//   'missing'; Next = the number NumberSequence.Next returned. Y56-I-* (install) and Y56-T-*, Y56-O-* use CompanyWide = false;
//   Y56-S-* (install) use the overloads without CompanyWide, the reporter's shape.
// Measured on the CI legs 27.5, 28.5 and 29.0 (27.5 runs these codeunits through page 130455 and codeunit 130450) and on a BC 29.0
//   SaaS sandbox through Test Suite Mgt. with Test Runner Id 130450; the same values everywhere:
//   - A sequence starts at its seed: Current is the seed before any Next, the first Next returns the seed. Restart(Name, Seed, false)
//     and Restart(Name, Seed) do the same (Next returns Seed); Restart(Name) without a seed restarts at 0 (Current 0, Next 0).
//   - A later test of the SAME codeunit sees every change of an earlier test: the restarted values, deleted sequences missing, a
//     sequence deleted and inserted again with its new seed, a new sequence.
//   - The NEXT codeunits see none of the earlier codeunit's Restart, Delete or Insert done in a test: under 130450 they are rolled
//     back with the codeunit. A restarted sequence keeps the numbers that were taken before the restart (Current 2 after two Nexts),
//     a deleted one exists again where it was (Current 1), a sequence inserted by a test is missing, a sequence that OnRun inserted
//     carries (OnRun runs outside the isolation, Y35OnRunStorage.al) but the test's Restart of it does not. Numbers taken by Next
//     are never given back: the next codeunit's Next continues after them, in the second and in the third codeunit.
//   - Rows of the app's own table do not carry either; a later codeunit inserts and reads its own row as usual.
// Not a test, because it breaks the run (SaaS BC 29.0): Restart(Name) without CompanyWide on a sequence made with CompanyWide = false
//   raises "The number sequence 'Y56-I-R' does not exist." (the overloads without CompanyWide reach only CompanyWide = true sequences,
//   SeqOverloads.al), and after that the next codeunit did not run ("Transaction was rolled back by the server.").
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
    // The overloads without CompanyWide reach the sequences made with CompanyWide = true (SeqOverloads.al); Y56-I-* and Y56-T-* are
    // made with false, Y56-S-* with the short overloads. No call reaches a name its Exists does not confirm.
    procedure State(Name: Text): Text
    begin
        if NumberSequence.Exists(Name, false) then
            exit('false/' + Format(NumberSequence.Current(Name, false)));
        if NumberSequence.Exists(Name) then
            exit('short/' + Format(NumberSequence.Current(Name)));
        exit('missing');
    end;

    procedure TakeNext(Name: Text): Text
    begin
        if NumberSequence.Exists(Name, false) then
            exit(Format(NumberSequence.Next(Name, false)));
        if NumberSequence.Exists(Name) then
            exit(Format(NumberSequence.Next(Name)));
        exit('missing');
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
        Log('start_sd', Probe.State('Y56-S-D'));
        Log('start_di', Probe.State('Y56-I-DI'));
        Log('start_n', Probe.State('Y56-I-N'));
        Log('start_tnew', Probe.State('Y56-T-NEW'));
        NumberSequence.Delete('Y56-I-D', false);
        Log('after_delete_d', Probe.State('Y56-I-D'));
        NumberSequence.Delete('Y56-S-D');
        Log('after_delete_sd', Probe.State('Y56-S-D'));
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
        Observer.Observe('later_sd', Probe.State('Y56-S-D'));
        Observer.Observe('later_di', Probe.State('Y56-I-DI'));
        Observer.Observe('later_n', Probe.State('Y56-I-N'));
        Observer.Observe('later_tnew', Probe.State('Y56-T-NEW'));
        Observer.Expect('start_d', 'false/1');
        Observer.Expect('start_sd', 'short/1');
        Observer.Expect('start_di', 'false/1');
        Observer.Expect('start_n', 'false/1');
        Observer.Expect('start_tnew', 'missing');
        Observer.Expect('after_delete_d', 'missing');
        Observer.Expect('after_delete_sd', 'missing');
        Observer.Expect('after_reinsert_di', 'false/40');
        Observer.Expect('next_n', '1');
        Observer.Expect('after_insert_tnew', 'false/7');
        Observer.Expect('next_tnew', '7');
        Observer.Expect('own_row', 'found/First');
        Observer.Expect('later_d', 'missing');
        Observer.Expect('later_sd', 'missing');
        Observer.Expect('later_di', 'false/40');
        Observer.Expect('later_n', 'false/1');
        Observer.Expect('later_tnew', 'false/7');
        Observer.Verify();
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
        Log('seen_sd', Probe.State('Y56-S-D'));
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
        Observer.Observe('later_sd', Probe.State('Y56-S-D'));
        Observer.Observe('later_di', Probe.State('Y56-I-DI'));
        Observer.Observe('later_n', Probe.State('Y56-I-N'));
        Observer.Observe('later_tnew', Probe.State('Y56-T-NEW'));
        Observer.Expect('seen_d', 'false/1');
        Observer.Expect('seen_sd', 'short/1');
        Observer.Expect('seen_di', 'false/1');
        Observer.Expect('seen_n', 'false/1');
        Observer.Expect('seen_tnew', 'missing');
        Observer.Expect('seen_row_d1', 'missing');
        Observer.Expect('next_di', '1');
        Observer.Expect('next_n', '2');
        Observer.Expect('next_tnew', 'missing');
        Observer.Expect('insert_d', 'exists');
        Observer.Expect('after_insert_d', 'false/1');
        Observer.Expect('own_row', 'found/Second');
        Observer.Expect('later_d', 'false/1');
        Observer.Expect('later_sd', 'short/1');
        Observer.Expect('later_di', 'false/1');
        Observer.Expect('later_n', 'false/2');
        Observer.Expect('later_tnew', 'missing');
        Observer.Verify();
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
        Log('seen_sd', Probe.State('Y56-S-D'));
        Log('seen_di', Probe.State('Y56-I-DI'));
        Log('seen_n', Probe.State('Y56-I-N'));
        Log('seen_tnew', Probe.State('Y56-T-NEW'));
        Log('seen_row_d2', Probe.RowSeen('D2'));
        Log('next_d', Probe.TakeNext('Y56-I-D'));
        Log('next_sd', Probe.TakeNext('Y56-S-D'));
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
        Observer.Observe('later_sd', Probe.State('Y56-S-D'));
        Observer.Observe('later_di', Probe.State('Y56-I-DI'));
        Observer.Observe('later_n', Probe.State('Y56-I-N'));
        Observer.Observe('later_tnew', Probe.State('Y56-T-NEW'));
        Observer.Expect('seen_d', 'false/1');
        Observer.Expect('seen_sd', 'short/1');
        Observer.Expect('seen_di', 'false/1');
        Observer.Expect('seen_n', 'false/2');
        Observer.Expect('seen_tnew', 'missing');
        Observer.Expect('seen_row_d2', 'missing');
        Observer.Expect('next_d', '1');
        Observer.Expect('next_sd', '1');
        Observer.Expect('next_di', '2');
        Observer.Expect('next_n', '3');
        Observer.Expect('later_d', 'false/1');
        Observer.Expect('later_sd', 'short/1');
        Observer.Expect('later_di', 'false/2');
        Observer.Expect('later_n', 'false/3');
        Observer.Expect('later_tnew', 'missing');
        Observer.Verify();
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
        Log('start_sr', Probe.State('Y56-S-R'));
        Log('start_srs', Probe.State('Y56-S-RS'));
        Log('start_tr', Probe.State('Y56-T-R'));
        Log('start_or', Probe.State('Y56-O-R'));
        Log('start_rn', Probe.State('Y56-I-RN'));
        Log('next_r', Probe.TakeNext('Y56-I-R'));
        Log('next_r2', Probe.TakeNext('Y56-I-R'));
        NumberSequence.Restart('Y56-I-R', 1, false);
        Log('after_restart_r', Probe.State('Y56-I-R'));
        Log('next_after_restart_r', Probe.TakeNext('Y56-I-R'));
        Log('next_rs', Probe.TakeNext('Y56-I-RS'));
        NumberSequence.Restart('Y56-I-RS', 50, false);
        Log('after_restart_rs', Probe.State('Y56-I-RS'));
        Log('next_sr', Probe.TakeNext('Y56-S-R'));
        Log('next_sr2', Probe.TakeNext('Y56-S-R'));
        NumberSequence.Restart('Y56-S-R');
        Log('after_restart_sr', Probe.State('Y56-S-R'));
        Log('next_after_restart_sr', Probe.TakeNext('Y56-S-R'));
        Log('next_srs', Probe.TakeNext('Y56-S-RS'));
        NumberSequence.Restart('Y56-S-RS', 49);
        Log('next_after_restart_srs', Probe.TakeNext('Y56-S-RS'));
        Log('after_restart_srs', Probe.State('Y56-S-RS'));
        Probe.Fresh('Y56-T-R', 1);
        Log('next_tr', Probe.TakeNext('Y56-T-R'));
        Log('next_tr2', Probe.TakeNext('Y56-T-R'));
        NumberSequence.Restart('Y56-T-R', 20, false);
        Log('after_restart_tr', Probe.State('Y56-T-R'));
        NumberSequence.Restart('Y56-O-R', 30, false);
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
        Observer.Observe('later_sr', Probe.State('Y56-S-R'));
        Observer.Observe('later_srs', Probe.State('Y56-S-RS'));
        Observer.Observe('later_tr', Probe.State('Y56-T-R'));
        Observer.Observe('later_or', Probe.State('Y56-O-R'));
        Observer.Observe('later_rn', Probe.State('Y56-I-RN'));
        Observer.Expect('onrun_next_or', '1');
        Observer.Expect('start_r', 'false/1');
        Observer.Expect('start_rs', 'false/1');
        Observer.Expect('start_sr', 'short/1');
        Observer.Expect('start_srs', 'short/1');
        Observer.Expect('start_tr', 'missing');
        Observer.Expect('start_or', 'false/1');
        Observer.Expect('start_rn', 'false/1');
        Observer.Expect('next_r', '1');
        Observer.Expect('next_r2', '2');
        Observer.Expect('after_restart_r', 'false/1');
        Observer.Expect('next_after_restart_r', '1');
        Observer.Expect('next_rs', '1');
        Observer.Expect('after_restart_rs', 'false/50');
        Observer.Expect('next_sr', '1');
        Observer.Expect('next_sr2', '2');
        Observer.Expect('after_restart_sr', 'short/0');
        Observer.Expect('next_after_restart_sr', '0');
        Observer.Expect('next_srs', '1');
        Observer.Expect('next_after_restart_srs', '49');
        Observer.Expect('after_restart_srs', 'short/49');
        Observer.Expect('next_tr', '1');
        Observer.Expect('next_tr2', '2');
        Observer.Expect('after_restart_tr', 'false/20');
        Observer.Expect('after_restart_or', 'false/30');
        Observer.Expect('own_row', 'found/First');
        Observer.Expect('later_r', 'false/1');
        Observer.Expect('later_rs', 'false/50');
        Observer.Expect('later_sr', 'short/0');
        Observer.Expect('later_srs', 'short/49');
        Observer.Expect('later_tr', 'false/20');
        Observer.Expect('later_or', 'false/30');
        Observer.Expect('later_rn', 'false/1');
        Observer.Verify();
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
        Log('seen_sr', Probe.State('Y56-S-R'));
        Log('seen_srs', Probe.State('Y56-S-RS'));
        Log('seen_tr', Probe.State('Y56-T-R'));
        Log('seen_or', Probe.State('Y56-O-R'));
        Log('seen_rn', Probe.State('Y56-I-RN'));
        Log('seen_row_r1', Probe.RowSeen('R1'));
        Log('next_r', Probe.TakeNext('Y56-I-R'));
        Log('next_rs', Probe.TakeNext('Y56-I-RS'));
        Log('next_sr', Probe.TakeNext('Y56-S-R'));
        Log('next_srs', Probe.TakeNext('Y56-S-RS'));
        Log('next_tr', Probe.TakeNext('Y56-T-R'));
        Log('next_or', Probe.TakeNext('Y56-O-R'));
        Log('next_rn', Probe.TakeNext('Y56-I-RN'));
        NumberSequence.Restart('Y56-I-RN', 70, false);
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
        Observer.Observe('later_sr', Probe.State('Y56-S-R'));
        Observer.Observe('later_srs', Probe.State('Y56-S-RS'));
        Observer.Observe('later_tr', Probe.State('Y56-T-R'));
        Observer.Observe('later_or', Probe.State('Y56-O-R'));
        Observer.Observe('later_rn', Probe.State('Y56-I-RN'));
        Observer.Expect('seen_r', 'false/2');
        Observer.Expect('seen_rs', 'false/1');
        Observer.Expect('seen_sr', 'short/2');
        Observer.Expect('seen_srs', 'short/1');
        Observer.Expect('seen_tr', 'missing');
        Observer.Expect('seen_or', 'false/1');
        Observer.Expect('seen_rn', 'false/1');
        Observer.Expect('seen_row_r1', 'missing');
        Observer.Expect('next_r', '3');
        Observer.Expect('next_rs', '2');
        Observer.Expect('next_sr', '3');
        Observer.Expect('next_srs', '2');
        Observer.Expect('next_tr', 'missing');
        Observer.Expect('next_or', '2');
        Observer.Expect('next_rn', '1');
        Observer.Expect('after_restart_rn', 'false/70');
        Observer.Expect('own_row', 'found/Second');
        Observer.Expect('later_r', 'false/3');
        Observer.Expect('later_rs', 'false/2');
        Observer.Expect('later_sr', 'short/3');
        Observer.Expect('later_srs', 'short/2');
        Observer.Expect('later_tr', 'missing');
        Observer.Expect('later_or', 'false/2');
        Observer.Expect('later_rn', 'false/70');
        Observer.Verify();
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
        Log('seen_sr', Probe.State('Y56-S-R'));
        Log('seen_srs', Probe.State('Y56-S-RS'));
        Log('seen_tr', Probe.State('Y56-T-R'));
        Log('seen_or', Probe.State('Y56-O-R'));
        Log('seen_rn', Probe.State('Y56-I-RN'));
        Log('next_r', Probe.TakeNext('Y56-I-R'));
        Log('next_rs', Probe.TakeNext('Y56-I-RS'));
        Log('next_sr', Probe.TakeNext('Y56-S-R'));
        Log('next_srs', Probe.TakeNext('Y56-S-RS'));
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
        Observer.Observe('later_sr', Probe.State('Y56-S-R'));
        Observer.Observe('later_srs', Probe.State('Y56-S-RS'));
        Observer.Observe('later_tr', Probe.State('Y56-T-R'));
        Observer.Observe('later_or', Probe.State('Y56-O-R'));
        Observer.Observe('later_rn', Probe.State('Y56-I-RN'));
        Observer.Expect('seen_r', 'false/3');
        Observer.Expect('seen_rs', 'false/2');
        Observer.Expect('seen_sr', 'short/3');
        Observer.Expect('seen_srs', 'short/2');
        Observer.Expect('seen_tr', 'missing');
        Observer.Expect('seen_or', 'false/2');
        Observer.Expect('seen_rn', 'false/1');
        Observer.Expect('next_r', '4');
        Observer.Expect('next_rs', '3');
        Observer.Expect('next_sr', '4');
        Observer.Expect('next_srs', '3');
        Observer.Expect('next_or', '3');
        Observer.Expect('next_rn', '2');
        Observer.Expect('later_r', 'false/4');
        Observer.Expect('later_rs', 'false/3');
        Observer.Expect('later_sr', 'short/4');
        Observer.Expect('later_srs', 'short/3');
        Observer.Expect('later_tr', 'missing');
        Observer.Expect('later_or', 'false/3');
        Observer.Expect('later_rn', 'false/2');
        Observer.Verify();
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
