// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 85061, 85062, 85064 and enum 85063 (CqOddLeadObjects.al)
// Topic: corpus issue 672 (odd AL behavior leads, part G), items 32 to 46: Duration and Option arithmetic, Round, 0T, for loops,
// DecimalPlaces, BigInteger narrowing in FlowFields, Integer overflow, Power, Code length, IncStr, MaxStrLen of var parameters,
// backslashes and line breaks in Message and Error.
// Facts: Round(x) keeps rounding to 0.01 after "Amount Rounding Precision" changes in the same session; Round(-1234.56789, 1) = -1235;
// 0T - 0T = 0 (no error); a for loop leaves the control variable at the last value it had (an empty loop sets it to the start value);
// a BigInteger end bound beyond Integer fails with ConversionCast; DecimalPlaces only changes Format, not the stored value;
// Integer products overflow before they reach a BigInteger or Decimal target; Decimal arithmetic near 2^62 loses the last digits;
// MaxStrLen of a var Text parameter is the argument's length, of a by-value Text parameter 2147483647; CR LF from TextBuilder.AppendLine
// reaches a MessageHandler and GetLastErrorText as one backslash each, and a backslash in a Message or Error text stays a backslash.
// Compile-only parts are must-not-compile cases 1728 to 1735 and 0584 (unary minus on Duration).
// BC versions: 27.5, 28.5, 29.0

