// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALT Blob (60008), ALTFixtureCleanup (60019),
//                shared Assert (60021), ALT Run Tx Inserter (60253),
//                ALT Run Tx Dirty Inserter (60255), ALT Run Tx None Inserter (60879),
//                ALT Run Tx None Dirty Inserter (60880),
//                ALT Run Tx None Rep Inserter (60412), ALT Run Tx None XmlPort (60413),
//                ALT Run Tx None Card (60414)
//
// Asks whether a write transaction survives a TEST-METHOD boundary. "Test Codeunit Run
// Write Tx" (60254) pins the write-transaction rule around Codeunit.Run WITHIN one test
// method — the guarded form is refused while the caller holds an uncommitted write, the
// statement form is not. Every one of its tests starts with a Commit-carrying Initialize,
// so none of them says what happens when the uncommitted write was made by the PREVIOUS
// test method in the same codeunit.
//
// "Test Isolation Rollback Scope" (60897) answers the neighbouring question about ROWS —
// under TestIsolation = Codeunit an uncommitted row written by one test is still visible to
// the next — and that is deliberately not the same question. A row surviving says nothing
// about whether the session still holds an open write transaction, and the guard on a
// guarded Codeunit.Run reads the transaction, not the row. Both answers hold at once: the
// row survives AND the transaction is gone, which Test06 asserts together.
//
// The tests below are declaration-ordered and share a codeunit, the same way 60897's are.
// Only Test01 and Test14 clear the fixture, and they do so WITHOUT a Commit: they carry no
// TransactionModel attribute, so the platform commits their work at the boundary. A Commit
// inside any of the AutoRollback tests would be refused outright ("Tests cannot call the
// Commit function if TransactionModel property is set to AutoRollback"), and a Commit
// anywhere after Test01 would close the very transaction the next test is here to ask about.
//
// Test07 onwards ask the same boundary question for TransactionModel::None, which the
// platform handles BEFORE the method body instead of after it: every active transaction is
// ended on the way in, and the body therefore runs with no transaction at all. Three
// consequences, one test each — the body starts with no write transaction and may make a
// guarded Codeunit.Run (Test08), a write from the body itself is refused outright with "A
// transaction must be started before changes can be made to the database." (Test09), and a
// codeunit the test RUNS may write anyway, because Codeunit.Run begins a transaction of its
// own (Test10).
//
// Codeunit.Run is not the only AL construct that begins a transaction, and Test10 on its own
// says nothing about the others. Test11-Test13 ask the same question of a report, an xmlport
// import, and a page field's OnValidate driven through a TestPage — one arm per construct,
// because "it is a construct that begins a transaction" is a claim about each of them
// separately and the answer for one does not carry to the next. Each arm writes its own
// marker number and the page arm seeds its own row (Test13a), so one arm coming back refused
// still leaves the other two measurable.
//
// Test01-Test10 were measured on a real BC 28.4.53241.0 service tier. Test11-Test13 are
// measured by the CI run of the pull request that adds them; whatever the tier reports is
// the answer, including a refusal.
// BC versions: 24+

