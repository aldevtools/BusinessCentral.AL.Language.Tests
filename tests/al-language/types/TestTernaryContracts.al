codeunit 60193 "Test Ternary Contracts"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure Ternary_TrueCondition_ReturnsFirstBranch()
    var
        Result: Text;
    begin
        Result := (5 > 3) ? 'big' : 'small';
        Assert.AreEqual('big', Result, 'Ternary with true condition must return first branch');
    end;

    [Test]
    procedure Ternary_FalseCondition_ReturnsSecondBranch()
    var
        Result: Text;
    begin
        Result := (3 > 5) ? 'big' : 'small';
        Assert.AreEqual('small', Result, 'Ternary with false condition must return second branch');
    end;

    [Test]
    procedure Ternary_Integer_TrueCondition()
    var
        Result: Integer;
    begin
        Result := (10 > 5) ? 100 : 200;
        Assert.AreEqual(100, Result, 'Ternary with integer values: true → 100');
    end;

    [Test]
    procedure Ternary_Integer_FalseCondition()
    var
        Result: Integer;
    begin
        Result := (5 > 10) ? 100 : 200;
        Assert.AreEqual(200, Result, 'Ternary with integer values: false → 200');
    end;

    [Test]
    procedure Ternary_InExitExpression()
    var
        Result: Text;
    begin
        Result := ClassifyNumber(7);
        Assert.AreEqual('big', Result, 'exit(n > 3 ? "big" : "small") must return "big" for n=7');
    end;

    [Test]
    procedure Ternary_InExitExpression_Opposite()
    var
        Result: Text;
    begin
        Result := ClassifyNumber(2);
        Assert.AreEqual('small', Result, 'exit(n > 3 ? "big" : "small") must return "small" for n=2');
    end;

    [Test]
    procedure Ternary_BothBranches_Differ()
    begin
        Assert.AreNotEqual(ClassifyNumber(10), ClassifyNumber(0), 'Ternary must produce different values for different branches');
    end;

    [Test]
    procedure Ternary_NestedTernary()
    var
        Result: Text;
    begin
        Result := BucketNumber(5);
        Assert.AreEqual('low', Result, 'Nested ternary: 5 < 10 → "low"');
    end;

    [Test]
    procedure Ternary_NestedTernary_Middle()
    var
        Result: Text;
    begin
        Result := BucketNumber(50);
        Assert.AreEqual('mid', Result, 'Nested ternary: 50 not < 10 but < 100 → "mid"');
    end;

    [Test]
    procedure Ternary_NestedTernary_High()
    var
        Result: Text;
    begin
        Result := BucketNumber(500);
        Assert.AreEqual('high', Result, 'Nested ternary: 500 not < 100 → "high"');
    end;

    [Test]
    procedure Ternary_Max_ReturnsLarger()
    var
        Result: Integer;
    begin
        Result := MaxOfTwo(7, 4);
        Assert.AreEqual(7, Result, 'a >= b ? a : b must return larger value');
    end;

    [Test]
    procedure Ternary_FlipBoolean()
    var
        Result: Boolean;
    begin
        Result := FlipBool(true);
        Assert.IsFalse(Result, 'Ternary flip: true ? false : true must return false');
    end;

    local procedure ClassifyNumber(N: Integer): Text
    begin
        exit(N > 3 ? 'big' : 'small');
    end;

    local procedure BucketNumber(N: Integer): Text
    begin
        exit(N < 10 ? 'low' : N < 100 ? 'mid' : 'high');
    end;

    local procedure MaxOfTwo(A: Integer; B: Integer): Integer
    begin
        exit(A >= B ? A : B);
    end;

    local procedure FlipBool(B: Boolean): Boolean
    begin
        exit(B ? false : true);
    end;

    // corpus issue 664 (writer BN): ternary branches of different types (microsoft/AL issues 7937, 7926, 8151, 8106). The true branch sets
    // the type of the expression. `Cond ? '1' : ''` and `Cond ? CurrentDateTime() : Today()` do not compile:
    // tests/must-not-compile/cases/1405 and 1406. Observed on BC (probe form: Observer.Finish).
    [Test]
    procedure BN_Ternary_CharAndTextLiterals()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('true', CharTextForms(true));
        Observer.Observe('false', CharTextForms(false));
        Observer.Expect('true', '[][1][1][a][1]');
        Observer.Expect('false', '[1][ ][0][][]');
        Observer.Verify();
    end;

    local procedure CharTextForms(Cond: Boolean): Text
    var
        Txt: Text;
        R: Text;
    begin
        Txt := Cond ? '' : '1';
        R := '[' + Txt + ']';
        Txt := Cond ? '1' : ' ';
        R += '[' + Txt + ']';
        Txt := Cond ? '1' : '0';
        R += '[' + Txt + ']';
        Txt := Cond ? ('' + 'a') : '';
        R += '[' + Txt + ']';
        Txt := Cond ? Format('1') : '';
        R += '[' + Txt + ']';
        exit(R);
    end;

    [Test]
    procedure BN_Ternary_VariantBranch()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
    begin
        if TryVariantTrueText(false, V) then
            Observer.Observe('Cond ? Bar : GetVariant(), false', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? Bar : GetVariant(), false');
        if TryVariantTrueText(true, V) then
            Observer.Observe('Cond ? Bar : GetVariant(), true', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? Bar : GetVariant(), true');
        if TryVariantTrueVariant(false, V) then
            Observer.Observe('Cond ? GetVariant() : Bar, false', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? GetVariant() : Bar, false');
        if TryVariantTrueVariant(true, V) then
            Observer.Observe('Cond ? GetVariant() : Bar, true', 'ok|' + Format(V) + '|' + VariantKind(V))
        else
            Observer.ObserveError('Cond ? GetVariant() : Bar, true');
        Observer.Expect('Cond ? Bar : GetVariant(), false|text', 'The expression Microsoft.Dynamics.Nav.Runtime.NavIndirectValue cannot be type-converted to a Microsoft.Dynamics.Nav.Runtime.NavText value.');
        Observer.Expect('Cond ? Bar : GetVariant(), false|code', 'TypeConversion');
        Observer.Expect('Cond ? Bar : GetVariant(), true', 'ok|Bar|Text');
        Observer.Expect('Cond ? GetVariant() : Bar, false', 'ok|Bar|Text');
        Observer.Expect('Cond ? GetVariant() : Bar, true', 'ok|5|Integer');
        Observer.Verify();
    end;

    local procedure GetVariant(): Variant
    var
        V: Variant;
        I: Integer;
    begin
        I := 5;
        V := I;
        exit(V);
    end;

    local procedure VariantKind(V: Variant): Text
    begin
        if V.IsInteger() then
            exit('Integer');
        if V.IsText() then
            exit('Text');
        if V.IsCode() then
            exit('Code');
        exit('other');
    end;

    [TryFunction]
    local procedure TryVariantTrueText(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? 'Bar' : GetVariant();
    end;

    [TryFunction]
    local procedure TryVariantTrueVariant(Cond: Boolean; var V: Variant)
    begin
        V := Cond ? GetVariant() : 'Bar';
    end;

    [Test]
    procedure BN_Ternary_IntegerAndDecimalBranches()
    var
        Observer: Codeunit "Probe Observer";
        Quantity: Decimal;
    begin
        if TryIntTrue(false, 0.25, Quantity) then
            Observer.Observe('Boo ? 1 : 0.25, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 0.25, false');
        if TryIntTrue(false, 3, Quantity) then
            Observer.Observe('Boo ? 1 : 3.0, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 3.0, false');
        if TryIntTrue(false, 2.5, Quantity) then
            Observer.Observe('Boo ? 1 : 2.5, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 2.5, false');
        if TryIntTrue(true, 0.25, Quantity) then
            Observer.Observe('Boo ? 1 : 0.25, true', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 1 : 0.25, true');
        if TryDecTrue(false, 0.25, Quantity) then
            Observer.Observe('Boo ? 0.25 : 1, false', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 0.25 : 1, false');
        if TryDecTrue(true, 0.25, Quantity) then
            Observer.Observe('Boo ? 0.25 : 1, true', 'ok|' + Format(Quantity))
        else
            Observer.ObserveError('Boo ? 0.25 : 1, true');
        Observer.Expect('Boo ? 1 : 0.25, false|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.25 to System.Int32.');
        Observer.Expect('Boo ? 1 : 0.25, false|code', 'ConversionCast');
        Observer.Expect('Boo ? 1 : 3.0, false', 'ok|3');
        Observer.Expect('Boo ? 1 : 2.5, false|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('Boo ? 1 : 2.5, false|code', 'ConversionCast');
        Observer.Expect('Boo ? 1 : 0.25, true', 'ok|1');
        Observer.Expect('Boo ? 0.25 : 1, false', 'ok|1');
        Observer.Expect('Boo ? 0.25 : 1, true', 'ok|0.25');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryIntTrue(Boo: Boolean; OrigQty: Decimal; var Quantity: Decimal)
    begin
        Quantity := Boo ? 1 : OrigQty;
    end;

    [TryFunction]
    local procedure TryDecTrue(Boo: Boolean; OrigQty: Decimal; var Quantity: Decimal)
    begin
        Quantity := Boo ? OrigQty : 1;
    end;

    [Test]
    procedure BN_Ternary_Code20TrueBranch()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        if TryCodeTrue(false, Result) then
            Observer.Observe('Cond ? Code20 : 30-char text, false', 'ok|' + Result + '|' + Format(StrLen(Result)))
        else
            Observer.ObserveError('Cond ? Code20 : 30-char text, false');
        if TryCodeTrue(true, Result) then
            Observer.Observe('Cond ? Code20 : 30-char text, true', 'ok|' + Result)
        else
            Observer.ObserveError('Cond ? Code20 : 30-char text, true');
        if TryTextTrue(false, Result) then
            Observer.Observe('Cond ? 30-char text : Code20, false', 'ok|' + Result)
        else
            Observer.ObserveError('Cond ? 30-char text : Code20, false');
        if TryTextTrue(true, Result) then
            Observer.Observe('Cond ? 30-char text : Code20, true', 'ok|' + Result + '|' + Format(StrLen(Result)))
        else
            Observer.ObserveError('Cond ? 30-char text : Code20, true');
        Observer.Expect('Cond ? Code20 : 30-char text, false|text', 'The length of the string is 30, but it must be less than or equal to 20 characters. Value: abcdefghijklmnopqrstuvwxyz1234');
        Observer.Expect('Cond ? Code20 : 30-char text, false|code', 'StringLengthExceeded');
        Observer.Expect('Cond ? Code20 : 30-char text, true', 'ok|SHORTCODE');
        Observer.Expect('Cond ? 30-char text : Code20, false', 'ok|SHORTCODE');
        Observer.Expect('Cond ? 30-char text : Code20, true', 'ok|abcdefghijklmnopqrstuvwxyz1234|30');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCodeTrue(Cond: Boolean; var Result: Text)
    var
        C20: Code[20];
        LongText: Text;
    begin
        C20 := 'shortcode';
        LongText := 'abcdefghijklmnopqrstuvwxyz1234';
        Result := Cond ? C20 : LongText;
    end;

    [TryFunction]
    local procedure TryTextTrue(Cond: Boolean; var Result: Text)
    var
        C20: Code[20];
        LongText: Text;
    begin
        C20 := 'shortcode';
        LongText := 'abcdefghijklmnopqrstuvwxyz1234';
        Result := Cond ? LongText : C20;
    end;
    // Writer PY-C (al-runtime-rs PR 339, probes-needed "Ternary and call-argument conversion"): Integer true with BigInteger false beyond Int32,
    // Text[10] true with a 12-character Text false, Option and Enum true with Integer false. Each read into a BigInteger, Text or Integer.
    [Test]
    procedure PYC_Ternary_MoreBranchPairs()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        R: Text;
        I: Integer;
    begin
        ClearLastError();
        if TryIntBig(false, 3000000000L, Big) then
            Observer.Observe('Cond ? 1 : Big 3e9, false', 'ok|' + Format(Big))
        else
            Observer.ObserveError('Cond ? 1 : Big 3e9, false');
        if TryIntBig(false, 5L, Big) then
            Observer.Observe('Cond ? 1 : Big 5, false', 'ok|' + Format(Big))
        else
            Observer.ObserveError('Cond ? 1 : Big 5, false');
        if TryBigInt(false, 3000000000L, Big) then
            Observer.Observe('Cond ? Big 3e9 : 1, true', 'ok|' + Format(Big))
        else
            Observer.ObserveError('Cond ? Big 3e9 : 1, true');
        if TryText10(false, R) then
            Observer.Observe('Cond ? Text10 : 12-char text, false', 'ok|' + R + '|' + Format(StrLen(R)))
        else
            Observer.ObserveError('Cond ? Text10 : 12-char text, false');
        if TryText10(true, R) then
            Observer.Observe('Cond ? Text10 : 12-char text, true', 'ok|' + R)
        else
            Observer.ObserveError('Cond ? Text10 : 12-char text, true');
        if TryOptionInt(false, I) then
            Observer.Observe('Cond ? Option : Integer 7, false', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Option : Integer 7, false');
        if TryOptionInt(true, I) then
            Observer.Observe('Cond ? Option : Integer 7, true', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Option : Integer 7, true');
        if TryEnumInt(false, I) then
            Observer.Observe('Cond ? Enum : Integer 7, false', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Enum : Integer 7, false');
        if TryEnumInt(true, I) then
            Observer.Observe('Cond ? Enum : Integer 7, true', 'ok|' + Format(I))
        else
            Observer.ObserveError('Cond ? Enum : Integer 7, true');
        Observer.Expect('Cond ? 1 : Big 3e9, false|text', 'Overflow under conversion of System.Int64 value 3000000000 to System.Int32.');
        Observer.Expect('Cond ? 1 : Big 3e9, false|code', 'ConversionCast');
        Observer.Expect('Cond ? 1 : Big 5, false', 'ok|5');
        Observer.Expect('Cond ? Big 3e9 : 1, true', 'ok|3000000000');
        Observer.Expect('Cond ? Text10 : 12-char text, false|text', 'The length of the string is 12, but it must be less than or equal to 10 characters. Value: abcdefghijkl');
        Observer.Expect('Cond ? Text10 : 12-char text, false|code', 'StringLengthExceeded');
        Observer.Expect('Cond ? Text10 : 12-char text, true', 'ok|short');
        Observer.Expect('Cond ? Option : Integer 7, false', 'ok|7');
        Observer.Expect('Cond ? Option : Integer 7, true', 'ok|2');
        Observer.Expect('Cond ? Enum : Integer 7, false', 'ok|7');
        Observer.Expect('Cond ? Enum : Integer 7, true', 'ok|2');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryIntBig(Cond: Boolean; B: BigInteger; var Result: BigInteger)
    begin
        Result := Cond ? 1 : B;
    end;

    [TryFunction]
    local procedure TryBigInt(Cond: Boolean; B: BigInteger; var Result: BigInteger)
    begin
        Result := not Cond ? B : 1;
    end;

    [TryFunction]
    local procedure TryText10(Cond: Boolean; var Result: Text)
    var
        T10: Text[10];
        T: Text;
    begin
        T10 := 'short';
        T := 'abcdefghijkl';
        Result := Cond ? T10 : T;
    end;

    [TryFunction]
    local procedure TryOptionInt(Cond: Boolean; var Result: Integer)
    var
        Opt: Option Zero,One,Two;
    begin
        Opt := Opt::Two;
        Result := Cond ? Opt : 7;
    end;

    [TryFunction]
    local procedure TryEnumInt(Cond: Boolean; var Result: Integer)
    var
        E: Enum "Sales Document Type";
    begin
        E := E::Invoice;
        Result := Cond ? E : 7;
    end;

    // Writer QW (corpus issue 685 section 2): a Label, a Label with Locked or MaxLength, and a TextConst as a branch (into a Text: see TextConstForms); Format and StrLen of the
    // result; a Variant holding the result. The branches that cannot convert are tests/must-not-compile/cases/2061-2069.
    [Test]
    procedure QW_Ternary_LabelBranches()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('true', LabelForms(true));
        Observer.Observe('false', LabelForms(false));
        Observer.Expect('true', '[Label A|7][|0][Label A|7][Locked text][With x][Label A|7]');
        Observer.Expect('false', '[|0][Label A|7][Label B, longer|15][Label A][Label A][Label B, longer|15]');
        Observer.Verify();
    end;

    local procedure LabelForms(Cond: Boolean): Text
    var
        LblA: Label 'Label A';
        LblB: Label 'Label B, longer';
        LblLocked: Label 'Locked text', Locked = true;
        LblCmt: Label 'With %1', Comment = '%1 = a value';
        R: Text;
        Txt: Text;
    begin
        Txt := Cond ? LblA : '';
        R := '[' + Txt + '|' + Format(StrLen(Txt)) + ']';
        Txt := Cond ? '' : LblA;
        R += '[' + Txt + '|' + Format(StrLen(Txt)) + ']';
        Txt := Cond ? LblA : LblB;
        R += '[' + Txt + '|' + Format(StrLen(Txt)) + ']';
        Txt := Cond ? LblLocked : LblA;
        R += '[' + Txt + ']';
        Txt := StrSubstNo(Cond ? LblCmt : LblA, 'x');
        R += '[' + Txt + ']';
        R += '[' + Format(Cond ? LblA : LblB) + '|' + Format(StrLen(Cond ? LblA : LblB)) + ']';
        exit(R);
    end;

    [Test]
    procedure QW_Ternary_LabelMaxLengthAndTextConst()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Short: Text[3];
        T: Boolean;
    begin
        for T := true downto false do begin
            if TryMaxLenIntoText(T, R) then
                Observer.Observe(Format(T) + ' MaxLength 5 : 11-char text into Text', 'ok|' + R + '|' + Format(StrLen(R)))
            else
                Observer.ObserveError(Format(T) + ' MaxLength 5 : 11-char text into Text');
            if TryMaxLenIntoText3(T, Short) then
                Observer.Observe(Format(T) + ' MaxLength 5 : ab into Text[3]', 'ok|' + Short)
            else
                Observer.ObserveError(Format(T) + ' MaxLength 5 : ab into Text[3]');
#if LTQW_TEXTCONST_PROBE
            Observer.Observe(Format(T) + ' TextConst', TextConstForms(T));
#endif
        end;
        Observer.Expect('Yes MaxLength 5 : 11-char text into Text', 'ok|Hello|5');
        Observer.Expect('Yes MaxLength 5 : ab into Text[3]|text', 'The length of the string is 5, but it must be less than or equal to 3 characters. Value: Hello');
        Observer.Expect('Yes MaxLength 5 : ab into Text[3]|code', 'StringLengthExceeded');
        Observer.Expect('No MaxLength 5 : 11-char text into Text', 'ok|longer text|11');
        Observer.Expect('No MaxLength 5 : ab into Text[3]', 'ok|ab');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryMaxLenIntoText(Cond: Boolean; var R: Text)
    var
        LblMax: Label 'Hello', MaxLength = 5;
    begin
        R := Cond ? LblMax : 'longer text';
    end;

    [TryFunction]
    local procedure TryMaxLenIntoText3(Cond: Boolean; var R: Text[3])
    var
        LblMax: Label 'Hello', MaxLength = 5;
    begin
        R := Cond ? LblMax : 'ab';
    end;

    // A TextConst branch read into a Text compiles, but BC 29.0 refuses to publish the app: "Failure while emitting method. Object:'Codeunit
    // "Test Ternary Contracts"' Method:'TextConstForms(Boolean)' (Unexpected value 'TextConst' of type
    // 'Microsoft.Dynamics.Nav.CodeAnalysis.NavTypeKind')" (corpus CI run 39741827358). So it is compiled only with LTQW_TEXTCONST_PROBE.
#if LTQW_TEXTCONST_PROBE
    local procedure TextConstForms(Cond: Boolean): Text
    var
        Tc: TextConst ENU = 'Text const';
        LblA: Label 'Label A';
        Txt: Text;
        R: Text;
    begin
        Txt := Cond ? Tc : '';
        R := '[' + Txt + '|' + Format(StrLen(Txt)) + ']';
        Txt := Cond ? Tc : LblA;
        R += '[' + Txt + ']';
        Txt := Cond ? LblA : Tc;
        R += '[' + Txt + ']';
        exit(R);
    end;
#endif

    [Test]
    procedure QW_Ternary_LabelIntoVariant()
    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        Tc: TextConst ENU = 'Text const';
        V: Variant;
        T: Boolean;
    begin
        for T := true downto false do begin
            V := T ? LblA : LblB;
            Observer.Observe(Format(T) + ' label:label', VariantInfo(V));
            V := T ? LblA : '';
            Observer.Observe(Format(T) + ' label:empty', VariantInfo(V));
#if LTQW_TEXTCONST_PROBE // the same publish failure as TextConstForms, for method QW_Ternary_LabelIntoVariant (corpus CI run 39745274809)
            V := T ? Tc : LblA;
            Observer.Observe(Format(T) + ' textconst:label', VariantInfo(V));
#endif
        end;
        V := LblA;
        Observer.Observe('plain label', VariantInfo(V));
        V := Tc;
        Observer.Observe('plain textconst', VariantInfo(V));
        Observer.Expect('Yes label:label', 'Label A|IsText=No|IsTextConstant=Yes|IsCode=No|IsChar=No');
        Observer.Expect('Yes label:empty', 'Label A|IsText=Yes|IsTextConstant=No|IsCode=No|IsChar=No');
        Observer.Expect('No label:label', 'Label B|IsText=No|IsTextConstant=Yes|IsCode=No|IsChar=No');
        Observer.Expect('No label:empty', '|IsText=Yes|IsTextConstant=No|IsCode=No|IsChar=No');
        Observer.Expect('plain label', 'Label A|IsText=No|IsTextConstant=Yes|IsCode=No|IsChar=No');
        Observer.Expect('plain textconst', 'Text const|IsText=No|IsTextConstant=Yes|IsCode=No|IsChar=No');
        Observer.Verify();
    end;

    local procedure VariantInfo(V: Variant): Text
    begin
        exit(Format(V) + '|IsText=' + Format(V.IsText()) + '|IsTextConstant=' + Format(V.IsTextConstant()) + '|IsCode=' + Format(V.IsCode()) + '|IsChar=' + Format(V.IsChar()));
    end;

    // Writer QW (corpus issue 685 section 3): Boolean, Guid, Time and DateTime pairs.
    [Test]
    procedure QW_Ternary_BooleanGuidTimePairs()
    var
        Observer: Codeunit "Probe Observer";
        G: Guid;
        Txt: Text;
        T: Boolean;
    begin
        for T := true downto false do begin
            Observer.Observe(Format(T) + ' scalars', ScalarPairs(T));
            if TryGuidOrText(T, '{00000000-0000-0000-0000-00000000000B}', G) then
                Observer.Observe(Format(T) + ' Guid : guid text into Guid', 'ok|' + Format(G))
            else
                Observer.ObserveError(Format(T) + ' Guid : guid text into Guid');
            if TryGuidOrText(T, 'abc', G) then
                Observer.Observe(Format(T) + ' Guid : abc into Guid', 'ok|' + Format(G))
            else
                Observer.ObserveError(Format(T) + ' Guid : abc into Guid');
            if TryGuidOrTextIntoText(T, Txt) then
                Observer.Observe(Format(T) + ' Guid : abc into Text', 'ok|' + Txt)
            else
                Observer.ObserveError(Format(T) + ' Guid : abc into Text');
        end;
        Observer.Expect('Yes scalars', '[Yes][No][{00000000-0000-0000-0000-00000000000A}][10:30:00|No][2024-02-01T12:00:00Z|No]');
        Observer.Expect('Yes Guid : guid text into Guid', 'ok|{00000000-0000-0000-0000-00000000000A}');
        Observer.Expect('Yes Guid : abc into Guid', 'ok|{00000000-0000-0000-0000-00000000000A}');
        Observer.Expect('Yes Guid : abc into Text', 'ok|{00000000-0000-0000-0000-00000000000A}');
        Observer.Expect('No scalars', '[No][Yes][{00000000-0000-0000-0000-000000000000}][|Yes][|Yes]');
        Observer.Expect('No Guid : guid text into Guid', 'ok|{00000000-0000-0000-0000-00000000000B}');
        Observer.Expect('No Guid : abc into Guid|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('No Guid : abc into Guid|code', 'InvalidGuidFormat');
        Observer.Expect('No Guid : abc into Text|text', 'Invalid format of GUID string. The correct format of the GUID string is: CDEF7890-ABCD-0123-1234-567890ABCDEF where 0-9, A-F symbolizes hexadecimal digits.');
        Observer.Expect('No Guid : abc into Text|code', 'InvalidGuidFormat');
        Observer.Verify();
    end;

    local procedure ScalarPairs(Cond: Boolean): Text
    var
        B1: Boolean;
        G1: Guid;
        G2: Guid;
        T1: Time;
        T2: Time;
        DT1: DateTime;
        DT2: DateTime;
        R: Text;
    begin
        B1 := true;
        R := '[' + Format(Cond ? B1 : false) + ']';
        R += '[' + Format(Cond ? false : B1) + ']';
        Evaluate(G1, '{00000000-0000-0000-0000-00000000000A}');
        R += '[' + Format(Cond ? G1 : G2) + ']';
        T1 := 103000T;
        T2 := 0T;
        R += '[' + Format(Cond ? T1 : T2, 0, 9) + '|' + Format((Cond ? T1 : T2) = 0T) + ']';
        DT1 := CreateDateTime(DMY2Date(1, 2, 2024), 120000T);
        R += '[' + Format(Cond ? DT1 : DT2, 0, 9) + '|' + Format((Cond ? DT1 : DT2) = 0DT) + ']';
        exit(R);
    end;

    [TryFunction]
    local procedure TryGuidOrText(Cond: Boolean; Txt: Text; var R: Guid)
    var
        G1: Guid;
    begin
        Evaluate(G1, '{00000000-0000-0000-0000-00000000000A}');
        R := Cond ? G1 : Txt;
    end;

    [TryFunction]
    local procedure TryGuidOrTextIntoText(Cond: Boolean; var R: Text)
    var
        G1: Guid;
    begin
        Evaluate(G1, '{00000000-0000-0000-0000-00000000000A}');
        R := Cond ? G1 : 'abc';
    end;

    // Writer QW (corpus issue 685 section 3): Duration with Integer, Byte with Integer and Char.
    [Test]
    procedure QW_Ternary_DurationBytePairs()
    var
        Observer: Codeunit "Probe Observer";
        Dur: Duration;
        I: Integer;
        C: Char;
        B: Byte;
        T: Boolean;
    begin
        for T := true downto false do begin
            if TryDurInt(T, Dur) then
                Observer.Observe(Format(T) + ' Dur : 5 into Duration', 'ok|' + Format(Dur) + '|' + Format(Dur, 0, 9))
            else
                Observer.ObserveError(Format(T) + ' Dur : 5 into Duration');
            if TryIntDur(T, Dur) then
                Observer.Observe(Format(T) + ' 5 : Dur into Duration', 'ok|' + Format(Dur) + '|' + Format(Dur, 0, 9))
            else
                Observer.ObserveError(Format(T) + ' 5 : Dur into Duration');
            if TryIntDurIntoInt(T, I) then
                Observer.Observe(Format(T) + ' 5 : Dur into Integer', 'ok|' + Format(I))
            else
                Observer.ObserveError(Format(T) + ' 5 : Dur into Integer');
            if TryByteInt(T, I) then
                Observer.Observe(Format(T) + ' Byte 250 : 200 into Integer', 'ok|' + Format(I))
            else
                Observer.ObserveError(Format(T) + ' Byte 250 : 200 into Integer');
            if TryIntByte(T, I) then
                Observer.Observe(Format(T) + ' 300 : Byte 250 into Integer', 'ok|' + Format(I))
            else
                Observer.ObserveError(Format(T) + ' 300 : Byte 250 into Integer');
            if TryByteChar(T, C) then begin
                I := C;
                Observer.Observe(Format(T) + ' Byte 66 : Char 256 into Char', 'ok|' + Format(C) + '|' + Format(I))
            end
            else
                Observer.ObserveError(Format(T) + ' Byte 66 : Char 256 into Char');
            if TryCharByte(T, B) then begin
                I := B;
                Observer.Observe(Format(T) + ' Char 256 : Byte 66 into Byte', 'ok|' + Format(B) + '|' + Format(I))
            end
            else
                Observer.ObserveError(Format(T) + ' Char 256 : Byte 66 into Byte');
        end;
        Observer.Expect('Yes Dur : 5 into Duration', 'ok|1 hour|P0DT1H0M0.0S');
        Observer.Expect('Yes 5 : Dur into Duration', 'ok|5 milliseconds|P0DT0H0M0.005S');
        Observer.Expect('Yes 5 : Dur into Integer', 'ok|5');
        Observer.Expect('Yes Byte 250 : 200 into Integer', 'ok|250');
        Observer.Expect('Yes 300 : Byte 250 into Integer', 'ok|300');
        Observer.Expect('Yes Byte 66 : Char 256 into Char', 'ok|B|66');
        Observer.Expect('Yes Char 256 : Byte 66 into Byte', 'ok|A|65');
        Observer.Expect('No Dur : 5 into Duration', 'ok|5 milliseconds|P0DT0H0M0.005S');
        Observer.Expect('No 5 : Dur into Duration', 'ok|1 hour|P0DT1H0M0.0S');
        Observer.Expect('No 5 : Dur into Integer', 'ok|3600000');
        Observer.Expect('No Byte 250 : 200 into Integer', 'ok|200');
        Observer.Expect('No 300 : Byte 250 into Integer', 'ok|250');
        Observer.Expect('No Byte 66 : Char 256 into Char', 'ok|A|65');
        Observer.Expect('No Char 256 : Byte 66 into Byte', 'ok|B|66');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDurInt(Cond: Boolean; var R: Duration)
    var
        D1: Duration;
    begin
        D1 := 3600000;
        R := Cond ? D1 : 5;
    end;

    [TryFunction]
    local procedure TryIntDur(Cond: Boolean; var R: Duration)
    var
        D1: Duration;
    begin
        D1 := 3600000;
        R := Cond ? 5 : D1;
    end;

    [TryFunction]
    local procedure TryIntDurIntoInt(Cond: Boolean; var R: Integer)
    var
        D1: Duration;
    begin
        D1 := 3600000;
        R := Cond ? 5 : D1;
    end;

    [TryFunction]
    local procedure TryByteInt(Cond: Boolean; var R: Integer)
    var
        B1: Byte;
    begin
        B1 := 250;
        R := Cond ? B1 : 200;
    end;

    [TryFunction]
    local procedure TryIntByte(Cond: Boolean; var R: Integer)
    var
        B1: Byte;
    begin
        B1 := 250;
        R := Cond ? 300 : B1;
    end;

    [TryFunction]
    local procedure TryByteChar(Cond: Boolean; var R: Char)
    var
        B1: Byte;
        C1: Char;
    begin
        B1 := 66;
        C1 := 256;
        R := Cond ? B1 : C1;
    end;

    [TryFunction]
    local procedure TryCharByte(Cond: Boolean; var R: Byte)
    var
        B1: Byte;
        C1: Char;
    begin
        B1 := 66;
        C1 := 256;
        R := Cond ? C1 : B1;
    end;

    // Writer QW (corpus issue 685 section 3): an Enum with another Enum type, an Enum with an Option, two Option types.
    [Test]
    procedure QW_Ternary_EnumOptionPairs()
    var
        Observer: Codeunit "Probe Observer";
        T: Boolean;
    begin
        for T := true downto false do
            Observer.Observe(Format(T), EnumForms(T));
        Observer.Expect('Yes', '[Invoice|2][2][Invoice|2][Gamma|2][2][2][Invoice|Gamma]');
        Observer.Expect('No', '[6|6][6][Invoice|2][Gamma|2][2][1][6|Beta]');
        Observer.Verify();
    end;

    local procedure EnumForms(Cond: Boolean): Text
    var
        E1: Enum "Sales Document Type";
        E2: Enum "Gen. Journal Document Type";
        RE: Enum "Sales Document Type";
        O1: Option Alpha,Beta,Gamma;
        O2: Option X,Y;
        RO: Option Alpha,Beta,Gamma;
        I: Integer;
        R: Text;
    begin
        E1 := E1::Invoice;
        E2 := E2::Refund;
        O1 := O1::Gamma;
        O2 := O2::Y;
        RE := Cond ? E1 : E2;
        R := '[' + Format(RE) + '|' + Format(RE.AsInteger()) + ']';
        I := Cond ? E1 : E2;
        R += '[' + Format(I) + ']';
        RE := Cond ? E1 : O1;
        R += '[' + Format(RE) + '|' + Format(RE.AsInteger()) + ']';
        RO := Cond ? O1 : E1;
        R += '[' + Format(RO) + '|' + Format(RO, 0, 9) + ']';
        I := Cond ? E1 : O1;
        R += '[' + Format(I) + ']';
        I := Cond ? O1 : O2;
        R += '[' + Format(I) + ']';
        R += '[' + Format(Cond ? E1 : E2) + '|' + Format(Cond ? O1 : O2) + ']';
        exit(R);
    end;

    // Writer QW (corpus issue 685 section 3): SecretText with SecretText (SecretText with Text does not compile: case 2064).
    [Test]
    procedure QW_Ternary_SecretTextPair()
    var
        Observer: Codeunit "Probe Observer";
        S1: SecretText;
        S2: SecretText;
        R: SecretText;
    begin
        IsolatedStorage.Set('LT QW Tern Secret', 'xy', DataScope::Module);
        IsolatedStorage.Get('LT QW Tern Secret', DataScope::Module, S2);
        IsolatedStorage.Delete('LT QW Tern Secret', DataScope::Module);
        Observer.Observe('S2 IsEmpty', Format(S2.IsEmpty()));
        R := true ? S1 : S2;
        Observer.Observe('true IsEmpty', Format(R.IsEmpty()));
        R := false ? S1 : S2;
        Observer.Observe('false IsEmpty', Format(R.IsEmpty()));
        Observer.Expect('S2 IsEmpty', 'No');
        Observer.Expect('true IsEmpty', 'Yes');
        Observer.Expect('false IsEmpty', 'No');
        Observer.Verify();
    end;

    // Writer QW (corpus issue 685 section 3): Record, RecordRef, interface, codeunit, JsonObject, JsonToken, List and Dictionary values as
    // branches. After the assignment the target is changed, to see whether it shares the branch value or holds a copy.
    [Test]
    procedure QW_Ternary_ReferenceTypeBranches()
    var
        Observer: Codeunit "Probe Observer";
        T: Boolean;
    begin
        for T := true downto false do begin
            Observer.Observe(Format(T) + ' record', RecordForms(T));
            Observer.Observe(Format(T) + ' objects', ObjectForms(T));
            Observer.Observe(Format(T) + ' collections', CollectionForms(T));
        end;
        Observer.Expect('Yes record', '[1|1|2][2000000026|77]');
        Observer.Expect('Yes objects', '[10][2|0|2]');
        Observer.Expect('Yes collections', '[{"a":1,"c":3}|{"b":2}][Yes|No][2|1][2|1]');
        Observer.Expect('No record', '[2|1|2][2000000007|0]');
        Observer.Expect('No objects', '[25][0|1|1]');
        Observer.Expect('No collections', '[{"a":1}|{"b":2,"c":3}][No|Yes][1|2][1|2]');
        Observer.Verify();
    end;

    local procedure RecordForms(Cond: Boolean): Text
    var
        R1: Record Integer;
        R2: Record Integer;
        R: Record Integer;
        RR1: RecordRef;
        RR2: RecordRef;
        RR: RecordRef;
        Txt: Text;
    begin
        R1.Number := 1;
        R2.Number := 2;
        R := Cond ? R1 : R2;
        Txt := '[' + Format(R.Number);
        R.Number := 9;
        Txt += '|' + Format(R1.Number) + '|' + Format(R2.Number) + ']';
        RR1.Open(Database::Integer);
        RR2.Open(Database::Date);
        RR := Cond ? RR1 : RR2;
        Txt += '[' + Format(RR.Number);
        RR.Field(1).Value := 77;
        Txt += '|' + Format(RR1.Field(1).Value) + ']';
        exit(Txt);
    end;

    local procedure ObjectForms(Cond: Boolean): Text
    var
        D1: Codeunit "LT QW Tern Double";
        D2: Codeunit "LT QW Tern Double";
        DR: Codeunit "LT QW Tern Double";
        Sq: Codeunit "LT QW Tern Square";
        I1: Interface "LT QW Tern Compute";
        I2: Interface "LT QW Tern Compute";
        IR: Interface "LT QW Tern Compute";
        Txt: Text;
    begin
        I1 := D1;
        I2 := Sq;
        IR := Cond ? I1 : I2;
        Txt := '[' + Format(IR.Compute(5)) + ']';
        DR := Cond ? D1 : D2;
        DR.Compute(1);
        Txt += '[' + Format(D1.CallCount()) + '|' + Format(D2.CallCount()) + '|' + Format(DR.CallCount()) + ']';
        exit(Txt);
    end;

    local procedure CollectionForms(Cond: Boolean): Text
    var
        J1: JsonObject;
        J2: JsonObject;
        JR: JsonObject;
        A2: JsonArray;
        Tok: JsonToken;
        L1: List of [Integer];
        L2: List of [Integer];
        LR: List of [Integer];
        D1: Dictionary of [Integer, Text];
        D2: Dictionary of [Integer, Text];
        DR: Dictionary of [Integer, Text];
        Txt: Text;
        J: Text;
    begin
        J1.Add('a', 1);
        J2.Add('b', 2);
        JR := Cond ? J1 : J2;
        JR.Add('c', 3);
        J1.WriteTo(J);
        Txt := '[' + J;
        J2.WriteTo(J);
        Txt += '|' + J + ']';
        Tok := Cond ? J1.AsToken() : A2.AsToken();
        Txt += '[' + Format(Tok.IsObject()) + '|' + Format(Tok.IsArray()) + ']';
        L1.Add(1);
        L2.Add(2);
        LR := Cond ? L1 : L2;
        LR.Add(9);
        Txt += '[' + Format(L1.Count()) + '|' + Format(L2.Count()) + ']';
        D1.Add(1, 'one');
        D2.Add(2, 'two');
        DR := Cond ? D1 : D2;
        DR.Add(9, 'nine');
        Txt += '[' + Format(D1.Count()) + '|' + Format(D2.Count()) + ']';
        exit(Txt);
    end;

    // Writer QW (corpus issue 685 section 4): a ternary as a by-value argument (a var argument does not compile: case 2066), inside Format with
    // format 9 and StrSubstNo, a field assignment followed by Validate and Validate(Field, ternary), an if condition, a case selector, a
    // compound assignment, a Decimal true branch read into an Integer and a Text true branch read into a Code[10].
    [Test]
    procedure QW_Ternary_Contexts()
    var
        Observer: Codeunit "Probe Observer";
        T: Boolean;
    begin
        for T := true downto false do
            Observer.Observe(Format(T), ContextForms(T));
        Observer.Expect('Yes', '[6][1.5|1.5/x][cc|V(aa;old=aa)V(cc;old=aa)N(1.5)][if-then][case 2][33]');
        Observer.Expect('No', '[8][2|2/y][dd|V(bb;old=bb)V(dd;old=bb)N(2)][if-else][case 7][48]');
        Observer.Verify();
    end;

    local procedure ContextForms(Cond: Boolean): Text
    var
        Rec: Record "LT QW Tern Val" temporary;
        A: Decimal;
        B: Integer;
        I: Integer;
        R: Text;
    begin
        A := 1.5;
        B := 2;
        R := '[' + Format(Twice(Cond ? 3 : 4)) + ']';
        R += '[' + Format(Cond ? A : B, 0, 9) + '|' + StrSubstNo('%1/%2', Cond ? A : B, Cond ? 'x' : 'y') + ']';
        Rec.Id := 1;
        Rec.Val := Cond ? 'aa' : 'bb';
        Rec.Validate(Val);
        Rec.Validate(Val, Cond ? 'cc' : 'dd');
        Rec.Validate(Num, Cond ? A : B);
        R += '[' + Rec.Val + '|' + Rec.Trail + ']';
        if Cond ? (A > 1) : (B > 5) then
            R += '[if-then]'
        else
            R += '[if-else]';
        case Cond ? B : 7 of
            2:
                R += '[case 2]';
            7:
                R += '[case 7]';
            else
                R += '[case else]';
        end;
        I := 10;
        I += Cond ? 1 : 2;
        I *= Cond ? 3 : 4;
        R += '[' + Format(I) + ']';
        exit(R);
    end;

    local procedure Twice(X: Integer): Integer
    begin
        exit(2 * X);
    end;

    [Test]
    procedure QW_Ternary_TargetConversions()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        C10: Code[10];
        R1: Text;
        T: Boolean;
    begin
        for T := true downto false do begin
            if TryDecIntoInt(T, 2.5, I) then
                Observer.Observe(Format(T) + ' Dec 2.5 : 1 into Integer', 'ok|' + Format(I))
            else
                Observer.ObserveError(Format(T) + ' Dec 2.5 : 1 into Integer');
            if TryDecIntoInt(T, 4, I) then
                Observer.Observe(Format(T) + ' Dec 4 : 1 into Integer', 'ok|' + Format(I))
            else
                Observer.ObserveError(Format(T) + ' Dec 4 : 1 into Integer');
            if TryTextIntoCode(T, 'abc', C10) then
                Observer.Observe(Format(T) + ' abc : x into Code10', 'ok|' + C10)
            else
                Observer.ObserveError(Format(T) + ' abc : x into Code10');
            if TryTextIntoCode(T, 'abcdefghijkl', C10) then
                Observer.Observe(Format(T) + ' 12 chars : x into Code10', 'ok|' + C10)
            else
                Observer.ObserveError(Format(T) + ' 12 chars : x into Code10');
            if TryIntFormat(T, R1) then
                Observer.Observe(Format(T) + ' Format(1 : 2.5, 0, 9)', 'ok|' + R1)
            else
                Observer.ObserveError(Format(T) + ' Format(1 : 2.5, 0, 9)');
        end;
        Observer.Expect('Yes Dec 2.5 : 1 into Integer|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('Yes Dec 2.5 : 1 into Integer|code', 'ConversionCast');
        Observer.Expect('Yes Dec 4 : 1 into Integer', 'ok|4');
        Observer.Expect('Yes abc : x into Code10', 'ok|ABC');
        Observer.Expect('Yes 12 chars : x into Code10|text', 'The length of the string is 12, but it must be less than or equal to 10 characters. Value: abcdefghijkl');
        Observer.Expect('Yes 12 chars : x into Code10|code', 'StringLengthExceeded');
        Observer.Expect('Yes Format(1 : 2.5, 0, 9)', 'ok|1');
        Observer.Expect('No Dec 2.5 : 1 into Integer', 'ok|1');
        Observer.Expect('No Dec 4 : 1 into Integer', 'ok|1');
        Observer.Expect('No abc : x into Code10', 'ok|X');
        Observer.Expect('No 12 chars : x into Code10', 'ok|X');
        Observer.Expect('No Format(1 : 2.5, 0, 9)|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2.5 to System.Int32.');
        Observer.Expect('No Format(1 : 2.5, 0, 9)|code', 'ConversionCast');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDecIntoInt(Cond: Boolean; D: Decimal; var R: Integer)
    begin
        R := Cond ? D : 1;
    end;

    [TryFunction]
    local procedure TryTextIntoCode(Cond: Boolean; T: Text; var R: Code[10])
    begin
        R := Cond ? T : 'x';
    end;

    [TryFunction]
    local procedure TryIntFormat(Cond: Boolean; var R: Text)
    var
        D: Decimal;
    begin
        D := 2.5;
        R := Format(Cond ? 1 : D, 0, 9);
    end;

    // Writer QW (corpus issue 685 section 4): side effects. Each branch calls a procedure that appends to a log; the log shows which branches ran.
    [Test]
    procedure QW_Ternary_OnlyChosenBranchEvaluates()
    var
        Observer: Codeunit "Probe Observer";
        Trail: Text;
        R: Integer;
        T: Boolean;
    begin
        for T := true downto false do begin
            Trail := '';
            R := Mark(Trail, 'cond', T) ? Mark(Trail, 'A', 1) : Mark(Trail, 'B', 2);
            Observer.Observe(Format(T) + ' simple', Format(R) + '|' + Trail);
            Trail := '';
            R := Mark(Trail, 'c1', T) ? (Mark(Trail, 'c2', not T) ? Mark(Trail, 'A', 1) : Mark(Trail, 'B', 2)) : Mark(Trail, 'C', 3);
            Observer.Observe(Format(T) + ' nested', Format(R) + '|' + Trail);
        end;
        Observer.Expect('Yes simple', '1|cond;A;');
        Observer.Expect('Yes nested', '2|c1;c2;B;');
        Observer.Expect('No simple', '2|cond;B;');
        Observer.Expect('No nested', '3|c1;C;');
        Observer.Verify();
    end;

    local procedure Mark(var Trail: Text; Name: Text; Value: Integer): Integer
    begin
        Trail += Name + ';';
        exit(Value);
    end;

    local procedure Mark(var Trail: Text; Name: Text; Value: Boolean): Boolean
    begin
        Trail += Name + ';';
        exit(Value);
    end;
}
