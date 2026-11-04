// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-runpageonrec-property
// Scope: in-scope
// Fixtures used: TPARPR Row (67350), TPARPR Probe (67350), TPARPR Host (67350),
//                TPARPR Target (67351), TPARPR Calc Host (67352), Assert (60021)
//
// A page action with RunObject = Page and RunPageOnRec = true opens the target on the host
// page's current row (codeunit 60455). This codeunit pins what the two pages share after that:
//
//   * ROW SET -- does the target's Rec see the host's filters, or only its row?
//   * POSITION -- when the target moves its Rec (in OnOpenPage, or through the TestPage in the
//     handler), does the host move with it? Codeunit 60606 answers yes for a RunObject codeunit.
//   * WRITE-BACK -- when the target edits the row and closes, does the host show the new value,
//     and can the host still save its own edit of that row afterwards? Which xRec does that save
//     carry into the table's OnModify?
//   * HOST TRIGGERS -- after the target closes, does the host still show what its own
//     OnAfterGetRecord wrote into Rec, and for which read of the row did that trigger run?
//
// Five rows in two groups: A Alpha G1, B Bravo G2, C Charlie G1, D Delta G1, E Echo G2. Every
// arm parks the host on a row the target can report back, so each assertion distinguishes
// "carried" from "not carried" by a concrete value rather than by a boolean.
//
// Written by agent stma-auto2-2, an automated implementation agent acting on the account
// holder's behalf, for AL Runner issue 4634.