codeunit 60878 "Test Write Tx Test Boundary"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure MarkerCount(EntryNo: Integer): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Reset();
        ALTUniversal.SetRange("Entry No.", EntryNo);
        exit(ALTUniversal.Count());
    end;

    [Test]
    procedure WriteTxBoundary_Test01_ClearsTheFixture()
    begin
        Cleanup.Initialize();

        Assert.AreEqual(0, MarkerCount(9255),
            'The marker row the guarded run below writes must not exist before it runs.');
        Assert.AreEqual(0, MarkerCount(9253),
            'The marker row the second guarded run writes must not exist before it runs.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WriteTxBoundary_Test02_AutoRollbackTestWritesWithoutCommitting()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878001;
        ALTUniversal."Text Field" := 'boundary-probe';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WriteTxBoundary_Test03_NextTestStartsWithNoWriteTransaction()
    begin
        // This test writes nothing of its own, so anything reported here was inherited from
        // the test above, whose Insert was never committed.
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A test method must not start inside the write transaction the previous test left open.');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure WriteTxBoundary_Test04_GuardedCodeunitRunIsAllowed()
    var
        Ok: Boolean;
    begin
        // The observable that matters. A guarded Codeunit.Run needs its own transaction
        // world, which the platform refuses to open while the caller holds an uncommitted
        // write — 60254's first test pins that refusal. Two tests back left exactly such a
        // write behind, so if a write transaction could survive the boundary this call would
        // be refused rather than run.
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'No write transaction may be pending at the start of this test.');

        // The run codeunit does not Commit: an AutoRollback test refuses a Commit anywhere
        // beneath it, including inside a codeunit it runs.
        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Dirty Inserter");

        Assert.IsTrue(Ok, 'A guarded Codeunit.Run must be allowed here and must succeed.');
        Assert.AreEqual(1, MarkerCount(9255),
            'The guarded Codeunit.Run must actually have run the codeunit.');
    end;

    [Test]
    procedure WriteTxBoundary_Test05_DefaultModelTestWritesWithoutCommitting()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // No TransactionModel attribute: the platform commits this test's work at the
        // boundary instead of rolling it back. Either way the transaction ends there.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878002;
        ALTUniversal."Text Field" := 'boundary-probe-2';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    procedure WriteTxBoundary_Test06_GuardedRunIsAllowedAfterADefaultModelWrite()
    var
        ALTUniversal: Record "ALT Universal";
        Ok: Boolean;
    begin
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A default-model test''s write is committed at the boundary, so no write transaction may be pending here.');

        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");

        Assert.IsTrue(Ok,
            'A guarded Codeunit.Run must be allowed after a default-model test wrote without committing.');
        Assert.AreEqual(1, MarkerCount(9253),
            'The guarded Codeunit.Run must actually have run the codeunit.');

        // The other direction of the same boundary, and the reason this is not a restatement
        // of 60897: ending the transaction by committing is not the same as discarding the
        // rows. The row is here AND no transaction is open.
        Assert.IsTrue(ALTUniversal.Get(60878002),
            'The previous test''s row must still be visible: the platform committed it at the boundary.');
    end;

    [Test]
    procedure WriteTxBoundary_Test07_DefaultModelWriteBeforeANoneTest()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // The set-up for Test08: an uncommitted write, so a write transaction is open when
        // this test method ends.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878003;
        ALTUniversal."Text Field" := 'boundary-probe-3';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test08_NoneTestStartsWithNoTransaction()
    var
        ALTUniversal: Record "ALT Universal";
        Ok: Boolean;
    begin
        // TransactionModel::None is handled BEFORE the method body rather than after it, so
        // the platform has already ended every active transaction by the time this line runs.
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');

        // Ending the transaction is not discarding the rows: the previous test ran under the
        // default model, so its write was committed at the boundary.
        Assert.IsTrue(ALTUniversal.Get(60878003),
            'The previous default-model test''s row must still be visible.');

        Assert.AreEqual(0, MarkerCount(9879),
            'The marker row the guarded run below writes must not exist before it runs.');

        Ok := Codeunit.Run(Codeunit::"ALT Run Tx None Inserter");

        Assert.IsTrue(Ok, 'A guarded Codeunit.Run must be allowed at the start of a None test.');
        Assert.AreEqual(1, MarkerCount(9879),
            'The guarded Codeunit.Run must actually have run the codeunit.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test09_NoneTestCannotWriteDirectly()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // The other side of "no transaction is active": a write from the test body itself has
        // no transaction to join, and the platform refuses it outright. The error is trappable
        // and leaves no write transaction behind.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 60878004;
        ALTUniversal."Text Field" := 'never-written';
        asserterror ALTUniversal.Insert();

        Assert.ExpectedError('A transaction must be started before changes can be made to the database.');

        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A refused write must not leave a write transaction open.');
        Assert.AreEqual(0, MarkerCount(60878004),
            'The refused Insert must not have written a row.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test10_ARunCodeunitMayWriteUnderNone()
    begin
        // Codeunit.Run begins a transaction of its own — the statement form joins one it
        // begins, the guarded form opens an isolated transaction world — so the write refused
        // in Test09 is allowed inside a codeunit this test RUNS.
        Assert.AreEqual(0, MarkerCount(9880),
            'The marker row the run below writes must not exist before it runs.');

        Codeunit.Run(Codeunit::"ALT Run Tx None Dirty Inserter");

        Assert.AreEqual(1, MarkerCount(9880),
            'A codeunit run from a None test must be able to write.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction Codeunit.Run began ends with the run, so the None test body is left with none.');
    end;

    // Test11-Test13 ask Test10's question of the three OTHER AL constructs that begin a
    // transaction on BC — a report, an xmlport import, and a page's field validation. Each is
    // shaped exactly like Test10: a marker row that does not exist before the construct runs,
    // the construct, the row, and then the observation that the body is again left with no
    // transaction. The write is made by the CONSTRUCT, never by an AL statement in the test
    // body, which Test09 has already established is refused.

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test11_AReportMayWriteUnderNone()
    var
        RepInserter: Report "ALT Run Tx None Rep Inserter";
    begin
        Assert.AreEqual(0, MarkerCount(9412),
            'The marker row the report below writes must not exist before it runs.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');

        // ProcessingOnly and UseRequestPage = false, so this neither renders nor opens a
        // request page: the only thing it does is run its dataitem trigger, which writes.
        RepInserter.UseRequestPage(false);
        RepInserter.RunModal();

        Assert.AreEqual(1, MarkerCount(9412),
            'A report run from a None test must be able to write.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction the report began ends with the report, so the None test body is left with none.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test12_AnXmlPortImportMayWriteUnderNone()
    var
        Staging: Record "ALT Blob" temporary;
        NoneXmlPort: XmlPort "ALT Run Tx None XmlPort";
        OutStr: OutStream;
        InStr: InStream;
    begin
        Assert.AreEqual(0, MarkerCount(9413),
            'The row the import below writes must not exist before it runs.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');

        // The payload is staged in a TEMPORARY record on purpose. A temporary record is not a
        // database write, so staging it needs no transaction and cannot itself be what the
        // assertion below measures — the only database write in this test is the import's.
        Staging.Init();
        Staging.Code := 'TXN-NONE';
        Staging.Insert();
        Staging.Data.CreateOutStream(OutStr);
        OutStr.WriteText('<?xml version="1.0" encoding="UTF-8"?>' +
            '<Universals><Universal><EntryNo>9413</EntryNo>' +
            '<TextValue>DIRTY-NONE-XMLPORT</TextValue></Universal></Universals>');
        Staging.Modify();
        Staging.CalcFields(Data);
        Staging.Data.CreateInStream(InStr);

        NoneXmlPort.SetSource(InStr);
        NoneXmlPort.Import();

        Assert.AreEqual(1, MarkerCount(9413),
            'An XmlPort import run from a None test must be able to write.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction the import began ends with it, so the None test body is left with none.');
    end;

    [Test]
    procedure WriteTxBoundary_Test13a_SeedsTheRowThePageArmOpensOn()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        // The page arm needs a row to open a Card on, and Test09 established that a None test
        // body cannot write one for itself. So a default-model test writes it here, one method
        // earlier, and the platform commits it at this boundary.
        //
        // Deliberately its OWN row rather than one of the rows Test11 and Test12 write: if
        // either of those arms comes back refused, the page arm must still be measurable. An
        // arm that fails because a DIFFERENT arm failed measures nothing.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9415;
        ALTUniversal."Text Field" := 'PAGE-ARM-SEED';
        ALTUniversal.Insert();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test13_APageFieldValidateMayWriteUnderNone()
    var
        ALTUniversal: Record "ALT Universal";
        Card: TestPage "ALT Run Tx None Card";
    begin
        Assert.AreEqual(0, MarkerCount(9414),
            'The marker row the OnValidate below writes must not exist before it runs.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');
        Assert.IsTrue(ALTUniversal.Get(9415),
            'The previous default-model test''s seed row must be visible here.');

        // The SetValue fires the field's OnValidate, which writes a marker row of its own — a
        // different row from the one the page is sitting on, so the assertion below cannot be
        // satisfied by the page's own Modify of the current record.
        Card.OpenEdit();
        Card.GoToKey(9415);
        Card."Text Field".SetValue('EDITED-UNDER-NONE');
        Card.Close();

        Assert.AreEqual(1, MarkerCount(9414),
            'A page field''s OnValidate, driven from a None test, must be able to write.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction the page began ends with it, so the None test body is left with none.');
    end;

    [Test]
    procedure WriteTxBoundary_Test13b_SeedsTheRowTheModifyArmOpensOn()
    var
        ALTUniversal: Record "ALT Universal";
        Marker: Record "ALT Universal";
    begin
        // Same reason as Test13a, and deliberately its own row: the modify arm below must stay
        // measurable even if the insert arm or the field-validate arm comes back refused.
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 9417;
        ALTUniversal."Text Field" := 'ROW-MODIFY-SEED';
        ALTUniversal.Insert();

        // The card's "Text Field" OnValidate inserts marker 9414, and Test13 already left one
        // behind. Editing that field again would re-run the trigger and fail on the duplicate
        // key -- a fixture collision between two arms, which says nothing about whether the
        // page's row Modify may write. Clearing it here, in a default-model test that is
        // allowed to write, keeps Test13d measuring the row write and nothing else.
        if Marker.Get(9414) then
            Marker.Delete();

        Assert.IsTrue(Database.IsInWriteTransaction(),
            'An uncommitted Insert must leave a write transaction open inside the test that made it.');
        Assert.AreEqual(0, MarkerCount(9414),
            'Test13''s OnValidate marker must be cleared before the modify arm re-fires that trigger.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test13c_APageRowInsertUnderNone()
    // CLAIM: whether a page-driven ROW INSERT -- the write a TestPage defers to Close() --
    // may write under TransactionModel::None, the way a report, an xmlport import and a field
    // OnValidate each may (Test11, Test12, Test13).
    //
    // This is a DIFFERENT write from Test13's. There the observable is a marker row an
    // OnValidate writes; here it is the page's own row, inserted by the page as it closes.
    // AL Runner issue StefanMaron/BusinessCentral.AL.Runner#3586 measured the runner refusing
    // this one while allowing the page-driven Modify below -- an asymmetry no corpus arm
    // covers, so nothing establishes which half is right.
    //
    // No assertion here predicts the answer: the arm records what BC does. If BC refuses, this
    // arm is the one that says so and the runner's refusal is correct; if BC allows it, the
    // runner has a gap. Either way the pair below discriminates, because both halves run.
    var
        Card: TestPage "ALT Run Tx None Card";
    begin
        Assert.AreEqual(0, MarkerCount(9416),
            'The row this arm inserts must not exist before it runs.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');

        Card.OpenNew();
        Card."Entry No.".SetValue(9416);
        Card.Close();

        Assert.AreEqual(1, MarkerCount(9416),
            'A page-driven row Insert, from a None test, must be able to write.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction the page began ends with it, so the None test body is left with none.');
    end;

    [Test]
    [TransactionModel(TransactionModel::None)]
    procedure WriteTxBoundary_Test13d_APageRowModifyUnderNone()
    // CLAIM: the same question for a page-driven ROW MODIFY -- the other half of FlushRow().
    //
    // Paired with Test13c on purpose. #3586's finding is that these two behave DIFFERENTLY in
    // the runner today (Insert refused, Modify never checked), and one arm alone cannot show
    // that: it would report a single outcome with nothing to compare it against. Two arms over
    // the same construct, differing only in which row write the page performs, make the
    // asymmetry visible if BC has one and rule it out if BC does not.
    //
    // The observable is the row's own field, not a marker written by a trigger, so this
    // measures the page's Modify rather than anything OnValidate does. It reads back through a
    // fresh Record to avoid asserting against the TestPage's in-memory view.
    var
        ALTUniversal: Record "ALT Universal";
        Card: TestPage "ALT Run Tx None Card";
    begin
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'A TransactionModel::None test must not start inside a write transaction.');
        Assert.IsTrue(ALTUniversal.Get(9417),
            'The previous default-model test''s seed row must be visible here.');
        Assert.AreEqual('ROW-MODIFY-SEED', ALTUniversal."Text Field",
            'The seed row must carry its seeded value before the page edits it.');

        Card.OpenEdit();
        Card.GoToKey(9417);
        Card."Text Field".SetValue('ROW-MODIFIED-UNDER-NONE');
        Card.Close();

        Clear(ALTUniversal);
        Assert.IsTrue(ALTUniversal.Get(9417),
            'The seed row must still exist after the page edited it.');
        Assert.AreEqual('ROW-MODIFIED-UNDER-NONE', ALTUniversal."Text Field",
            'A page-driven row Modify, from a None test, must be able to write.');
        Assert.AreEqual(1, MarkerCount(9414),
            'The edit must have reached the field''s OnValidate, so a failure above is the ROW '
            + 'write being refused rather than the page never getting that far.');
        Assert.IsFalse(Database.IsInWriteTransaction(),
            'The transaction the page began ends with it, so the None test body is left with none.');
    end;

    [Test]
    procedure WriteTxBoundary_Test14_ClearsTheFixtureAgain()
    begin
        // Leaves nothing behind for the codeunits that share these fixture tables. No
        // TransactionModel attribute, so the platform commits this at the boundary.
        Cleanup.Initialize();

        Assert.AreEqual(0, MarkerCount(9879), 'The fixture must be empty again.');
        Assert.AreEqual(0, MarkerCount(9880), 'The fixture must be empty again.');
        Assert.AreEqual(0, MarkerCount(9412), 'The report arm''s marker must be gone too.');
        Assert.AreEqual(0, MarkerCount(9413), 'The xmlport arm''s row must be gone too.');
        Assert.AreEqual(0, MarkerCount(9414), 'The page arm''s marker must be gone too.');
        Assert.AreEqual(0, MarkerCount(9415), 'The page arm''s seed row must be gone too.');
        Assert.AreEqual(0, MarkerCount(9416), 'The row-insert arm''s row must be gone too.');
        Assert.AreEqual(0, MarkerCount(9417), 'The row-modify arm''s seed row must be gone too.');
    end;
}
