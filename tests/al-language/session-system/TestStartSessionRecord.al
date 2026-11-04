// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope
// Fixtures used: SS Passed Record (60393), SS Worker Result (60394),
//                SS Baseline Worker (60395), SS Record Worker (60396), Assert
//
// StartSession cannot be called from a test codeunit under this repository's isolation, and
// this pins that refusal — including its exact reason, which names the one configuration that
// would allow it.
//
// HOW THIS SUITE GOT HERE
//
// It was written to pin what StartSession's record-carrying overload hands a worker: BC's
// ALStartSessionAsyncImpl does not re-read the row in the worker's new session, it clones the
// caller's in-memory field values (record.CloneRecord(newSession)). That question was never
// reached. All eight BC legs answered the same thing, on the CONTROL test first:
//
//     Sessions can only be started in tests that are run by a TestRunner that has
//     TestIsolation set to Disabled.
//
// which is ALStartSessionAsyncImpl's very first guard, before any record handling:
//
//     if (session.TestExecution != null
//         && (!session.TestExecution.CommitTestCodeunits || !session.TestExecution.CommitTestFunctions))
//         throw new NavTestStartSessionNotAllowedException();
//
// The record-cloning code sits about forty lines further down and never runs. So the original
// question is not answerable through this harness at all, and the answer to "why not" is worth
// pinning in its place: it is a hard platform rule that constrains every test in this corpus.
//
// WHY IT CANNOT SIMPLY BE ALLOWED
//
// This corpus runs under TestIsolation = Codeunit — the standard "Test Runner - Isol. Codeunit"
// (130450), as codeunit 60897 (TestIsolationRollbackScope) documents and pins. Switching the
// harness to TestIsolation = Disabled to let StartSession through would change what 60897,
// TestIsolationGlobalVariableScope, TestTransactionModelAutoRollback and
// TestEventManualBindingCrossCodeunit measure — every one of them is a claim ABOUT Codeunit
// isolation. Answering the record question would cost the isolation coverage, which is a bad
// trade.
//
// The record-carrying overload is asserted separately below, so the refusal is visibly a
// property of StartSession-inside-a-test and not of anything to do with the record.
codeunit 60397 "Test StartSession Record"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        // A substring rather than the whole sentence: Assert.ExpectedError is a StrPos match,
        // and this is the part that names the mechanism. Measured byte-identical on 27.0, 27.3,
        // 27.5, 28.0, 28.1, 28.2, 28.3 and 28.4.
        IsolationRefusalErr: Label 'can only be started in tests that are run by a TestRunner that has TestIsolation set to Disabled', Locked = true;

    [Test]
    procedure StartSession_FromATestCodeunit_IsRefusedUnderCodeunitIsolation()
    var
        SessionId: Integer;
    begin
        asserterror StartSession(SessionId, Codeunit::"SS Baseline Worker");

        Assert.ExpectedError(IsolationRefusalErr);

        // The guard is the FIRST statement in ALStartSessionAsyncImpl; sessionId.ObjectValue is
        // assigned much later, after the new session has been opened. So a refusal must leave
        // this untouched — if it were non-zero, a session had already been created and the
        // refusal would be something other than the guard.
        Assert.AreEqual(0, SessionId,
            'a refused StartSession must not have assigned a session id');
    end;

    // The same refusal, through the overload that carries a record. The record is prepared
    // exactly as the original question needed it — set on the caller's own variable and
    // deliberately never Insert()'d — so that if this overload were ever reachable, the setup
    // is already the one that distinguishes "cloned the caller's field values" from "read the
    // row fresh". Today it does not get that far, and this test says so.
    [Test]
    procedure StartSession_RecordOverload_IsRefusedTheSameWay()
    var
        Passed: Record "SS Passed Record";
        SessionId: Integer;
    begin
        Passed.Init();
        Passed."No." := 'X';
        Passed."Value" := 'uncommitted-value';

        asserterror StartSession(SessionId, Codeunit::"SS Record Worker", '', Passed);

        Assert.ExpectedError(IsolationRefusalErr);
        Assert.AreEqual(0, SessionId,
            'a refused StartSession must not have assigned a session id, record overload included');
    end;
}
