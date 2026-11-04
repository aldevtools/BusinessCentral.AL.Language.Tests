// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runobject-property
// Scope: in-scope
// Fixtures used: TPARCR Row (60585), TPARCR Probe (60586), TPARCR Target (60595),
//                TPARCR Host (60596), Assert (60021)
//
// A page action whose RunObject names a codeunit runs that codeunit on the host page's current
// row (codeunit 60559). This codeunit pins the two properties of that call 60559 leaves open:
//
//   * FILTERS -- does the codeunit's Rec see the host's row set (the page's filters), or the
//     whole table? A codeunit that walks Rec would process different rows if the two differ.
//   * SHARING -- when the codeunit moves, re-filters or modifies its Rec, does the TestPage
//     move with it and show the modified value? It does: on every cloud leg of corpus PR 410's
//     first run the host read the row the codeunit moved its Rec to (Echo / E), so the codeunit
//     is handed the host's own record, not a copy of it.
//
// Five rows in two groups: A Alpha G1, B Bravo G2, C Charlie G1, D Delta G1, E Echo G2. Every
// arm parks the host on a row the codeunit can report back, so each assertion distinguishes
// "carried" from "not carried" by a concrete value rather than by a boolean.
//
// Written by agent stma-auto2-12, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4589.

codeunit 60606 "TPARCR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(Mode: Text[20])
    var
        Probe: Codeunit "TPARCR Probe";
    begin
        Probe.Reset(Mode);
        Seed();
        Commit();
    end;

    local procedure Seed()
    var
        Row: Record "TPARCR Row";
    begin
        Row.DeleteAll();
        AddRow('A', 'Alpha', 'G1');
        AddRow('B', 'Bravo', 'G2');
        AddRow('C', 'Charlie', 'G1');
        AddRow('D', 'Delta', 'G1');
        AddRow('E', 'Echo', 'G2');
    end;

    local procedure AddRow(No: Code[20]; Descr: Text[50]; Grp: Code[10])
    var
        Row: Record "TPARCR Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Descr := Descr;
        Row.Grp := Grp;
        Row.Insert();
    end;

    // CONTROL for the filtered arm: no filter on the host, so the codeunit's Rec must see all
    // five rows. Without it, the filtered arm's three rows could be the target miscounting.
    [Test]
    procedure UnfilteredHostHandsTheCodeunitEveryRow()
    var
        Probe: Codeunit "TPARCR Probe";
        Host: TestPage "TPARCR Host";
    begin
        Initialize('READ');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Assert.IsTrue(Probe.GetRan(), 'the RunObject codeunit must run');
        Assert.AreEqual('Bravo', Probe.GetRecSeen(), 'the codeunit is handed the host''s current row');
        Assert.AreEqual('ABCDE', Probe.GetRowsSeen(), 'an unfiltered host hands the codeunit a Rec over every row');
        Assert.AreEqual(5, Probe.GetCountSeen(), 'an unfiltered host hands the codeunit a Rec counting every row');
    end;

    // FILTERS. The host is filtered to G1 (A, C, D) and parked on its second row, C. A codeunit
    // handed the host's filters walks 'ACD' and counts 3; one handed only the row walks 'ABCDE'.
    [Test]
    procedure FilteredHostHandsTheCodeunitItsFilters()
    var
        Probe: Codeunit "TPARCR Probe";
        Host: TestPage "TPARCR Host";
    begin
        Initialize('READ');

        Host.OpenEdit();
        Host.Filter.SetFilter(Grp, 'G1');
        Host.First();
        Host.Next();
        Assert.AreEqual('Charlie', Host.Descr.Value(), 'precondition: the filtered host''s second row is C');
        Host.RunTarget.Invoke();

        Assert.IsTrue(Probe.GetRan(), 'the RunObject codeunit must run');
        Assert.AreEqual('Charlie', Probe.GetRecSeen(), 'the codeunit is handed the filtered host''s current row');
        Assert.AreEqual('ACD', Probe.GetRowsSeen(), 'the codeunit''s Rec carries the host page''s filters');
        Assert.AreEqual(3, Probe.GetCountSeen(), 'the codeunit''s Rec counts only the host page''s filtered rows');
    end;

    // SHARING, position. The codeunit drops its filters and moves its Rec to E. The probe's
    // 'Echo' proves the move happened; the host then reads E too, because the codeunit moved the
    // host's own record rather than a copy of it.
    [Test]
    procedure CodeunitMovingItsRecMovesTheHost()
    var
        Probe: Codeunit "TPARCR Probe";
        Host: TestPage "TPARCR Host";
    begin
        Initialize('MOVE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Assert.AreEqual('Echo', Probe.GetMovedTo(), 'precondition: the codeunit really moved its Rec to E');
        Assert.AreEqual('Echo', Host.Descr.Value(), 'the host page follows the codeunit moving its Rec');
    end;

    // SHARING, filters. The host is filtered to G1 and parked on A; the codeunit Resets its Rec
    // and lands on E, a G2 row. The host then reads E: a row its own G1 filter excludes, so the
    // codeunit's Reset reached the host's record along with the move.
    [Test]
    procedure CodeunitResettingItsRecMovesTheFilteredHostOutsideItsFilter()
    var
        Probe: Codeunit "TPARCR Probe";
        Host: TestPage "TPARCR Host";
    begin
        Initialize('MOVE');

        Host.OpenEdit();
        Host.Filter.SetFilter(Grp, 'G1');
        Host.First();
        Host.RunTarget.Invoke();

        Assert.AreEqual('Echo', Probe.GetMovedTo(), 'precondition: the codeunit really moved its Rec to E');
        Assert.AreEqual('E', Host."No.".Value(), 'the filtered host follows the codeunit to a row outside the host''s filter');
    end;

    // WRITE-BACK. The codeunit modifies the row it was handed. The database row changes; the
    // arm then reads what the host page shows for that same row after the action returns.
    [Test]
    procedure CodeunitModifyingItsRecIsShownOnTheHost()
    var
        Row: Record "TPARCR Row";
        Host: TestPage "TPARCR Host";
    begin
        Initialize('WRITE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Row.Get('B');
        Assert.AreEqual('Written', Row.Descr, 'the codeunit''s Modify must reach the database');
        Assert.AreEqual('B', Host."No.".Value(), 'the host stays on the modified row');
        Assert.AreEqual('Written', Host.Descr.Value(), 'the host page shows the value the codeunit wrote to its row');
    end;

    // WRITE-BACK, then an edit on the host. After the codeunit modified row B, the host edits the
    // same row and leaves it. The edit must land on top of the codeunit's write, not fail as a
    // write over a stale copy and not put 'Bravo' back.
    [Test]
    procedure HostEditAfterTheCodeunitModifiedTheRowIsSaved()
    var
        Row: Record "TPARCR Row";
        Host: TestPage "TPARCR Host";
    begin
        Initialize('WRITE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();
        Host.Grp.SetValue('G9');
        Host.Next();

        Row.Get('B');
        Assert.AreEqual('G9', Row.Grp, 'the host''s edit after the action must be saved');
        Assert.AreEqual('Written', Row.Descr, 'the host''s save must not overwrite the codeunit''s write with the value the host loaded');
    end;
}
