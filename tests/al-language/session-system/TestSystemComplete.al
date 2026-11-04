// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Fixture Cleanup (60001)
// Remaining System global functions: DateTime handling, math functions, string utilities, array operations

codeunit 60142 "Test System Complete"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── DateTime Functions ──────────────────────────────────────────────────────

    [Test]
    procedure System_DT2Date_ExtractsDateFromDateTime()
    var
        DT: DateTime;
        D: Date;
    begin
        Initialize();
        DT := CreateDateTime(20240101D, 120000T);
        D := DT2Date(DT);
        Assert.AreEqual(20240101D, D, 'DT2Date must extract date portion from datetime');
    end;

    [Test]
    procedure System_DT2Time_ExtractsTimeFromDateTime()
    var
        DT: DateTime;
        T: Time;
    begin
        Initialize();
        DT := CreateDateTime(20240101D, 120000T);
        T := DT2Time(DT);
        Assert.AreEqual(120000T, T, 'DT2Time must extract time portion from datetime');
    end;

    [Test]
    procedure System_NormalDate_ConvertsClosingDateToNormalDate()
    var
        D: Date;
        D2: Date;
    begin
        Initialize();
        D := ClosingDate(20241231D);
        D2 := NormalDate(D);
        Assert.AreNotEqual(0D, D2, 'NormalDate must convert closing date back to normal date');
    end;

    // ── Math Functions: Absolute Value ──────────────────────────────────────────

    [Test]
    procedure System_Abs_ReturnsAbsoluteValue()
    var
        Value: Decimal;
        Result: Decimal;
    begin
        Initialize();
        Value := -42;
        Result := Abs(Value);
        Assert.AreEqual(42, Result, 'Abs must return absolute value of decimal');
    end;

    [Test]
    procedure System_Abs_WithBigInteger_ReturnsAbsoluteValue()
    var
        BI: BigInteger;
        Result: BigInteger;
    begin
        Initialize();
        BI := -100;
        Result := Abs(BI);
        Assert.IsTrue(Result = 100, 'Abs must return absolute value of BigInteger');
    end;

    // ── Math Functions: Rounding ────────────────────────────────────────────────

    [Test]
    procedure System_Round_HalfValue_RoundsHalfUp()
    var
        Value: Decimal;
        Result: Decimal;
    begin
        Initialize();
        Value := 2.5;
        Result := Round(Value, 1);
        Assert.AreEqual(3.0, Result, 'Round(2.5, 1) must use round-half-away-from-zero (standard BC rounding) and return 3');
    end;

    [Test]
    procedure System_Round_WithPrecision()
    var
        Value: Decimal;
        Result: Decimal;
    begin
        Initialize();
        Value := 3.14159;
        Result := Round(Value, 0.01);
        Assert.AreEqual(3.14, Result, 'Round with 0.01 precision must round to 3.14');
    end;

    [Test]
    procedure System_Round_NegativeValue_RoundsHalfAwayFromZero()
    var
        Value: Decimal;
        Result: Decimal;
    begin
        Initialize();
        Value := -2.5;
        Result := Round(Value, 1);
        Assert.AreEqual(-3.0, Result, 'Round(-2.5, 1) must use round-half-away-from-zero and return -3');
    end;

    // ── Math Functions: Power ───────────────────────────────────────────────────

    [Test]
    procedure System_Power_CalculatesPower()
    var
        Result: Decimal;
    begin
        Initialize();
        Result := Power(2, 3);
        Assert.AreEqual(8.0, Result, '2^3 must equal 8');
    end;

    [Test]
    procedure System_Power_PowerOfZero()
    var
        Result: Decimal;
    begin
        Initialize();
        Result := Power(5, 0);
        Assert.AreEqual(1.0, Result, '5^0 must equal 1');
    end;

    [Test]
    procedure System_Power_BaseOfOne()
    var
        Result: Decimal;
    begin
        Initialize();
        Result := Power(1, 100);
        Assert.AreEqual(1.0, Result, '1^100 must equal 1');
    end;

    // ── Math Functions: Exponential & Logarithm ────────────────────────────────

                // ── Math Functions: Square Root ─────────────────────────────────────────────

                // ── Math Functions: Trigonometry ────────────────────────────────────────────

                // ── Math Functions: Inverse Trigonometry ───────────────────────────────────

                // ── Array Functions ────────────────────────────────────────────────────────

    [Test]
    procedure System_ArrayLen_Single_Dimension()
    var
        A: array[5] of Integer;
        Len: Integer;
    begin
        Initialize();
        Len := ArrayLen(A);
        Assert.AreEqual(5, Len, 'ArrayLen must return correct length for single-dimension array');
    end;

    [Test]
    procedure System_ArrayLen_Two_Dimensions_FirstDim()
    var
        A: array[3, 4] of Integer;
        Len: Integer;
    begin
        Initialize();
        Len := ArrayLen(A, 1);
        Assert.AreEqual(3, Len, 'ArrayLen(A, 1) must return first dimension length');
    end;

    [Test]
    procedure System_ArrayLen_Two_Dimensions_SecondDim()
    var
        A: array[3, 4] of Integer;
        Len: Integer;
    begin
        Initialize();
        Len := ArrayLen(A, 2);
        Assert.AreEqual(4, Len, 'ArrayLen(A, 2) must return second dimension length');
    end;

    // ── String Functions ────────────────────────────────────────────────────────

    [Test]
    procedure System_StrSubstNo_SinglePlaceholder()
    var
        Result: Text;
    begin
        Initialize();
        Result := StrSubstNo('Value is %1', 42);
        Assert.AreEqual('Value is 42', Result, 'StrSubstNo must substitute single placeholder');
    end;

    [Test]
    procedure System_StrSubstNo_MultiplePlaceholders()
    var
        Result: Text;
    begin
        Initialize();
        Result := StrSubstNo('%1 and %2', 'A', 'B');
        Assert.AreEqual('A and B', Result, 'StrSubstNo must substitute multiple placeholders');
    end;

    [Test]
    procedure System_StrSubstNo_WithDecimals()
    var
        Result: Text;
    begin
        Initialize();
        Result := StrSubstNo('Price: %1, Qty: %2', 99.99, 10);
        Assert.AreEqual('Price: 99.99, Qty: 10', Result, 'StrSubstNo must handle decimal values');
    end;

    // ── Global State Functions ─────────────────────────────────────────────────

    [Test]
    procedure System_ClearAll_DoesNotThrow()
    begin
        Initialize();
        ClearAll();
        Assert.IsTrue(true, 'ClearAll() must not throw');
    end;

    [Test]
    procedure System_SelectLatestVersion_NoParameter_DoesNotThrow()
    begin
        Initialize();
        SelectLatestVersion();
        Assert.IsTrue(true, 'SelectLatestVersion() without parameter must not throw');
    end;

    [Test]
    procedure System_SelectLatestVersion_WithTableNo_DoesNotThrow()
    begin
        Initialize();
        SelectLatestVersion(60000);
        Assert.IsTrue(true, 'SelectLatestVersion(TableNo) must not throw');
    end;

    // ── Cleanup ─────────────────────────────────────────────────────────────────

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
