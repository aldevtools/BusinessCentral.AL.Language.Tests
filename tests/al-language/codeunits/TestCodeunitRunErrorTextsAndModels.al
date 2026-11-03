// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021),
//                ALT Run Tx Inserter (60253), ALT Run Tx Dirty Inserter (60255),
//                NTC Inner Tests (67565), NTC Plain Codeunit (67568)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// Pins the full texts and error codes of the Codeunit.Run refusals (nested test codeunit,
// guarded run with a write pending, missing object id) and how a guarded Codeunit.Run
// interacts with TransactionModel::AutoRollback. Existing corpus tests pin only fragments
// of these texts (TestCodeunitRunNestedTestCodeunit.al, TestCodeunitRunWriteTransaction.al,
// TestCodeunitRunMissing.al).
//
// The two "AutoRollback" tests are a declaration-ordered pair, like the tests in
// "Test Write Tx Test Boundary" (60878): the later tests ask what the earlier one left behind,
// so only AutoRollback_Test01 (default model, committed at its boundary) clears the fixture.
// BC versions: 27.5

codeunit 68100 "Probe Codeunit Run Texts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        // Cleanup deletes rows, which opens a write transaction. Close it so each test controls
        // its own pending write.
        Commit();
    end;

    local procedure InsertPendingRow()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 1;
        ALTUniversal.Insert();
    end;

    local procedure Count(EntryNo: Integer): Integer
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.SetRange("Entry No.", EntryNo);
        exit(ALTUniversal.Count());
    end;

    local procedure TransactionStoppedText(): Text
    begin
        exit('An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
    end;

    local procedure NestedTestCodeunitText(): Text
    begin
        exit('You cannot nest the execution of test codeunits. Test codeunit 67565 NTC Inner Tests was called from another test codeunit.');
    end;

    [Test]
    procedure CodeunitRun_TestCodeunitFromTest_Unguarded_FullTextAndCode()
    // CLAIM: the nested-run refusal is the two sentences joined by one space, with error code TestCodeUnitNestedInvocation.
    begin
        Initialize();

        asserterror Codeunit.Run(Codeunit::"NTC Inner Tests");

        Assert.AreEqual(NestedTestCodeunitText(), GetLastErrorText(), 'full text of the nested test codeunit refusal');
        Assert.AreEqual('TestCodeUnitNestedInvocation', GetLastErrorCode(), 'error code of the nested test codeunit refusal');
    end;

    [Test]
    procedure CodeunitRun_TestCodeunitFromTest_Guarded_FullTextAndCode()
    // CLAIM: the guarded form raises the same text and code instead of returning false.
    var
        Ok: Boolean;
    begin
        Initialize();

        asserterror Ok := Codeunit.Run(Codeunit::"NTC Inner Tests");

        Assert.AreEqual(NestedTestCodeunitText(), GetLastErrorText(), 'full text of the guarded nested test codeunit refusal');
        Assert.AreEqual('TestCodeUnitNestedInvocation', GetLastErrorCode(), 'error code of the guarded nested test codeunit refusal');
    end;

    [Test]
    procedure CodeunitRun_GuardedWithPendingWrite_FullTextAndCode()
    // CLAIM: the refusal text is "...the transaction is stopped. Contact your administrator or partner for further assistance." with code DB:Ok.
    var
        Ok: Boolean;
    begin
        Initialize();
        InsertPendingRow();

        asserterror Ok := Codeunit.Run(Codeunit::"ALT Run Tx Inserter");

        Assert.AreEqual(TransactionStoppedText(), GetLastErrorText(), 'full text of the guarded-run refusal');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'error code of the guarded-run refusal');
    end;

    [Test]
    procedure CodeunitRun_GuardedOfCodeunitWithoutOnRun_WithPendingWrite_IsRefusedLikeAnyOther()
    // CLAIM: a codeunit with no OnRun trigger gets no special treatment from the pending-write rule.
    var
        Ok: Boolean;
    begin
        Initialize();
        InsertPendingRow();

        asserterror Ok := Codeunit.Run(Codeunit::"NTC Plain Codeunit");

        Assert.AreEqual(TransactionStoppedText(), GetLastErrorText(), 'text of the refusal for a codeunit without OnRun');
    end;

    [Test]
    procedure CodeunitRun_GuardedOfCodeunitWithoutOnRun_NoPendingWrite_ReturnsTrue()
    // CLAIM: with no write pending a guarded run of a codeunit without OnRun returns true.
    begin
        Initialize();

        Assert.IsTrue(Codeunit.Run(Codeunit::"NTC Plain Codeunit"), 'guarded run of a codeunit without OnRun returns true');
    end;

    [Test]
    procedure CodeunitRun_GuardedInsideTryFunction_NoPendingWrite_ReturnsTrue()
    // CLAIM: a guarded Codeunit.Run inside a TryFunction is allowed.
    begin
        Initialize();

        Assert.IsTrue(TryGuardedRun(), 'the TryFunction must succeed when no write is pending');
    end;

    [Test]
    procedure CodeunitRun_GuardedInsideTryFunction_WithPendingWrite_TryFunctionFailsWithTheRefusal()
    // CLAIM: the refusal is trapped by the TryFunction: it returns false and GetLastErrorText holds the refusal.
    begin
        Initialize();
        InsertPendingRow();
        ClearLastError();

        Assert.IsFalse(TryGuardedRun(), 'the TryFunction must fail while a write is pending');

        Assert.AreEqual(TransactionStoppedText(), GetLastErrorText(), 'text trapped by the TryFunction');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'code trapped by the TryFunction');
    end;

    [TryFunction]
    local procedure TryGuardedRun()
    var
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"NTC Plain Codeunit");
    end;

    [Test]
    procedure CodeunitRun_MissingId_TextShapeAndCode()
    // CLAIM: the text is "You tried to invoke the CodeUnit object with the ID 99990 from the object <caller>. An object with that ID does not exist in the current application compiled with emit version <n>." with code AL:MetadataNotFound.
    // The caller name and the emit version differ by host and BC version, so only the fixed parts are compared.
    var
        Text: Text;
        Rest: Text;
        Version: Text;
        VersionNo: Integer;
    begin
        Initialize();

        asserterror Codeunit.Run(99990);

        Text := GetLastErrorText();
        Assert.IsTrue(Text.StartsWith('You tried to invoke the CodeUnit object with the ID 99990 from the object '), 'prefix: ' + Text);
        Assert.IsTrue(Text.Contains('. An object with that ID does not exist in the current application compiled with emit version '), 'glue: ' + Text);
        Assert.IsTrue(Text.EndsWith('.'), 'the text ends with a full stop: ' + Text);
        Rest := Text.Substring(Text.IndexOf('compiled with emit version ') + StrLen('compiled with emit version ') + 1);
        Version := Rest.TrimEnd('.');
        Assert.IsTrue(Evaluate(VersionNo, Version), 'the emit version is a number: ' + Version);
        Assert.AreEqual('AL:MetadataNotFound', GetLastErrorCode(), 'error code of the missing object refusal');
    end;

    [Test]
    procedure CodeunitRun_MissingId_Guarded_SameCode()
    // CLAIM: the guarded form raises with the same code.
    var
        Ok: Boolean;
    begin
        Initialize();

        asserterror Ok := Codeunit.Run(99990);

        Assert.AreEqual('AL:MetadataNotFound', GetLastErrorCode(), 'error code of the guarded missing object refusal');
    end;

    [Test]
    procedure CodeunitRun_TableNoCodeunit_RunReceivesTheCallersRecord()
    // CLAIM: Codeunit.Run(Id, Rec) passes the record by reference; the guarded and the statement form both see the change.
    var
        ALTUniversal: Record "ALT Universal";
        Ok: Boolean;
    begin
        Initialize();

        ALTUniversal.Init();
        ALTUniversal."Text Field" := 'before';
        Ok := Codeunit.Run(Codeunit::"Probe TableNo Runner", ALTUniversal);

        Assert.IsTrue(Ok, 'guarded run returns true');
        Assert.AreEqual('SET-BY-RUN', ALTUniversal."Text Field", 'the guarded run changed the caller''s record');

        ALTUniversal."Text Field" := 'before again';
        Codeunit.Run(Codeunit::"Probe TableNo Runner", ALTUniversal);

        Assert.AreEqual('SET-BY-RUN', ALTUniversal."Text Field", 'the statement-form run changed the caller''s record');
    end;

    [Test]
    procedure AutoRollback_Test01_ClearsTheFixture()
    begin
        // Default model: the platform commits at the boundary, so the next test starts clean.
        Cleanup.Initialize();
        Assert.AreEqual(0, Count(9255), 'the marker row of the dirty inserter must not exist yet');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AutoRollback_Test02_GuardedRunWithPendingWrite_IsRefused()
    // CLAIM: AutoRollback does not exempt a guarded run from the pending-write refusal.
    var
        ALTUniversal: Record "ALT Universal";
        Ok: Boolean;
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 68100001;
        ALTUniversal.Insert();

        asserterror Ok := Codeunit.Run(Codeunit::"ALT Run Tx Dirty Inserter");

        Assert.AreEqual(TransactionStoppedText(), GetLastErrorText(), 'text of the refusal inside an AutoRollback test');
        Assert.AreEqual(0, Count(9255), 'the refused codeunit never ran');
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure AutoRollback_Test03_SuccessfulGuardedRun_WritesWithoutCommitting()
    // CLAIM: the guarded run's write is visible inside the test (the run codeunit does not call Commit).
    var
        Ok: Boolean;
    begin
        Ok := Codeunit.Run(Codeunit::"ALT Run Tx Dirty Inserter");

        Assert.IsTrue(Ok, 'guarded run succeeds');
        Assert.AreEqual(1, Count(9255), 'the row is visible inside the test');
    end;

    [Test]
    procedure AutoRollback_Test04_SuccessfulGuardedRun_RowSurvivesTheTestBoundary()
    // CLAIM: unlike the test's own writes, the guarded run's row is NOT rolled back with the AutoRollback test: the run committed it.
    var
    begin
        Assert.AreEqual(1, Count(9255), 'the guarded run''s row survives the previous AutoRollback test');
        Assert.AreEqual(0, Count(68100001), 'the previous AutoRollback test''s own write is rolled back');
        Assert.IsFalse(Database.IsInWriteTransaction(), 'no write transaction is left open');
        Cleanup.Initialize();
        Assert.AreEqual(0, Count(9255), 'the fixture is empty again');
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 6438): Codeunit.Run of a codeunit with TableNo = "ALT Universal" given a record of
    // another table (ALT Composite), guarded and unguarded, and Page.Run of a page whose SourceTable is "ALT Universal" with that record.
    [Test]
    procedure CodeunitRun_TableNoCodeunit_RecordOfAnotherTable_BP()
    var
        Observer: Codeunit "Probe Observer";
        Composite: Record "ALT Composite";
        Ok: Boolean;
    begin
        Initialize();

        // The error is not trapped by the Boolean result of Codeunit.Run: it reaches the caller (asserterror catches it).
        ClearLastError();
        Ok := true;
        asserterror Ok := Codeunit.Run(Codeunit::"Probe TableNo Runner", Composite);
        Observer.Observe('guarded result', Format(Ok));
        Observer.ObserveError('guarded');

        asserterror Codeunit.Run(Codeunit::"Probe TableNo Runner", Composite);
        Observer.ObserveError('unguarded');

        asserterror Page.Run(Page::"ALT Card Page", Composite);
        Observer.ObserveError('page run');
        Observer.Expect('guarded result', 'Yes');
        Observer.Expect('guarded|text', 'Record(60001) is not compatible with Codeunit.Run(Record(60000)).');
        Observer.Expect('guarded|code', 'InvalidType');
        Observer.Expect('unguarded|text', 'Record(60001) is not compatible with Codeunit.Run(Record(60000)).');
        Observer.Expect('unguarded|code', 'InvalidType');
        Observer.Expect('page run|text', 'The table IDs do not match.');
        Observer.Expect('page run|code', 'TableIdMismatch');
        Observer.Verify();
    end;
}

codeunit 68101 "Probe TableNo Runner"
{
    TableNo = "ALT Universal";

    trigger OnRun()
    begin
        Rec."Text Field" := 'SET-BY-RUN';
    end;
}