codeunit 67351 "TPARPR Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize(Mode: Text[20])
    var
        Probe: Codeunit "TPARPR Probe";
    begin
        Probe.Reset(Mode);
        Seed();
        Commit();
    end;

    local procedure Seed()
    var
        Row: Record "TPARPR Row";
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
        Row: Record "TPARPR Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Descr := Descr;
        Row.Grp := Grp;
        Row.Insert();
    end;

    // CONTROL for the filtered arm: no filter on the host, so the target's Rec sees all five rows.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure UnfilteredHostOpensTheTargetOnItsRow()
    var
        Probe: Codeunit "TPARPR Probe";
        Host: TestPage "TPARPR Host";
    begin
        Initialize('READ');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Assert.IsTrue(Probe.GetOpened(), 'the RunObject page must open');
        Assert.AreEqual('Bravo', Probe.GetRecSeen(), 'RunPageOnRec opens the target on the host''s current row');
        Assert.AreEqual('ABCDE', Probe.GetRowsSeen(), 'an unfiltered host hands the target a Rec over every row');
        Assert.AreEqual(5, Probe.GetCountSeen(), 'an unfiltered host hands the target a Rec counting every row');
    end;

    // ROW SET. The host is filtered to G1 (A, C, D) and parked on its second row, C. A target
    // handed the host's filters walks 'ACD'; one handed only the row walks 'ABCDE'.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure FilteredHostTargetRowSet()
    var
        Probe: Codeunit "TPARPR Probe";
        Host: TestPage "TPARPR Host";
    begin
        Initialize('READ');

        Host.OpenEdit();
        Host.Filter.SetFilter(Grp, 'G1');
        Host.First();
        Host.Next();
        Assert.AreEqual('Charlie', Host.Descr.Value(), 'precondition: the filtered host''s second row is C');
        Host.RunTarget.Invoke();

        Assert.AreEqual('Charlie', Probe.GetRecSeen(), 'RunPageOnRec opens the target on the filtered host''s current row');
        Assert.AreEqual('ABCDE', Probe.GetRowsSeen(), 'the rows the target''s Rec walks under a filtered host');
        Assert.AreEqual(5, Probe.GetCountSeen(), 'the rows the target''s Rec counts under a filtered host');
    end;

    // POSITION, OnOpenPage. The target drops its filters and moves its Rec to E. The probe's
    // 'Echo' proves the move happened; the arm then reads the row the host shows.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure TargetMovingItsRecInOnOpenPage()
    var
        Probe: Codeunit "TPARPR Probe";
        Host: TestPage "TPARPR Host";
    begin
        Initialize('MOVE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Assert.AreEqual('Echo', Probe.GetMovedTo(), 'precondition: the target really moved its Rec to E');
        Assert.AreEqual('Bravo', Host.Descr.Value(), 'the row the host shows after the target moved its Rec');
    end;

    // POSITION, handler. The handler steps the target TestPage to its next row, C.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure TargetStepsToItsNextRowInTheHandler()
    var
        Probe: Codeunit "TPARPR Probe";
        Host: TestPage "TPARPR Host";
    begin
        Initialize('NEXT');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Assert.AreEqual('Charlie', Probe.GetMovedTo(), 'precondition: the target really stepped from B to C');
        Assert.AreEqual('Bravo', Host.Descr.Value(), 'the row the host shows after the target stepped to its next row');
    end;

    // WRITE-BACK. The handler edits the row the target was opened on and closes it. The database
    // row changes; the arm then reads what the host shows for that same row.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure TargetEditingTheRowAndTheHostsValue()
    var
        Row: Record "TPARPR Row";
        Host: TestPage "TPARPR Host";
    begin
        Initialize('WRITE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();

        Row.Get('B');
        Assert.AreEqual('Written', Row.Descr, 'the target''s edit must reach the database');
        Assert.AreEqual('B', Host."No.".Value(), 'the host stays on the edited row');
        Assert.AreEqual('Written', Host.Descr.Value(), 'the value the host shows for the row the target edited');
    end;

    // WRITE-BACK, then an edit on the host. After the target edited row B, the host edits the
    // same row and leaves it. The arm reads what the database then holds.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure HostEditAfterTheTargetEditedTheRow()
    var
        Row: Record "TPARPR Row";
        Host: TestPage "TPARPR Host";
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
        Assert.AreEqual('Written', Row.Descr, 'the host''s save must not overwrite the target''s write with the value the host loaded');
    end;

    // WRITE-BACK, the before-image. The table's OnModify records xRec.Descr>Rec.Descr. After the
    // target wrote 'Written' to row B, the host edits Grp on that row and leaves it; the arm reads
    // the images the host's save carried. The host's Rec shows the target's write, but its xRec
    // is still the row as the host loaded it before the action.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure HostSaveAfterTheTargetEditedTheRowCarriesXRec()
    var
        Probe: Codeunit "TPARPR Probe";
        Host: TestPage "TPARPR Host";
    begin
        Initialize('WRITE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunTarget.Invoke();
        Assert.AreEqual('Bravo>Written', Probe.GetLastModify(), 'precondition: the target''s own save of row B');
        Host.Grp.SetValue('G9');
        Host.Next();

        Assert.AreEqual('Bravo>Written', Probe.GetLastModify(), 'xRec>Rec in OnModify for the host''s save after the target wrote the row');
    end;

    // HOST TRIGGERS, plain RunObject. The target opens on its own rowset and changes nothing.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure HostOnAfterGetRecordValueAfterPlainRunObject()
    var
        Host: TestPage "TPARPR Calc Host";
    begin
        Initialize('READ');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Assert.AreEqual('CALC:Bravo', Host.Calc.Value(), 'precondition: the host''s OnAfterGetRecord ran for B');
        Host.RunPlain.Invoke();

        Assert.AreEqual('B', Host."No.".Value(), 'the host stays on its row');
        Assert.AreEqual('CALC:Bravo', Host.Calc.Value(), 'the host''s OnAfterGetRecord value after a plain RunObject page closed');
    end;

    // HOST TRIGGERS, RunPageOnRec. The target opens on the host's row and changes nothing.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure HostOnAfterGetRecordValueAfterRunPageOnRec()
    var
        Host: TestPage "TPARPR Calc Host";
    begin
        Initialize('READ');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunOnRec.Invoke();

        Assert.AreEqual('B', Host."No.".Value(), 'the host stays on its row');
        Assert.AreEqual('CALC:Bravo', Host.Calc.Value(), 'the host''s OnAfterGetRecord value after a RunPageOnRec page closed');
    end;

    // HOST TRIGGERS, after a write. The target writes 'Written' to the host's row. 'CALC:Written'
    // means the host's OnAfterGetRecord ran again on the re-read row; 'CALC:Bravo' that it did
    // not; '' that the row was re-read with no trigger.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure HostOnAfterGetRecordAfterTheTargetWroteTheRow()
    var
        Host: TestPage "TPARPR Calc Host";
    begin
        Initialize('WRITE');

        Host.OpenEdit();
        Host.First();
        Host.Next();
        Host.RunOnRec.Invoke();

        Assert.AreEqual('Written', Host.Descr.Value(), 'the value the host shows for the row the target edited');
        Assert.AreEqual('CALC:Written', Host.Calc.Value(), 'the host''s OnAfterGetRecord value after the target wrote the row');
    end;

    // CONTROL, no action involved. AL's own Page.Run(Number, Record) hands the page a record;
    // the page's OnOpenPage then moves its Rec to E. The arm reads the caller's record after.
    [Test]
    [HandlerFunctions('TargetHandler')]
    procedure PageRunTargetMovingItsRecAndTheCallersRecord()
    var
        Probe: Codeunit "TPARPR Probe";
        Row: Record "TPARPR Row";
    begin
        Initialize('MOVE');

        Row.Get('B');
        Page.Run(Page::"TPARPR Target", Row);

        Assert.AreEqual('Echo', Probe.GetMovedTo(), 'precondition: the page really moved its Rec to E');
        Assert.AreEqual('Bravo', Row.Descr, 'the caller''s record after Page.Run''s page moved its Rec');
        Assert.AreEqual('B', Row."No.", 'the caller''s record position after Page.Run''s page moved its Rec');
    end;

    // CONTROL, modal. The same through Page.RunModal, answered by a [ModalPageHandler].
    [Test]
    [HandlerFunctions('TargetModalHandler')]
    procedure PageRunModalTargetMovingItsRecAndTheCallersRecord()
    var
        Probe: Codeunit "TPARPR Probe";
        Row: Record "TPARPR Row";
    begin
        Initialize('MOVE');

        Row.Get('B');
        Page.RunModal(Page::"TPARPR Target", Row);

        Assert.AreEqual('Echo', Probe.GetMovedTo(), 'precondition: the page really moved its Rec to E');
        Assert.AreEqual('Bravo', Row.Descr, 'the caller''s record after Page.RunModal''s page moved its Rec');
        Assert.AreEqual('B', Row."No.", 'the caller''s record position after Page.RunModal''s page moved its Rec');
    end;

    [ModalPageHandler]
    procedure TargetModalHandler(var Target: TestPage "TPARPR Target")
    begin
    end;

    [PageHandler]
    procedure TargetHandler(var Target: TestPage "TPARPR Target")
    var
        Probe: Codeunit "TPARPR Probe";
    begin
        case Probe.GetMode() of
            'NEXT':
                begin
                    Target.Next();
                    Probe.RecordMovedTo(CopyStr(Target.Descr.Value(), 1, 50));
                end;
            'WRITE':
                begin
                    Target.Descr.SetValue('Written');
                    Target.Close();
                end;
        end;
    end;
}
