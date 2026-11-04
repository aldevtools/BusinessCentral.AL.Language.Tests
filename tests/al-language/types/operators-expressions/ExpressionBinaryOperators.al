// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-operators-and-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 72789
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: every binary operator (+ - * / div mod and or xor in = <> < > <= >=) over Integer, BigInteger, Decimal, Text, Code and Boolean operands: result, Format, overflow, rounding, comparison rules (case, trailing blanks, empty), and whether the right operand of and / or is evaluated.
codeunit 72789 "LT Binary Operators"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Calls: Integer;

    local procedure Hit(Result: Boolean): Boolean
    begin
        Calls += 1;
        exit(Result);
    end;

    [Test]
    procedure P195_Binary_IntegerArithmetic()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        Neg: Integer;
        Max: Integer;
    begin
        A := 17;
        B := 5;
        Neg := -5;
        Max := 2147483647;
        Observer.Observe('add', Format(A + B));
        Observer.Observe('sub', Format(B - A));
        Observer.Observe('mul', Format(A * B));
        Observer.Observe('slash', Format(A / B));
        Observer.Observe('slash-exact', Format(10 / 5));
        Observer.Observe('div', Format(A div B));
        Observer.Observe('mod', Format(A mod B));
        Observer.Observe('div-neg-divisor', Format(A div Neg));
        Observer.Observe('mod-neg-divisor', Format(A mod Neg));
        Observer.Observe('div-neg-dividend', Format(-A div B));
        Observer.Observe('mod-neg-dividend', Format(-A mod B));
        Observer.Observe('div-both-neg', Format(-A div Neg));
        Observer.Observe('mod-both-neg', Format(-A mod Neg));
        Observer.Observe('div-smaller-than-divisor', Format(3 div 5));
        Observer.Observe('mod-smaller-than-divisor', Format(3 mod 5));
        Observer.Observe('precedence-mul-add', Format(2 + 3 * 4));
        Observer.Observe('precedence-div-mod-left-to-right', Format(100 div 7 mod 5));
        Observer.Observe('left-to-right-sub', Format(10 - 3 - 2));
        Observer.Observe('left-to-right-slash', Format(100 / 10 / 5));
        asserterror A := Max + 1;
        Observer.ObserveError('add-overflow');
        asserterror A := Max * 2;
        Observer.ObserveError('mul-overflow');
        asserterror A := -Max - 2;
        Observer.ObserveError('sub-underflow');
        Observer.Expect('add', '22');
        Observer.Expect('sub', '-12');
        Observer.Expect('mul', '85');
        Observer.Expect('slash', '3.4');
        Observer.Expect('slash-exact', '2');
        Observer.Expect('div', '3');
        Observer.Expect('mod', '2');
        Observer.Expect('div-neg-divisor', '-3');
        Observer.Expect('mod-neg-divisor', '2');
        Observer.Expect('div-neg-dividend', '-3');
        Observer.Expect('mod-neg-dividend', '-2');
        Observer.Expect('div-both-neg', '3');
        Observer.Expect('mod-both-neg', '-2');
        Observer.Expect('div-smaller-than-divisor', '0');
        Observer.Expect('mod-smaller-than-divisor', '3');
        Observer.Expect('precedence-mul-add', '14');
        Observer.Expect('precedence-div-mod-left-to-right', '4');
        Observer.Expect('left-to-right-sub', '5');
        Observer.Expect('left-to-right-slash', '2');
        Observer.Expect('add-overflow|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('add-overflow|code', 'AL:Overflow');
        Observer.Expect('mul-overflow|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('mul-overflow|code', 'AL:Overflow');
        Observer.Expect('sub-underflow|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('sub-underflow|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_BigIntegerAndDecimalArithmetic()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        Big2: BigInteger;
        D: Decimal;
        E: Decimal;
    begin
        Big := 2147483647;
        Big2 := Big * 4;
        Observer.Observe('big-mul', Format(Big2));
        Observer.Observe('big-add-int', Format(Big2 + 1));
        Observer.Observe('big-div', Format(Big2 div 3));
        Observer.Observe('big-mod', Format(Big2 mod 1000));
        Observer.Observe('big-slash', Format(Big2 / 8));
        Observer.Observe('big-compare-int', Format(Big2 > 5));
        Observer.Observe('big-eq-int', Format(Big = 2147483647));
        D := 7.5;
        E := 2.25;
        Observer.Observe('dec-add', Format(D + E));
        Observer.Observe('dec-sub', Format(E - D));
        Observer.Observe('dec-mul', Format(D * E));
        Observer.Observe('dec-slash', Format(D / E));
        Observer.Observe('dec-one-third', Format(1 / 3));
        Observer.Observe('dec-one-third-xml', Format(1 / 3, 0, 9));
        Observer.Observe('dec-two-thirds-xml', Format(2 / 3, 0, 9));
        Observer.Observe('dec-sum-point-one', Format(0.1 + 0.2 = 0.3));
        Observer.Observe('dec-mul-by-int', Format(D * 4));
        Observer.Observe('dec-neg-compare', Format(-1.5 < -1.25));
        Observer.Observe('dec-eq-int', Format(2.0 = 2));
        Observer.Observe('dec-compare-ge', Format(D >= 7.5));
        Observer.Expect('big-mul', '8589934588');
        Observer.Expect('big-add-int', '8589934589');
        Observer.Expect('big-div', '2863311529');
        Observer.Expect('big-mod', '588');
        Observer.Expect('big-slash', '1,073,741,823.5');
        Observer.Expect('big-compare-int', 'Yes');
        Observer.Expect('big-eq-int', 'Yes');
        Observer.Expect('dec-add', '9.75');
        Observer.Expect('dec-sub', '-5.25');
        Observer.Expect('dec-mul', '16.875');
        Observer.Expect('dec-slash', '3.33333333333333333');
        Observer.Expect('dec-one-third', '0.333333333333333333');
        Observer.Expect('dec-one-third-xml', '0.333333333333333333');
        Observer.Expect('dec-two-thirds-xml', '0.666666666666666667');
        Observer.Expect('dec-sum-point-one', 'Yes');
        Observer.Expect('dec-mul-by-int', '30');
        Observer.Expect('dec-neg-compare', 'Yes');
        Observer.Expect('dec-eq-int', 'Yes');
        Observer.Expect('dec-compare-ge', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_TextAndCodeOperands()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
        C: Code[10];
        C2: Code[10];
    begin
        T := 'abc';
        C := 'abc';
        C2 := 'ABD';
        Observer.Observe('text-concat', T + 'def');
        Observer.Observe('code-concat', C + C2);
        Observer.Observe('text-plus-code', T + C);
        Observer.Observe('code-plus-text-len', Format(StrLen(C + T)));
        Observer.Observe('text-eq-same-case', Format(T = 'abc'));
        Observer.Observe('text-eq-other-case', Format(T = 'ABC'));
        Observer.Observe('text-ne-other-case', Format(T <> 'ABC'));
        Observer.Observe('text-eq-trailing-blank', Format(T = 'abc '));
        Observer.Observe('text-eq-leading-blank', Format(T = ' abc'));
        Observer.Observe('text-eq-empty', Format('' = ''));
        Observer.Observe('text-eq-blank-vs-empty', Format('' = ' '));
        Observer.Observe('code-eq-lower', Format(C = 'ABC'));
        Observer.Observe('code-eq-text', Format(C = T));
        Observer.Observe('code-lt-code', Format(C < C2));
        Observer.Observe('text-lt-upper-vs-lower', Format('a' < 'B'));
        Observer.Observe('text-gt-upper-vs-lower', Format('Z' > 'a'));
        Observer.Observe('text-le-equal-other-case', Format('abc' <= 'ABC'));
        Observer.Observe('text-ge-prefix', Format('abcd' >= 'abc'));
        Observer.Observe('text-lt-prefix', Format('abc' < 'abcd'));
        Observer.Observe('text-lt-empty', Format('' < 'a'));
        Observer.Observe('text-umlaut-lt', Format('z' < 'ä'));
        Observer.Observe('text-digit-lt-letter', Format('9' < 'a'));
        Observer.Observe('text-in-set', Format(T in ['ABC', 'x']));
        Observer.Expect('text-concat', 'abcdef');
        Observer.Expect('code-concat', 'ABCABD');
        Observer.Expect('text-plus-code', 'abcABC');
        Observer.Expect('code-plus-text-len', '6');
        Observer.Expect('text-eq-same-case', 'Yes');
        Observer.Expect('text-eq-other-case', 'No');
        Observer.Expect('text-ne-other-case', 'Yes');
        Observer.Expect('text-eq-trailing-blank', 'No');
        Observer.Expect('text-eq-leading-blank', 'No');
        Observer.Expect('text-eq-empty', 'Yes');
        Observer.Expect('text-eq-blank-vs-empty', 'No');
        Observer.Expect('code-eq-lower', 'Yes');
        Observer.Expect('code-eq-text', 'No');
        Observer.Expect('code-lt-code', 'Yes');
        Observer.Expect('text-lt-upper-vs-lower', 'Yes');
        Observer.Expect('text-gt-upper-vs-lower', 'Yes');
        Observer.Expect('text-le-equal-other-case', 'Yes');
        Observer.Expect('text-ge-prefix', 'Yes');
        Observer.Expect('text-lt-prefix', 'Yes');
        Observer.Expect('text-lt-empty', 'Yes');
        Observer.Expect('text-umlaut-lt', 'No');
        Observer.Expect('text-digit-lt-letter', 'Yes');
        Observer.Expect('text-in-set', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_BooleanOperands()
    var
        Observer: Codeunit "Probe Observer";
        P: Boolean;
        Q: Boolean;
    begin
        P := true;
        Q := false;
        Observer.Observe('and-tt', Format(P and P));
        Observer.Observe('and-tf', Format(P and Q));
        Observer.Observe('or-ff', Format(Q or Q));
        Observer.Observe('or-ft', Format(Q or P));
        Observer.Observe('xor-tt', Format(P xor P));
        Observer.Observe('xor-tf', Format(P xor Q));
        Observer.Observe('xor-ff', Format(Q xor Q));
        Observer.Observe('eq-tt', Format(P = P));
        Observer.Observe('eq-tf', Format(P = Q));
        Observer.Observe('ne-tf', Format(P <> Q));
        Observer.Observe('lt-false-true', Format(Q < P));
        Observer.Observe('gt-true-false', Format(P > Q));
        Observer.Observe('le-true-true', Format(P <= P));
        Observer.Observe('ge-false-true', Format(Q >= P));
        Observer.Observe('precedence-and-before-or', Format(P or Q and Q));
        Observer.Observe('precedence-comparison-in-parens', Format((1 < 2) and (3 > 2)));
        Calls := 0;
        Observer.Observe('and-short-circuit-result', Format(Hit(false) and Hit(true)));
        Observer.Observe('and-short-circuit-calls', Format(Calls));
        Calls := 0;
        Observer.Observe('or-short-circuit-result', Format(Hit(true) or Hit(false)));
        Observer.Observe('or-short-circuit-calls', Format(Calls));
        Calls := 0;
        Observer.Observe('xor-both-evaluated-result', Format(Hit(true) xor Hit(true)));
        Observer.Observe('xor-both-evaluated-calls', Format(Calls));
        Calls := 0;
        Observer.Observe('and-second-evaluated-result', Format(Hit(true) and Hit(true)));
        Observer.Observe('and-second-evaluated-calls', Format(Calls));
        Observer.Expect('and-tt', 'Yes');
        Observer.Expect('and-tf', 'No');
        Observer.Expect('or-ff', 'No');
        Observer.Expect('or-ft', 'Yes');
        Observer.Expect('xor-tt', 'No');
        Observer.Expect('xor-tf', 'Yes');
        Observer.Expect('xor-ff', 'No');
        Observer.Expect('eq-tt', 'Yes');
        Observer.Expect('eq-tf', 'No');
        Observer.Expect('ne-tf', 'Yes');
        Observer.Expect('lt-false-true', 'Yes');
        Observer.Expect('gt-true-false', 'Yes');
        Observer.Expect('le-true-true', 'Yes');
        Observer.Expect('ge-false-true', 'No');
        Observer.Expect('precedence-and-before-or', 'Yes');
        Observer.Expect('precedence-comparison-in-parens', 'Yes');
        Observer.Expect('and-short-circuit-result', 'No');
        Observer.Expect('and-short-circuit-calls', '2');
        Observer.Expect('or-short-circuit-result', 'Yes');
        Observer.Expect('or-short-circuit-calls', '2');
        Observer.Expect('xor-both-evaluated-result', 'No');
        Observer.Expect('xor-both-evaluated-calls', '2');
        Observer.Expect('and-second-evaluated-result', 'Yes');
        Observer.Expect('and-second-evaluated-calls', '2');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_InOperatorOverTypes()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
        C: Code[10];
        Opt: Option A,B,C;
    begin
        I := 7;
        D := 2.5;
        C := 'k';
        Opt := Opt::B;
        Observer.Observe('int-in-range', Format(I in [1 .. 10]));
        Observer.Observe('int-in-range-edge-low', Format(1 in [1 .. 10]));
        Observer.Observe('int-in-range-edge-high', Format(10 in [1 .. 10]));
        Observer.Observe('int-out-of-range', Format(11 in [1 .. 10]));
        Observer.Observe('int-in-list-and-range', Format(I in [1, 3, 5 .. 8]));
        Observer.Observe('int-negative-range', Format(-3 in [-5 .. -1]));
        Observer.Observe('dec-in-range', Format(D in [2 .. 3]));
        Observer.Observe('dec-in-list', Format(D in [2.5, 3.5]));
        Observer.Observe('code-in-list-other-case', Format(C in ['K', 'L']));
        Observer.Observe('code-in-range', Format(C in ['a' .. 'z']));
        Observer.Observe('char-range-upper', Format('K' in ['a' .. 'z']));
        Observer.Observe('option-in-set', Format(Opt in [Opt::A, Opt::B]));
        Observer.Observe('option-not-in-set', Format(Opt in [Opt::C]));
        Observer.Observe('not-in', Format(not (I in [1 .. 3])));
        Observer.Observe('date-in-range', Format(20240115D in [20240101D .. 20240131D]));
        Observer.Expect('int-in-range', 'Yes');
        Observer.Expect('int-in-range-edge-low', 'Yes');
        Observer.Expect('int-in-range-edge-high', 'Yes');
        Observer.Expect('int-out-of-range', 'No');
        Observer.Expect('int-in-list-and-range', 'Yes');
        Observer.Expect('int-negative-range', 'Yes');
        Observer.Expect('dec-in-range', 'Yes');
        Observer.Expect('dec-in-list', 'Yes');
        Observer.Expect('code-in-list-other-case', 'Yes');
        Observer.Expect('code-in-range', 'Yes');
        Observer.Expect('char-range-upper', 'No');
        Observer.Expect('option-in-set', 'Yes');
        Observer.Expect('option-not-in-set', 'No');
        Observer.Expect('not-in', 'Yes');
        Observer.Expect('date-in-range', 'Yes');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 39: an expression of Integer operands is computed as Integer even
    // when its result goes to a BigInteger (60*10 * 120*10 * 80*10 * 4 = 2,304,000,000 is above the Integer range).
    [Test]
    procedure LT_BU_Binary_IntegerProductIntoBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        H: Integer;
        L: Integer;
        W: Integer;
        Q: Integer;
        Big: BigInteger;
        Dec: Decimal;
        Txt: Text;
    begin
        H := 60;
        L := 120;
        W := 80;
        Q := 4;
        ClearLastError();
        if TryIntegerProductToBig(H, L, W, Q, Big) then
            Observer.Observe('assign', Format(Big))
        else
            Observer.Observe('assign', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryIntegerProductAsBigParameter(H, L, W, Q, Big) then
            Observer.Observe('biginteger parameter', Format(Big))
        else
            Observer.Observe('biginteger parameter', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        ClearLastError();
        if TryIntegerProductToJson(H, L, W, Q, Txt) then
            Observer.Observe('json add', Txt)
        else
            Observer.Observe('json add', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Big := H;
        Big := (Big * 10) * (L * 10) * (W * 10) * Q;
        Observer.Observe('first operand biginteger', Format(Big));
        Dec := (H * 10.0) * (L * 10) * (W * 10) * Q;
        Observer.Observe('decimal literal operand', Format(Dec, 0, 9));
        Big := H * 10;
        Big := Big * (L * 10) * (W * 10) * Q;
        Observer.Observe('biginteger left to right', Format(Big));
        ClearLastError();
        if TryIntegerProductLateBig(H, L, W, Q, Big) then
            Observer.Observe('biginteger last operand', Format(Big))
        else
            Observer.Observe('biginteger last operand', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('assign', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('biginteger parameter', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('json add', 'error:Arithmetic operation resulted in an overflow.|AL:Overflow');
        Observer.Expect('first operand biginteger', '2304000000');
        Observer.Expect('decimal literal operand', '2304000000');
        Observer.Expect('biginteger left to right', '2304000000');
        Observer.Expect('biginteger last operand', '2304000000');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryIntegerProductToBig(H: Integer; L: Integer; W: Integer; Q: Integer; var Big: BigInteger)
    begin
        Big := (H * 10) * (L * 10) * (W * 10) * Q;
    end;

    [TryFunction]
    local procedure TryIntegerProductAsBigParameter(H: Integer; L: Integer; W: Integer; Q: Integer; var Big: BigInteger)
    begin
        Big := TakeBig((H * 10) * (L * 10) * (W * 10) * Q);
    end;

    local procedure TakeBig(Value: BigInteger): BigInteger
    begin
        exit(Value);
    end;

    [TryFunction]
    local procedure TryIntegerProductToJson(H: Integer; L: Integer; W: Integer; Q: Integer; var Txt: Text)
    var
        Json: JsonObject;
    begin
        Json.Add('v', (H * 10) * (L * 10) * (W * 10) * Q);
        Json.WriteTo(Txt);
    end;

    [TryFunction]
    local procedure TryIntegerProductLateBig(H: Integer; L: Integer; W: Integer; Q: Integer; var Big: BigInteger)
    var
        BigQ: BigInteger;
    begin
        BigQ := Q;
        Big := (H * 10) * (L * 10) * (W * 10) * BigQ;
    end;
}
