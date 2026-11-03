// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
//
// A codeunit VARIABLE and Codeunit.Run are two different dispatch paths onto one object, and
// codeunit 60078 "Test Codeunit Instantiation" already measures that each of them works. What
// it does not measure is that they are DISTINCT — its Codeunit_Variable_CanBeAssigned asserts
// `IsTrue(true)` after the call, which a platform that quietly did nothing would also satisfy.
//
// These tests pin the distinction and the values, so an implementation cannot satisfy them by
// no-opping either path:
//   - a never-assigned codeunit variable's procedure call executes the real body and returns
//     the real value, for an Integer and for a Text return;
//   - Codeunit.Run reaches OnRun and NOT the procedures;
//   - a procedure call reaches the procedure and NOT OnRun;
//   - instance state persists across calls through one variable and starts clean in a new one.
codeunit 60966 "Test Codeunit Var Dispatch"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure ProcedureOnUnassignedVariable_ReturnsTheComputedValue()
    var
        Probe: Codeunit ALTDispatchProbe;
    begin
        // [GIVEN] A codeunit variable that was never assigned to
        Cleanup.Initialize();

        // [WHEN]  A procedure is called on it
        // [THEN]  The real body ran: 3*7, not Integer's default 0
        Assert.AreEqual(21, Probe.Triple(7),
            'A procedure on a never-assigned codeunit variable must return its computed value.');
    end;

    [Test]
    procedure ProcedureOnUnassignedVariable_ReturnsTheComputedText()
    var
        Probe: Codeunit ALTDispatchProbe;
    begin
        // The same question of a Text return, where the default ('') is a different value
        // from Integer's — so one type's result cannot carry the other's claim.
        Cleanup.Initialize();
        Assert.AreEqual('echo:abc', Probe.Echo('abc'),
            'A Text-returning procedure on a never-assigned codeunit variable must return its computed text.');
    end;

    [Test]
    procedure ProcedureCall_DoesNotReachOnRun()
    var
        Probe: Codeunit ALTDispatchProbe;
    begin
        // [GIVEN] A fresh variable
        Cleanup.Initialize();

        // [WHEN]  A procedure is called
        Probe.Triple(1);

        // [THEN]  The procedure ran and OnRun did not — the two entry points are distinct
        Assert.AreEqual(1, Probe.GetProcCalls(), 'The procedure must have executed exactly once.');
        Assert.AreEqual(0, Probe.GetRunCalls(), 'A procedure call must not reach the OnRun trigger.');
    end;

    [Test]
    procedure InstanceState_PersistsAcrossCallsOnOneVariable()
    var
        Probe: Codeunit ALTDispatchProbe;
    begin
        Cleanup.Initialize();

        Probe.Triple(1);
        Probe.Triple(2);
        Probe.Echo('x');

        // Three procedure calls through one variable address one instance.
        Assert.AreEqual(3, Probe.GetProcCalls(),
            'Instance state must accumulate across calls made through the same codeunit variable.');
    end;

    [Test]
    procedure ASecondVariable_StartsWithCleanInstanceState()
    var
        First: Codeunit ALTDispatchProbe;
        Second: Codeunit ALTDispatchProbe;
    begin
        // The negative direction of the test above: without this, "state persists" is also
        // satisfied by one process-wide instance shared by every variable, which is what
        // SingleInstance = true would mean and this codeunit does not declare.
        Cleanup.Initialize();

        First.Triple(1);
        First.Triple(2);

        Assert.AreEqual(2, First.GetProcCalls(), 'The first variable must see its own two calls.');
        Assert.AreEqual(0, Second.GetProcCalls(),
            'A second variable of a non-SingleInstance codeunit must start with clean state.');
    end;

    [Test]
    procedure CodeunitRun_ReachesOnRunAndNotTheProcedures()
    var
        Probe: Codeunit ALTDispatchProbe;
    begin
        Cleanup.Initialize();
        Commit();  // ensure clean transaction state before Codeunit.Run

        // [WHEN]  The codeunit is run by id
        Assert.IsTrue(Codeunit.Run(Codeunit::ALTDispatchProbe), 'Codeunit.Run must return true on success.');

        // [THEN]  The variable's own instance saw neither call: Codeunit.Run builds its OWN
        //         instance, so it is not merely a different entry point but a different object.
        Assert.AreEqual(0, Probe.GetRunCalls(),
            'Codeunit.Run must not write the OnRun counter of a separate variable''s instance.');
        Assert.AreEqual(0, Probe.GetProcCalls(),
            'Codeunit.Run must not reach the procedures at all.');
    end;

    [Test]
    procedure RunOnAVariable_ReachesThatVariablesOwnInstance()
    var
        Probe: Codeunit ALTDispatchProbe;
    begin
        // The instance spelling of Run, which DOES address the variable's own instance —
        // the distinction the static spelling above cannot show.
        Cleanup.Initialize();
        Commit();

        Probe.Triple(4);
        Probe.Run();

        Assert.AreEqual(1, Probe.GetRunCalls(),
            'Var.Run() must reach the OnRun trigger of that variable''s own instance.');
        Assert.AreEqual(1, Probe.GetProcCalls(),
            'Var.Run() must not disturb state an earlier procedure call wrote on the same instance.');
    end;
}
