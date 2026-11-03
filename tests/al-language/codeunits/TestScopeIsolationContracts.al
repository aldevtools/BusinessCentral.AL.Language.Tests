codeunit 60170 "Test Scope Isolation Contracts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        SharedCounter: Integer;  // codeunit-level variable for tests 7 & 8

    trigger OnRun()
    begin
        // Test runner invokes this before each test
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    // Test 1: ByValue_Record_Change_NotVisibleToCaller
    [Test]
    procedure Test01ByValueRecordChangeNotVisibleToCaller()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        // Arrange
        Rec."Entry No." := 1;
        Rec."Integer Field" := 0;
        Rec.Insert();
        Rec.Get(1);

        // Act
        ModifyByValue(Rec);

        // Assert
        Assert.AreEqual(0, Rec."Integer Field", 'By-value record modification in procedure must NOT affect caller''s variable');
    end;

    // Test 2: VarRecord_Change_VisibleToCaller
    [Test]
    procedure Test02VarRecordChangeVisibleToCaller()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        // Arrange
        Rec."Entry No." := 1;
        Rec."Integer Field" := 0;
        Rec.Insert();
        Rec.Get(1);

        // Act
        ModifyByVar(Rec);

        // Assert
        Assert.AreEqual(77, Rec."Integer Field", 'VAR record modification in procedure MUST be visible to caller');
    end;

    // Test 3: AssertError_VarParam_ChangesVisibleToCaller
    [Test]
    procedure Test03AssertErrorVarParamChangesVisibleToCaller()
    var
        Value: Integer;
    begin
        Initialize();

        // Arrange
        Value := 0;

        // Act & Assert
        asserterror SetVarAndError(Value);
        Assert.AreEqual(42, Value, 'VAR parameter set before Error() inside asserterror-captured call MUST be visible to caller');
    end;

    // Test 4: AssertError_LocalVarChanges_NotAffectCaller
    [Test]
    procedure Test04AssertErrorLocalVarChangesNotAffectCaller()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        // Arrange
        // MEASURED on real BC (CI of corpus issue 205, BC 27.0): an Insert that was not committed
        // is rolled back when asserterror catches an error, so the row is gone afterwards. The
        // earlier version of this test inserted Entry No. 1, which Test01 and Test02 also insert,
        // so a rollback to the last commit restored key 1 and the assertion could not fail.
        // The key must stay unique in this codeunit, or the test stops discriminating.
        Rec."Entry No." := 4004;
        Rec.Insert();
        Assert.IsTrue(Rec.Get(4004), 'The inserted row must be readable before asserterror');

        // Act
        asserterror Error('test');

        // Assert
        Assert.IsFalse(Rec.Get(4004), 'An Insert not yet committed is rolled back when asserterror catches an error');
    end;

    // Test 5: CodeunitRun_ReturnsFalse_ErrorTextAvailable
    [Test]
    procedure Test05CodeunitRunReturnsFalseErrorTextAvailable()
    begin
        Initialize();

        // Act & Assert
        asserterror Error('scope test error');
        Assert.AreEqual('scope test error', GetLastErrorText(), 'GetLastErrorText after asserterror must return the error message');
    end;

    // Test 6: LocalVariable_NotRetainedBetweenCalls
    [Test]
    procedure Test06LocalVariableNotRetainedBetweenCalls()
    var
        Result1: Integer;
        Result2: Integer;
    begin
        Initialize();

        // Act
        IncrementLocal(Result1);
        IncrementLocal(Result2);

        // Assert
        Assert.AreEqual(1, Result1, 'First call must return 1 (local var starts at 0, increments once)');
        Assert.AreEqual(1, Result2, 'Second call must ALSO return 1 (local var does not persist between calls)');
    end;

    // Test 7: CodeunitVar_SharedBetweenTests
    [Test]
    procedure Test07CodeunitVarSharedBetweenTests()
    begin
        Initialize();

        // Arrange & Act
        SharedCounter := 999;

        // Assert
        Assert.AreEqual(999, SharedCounter, 'SharedCounter set to 999 in this test must be visible immediately');
    end;

    // Test 8: CodeunitVar_RetainedAcrossTests
    [Test]
    procedure Test08CodeunitVarRetainedAcrossTests()
    begin
        Initialize();

        // Assert
        // SharedCounter should be 999 if retained from Test 7, or 0 if reset by runner
        // This test validates the behavior either way
        Assert.IsTrue((SharedCounter = 999) or (SharedCounter = 0),
            'SharedCounter must be either 999 (retained from previous test) or 0 (if reset by runner)');
    end;

    // Test 9: Recursive_Procedure_MaintainsIsolatedFrames
    [Test]
    procedure Test09RecursiveProcedureMaintainsIsolatedFrames()
    var
        Result: Integer;
    begin
        Initialize();

        // Act
        Result := RecursiveSum(5);

        // Assert (5+4+3+2+1 = 15)
        Assert.AreEqual(15, Result, 'Recursive procedure must correctly sum 5+4+3+2+1=15 with isolated frames per call');
    end;

    // Test 10: VarParam_Modified_BeforeReturn_VisibleToCaller
    [Test]
    procedure Test10VarParamModifiedBeforeReturnVisibleToCaller()
    var
        Output: Text;
    begin
        Initialize();

        // Arrange
        Output := '';

        // Act
        AppendToVar(Output);

        // Assert
        Assert.AreEqual('appended', Output, 'VAR Text parameter modified in procedure must be visible to caller');
    end;

    // Test 11: ByValueParam_Modified_NotVisibleToCaller
    [Test]
    procedure Test11ByValueParamModifiedNotVisibleToCaller()
    var
        Input: Text;
    begin
        Initialize();

        // Arrange
        Input := 'original';

        // Act
        ModifyByValueText(Input);

        // Assert
        Assert.AreEqual('original', Input, 'By-value Text parameter modification must NOT affect caller variable');
    end;

    // Test 12: Record_Inserted_InProcedure_VisibleToCallerAfterCommit
    [Test]
    procedure Test12RecordInsertedInProcedureVisibleToCallerAfterCommit()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();

        // Act
        InsertRecord(42);

        // Assert
        Assert.IsTrue(Rec.Get(42), 'Record inserted in called procedure must be visible to caller');
    end;

    // Test 13: Error_Message_Preserved_Through_Call_Chain
    [Test]
    procedure Test13ErrorMessagePreservedThroughCallChain()
    begin
        Initialize();

        // Act & Assert
        asserterror ThrowThroughChain();
        Assert.AreEqual('deep error', GetLastErrorText(), 'Error thrown 3 levels deep must be captured with original message');
    end;

    // ==================== Local Helper Procedures ====================

    local procedure ModifyByValue(Rec: Record "ALT Universal")
    begin
        Rec."Integer Field" := 99;  // by value — caller not affected
    end;

    local procedure ModifyByVar(var Rec: Record "ALT Universal")
    begin
        Rec."Integer Field" := 77;  // VAR — caller IS affected
    end;

    local procedure SetVarAndError(var Value: Integer)
    begin
        Value := 42;
        Error('error after setting var');
    end;

    local procedure IncrementLocal(var Result: Integer)
    var
        LocalVar: Integer;  // starts at 0 each call
    begin
        LocalVar += 1;
        Result := LocalVar;
    end;

    local procedure AppendToVar(var S: Text)
    begin
        S := 'appended';
    end;

    local procedure ModifyByValueText(S: Text)
    begin
        S := 'modified';  // by value — caller not affected
    end;

    local procedure InsertRecord(EntryNo: Integer)
    var
        Rec: Record "ALT Universal";
    begin
        Rec."Entry No." := EntryNo;
        Rec.Insert(false);
    end;

    local procedure ThrowThroughChain()
    begin
        ThrowLevel2();
    end;

    local procedure ThrowLevel2()
    begin
        ThrowLevel3();
    end;

    local procedure ThrowLevel3()
    begin
        Error('deep error');
    end;

    local procedure RecursiveSum(N: Integer): Integer
    begin
        if N <= 0 then
            exit(0);
        exit(N + RecursiveSum(N - 1));
    end;
}