codeunit 85060 "LT CQ Odd Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LastMessage: Text;

    [Test]
    procedure Item32_DurationNegation()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        M: Duration;
    begin
        D := 90000;
        M := 0 - D;
        Observer.Observe('0 - D', Format(M));
        M := -1 * D;
        Observer.Observe('-1 * D', Format(M));
        M := D * -1;
        Observer.Observe('D * -1', Format(M));
        Observer.Observe('0 - D = -90000', Format((0 - D) = -90000));
        Observer.Expect('0 - D', '-1 minute 30 seconds');
        Observer.Expect('-1 * D', '-1 minute 30 seconds');
        Observer.Expect('D * -1', '-1 minute 30 seconds');
        Observer.Expect('0 - D = -90000', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item33_RoundFollowsAmountRoundingPrecision()
    var
        Observer: Codeunit "Probe Observer";
        GLSetup: Record "General Ledger Setup";
        Saved: Decimal;
    begin
        if not GLSetup.Get() then begin
            GLSetup.Init();
            GLSetup.Insert();
        end;
        Saved := GLSetup."Amount Rounding Precision";
        Observer.Observe('setup', Format(Saved));
        Observer.Observe('before 1.555', Format(Round(1.555)));
        Observer.Observe('before 2.5', Format(Round(2.5)));
        SetPrecision(1);
        Observer.Observe('p1 1.55', Format(Round(1.55)));
        Observer.Observe('p1 2.5', Format(Round(2.5)));
        Observer.Observe('p1 -2.5', Format(Round(-2.5)));
        SetPrecision(0.1);
        Observer.Observe('p0.1 1.55', Format(Round(1.55)));
        Observer.Observe('p0.1 2.5', Format(Round(2.5)));
        SetPrecision(0.001);
        Observer.Observe('p0.001 1.5555', Format(Round(1.5555)));
        SetPrecision(0);
        Observer.Observe('p0 1.555', Format(Round(1.555)));
        Observer.Observe('p0 1.5555', Format(Round(1.5555)));
        SetPrecision(Saved);
        Observer.Observe('restored 1.555', Format(Round(1.555)));
        Observer.Expect('setup', '0.01');
        Observer.Expect('before 1.555', '1.56');
        Observer.Expect('before 2.5', '2.5');
        Observer.Expect('p1 1.55', '1.55');
        Observer.Expect('p1 2.5', '2.5');
        Observer.Expect('p1 -2.5', '-2.5');
        Observer.Expect('p0.1 1.55', '1.55');
        Observer.Expect('p0.1 2.5', '2.5');
        Observer.Expect('p0.001 1.5555', '1.56');
        Observer.Expect('p0 1.555', '1.56');
        Observer.Expect('p0 1.5555', '1.56');
        Observer.Expect('restored 1.555', '1.56');
        Observer.Verify();
    end;

    local procedure SetPrecision(P: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Amount Rounding Precision" := P;
        GLSetup.Modify();
    end;

    [Test]
    procedure Item34_DefaultTimeAgainst0TAndMidnight()
    var
        Observer: Codeunit "Probe Observer";
        Time1: Time;
        Time2: Time;
    begin
        Observer.Observe('Time1 = 0T', Format(Time1 = 0T));
        Observer.Observe('Time1 = 000000T', Format(Time1 = 000000T));
        Observer.Observe('Time1 <> 0T', Format(Time1 <> 0T));
        Observer.Observe('Time1 <> 000000T', Format(Time1 <> 000000T));
        Observer.Observe('0T <> 000000T', Format(0T <> 000000T));
        Observer.Observe('Format Time1', Format(Time1));
        Observer.Observe('Format 000000T', Format(000000T));
        Observer.Observe('Evaluate 00:00:00', Format(Evaluate(Time2, '00:00:00')));
        Observer.Observe('eval = 0T', Format(Time2 = 0T));
        Observer.Observe('eval = 000000T', Format(Time2 = 000000T));
        Observer.Observe('eval format 9', Format(Time2, 0, 9));
        Observer.Observe('Evaluate empty', Format(Evaluate(Time2, '')));
        Observer.Observe('empty = 0T', Format(Time2 = 0T));
        Observer.Expect('Time1 = 0T', 'Yes');
        Observer.Expect('Time1 = 000000T', 'No');
        Observer.Expect('Time1 <> 0T', 'No');
        Observer.Expect('Time1 <> 000000T', 'Yes');
        Observer.Expect('0T <> 000000T', 'Yes');
        Observer.Expect('Format Time1', '');
        Observer.Expect('Format 000000T', '12:00:00 AM');
        Observer.Expect('Evaluate 00:00:00', 'Yes');
        Observer.Expect('eval = 0T', 'No');
        Observer.Expect('eval = 000000T', 'Yes');
        Observer.Expect('eval format 9', '00:00:00');
        Observer.Expect('Evaluate empty', 'Yes');
        Observer.Expect('empty = 0T', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item35_ZeroTimeMinusZeroTime()
    var
        Observer: Codeunit "Probe Observer";
        A: Time;
        B: Time;
        I: Integer;
    begin
        I := A - B;
        Observer.Observe('0T - 0T', Format(I));
        I := 0T - 0T;
        Observer.Observe('0T - 0T literal', Format(I));
        Observer.Observe('0T - 0T = 0', Format(A - B = 0));
        Observer.Expect('0T - 0T', '0');
        Observer.Expect('0T - 0T literal', '0');
        Observer.Expect('0T - 0T = 0', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item36_ForLoopBoundsAndCounterAfterLoop()
    var
        Observer: Codeunit "Probe Observer";
        Count: Integer;
        Steps: Integer;
        Big: BigInteger;
    begin
        Steps := 0;
        Big := 100000000000000L;
        asserterror begin
            for Count := 1 to Big do begin
                Steps += 1;
                if Steps = 3 then
                    break;
            end;
            Error('no error');
        end;
        Observer.ObserveError('bigint end bound');
        Observer.Observe('bigint steps', Format(Steps));
        for Count := 1 to 5 do
            Steps := Count;
        Observer.Observe('after normal end', Format(Count));
        for Count := 5 downto 1 do
            Steps := Count;
        Observer.Observe('after downto end', Format(Count));
        for Count := 1 to 5 do
            if Count = 3 then
                break;
        Observer.Observe('after break', Format(Count));
        Count := 77;
        for Count := 5 to 1 do
            Steps := Count;
        Observer.Observe('after empty loop', Format(Count));
        Steps := 0;
        for Count := 1 to 5 do begin
            Steps += 1;
            Count := Count + 1;
        end;
        Observer.Observe('body assigns steps', Format(Steps));
        Observer.Observe('body assigns after', Format(Count));
        Steps := 0;
        for Count := 1 to 5 do begin
            Steps += 1;
            if Steps = 1 then
                Count := 10;
        end;
        Observer.Observe('body jumps past end steps', Format(Steps));
        Observer.Observe('body jumps past end after', Format(Count));
        Observer.Expect('bigint end bound|text', 'Overflow under conversion of System.Int64 value 100000000000000 to System.Int32.');
        Observer.Expect('bigint end bound|code', 'ConversionCast');
        Observer.Expect('bigint steps', '0');
        Observer.Expect('after normal end', '5');
        Observer.Expect('after downto end', '1');
        Observer.Expect('after break', '3');
        Observer.Expect('after empty loop', '5');
        Observer.Expect('body assigns steps', '3');
        Observer.Expect('body assigns after', '6');
        Observer.Expect('body jumps past end steps', '1');
        Observer.Expect('body jumps past end after', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Item37_DecimalPlacesAndStoredValue()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT CQ Dec";
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.D2 := 1.23456;
        Observer.Observe('D2 assigned', Format(Rec.D2));
        Observer.Observe('D2 assigned = 1.23456', Format(Rec.D2 = 1.23456));
        Rec.Validate(D2, 2.34567);
        Observer.Observe('D2 validated', Format(Rec.D2));
        Rec.D20 := 1.123456789012345678;
        Observer.Observe('D20', Format(Rec.D20));
        Rec.D25 := 1;
        Observer.Observe('D25 one', Format(Rec.D25));
        Rec.Insert();
        Rec.Get(1);
        Observer.Observe('D2 read back', Format(Rec.D2));
        Observer.Observe('D2 read back = 2.34567', Format(Rec.D2 = 2.34567));
        Observer.Observe('D25 read back', Format(Rec.D25));
        Observer.Observe('D25 format 9', Format(Rec.D25, 0, 9));
        Observer.Expect('D2 assigned', '1.23');
        Observer.Expect('D2 assigned = 1.23456', 'Yes');
        Observer.Expect('D2 validated', '2.35');
        Observer.Expect('D20', '1.12345678901234568');
        Observer.Expect('D25 one', '1.00');
        Observer.Expect('D2 read back', '2.35');
        Observer.Expect('D2 read back = 2.34567', 'Yes');
        Observer.Expect('D25 read back', '1.00');
        Observer.Expect('D25 format 9', '1.00');
        Observer.Verify();
    end;

    [Test]
    procedure Item38_BigIntegerSumIntoIntegerFlowField()
    var
        Observer: Codeunit "Probe Observer";
        Flow: Record "LT CQ Flow";
    begin
        // asserterror rolls back the inserted rows, so every step inserts them again first.
#if BC29PLUS
        SetupFlowRows(Flow);
        Flow.Id := 2;
        Flow.CalcFields(SumInt);
        Observer.Observe('sum small', Format(Flow.SumInt));
        SetupFlowRows(Flow);
        Flow.Id := 3;
        asserterror begin
            Flow.CalcFields(SumInt);
            Error('no error: %1', Flow.SumInt);
        end;
        Observer.ObserveError('sum 4000000001');
        Observer.Expect('sum small', '11');
        Observer.Expect('sum 4000000001|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('sum 4000000001|code', 'AL:Overflow');
#else
        // BC 27.5 and 28.5 publish the FlowField but refuse to calculate it, also for a small sum.
        SetupFlowRows(Flow);
        Flow.Id := 2;
        asserterror begin
            Flow.CalcFields(SumInt);
            Error('no error: %1', Flow.SumInt);
        end;
        Observer.ObserveError('sum small');
        Observer.Expect('sum small|text', 'The following fields must have the same type:\\Field: SumInt <-- Id\Table: LT CQ Flow <-- LT CQ Src\Type: Integer <-- BigInteger');
        Observer.Expect('sum small|code', 'DB:TypeMisMatch');
#endif
        Observer.Verify();
    end;

#if BC29PLUS
    // BC 27.5 and 28.5 refuse to publish the FlowFields LookupInt, Cnt2 and CntEnum (AL0427 for LookupInt, AL0204 for the two
    // count filters); the BC 29 service tier accepts them, and the AL 30 compiler only warns (AL0662, AL0663).
    [Test]
    procedure Item38_BigIntegerIntoIntegerAndEnumFlowFields()
    var
        Observer: Codeunit "Probe Observer";
        Flow: Record "LT CQ Flow";
    begin
        SetupFlowRows(Flow);
        Flow.Id := 2;
        Flow.CalcFields(LookupInt);
        Observer.Observe('lookup small', Format(Flow.LookupInt));
        Flow.Big := 1;
        Flow.CalcFields(Cnt2);
        Observer.Observe('count int = 1', Format(Flow.Cnt2));
        Flow.Big := 0;
        Flow.CalcFields(Cnt2);
        Observer.Observe('count int = 0', Format(Flow.Cnt2));
        SetupFlowRows(Flow);
        Flow.Id := 1;
        asserterror begin
            Flow.CalcFields(LookupInt);
            Error('no error: %1', Flow.LookupInt);
        end;
        Observer.ObserveError('lookup 3000000000');
        SetupFlowRows(Flow);
        Flow.Big := 1;
        asserterror begin
            Flow.CalcFields(CntEnum);
            Error('no error: %1', Flow.CntEnum);
        end;
        Observer.ObserveError('count enum = 1');
        SetupFlowRows(Flow);
        Flow.Big := 3000000000L;
        asserterror begin
            Flow.CalcFields(Cnt2);
            Error('no error: %1', Flow.Cnt2);
        end;
        Observer.ObserveError('count int = 3000000000');
        Observer.Expect('lookup small', '5');
        Observer.Expect('count int = 1', '2');
        Observer.Expect('count int = 0', '3');
        Observer.Expect('lookup 3000000000|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('lookup 3000000000|code', 'AL:Overflow');
        Observer.Expect('count enum = 1|text', 'The following fields must have the same type:\\Field: En <-- Big\Table: LT CQ Src <-- LT CQ Flow\Type: Option <-- BigInteger');
        Observer.Expect('count enum = 1|code', 'DB:TypeMisMatch');
        Observer.Expect('count int = 3000000000|text', 'Overflow under conversion of System.Int64 value 3000000000 to System.Int32.');
        Observer.Expect('count int = 3000000000|code', 'ConversionCast');
        Observer.Verify();
    end;
#endif

    local procedure SetupFlowRows(var Flow: Record "LT CQ Flow")
    var
        Src: Record "LT CQ Src";
    begin
        Src.DeleteAll();
        Flow.DeleteAll();
        AddSrc(3000000000L, 1, Enum::"LT CQ E"::A, 0);
        AddSrc(5, 2, Enum::"LT CQ E"::B, 1);
        AddSrc(6, 2, Enum::"LT CQ E"::B, 1);
        AddSrc(2000000000, 3, Enum::"LT CQ E"::A, 0);
        AddSrc(2000000001, 3, Enum::"LT CQ E"::A, 0);
        Flow.Init();
        Flow.Id := 1;
        Flow.Insert();
    end;

    local procedure AddSrc(Id: BigInteger; Other: Integer; En: Enum "LT CQ E"; Int: Integer)
    var
        Src: Record "LT CQ Src";
    begin
        Src.Init();
        Src.Id := Id;
        Src.Other := Other;
        Src.En := En;
        Src.Int := Int;
        Src.Insert();
    end;

    [Test]
    procedure Item39_IntegerProductAssignedToBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        H: Integer;
        L: Integer;
        W: Integer;
        Q: Integer;
        Big: BigInteger;
        B1: BigInteger;
        Dec: Decimal;
        J: JsonObject;
    begin
        H := 60;
        L := 120;
        W := 80;
        Q := 4;
        asserterror Big := (H * 10) * (L * 10) * (W * 10) * Q;
        Observer.ObserveError('assign');
        asserterror TakeBig((H * 10) * (L * 10) * (W * 10) * Q);
        Observer.ObserveError('parameter');
        asserterror J.Add('k', (H * 10) * (L * 10) * (W * 10) * Q);
        Observer.ObserveError('json add');
        B1 := H * 10;
        Big := B1 * (L * 10) * (W * 10) * Q;
        Observer.Observe('BigInteger first', Format(Big));
        asserterror Dec := (H * 10) * (L * 10) * (W * 10) * Q * 1.0;
        Observer.ObserveError('decimal literal last');
        Dec := 1.0 * (H * 10) * (L * 10) * (W * 10) * Q;
        Observer.Observe('decimal literal first', Format(Dec));
        Observer.Expect('assign|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('assign|code', 'AL:Overflow');
        Observer.Expect('parameter|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('parameter|code', 'AL:Overflow');
        Observer.Expect('json add|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('json add|code', 'AL:Overflow');
        Observer.Expect('BigInteger first', '2304000000');
        Observer.Expect('decimal literal last|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('decimal literal last|code', 'AL:Overflow');
        Observer.Expect('decimal literal first', '2,304,000,000');
        Observer.Verify();
    end;

    local procedure TakeBig(Value: BigInteger)
    begin
        Error('got %1', Value);
    end;

    [Test]
    procedure Item40_PowerPrecision()
    var
        Observer: Codeunit "Probe Observer";
        V1: Decimal;
        V11: Decimal;
        V22: Decimal;
    begin
        V1 := Power(2, 63);
        V11 := V1 - 1.0;
        V22 := V1 - 5.0;
        Observer.Observe('v1-1 = v1-5', Format(V11 = V22));
        Observer.Observe('v1-1 <> v1-5', Format(V11 <> V22));
        Observer.Observe('(v1-1)-(v1-5)', Format(V11 - V22));
        Observer.Observe('2^53+1-2^53', Format(Power(2, 53) + 1 - Power(2, 53)));
        Observer.Observe('2^60 - exact', Format(Power(2, 60) - 1152921504606846976.0));
        Observer.Observe('2^63 - exact', Format(V1 - 9223372036854775808.0));
        Observer.Observe('3^40 - exact', Format(Power(3, 40) - 12157665459056928801.0));
        Observer.Observe('2^62 = 2^62+1', Format(Power(2, 62) = Power(2, 62) + 1));
        Observer.Expect('v1-1 = v1-5', 'Yes');
        Observer.Expect('v1-1 <> v1-5', 'No');
        Observer.Expect('(v1-1)-(v1-5)', '0');
        Observer.Expect('2^53+1-2^53', '1');
        Observer.Expect('2^60 - exact', '0');
        Observer.Expect('2^63 - exact', '0');
        Observer.Expect('3^40 - exact', '0');
        Observer.Expect('2^62 = 2^62+1', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Item41_RoundLearnTable()
    var
        Observer: Codeunit "Probe Observer";
        X: Decimal;
    begin
        X := -1234.56789;
        Observer.Observe('-x 100', Format(Round(X, 100)));
        Observer.Observe('-x 10', Format(Round(X, 10)));
        Observer.Observe('-x 1', Format(Round(X, 1)));
        Observer.Observe('-x 0.1', Format(Round(X, 0.1)));
        Observer.Observe('-x 0.01', Format(Round(X, 0.01)));
        Observer.Observe('-x 0.001', Format(Round(X, 0.001)));
        Observer.Observe('-x 1 <', Format(Round(X, 1, '<')));
        Observer.Observe('-x 1 >', Format(Round(X, 1, '>')));
        Observer.Observe('+x 1', Format(Round(-X, 1)));
        Observer.Observe('+x 10', Format(Round(-X, 10)));
        Observer.Observe('+x 100', Format(Round(-X, 100)));
        Observer.Expect('-x 100', '-1,200');
        Observer.Expect('-x 10', '-1,230');
        Observer.Expect('-x 1', '-1,235');
        Observer.Expect('-x 0.1', '-1,234.6');
        Observer.Expect('-x 0.01', '-1,234.57');
        Observer.Expect('-x 0.001', '-1,234.568');
        Observer.Expect('-x 1 <', '-1,234');
        Observer.Expect('-x 1 >', '-1,235');
        Observer.Expect('+x 1', '1,235');
        Observer.Expect('+x 10', '1,230');
        Observer.Expect('+x 100', '1,200');
        Observer.Verify();
    end;

    [Test]
    procedure Item42_OptionAndEnumNegatedByMultiplication()
    var
        Observer: Codeunit "Probe Observer";
        Alignment: Option Left,Center,Right;
        Other: Option Left,Center,Right;
        E: Enum "LT CQ E";
        I: Integer;
    begin
        Alignment := Alignment::Center;
        I := -1 * Alignment;
        Observer.Observe('-1 * option', Format(I));
        Other := -1 * Alignment;
        Observer.Observe('option := -1 * option', Format(Other));
        Observer.Observe('option ordinal', Format(Other = -1));
        Other := -1;
        Observer.Observe('option := -1', Format(Other));
        E := E::B;
        I := -1 * E.AsInteger();
        Observer.Observe('-1 * enum ordinal', Format(I));
        Observer.Expect('-1 * option', '-1');
        Observer.Expect('option := -1 * option', '-1');
        Observer.Expect('option ordinal', 'Yes');
        Observer.Expect('option := -1', '-1');
        Observer.Expect('-1 * enum ordinal', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure Item43_CodeVariableLengths()
    var
        Observer: Codeunit "Probe Observer";
        C1025: Code[1025];
        C2048: Code[2048];
    begin
        C1025 := PadStr('', 1025, 'a');
        Observer.Observe('1025 len', Format(StrLen(C1025)));
        Observer.Observe('1025 max', Format(MaxStrLen(C1025)));
        Observer.Observe('1025 upper', Format(C1025 = PadStr('', 1025, 'A')));
        C2048 := ' ' + PadStr('', 2047, 'b') + ' ';
        Observer.Observe('2048 len', Format(StrLen(C2048)));
        Observer.Observe('2048 max', Format(MaxStrLen(C2048)));
        asserterror C2048 := PadStr('', 2049, 'c');
        Observer.Observe('2049 into 2048 text start', CopyStr(GetLastErrorText(), 1, 100));
        Observer.Observe('2049 into 2048 text length', Format(StrLen(GetLastErrorText())));
        Observer.Observe('2049 into 2048 code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('1025 len', '1025');
        Observer.Expect('1025 max', '1025');
        Observer.Expect('1025 upper', 'Yes');
        Observer.Expect('2048 len', '2047');
        Observer.Expect('2048 max', '2048');
        Observer.Expect('2049 into 2048 text start', 'The length of the string is 2049, but it must be less than or equal to 2048 characters. Value: ccccc');
        Observer.Expect('2049 into 2048 text length', '298');
        Observer.Expect('2049 into 2048 code', 'StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Item44_IncStrWithDecimalPoint()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('a99.99b', IncStr('a99.99b'));
        Observer.Observe('1.5', IncStr('1.5'));
        Observer.Observe('a99.99', IncStr('a99.99'));
        Observer.Observe('-1.5', IncStr('-1.5'));
        Observer.Observe('1.9', IncStr('1.9'));
        Observer.Observe('0.99', IncStr('0.99'));
        Observer.Observe('1.', IncStr('1.'));
        Observer.Expect('a99.99b', 'a99.100b');
        Observer.Expect('1.5', '1.6');
        Observer.Expect('a99.99', 'a99.100');
        Observer.Expect('-1.5', '-1.6');
        Observer.Expect('1.9', '1.10');
        Observer.Expect('0.99', '0.100');
        Observer.Expect('1.', '2.');
        Observer.Verify();
    end;

    [Test]
    procedure Item45_MaxStrLenOfParameters()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT CQ Dec";
        T50: Text[50];
        C20: Code[20];
    begin
        Observer.Observe('var Text <- Text[100] field', Format(VarText(Rec.Description)));
        Observer.Observe('var Text <- Text[50] variable', Format(VarText(T50)));
        Observer.Observe('var Text[30] <- Text[30] field', Format(VarText30(Rec.Short)));
        Observer.Observe('var Code <- Code[20] field', Format(VarCode(Rec.No)));
        Observer.Observe('var Code <- Code[20] variable', Format(VarCode(C20)));
        Observer.Observe('Text <- Text[100] field', Format(ValText(Rec.Description)));
        Observer.Observe('Text[30] <- Text[100] field', Format(ValText30(Rec.Description)));
        Observer.Expect('var Text <- Text[100] field', '100');
        Observer.Expect('var Text <- Text[50] variable', '50');
        Observer.Expect('var Text[30] <- Text[30] field', '30');
        Observer.Expect('var Code <- Code[20] field', '20');
        Observer.Expect('var Code <- Code[20] variable', '20');
        Observer.Expect('Text <- Text[100] field', '2147483647');
        Observer.Expect('Text[30] <- Text[100] field', '30');
        Observer.Verify();
    end;

    local procedure VarText(var S: Text): Integer
    begin
        exit(MaxStrLen(S));
    end;

    local procedure VarText30(var S: Text[30]): Integer
    begin
        exit(MaxStrLen(S));
    end;

    local procedure VarCode(var S: Code[20]): Integer
    begin
        exit(MaxStrLen(S));
    end;

    local procedure ValText(S: Text): Integer
    begin
        exit(MaxStrLen(S));
    end;

    local procedure ValText30(S: Text[30]): Integer
    begin
        exit(MaxStrLen(S));
    end;

    [Test]
    [HandlerFunctions('CaptureMessage')]
    procedure Item46_BackslashAndAppendLineInMessageAndError()
    var
        Observer: Codeunit "Probe Observer";
        TB: TextBuilder;
        N: Integer;
        T: Text;
    begin
        N := 5;
        T := 'x';
        Message('A: \' + 'B:%1\' + 'C:%2', N, T);
        Observer.Observe('message backslash', LastMessage);
        Observer.Observe('message backslash codes', Codes(LastMessage));
        TB.AppendLine('L1');
        TB.AppendLine('L2');
        Observer.Observe('textbuilder codes', Codes(TB.ToText()));
        Message(TB.ToText());
        Observer.Observe('message appendline codes', Codes(LastMessage));
        Message('%1', TB.ToText());
        Observer.Observe('message %1 appendline codes', Codes(LastMessage));
        asserterror Error(TB.ToText());
        Observer.Observe('error appendline codes', Codes(GetLastErrorText()));
        asserterror Error('A: \' + 'B:%1\' + 'C:%2', N, T);
        Observer.ObserveError('error backslash');
        Observer.Expect('message backslash', 'A: \B:5\C:x');
        Observer.Expect('message backslash codes', 'A: \B:5\C:x');
        Observer.Expect('textbuilder codes', 'L1<13><10>L2<13><10>');
        Observer.Expect('message appendline codes', 'L1\L2\');
        Observer.Expect('message %1 appendline codes', 'L1\L2\');
        Observer.Expect('error appendline codes', 'L1\L2\');
        Observer.Expect('error backslash|text', 'A: \B:5\C:x');
        Observer.Expect('error backslash|code', 'Dialog');
        Observer.Verify();
    end;

    local procedure Codes(Value: Text) Result: Text
    var
        I: Integer;
        C: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            C := Value[I];
            if C < 32 then
                Result += '<' + Format(C) + '>'
            else
                Result += CopyStr(Value, I, 1);
        end;
    end;

    [MessageHandler]
    procedure CaptureMessage(Message: Text[1024])
    begin
        LastMessage := Message;
    end;
}
