// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enum 73945 (P79Enums.al), enums 74181-74183, test codeunit 74180
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Enum from Integer/BigInteger, Integer/BigInteger from Enum, E + 1, Integer to Enum parameter, E = Integer, comparison of two different enum types
// BC versions: 29 (27 and 28 by CI)

enum 74181 "LT P79 Plain"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
    value(5; C) { }
}

enum 74182 "LT P79 Plain2"
{
    Extensible = false;
    value(0; A) { }
    value(1; B) { }
    value(2; D) { }
}

enum 74183 "LT P79 Compat"
{
    Extensible = true;
    value(0; A) { }
    value(1; B) { }
    value(5; C) { }
}

codeunit 74180 "LT P79 Accepted Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure IntVal(i: Integer): Integer
    begin
        case i of
            1: exit(0);
            2: exit(1);
            3: exit(5);
            4: exit(100);
            5: exit(2);
            6: exit(99);
            7: exit(-1);
        end;
    end;

    local procedure BigVal(i: Integer): BigInteger
    var
        B: BigInteger;
    begin
        case i of
            1: exit(0);
            2: exit(1);
            3: exit(5);
            4: exit(2);
            5: exit(-1);
            6: Evaluate(B, '4294967296');
            7: Evaluate(B, '-2147483649');
        end;
        exit(B);
    end;

    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryEnumFromInt(I: Integer; var R: Text)
    var
        E: Enum "LT P79 Color";
    begin
        E := I;
        R := Format(E) + '/' + Format(E, 0, 2);
    end;

    [TryFunction]
    local procedure TryIntFromEnum(E: Enum "LT P79 Color"; var R: Text)
    var
        I: Integer;
    begin
        I := E;
        R := Format(I);
    end;

    [TryFunction]
    local procedure TryPlus(E: Enum "LT P79 Color"; var R: Text)
    var
        I: Integer;
    begin
        I := E + 1;
        R := Format(I);
    end;

    [TryFunction]
    local procedure TryPlusExpr(E: Enum "LT P79 Color"; var R: Text)
    begin
        R := Format(E + 1) + '/' + Format((E + 1) * 2) + '/' + Format(E - 1) + '/' + Format(E + E);
    end;

    local procedure TakeEnum(E: Enum "LT P79 Color"): Text
    begin
        exit(Format(E) + '/' + Format(E, 0, 2));
    end;

    [TryFunction]
    local procedure TryArg(I: Integer; var R: Text)
    begin
        R := TakeEnum(I);
    end;

    [TryFunction]
    local procedure TryEq(E: Enum "LT P79 Color"; I: Integer; var R: Text)
    begin
        R := Format(E = I) + '/' + Format(I = E) + '/' + Format(E <> I) + '/' + Format(I <> E);
    end;

    [Test]
    procedure EnumFromInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        i: Integer;
    begin
        for i := 1 to 7 do
            if TryEnumFromInt(IntVal(i), R) then
                Observer.Observe('v' + Format(IntVal(i)), R)
            else
                Observer.Observe('v' + Format(IntVal(i)), Err());
        Observer.Expect('v0', 'Red/0');
        Observer.Expect('v1', 'Green/1');
        Observer.Expect('v5', 'Blue Caption/5');
        Observer.Expect('v100', 'Big/100');
        Observer.Expect('v2', '2/2');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerFromEnum()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryIntFromEnum(Enum::"LT P79 Color"::Red, R) then Observer.Observe('red', R) else Observer.Observe('red', Err());
        if TryIntFromEnum(Enum::"LT P79 Color"::Green, R) then Observer.Observe('green', R) else Observer.Observe('green', Err());
        if TryIntFromEnum(Enum::"LT P79 Color"::Blue, R) then Observer.Observe('blue', R) else Observer.Observe('blue', Err());
        if TryIntFromEnum(Enum::"LT P79 Color"::Big, R) then Observer.Observe('big', R) else Observer.Observe('big', Err());
        Observer.Expect('red', '0');
        Observer.Expect('green', '1');
        Observer.Expect('blue', '5');
        Observer.Expect('big', '100');
        Observer.Verify();
    end;

    [Test]
    procedure EnumPlusInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryPlus(Enum::"LT P79 Color"::Red, R) then Observer.Observe('assign-red', R) else Observer.Observe('assign-red', Err());
        if TryPlus(Enum::"LT P79 Color"::Blue, R) then Observer.Observe('assign-blue', R) else Observer.Observe('assign-blue', Err());
        if TryPlus(Enum::"LT P79 Color"::Big, R) then Observer.Observe('assign-big', R) else Observer.Observe('assign-big', Err());
        if TryPlusExpr(Enum::"LT P79 Color"::Red, R) then Observer.Observe('expr-red', R) else Observer.Observe('expr-red', Err());
        if TryPlusExpr(Enum::"LT P79 Color"::Blue, R) then Observer.Observe('expr-blue', R) else Observer.Observe('expr-blue', Err());
        if TryPlusExpr(Enum::"LT P79 Color"::Big, R) then Observer.Observe('expr-big', R) else Observer.Observe('expr-big', Err());
        Observer.Expect('assign-red', '1');
        Observer.Expect('assign-blue', '6');
        Observer.Expect('assign-big', '101');
        Observer.Expect('expr-red', '1/2/-1/0');
        Observer.Expect('expr-blue', '6/12/4/10');
        Observer.Expect('expr-big', '101/202/99/200');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerToEnumParameter()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        i: Integer;
    begin
        for i := 1 to 7 do
            if TryArg(IntVal(i), R) then
                Observer.Observe('v' + Format(IntVal(i)), R)
            else
                Observer.Observe('v' + Format(IntVal(i)), Err());
        Observer.Expect('v0', 'Red/0');
        Observer.Expect('v1', 'Green/1');
        Observer.Expect('v5', 'Blue Caption/5');
        Observer.Expect('v100', 'Big/100');
        Observer.Expect('v2', '2/2');
        Observer.Expect('v99', '99/99');
        Observer.Expect('v-1', '-1/-1');
        Observer.Verify();
    end;

    [Test]
    procedure EnumEqualsInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        i: Integer;
    begin
        for i := 1 to 7 do begin
            if TryEq(Enum::"LT P79 Color"::Blue, IntVal(i), R) then
                Observer.Observe('blue-vs-' + Format(IntVal(i)), R)
            else
                Observer.Observe('blue-vs-' + Format(IntVal(i)), Err());
            if TryEq(Enum::"LT P79 Color"::Red, IntVal(i), R) then
                Observer.Observe('red-vs-' + Format(IntVal(i)), R)
            else
                Observer.Observe('red-vs-' + Format(IntVal(i)), Err());
        end;
        Observer.Expect('blue-vs-0', 'No/No/Yes/Yes');
        Observer.Expect('red-vs-0', 'Yes/Yes/No/No');
        Observer.Expect('blue-vs-1', 'No/No/Yes/Yes');
        Observer.Expect('red-vs-1', 'No/No/Yes/Yes');
        Observer.Expect('blue-vs-5', 'Yes/Yes/No/No');
        Observer.Expect('red-vs-5', 'No/No/Yes/Yes');
        Observer.Expect('blue-vs-100', 'No/No/Yes/Yes');
        Observer.Expect('red-vs-100', 'No/No/Yes/Yes');
        Observer.Expect('blue-vs-2', 'No/No/Yes/Yes');
        Observer.Expect('red-vs-2', 'No/No/Yes/Yes');
        Observer.Expect('blue-vs-99', 'No/No/Yes/Yes');
        Observer.Expect('red-vs-99', 'No/No/Yes/Yes');
        Observer.Expect('blue-vs--1', 'No/No/Yes/Yes');
        Observer.Expect('red-vs--1', 'No/No/Yes/Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryPlainPlain2(P: Enum "LT P79 Plain"; P2: Enum "LT P79 Plain2"; var R: Text)
    begin
        R := Format(P = P2) + '/' + Format(P <> P2);
    end;

    [TryFunction]
    local procedure TryPlainCompat(P: Enum "LT P79 Plain"; C: Enum "LT P79 Compat"; var R: Text)
    begin
        R := Format(P = C) + '/' + Format(P <> C);
    end;

    [TryFunction]
    local procedure TryCompatPlain(C: Enum "LT P79 Compat"; P: Enum "LT P79 Plain"; var R: Text)
    begin
        R := Format(C = P) + '/' + Format(C <> P);
    end;

    [Test]
    procedure DifferentEnums_PlainVsPlain2()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryPlainPlain2(Enum::"LT P79 Plain"::A, Enum::"LT P79 Plain2"::A, R) then Observer.Observe('A-A', R) else Observer.Observe('A-A', Err());
        if TryPlainPlain2(Enum::"LT P79 Plain"::B, Enum::"LT P79 Plain2"::B, R) then Observer.Observe('B-B', R) else Observer.Observe('B-B', Err());
        if TryPlainPlain2(Enum::"LT P79 Plain"::A, Enum::"LT P79 Plain2"::B, R) then Observer.Observe('A-B', R) else Observer.Observe('A-B', Err());
        if TryPlainPlain2(Enum::"LT P79 Plain"::C, Enum::"LT P79 Plain2"::D, R) then Observer.Observe('C-D', R) else Observer.Observe('C-D', Err());
        if TryPlainPlain2(Enum::"LT P79 Plain"::C, Enum::"LT P79 Plain2"::A, R) then Observer.Observe('C-A', R) else Observer.Observe('C-A', Err());
        Observer.Expect('A-A', 'Yes/No');
        Observer.Expect('B-B', 'Yes/No');
        Observer.Expect('A-B', 'No/Yes');
        Observer.Expect('C-D', 'No/Yes');
        Observer.Expect('C-A', 'No/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DifferentEnums_PlainVsCompat()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryPlainCompat(Enum::"LT P79 Plain"::A, Enum::"LT P79 Compat"::A, R) then Observer.Observe('A-A', R) else Observer.Observe('A-A', Err());
        if TryPlainCompat(Enum::"LT P79 Plain"::C, Enum::"LT P79 Compat"::C, R) then Observer.Observe('C-C', R) else Observer.Observe('C-C', Err());
        if TryPlainCompat(Enum::"LT P79 Plain"::A, Enum::"LT P79 Compat"::B, R) then Observer.Observe('A-B', R) else Observer.Observe('A-B', Err());
        if TryPlainCompat(Enum::"LT P79 Plain"::B, Enum::"LT P79 Compat"::C, R) then Observer.Observe('B-C', R) else Observer.Observe('B-C', Err());
        Observer.Expect('A-A', 'Yes/No');
        Observer.Expect('C-C', 'Yes/No');
        Observer.Expect('A-B', 'No/Yes');
        Observer.Expect('B-C', 'No/Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DifferentEnums_CompatVsPlain()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
    begin
        if TryCompatPlain(Enum::"LT P79 Compat"::A, Enum::"LT P79 Plain"::A, R) then Observer.Observe('A-A', R) else Observer.Observe('A-A', Err());
        if TryCompatPlain(Enum::"LT P79 Compat"::C, Enum::"LT P79 Plain"::C, R) then Observer.Observe('C-C', R) else Observer.Observe('C-C', Err());
        if TryCompatPlain(Enum::"LT P79 Compat"::B, Enum::"LT P79 Plain"::A, R) then Observer.Observe('B-A', R) else Observer.Observe('B-A', Err());
        if TryCompatPlain(Enum::"LT P79 Compat"::C, Enum::"LT P79 Plain"::B, R) then Observer.Observe('C-B', R) else Observer.Observe('C-B', Err());
        Observer.Expect('A-A', 'Yes/No');
        Observer.Expect('C-C', 'Yes/No');
        Observer.Expect('B-A', 'No/Yes');
        Observer.Expect('C-B', 'No/Yes');
        Observer.Verify();
    end;
}
