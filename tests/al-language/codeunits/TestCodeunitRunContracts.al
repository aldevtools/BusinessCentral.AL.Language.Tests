codeunit 60190 "Test Codeunit Run Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Codeunit_Run_ById_ReturnsTrue()
    var
        Result: Boolean;
    begin
        Cleanup.Initialize();
        Commit();  // ensure clean transaction state before Codeunit.Run

        // Assert codeunit has an explicit OnRun trigger (no-op) — safe to call via Codeunit.Run()
        Result := Codeunit.Run(Codeunit::Assert);
        Assert.IsTrue(Result, 'Codeunit.Run(validId) must return true on success');
    end;

    [Test]
    procedure Codeunit_Run_SetsErrorTextOnFailure()
    begin
        Cleanup.Initialize();

        ClearLastError();
        Codeunit.Run(Codeunit::ALTFixtureCleanup);
        Assert.AreEqual('', GetLastErrorText(), 'After successful Codeunit.Run, no error must be set');
    end;

    [Test]
    procedure Codeunit_Variable_Direct_Call()
    var
        CU: Codeunit ALTDouble;
    begin
        Cleanup.Initialize();

        Assert.AreEqual(10, CU.Compute(5), 'Direct codeunit variable call must return correct result');
    end;

    [Test]
    procedure Codeunit_Variable_RetainsState()
    var
        CU: Codeunit ALTDouble;
    begin
        Cleanup.Initialize();

        Assert.AreEqual(6, CU.Compute(3), 'First call');
        Assert.AreEqual(8, CU.Compute(4), 'Second call must work independently');
    end;

    [Test]
    procedure Codeunit_Interface_Dispatch()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
    begin
        Cleanup.Initialize();

        C := D;
        Assert.AreEqual(14, C.Compute(7), 'Interface dispatch to ALTDouble must return 2*7=14');
    end;

    [Test]
    procedure Codeunit_Interface_Reassign()
    var
        C: Interface IALTCompute;
        D: Codeunit ALTDouble;
        S: Codeunit ALTSquare;
    begin
        Cleanup.Initialize();

        C := D;
        Assert.AreEqual(10, C.Compute(5), 'Initial interface call returns double');

        C := S;
        Assert.AreEqual(25, C.Compute(5), 'Interface after reassign to Square must return 5^2=25');
    end;

    [Test]
    procedure Codeunit_Run_WithRecord_PassesRecord()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Cleanup.Initialize();

        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();  // ensure clean transaction state before Codeunit.Run

        // Codeunit.Run() with a record variable — Assert codeunit has explicit OnRun (no-op),
        // runs successfully, returns true. The record is passed by reference but not mutated.
        Result := Codeunit.Run(Codeunit::Assert, Rec);
        Assert.IsTrue(Result, 'Codeunit.Run with record variable must return true on success');
        // Record still exists — Codeunit.Run did not delete it
        Rec.Reset();
        Assert.AreEqual(1, Rec.Count(), 'Record must still exist after Codeunit.Run on Assert codeunit');
    end;

    [Test]
    procedure Codeunit_ErrorPropagation_ThroughProcedures()
    begin
        Cleanup.Initialize();

        asserterror CallThroughTwoLevels();
        Assert.AreEqual('level2 error', GetLastErrorText(), 'Error must propagate from inner to outer procedure');
    end;

    [Test]
    procedure Codeunit_LocalProcedure_CanCallOtherLocalProcedure()
    var
        Result: Integer;
    begin
        Cleanup.Initialize();

        Result := OuterCall(3);
        Assert.AreEqual(9, Result, 'Local procedure calling another local procedure: Square(3) = 9');
    end;

    [Test]
    procedure Codeunit_ProcedureOverloading_NotSupported()
    var
        D: Codeunit ALTDouble;
        S: Codeunit ALTSquare;
    begin
        Cleanup.Initialize();

        Assert.AreEqual(10, D.Compute(5), 'ALTDouble.Compute returns 2*5=10');
        Assert.AreEqual(25, S.Compute(5), 'ALTSquare.Compute returns 5*5=25');
    end;

    [Test]
    procedure Codeunit_Run_False_DoesNotThrow()
    var
        Reached: Boolean;
    begin
        Cleanup.Initialize();

        Reached := false;
        Codeunit.Run(Codeunit::ALTFixtureCleanup);
        Reached := true;
        Assert.IsTrue(Reached, 'Code after Codeunit.Run must execute normally');
    end;

    [Test]
    procedure Codeunit_ProcedureWithVarParam_ModifiesCaller()
    var
        Val: Integer;
    begin
        Cleanup.Initialize();

        Val := 0;
        DoubleIt(Val);

        Val := 5;
        DoubleIt(Val);
        Assert.AreEqual(10, Val, 'VAR parameter procedure must modify caller value: 5 doubled = 10');
    end;

    local procedure CallThroughTwoLevels()
    begin
        CallLevel2();
    end;

    local procedure CallLevel2()
    begin
        Error('level2 error');
    end;

    local procedure OuterCall(N: Integer): Integer
    begin
        exit(LocalSquare(N));
    end;

    local procedure LocalSquare(N: Integer): Integer
    begin
        exit(N * N);
    end;

    local procedure DoubleIt(var Val: Integer)
    begin
        Val := Val * 2;
    end;

    [Test]
    procedure Codeunit_Run_AfterCommit_Succeeds()
    // CLAIM: Commit() before Codeunit.Run() closes the write transaction and allows the call.
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Commit();  // Close the write transaction
        Codeunit.Run(Codeunit::Assert);
        Assert.IsTrue(true, 'Codeunit.Run must succeed after Commit() closes the write transaction');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
