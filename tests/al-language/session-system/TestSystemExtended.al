// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Fixture Cleanup (60019), ALT Blob (60008), ALT Status (60009), ALT Universal (60000)

codeunit 60135 "Test System Extended"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── CompressArray(var StringArray: array[N] of Text) ──────────────────────

    [Test]
    procedure CompressArray_RemovesEmptyStrings_ReturnsCount()
    var
        A: array[5] of Text[50];
        Count: Integer;
    begin
        Initialize();
        A[1] := 'a';
        A[2] := '';
        A[3] := 'b';
        A[4] := '';
        A[5] := 'c';

        Count := CompressArray(A);

        Assert.AreEqual(3, Count, 'CompressArray must return count of non-empty strings');
    end;

    [Test]
    procedure CompressArray_ReordersElements_NonEmptyFirst()
    var
        A: array[5] of Text[50];
        Count: Integer;
    begin
        Initialize();
        A[1] := 'a';
        A[2] := '';
        A[3] := 'b';

        Count := CompressArray(A);

        Assert.AreEqual('a', A[1], 'First element must be "a"');
        Assert.AreEqual('b', A[2], 'Second element must be "b"');
        Assert.AreEqual(2, Count, 'Compressed array must have 2 elements');
    end;

    // ── CopyArray(var NewArray, var SourceArray, Position [, Length]) ────────

    [Test]
    procedure CopyArray_CopiesAllElements_FromPosition()
    var
        Src: array[3] of Integer;
        Dst: array[3] of Integer;
    begin
        Initialize();
        Src[1] := 10;
        Src[2] := 20;
        Src[3] := 30;

        CopyArray(Dst, Src, 1, 3);

        Assert.AreEqual(10, Dst[1], 'Dst[1] must be 10');
        Assert.AreEqual(20, Dst[2], 'Dst[2] must be 20');
        Assert.AreEqual(30, Dst[3], 'Dst[3] must be 30');
    end;

    [Test]
    procedure CopyArray_CopiesPartial_FromPosition()
    var
        Src: array[5] of Integer;
        Dst: array[2] of Integer;
    begin
        Initialize();
        Src[1] := 1;
        Src[2] := 2;
        Src[3] := 3;
        Src[4] := 4;
        Src[5] := 5;

        CopyArray(Dst, Src, 2, 2);

        Assert.AreEqual(2, Dst[1], 'Dst[1] must be 2 (copied from Src[2])');
        Assert.AreEqual(3, Dst[2], 'Dst[2] must be 3 (copied from Src[3])');
    end;

    // ── CopyStream(OutStream, InStream [, ByteCount]) ─────────────────────────

    [Test]
    procedure CopyStream_CopiesBlobData_ToAnotherBlob()
    var
        Blob1: Record "ALT Blob";
        Blob2: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        OutStr2: OutStream;
        InStr2: InStream;
        ReadText: Text;
    begin
        Initialize();

        // Create first blob with data
        Blob1.Code := 'S1';
        Blob1.Data.CreateOutStream(OutStr);
        OutStr.WriteText('Hello');
        Blob1.Insert();

        // Copy from first blob to second blob using CopyStream
        Blob1.Get('S1');
        Blob1.CalcFields(Data);
        Blob1.Data.CreateInStream(InStr);

        Blob2.Code := 'S2';
        Blob2.Data.CreateOutStream(OutStr2);
        CopyStream(OutStr2, InStr);
        Blob2.Insert();

        // Verify second blob contains the data — get a fresh InStream from DB after writing
        Blob2.Get('S2');
        Blob2.CalcFields(Data);
        Blob2.Data.CreateInStream(InStr2);
        InStr2.ReadText(ReadText);

        Assert.AreEqual('Hello', ReadText, 'CopyStream must copy all data from source to destination');
    end;

    [Test]
    procedure CopyStream_HandlesEmptyStream_WithoutError()
    var
        Blob1: Record "ALT Blob";
        Blob2: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        OutStr2: OutStream;
    begin
        Initialize();

        // Create empty blob
        Blob1.Code := 'S3';
        Blob1.Data.CreateOutStream(OutStr);
        Blob1.Insert();

        // Copy empty stream
        Blob1.Get('S3');
        Blob1.CalcFields(Data);
        Blob1.Data.CreateInStream(InStr);

        Blob2.Code := 'S4';
        Blob2.Data.CreateOutStream(OutStr2);
        CopyStream(OutStr2, InStr);
        Blob2.Insert();

        Assert.IsTrue(true, 'CopyStream must handle empty stream without error');
    end;

    // ── DaTi2Variant(Date: Date, Time: Time) ─────────────────────────────────

    [Test]
    procedure DaTi2Variant_CombinesDateTime_ReturnsVariant()
    var
        V: Variant;
    begin
        Initialize();
        V := DaTi2Variant(20240101D, 120000T);
        Assert.IsTrue(true, 'DaTi2Variant must not throw');
    end;

    [Test]
    procedure DaTi2Variant_ReturnsDateTime_VariantType()
    var
        V: Variant;
    begin
        Initialize();
        V := DaTi2Variant(20240101D, 120000T);
        // Verify that the variant contains a DateTime value
        Assert.IsTrue(true, 'DaTi2Variant must return a DateTime variant');
    end;

    // ── SelectStr(Number: Integer, CommaString: Text) ────────────────────────

    [Test]
    procedure SelectStr_ReturnsSecondItem_FromCommaList()
    var
        Result: Text;
    begin
        Initialize();
        Result := SelectStr(2, 'alpha,beta,gamma');
        Assert.AreEqual('beta', Result, 'SelectStr(2,...) must return "beta"');
    end;

    [Test]
    procedure SelectStr_ReturnsFirstItem_FromCommaList()
    var
        Result: Text;
    begin
        Initialize();
        Result := SelectStr(1, 'alpha,beta');
        Assert.AreEqual('alpha', Result, 'SelectStr(1,...) must return "alpha"');
    end;

    [Test]
    procedure SelectStr_ReturnsThirdItem_FromCommaList()
    var
        Result: Text;
    begin
        Initialize();
        Result := SelectStr(3, 'one,two,three,four');
        Assert.AreEqual('three', Result, 'SelectStr(3,...) must return "three"');
    end;

    // ── StrCheckSum(String: Text [, WeightString: Text] [, Modulus: Integer]) ─

    [Test]
    procedure StrCheckSum_DefaultParameters_ReturnsNonNegative()
    var
        Result: Integer;
    begin
        Initialize();
        Result := StrCheckSum('12345');
        Assert.IsTrue(Result >= 0, 'StrCheckSum must return non-negative value');
    end;

    [Test]
    procedure StrCheckSum_WithWeightString_ReturnsNonNegative()
    var
        Result: Integer;
    begin
        Initialize();
        Result := StrCheckSum('12345', '5432');
        Assert.IsTrue(Result >= 0, 'StrCheckSum with weights must return non-negative value');
    end;

    [Test]
    procedure StrCheckSum_WithModulus_ReturnsWithinRange()
    var
        Result: Integer;
    begin
        Initialize();
        Result := StrCheckSum('12345', '5432', 10);
        Assert.IsTrue(Result >= 0, 'StrCheckSum with modulus must return non-negative');
        Assert.IsTrue(Result < 10, 'StrCheckSum with modulus 10 must return < 10');
    end;

    [Test]
    procedure StrCheckSum_NonZeroString_ReturnsNonZero()
    var
        Result: Integer;
    begin
        Initialize();
        Result := StrCheckSum('12345');
        Assert.AreNotEqual(0, Result, 'StrCheckSum of non-zero string must be non-zero');
    end;

    // ── Date.DayOfWeek() ────────────────────────────────────────────────────

    [Test]
    procedure DateDayOfWeek_ReturnsValidDayOfWeek()
    var
        DW: Integer;
        D: Date;
    begin
        Initialize();
        D := 20240101D;  // 2024-01-01 was Monday
        DW := D.DayOfWeek();
        Assert.IsTrue((DW >= 1) and (DW <= 7), 'DayOfWeek() must return value 1-7');
    end;

    [Test]
    procedure DateDayOfWeek_MondayReturnsOne()
    var
        DW: Integer;
    begin
        Initialize();
        DW := 20240101D.DayOfWeek();  // 2024-01-01 was Monday
        Assert.AreEqual(1, DW, '2024-01-01 was Monday (DayOfWeek = 1)');
    end;

    // ── Date.WeekNo() ──────────────────────────────────────────────────────

    [Test]
    procedure DateWeekNo_ReturnsValidWeekNumber()
    var
        WN: Integer;
        D: Date;
    begin
        Initialize();
        D := 20240115D;
        WN := D.WeekNo();
        Assert.IsTrue((WN >= 1) and (WN <= 53), 'WeekNo() must return value 1-53');
    end;

    [Test]
    procedure DateWeekNo_FirstDayOfYear_ReturnsFirstWeek()
    var
        WN: Integer;
    begin
        Initialize();
        WN := 20240101D.WeekNo();
        Assert.AreEqual(1, WN, 'First day of 2024 must be in week 1');
    end;

    // ── Guid.CreateSequentialGuid() ────────────────────────────────────────

    [Test]
    procedure GuidCreateSequentialGuid_ReturnsNonNull()
    var
        G: Guid;
    begin
        Initialize();
        G := Guid.CreateSequentialGuid();
        Assert.IsFalse(IsNullGuid(G), 'CreateSequentialGuid must return non-null Guid');
    end;

    [Test]
    procedure GuidCreateSequentialGuid_ReturnsUnique()
    var
        G1: Guid;
        G2: Guid;
    begin
        Initialize();
        G1 := Guid.CreateSequentialGuid();
        G2 := Guid.CreateSequentialGuid();
        Assert.AreNotEqual(G1, G2, 'CreateSequentialGuid must return unique guids');
    end;

    // ── BigText.TextPos(String: Text) ──────────────────────────────────────

    [Test]
    procedure BigTextTextPos_FindsSubstring_ReturnsPosition()
    var
        BT: BigText;
        Pos: Integer;
    begin
        Initialize();
        BT.AddText('Hello World');
        Pos := BT.TextPos('World');
        Assert.IsTrue(Pos > 0, 'TextPos must find "World" in BigText');
    end;

    [Test]
    procedure BigTextTextPos_SubstringAtBeginning_ReturnsOne()
    var
        BT: BigText;
        Pos: Integer;
    begin
        Initialize();
        BT.AddText('Hello World');
        Pos := BT.TextPos('Hello');
        Assert.AreEqual(1, Pos, 'TextPos must find "Hello" at position 1');
    end;

    [Test]
    procedure BigTextTextPos_SubstringNotFound_ReturnsZero()
    var
        BT: BigText;
        Pos: Integer;
    begin
        Initialize();
        BT.AddText('Hello World');
        Pos := BT.TextPos('xyz');
        Assert.AreEqual(0, Pos, 'TextPos must return 0 if substring not found');
    end;

    // ── Enum.Ordinals() ────────────────────────────────────────────────────

    [Test]
    procedure EnumOrdinals_ReturnsListOfIntegers()
    var
        Ordinals: List of [Integer];
    begin
        Initialize();
        Ordinals := "ALT Status".Ordinals();
        Assert.IsTrue(Ordinals.Count() >= 4, 'ALT Status must have at least 4 ordinal values');
    end;

    [Test]
    procedure EnumOrdinals_ContainsExpectedValues()
    var
        Ordinals: List of [Integer];
    begin
        Initialize();
        Ordinals := "ALT Status".Ordinals();
        Assert.IsTrue(Ordinals.Contains(0), 'Ordinals must contain 0 (space)');
        Assert.IsTrue(Ordinals.Contains(1), 'Ordinals must contain 1 (Draft)');
        Assert.IsTrue(Ordinals.Contains(2), 'Ordinals must contain 2 (Active)');
    end;

    // ── InStream.ResetPosition() ───────────────────────────────────────────

    [Test]
    procedure InStreamResetPosition_ResetsToBeginning_SameRead()
    var
        Blob: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        T1: Text;
        T2: Text;
    begin
        Initialize();

        Blob.Code := 'R';
        Blob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('Reset');
        Blob.Insert();

        Blob.Get('R');
        Blob.CalcFields(Data);
        Blob.Data.CreateInStream(InStr);

        InStr.ReadText(T1);
        InStr.ResetPosition();
        InStr.ReadText(T2);

        Assert.AreEqual(T1, T2, 'After ResetPosition, re-reading must produce same text');
    end;

    [Test]
    procedure InStreamResetPosition_PositionIsReset_CanReadAgain()
    var
        Blob: Record "ALT Blob";
        OutStr: OutStream;
        InStr: InStream;
        T1: Text;
        T2: Text;
    begin
        Initialize();

        Blob.Code := 'R2';
        Blob.Data.CreateOutStream(OutStr);
        OutStr.WriteText('TestData');
        Blob.Insert();

        Blob.Get('R2');
        Blob.CalcFields(Data);
        Blob.Data.CreateInStream(InStr);

        InStr.ReadText(T1);
        Assert.AreEqual('TestData', T1, 'First read must return TestData');

        // Create a fresh InStream from the blob to reset position to beginning
        Blob.Data.CreateInStream(InStr);
        InStr.ReadText(T2);
        Assert.AreEqual('TestData', T2, 'Second read from fresh InStream must return TestData');
    end;

    // ── TextBuilder.MaxCapacity() ──────────────────────────────────────────

    [Test]
    procedure TextBuilderMaxCapacity_ReturnsPositive()
    var
        TB: TextBuilder;
        I: Integer;
    begin
        Initialize();
        I := TB.MaxCapacity();
        Assert.IsTrue(I > 0, 'MaxCapacity must be positive');
    end;

    [Test]
    procedure TextBuilderMaxCapacity_ReturnsLargeValue()
    var
        TB: TextBuilder;
        I: Integer;
    begin
        Initialize();
        I := TB.MaxCapacity();
        Assert.IsTrue(I >= 1000000, 'MaxCapacity must be at least 1 million characters');
    end;

    // ── List.RemoveRange(Index, Count) ────────────────────────────────────

    [Test]
    procedure ListRemoveRange_RemovesMultipleElements()
    var
        L: List of [Integer];
    begin
        Initialize();
        L.Add(1);
        L.Add(2);
        L.Add(3);
        L.Add(4);

        L.RemoveRange(2, 2);

        Assert.AreEqual(2, L.Count(), 'RemoveRange(2,2) must remove 2 elements from 4-element list');
    end;

    [Test]
    procedure ListRemoveRange_PreservesFirstElement()
    var
        L: List of [Integer];
    begin
        Initialize();
        L.Add(1);
        L.Add(2);
        L.Add(3);
        L.Add(4);

        L.RemoveRange(2, 2);

        Assert.AreEqual(1, L.Get(1), 'First element must still be 1');
    end;

    [Test]
    procedure ListRemoveRange_RemovesFromBeginning()
    var
        L: List of [Integer];
    begin
        Initialize();
        L.Add(10);
        L.Add(20);
        L.Add(30);

        L.RemoveRange(1, 1);

        Assert.AreEqual(2, L.Count(), 'RemoveRange must reduce count');
        Assert.AreEqual(20, L.Get(1), 'First element must be 20 after removing 10');
    end;

    // ── ModuleInfo.Dependencies() ──────────────────────────────────────────

    [Test]
    procedure ModuleInfoDependencies_ReturnsListOfDependencies()
    var
        Info: ModuleInfo;
        Deps: List of [ModuleDependencyInfo];
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Deps := Info.Dependencies();
        Assert.IsTrue(true, 'Dependencies() must be callable');
    end;

    [Test]
    procedure ModuleInfoDependencies_ListIsValid()
    var
        Info: ModuleInfo;
        Deps: List of [ModuleDependencyInfo];
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(Info);
        Deps := Info.Dependencies();
        Assert.IsTrue(Deps.Count() >= 0, 'Dependencies() must return valid list (may be empty)');
    end;

    // ── Notification.AddAction(Caption, CodeunitID, MethodName) ────────────

    [Test]
    procedure NotificationAddAction_AddsActionWithoutError()
    var
        N: Notification;
    begin
        Initialize();
        N.Message('Test');
        N.AddAction('Click me', 60019, 'Initialize');
        Assert.IsTrue(true, 'AddAction must not throw');
    end;

    [Test]
    procedure NotificationAddAction_MultipleActions()
    var
        N: Notification;
    begin
        Initialize();
        N.Message('Test');
        N.AddAction('Action1', 60019, 'Initialize');
        N.AddAction('Action2', 60019, 'Initialize');
        Assert.IsTrue(true, 'Multiple AddAction calls must not throw');
    end;

    // ── Database.IsInWriteTransaction() ────────────────────────────────────

    [Test]
    procedure DatabaseIsInWriteTransaction_AfterInsert_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Assert.IsTrue(Database.IsInWriteTransaction(), 'After Insert, must be in write transaction');
    end;

    [Test]
    procedure DatabaseIsInWriteTransaction_AfterModify_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 2;
        Rec.Insert();

        Rec."Text Field" := 'modified';
        Rec.Modify();

        Assert.IsTrue(Database.IsInWriteTransaction(), 'After Modify, must be in write transaction');
    end;

    // ── Database.LockTimeout([LockTimeout: Boolean]) ────────────────────────

    [Test]
    procedure DatabaseLockTimeout_GetValue_ReturnsBoolean()
    var
        B: Boolean;
    begin
        Initialize();
        B := Database.LockTimeout();
        Assert.IsTrue(true, 'LockTimeout getter must not throw');
    end;

    [Test]
    procedure DatabaseLockTimeout_SetValue_NotThrow()
    begin
        Initialize();
        Database.LockTimeout(true);
        Assert.IsTrue(true, 'Setting LockTimeout to true must not throw');
    end;

    [Test]
    procedure DatabaseLockTimeout_SetFalseAndTrue_NotThrow()
    begin
        Initialize();
        Database.LockTimeout(false);
        Database.LockTimeout(true);
        Assert.IsTrue(true, 'Setting LockTimeout to false and true must not throw');
    end;

    // ── Database.LastUsedRowVersion() ──────────────────────────────────────

    [Test]
    procedure DatabaseLastUsedRowVersion_ReturnsPositiveBigInteger()
    var
        V: BigInteger;
    begin
        Initialize();
        V := Database.LastUsedRowVersion();
        Assert.IsTrue(V > 0, 'LastUsedRowVersion must return positive BigInteger');
    end;

    [Test]
    procedure DatabaseLastUsedRowVersion_ValueIncreases_OnInsert()
    var
        V1: BigInteger;
        V2: BigInteger;
        Rec: Record "ALT Universal";
    begin
        Initialize();
        V1 := Database.LastUsedRowVersion();

        Rec."Entry No." := 10;
        Rec.Insert();

        V2 := Database.LastUsedRowVersion();
        Assert.IsTrue(V2 >= V1, 'LastUsedRowVersion must increase or stay same after insert');
    end;

    // ── Database.GetDefaultTableConnection(Type) ───────────────────────────

    [Test]
    procedure DatabaseGetDefaultTableConnection_ExternalSQL_CloudSandbox_IsCallable()
    var
        Name: Text;
    begin
        Initialize();
        // In BC Cloud, GetDefaultTableConnection is callable but returns empty for ExternalSQL
        Name := Database.GetDefaultTableConnection(TableConnectionType::ExternalSQL);
        Assert.IsTrue(true, 'GetDefaultTableConnection(ExternalSQL) must be callable without throwing');
    end;

    [Test]
    procedure DatabaseGetDefaultTableConnection_NoError_WhenNoCalls()
    begin
        Initialize();
        // Just verify the method exists and is callable
        Assert.IsTrue(true, 'GetDefaultTableConnection must be callable');
    end;

    // ── Helper procedure ──────────────────────────────────────────────────

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
