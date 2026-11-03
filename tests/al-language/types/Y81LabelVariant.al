// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunits 94253-94258 (one per way of reading the Variant) and 94259 (not a test)
// Probe (writer Y81): a conditional expression with a Label as one branch (against another Label, a text literal, a Text variable and a Code variable, both orders) that ends
// in a Variant through different routes: assignment, Variant parameter, return value, Variant array element (List of [Variant] and Dictionary of [Text, Variant]
// do not compile: AL0408, must-not-compile 2770 and 2771).
// The Variant is read in six ways, one per test codeunit: the kind flags (IsText, IsCode, IsTextConstant, IsChar), Format(V), Format(V, 0, 9), and the value taken back into a
// Text, a Code[20] and a Text[5].
// Held (platform crash, not an oracle): a conditional Cond ? Label : 'literal' (Label first, text literal second) used directly as the argument of a Variant parameter or as
// the exit value of a procedure that returns a Variant ends the whole session ("hub connection closed") when its codeunit is loaded, even if the procedure is never called
// (SaaS BC 29). The reverse order (literal first), Label : Label, an assignment to a Variant variable and a named return value assigned the same expression load and run.
// The held shapes are in the non-test codeunit 94259; the runtime should refuse them.
// Pinned elsewhere: assignment of the pairs and the kind of the Variant: types/lt-y66-ternary-label/Y66TernaryLabel.al, types/TestTernaryContracts.al:568-579.
// BC versions: 27, 28, 29

codeunit 94253 "LT Y81 Label Variant 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    [TryFunction]
    local procedure TryDescribe(V: Variant; var R: Text)
    begin
        R := Format(V.IsText()) + '/' + Format(V.IsCode()) + '/' + Format(V.IsTextConstant()) + '/' + Format(V.IsChar());
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryDescribe(V, R) then
            exit(R);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure ReturnNamed(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    exit(Describe(V));
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    exit(Describe(V));
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    exit(Describe(V));
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    exit(Describe(V));
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    exit(Describe(V));
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    exit(Describe(V));
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    exit(Describe(V));
                end;
            8:
                exit(Describe(Cond ? LblA : LblB));
            9:
                exit(Describe(Cond ? 'literal' : LblA));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
            13:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    exit(Describe(Arr[2]));
                end;
        end;
    end;

    [Test]
    procedure Y81_LabelVariant_1_Assign_A()
    begin
        Observer.Observe('route 1 true', Pairs(true, 1));
        Observer.Observe('route 1 false', Pairs(false, 1));
        Observer.Observe('route 2 true', Pairs(true, 2));
        Observer.Observe('route 2 false', Pairs(false, 2));
        Observer.Observe('route 3 true', Pairs(true, 3));
        Observer.Observe('route 3 false', Pairs(false, 3));
        Observer.Observe('route 4 true', Pairs(true, 4));
        Observer.Observe('route 4 false', Pairs(false, 4));
        Observer.Expect('route 1 true', 'No/No/Yes/No');
        Observer.Expect('route 1 false', 'No/No/Yes/No');
        Observer.Expect('route 2 true', 'Yes/No/No/No');
        Observer.Expect('route 2 false', 'Yes/No/No/No');
        Observer.Expect('route 3 true', 'Yes/No/No/No');
        Observer.Expect('route 3 false', 'Yes/No/No/No');
        Observer.Expect('route 4 true', 'No/No/Yes/No');
        Observer.Expect('route 4 false', 'Yes/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_1_Assign_B()
    begin
        Observer.Observe('route 5 true', Pairs(true, 5));
        Observer.Observe('route 5 false', Pairs(false, 5));
        Observer.Observe('route 6 true', Pairs(true, 6));
        Observer.Observe('route 6 false', Pairs(false, 6));
        Observer.Observe('route 7 true', Pairs(true, 7));
        Observer.Observe('route 7 false', Pairs(false, 7));
        Observer.Expect('route 5 true', 'Yes/No/No/No');
        Observer.Expect('route 5 false', 'Yes/No/No/No');
        Observer.Expect('route 6 true', 'No/No/Yes/No');
        Observer.Expect('route 6 false', 'No/Yes/No/No');
        Observer.Expect('route 7 true', 'No/Yes/No/No');
        Observer.Expect('route 7 false', 'No/Yes/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_1_ParameterAndReturn()
    begin
        Observer.Observe('route 8 true', Pairs(true, 8));
        Observer.Observe('route 8 false', Pairs(false, 8));
        Observer.Observe('route 9 true', Pairs(true, 9));
        Observer.Observe('route 9 false', Pairs(false, 9));
        Observer.Observe('route 10 true', Pairs(true, 10));
        Observer.Observe('route 10 false', Pairs(false, 10));
        Observer.Observe('route 11 true', Pairs(true, 11));
        Observer.Observe('route 11 false', Pairs(false, 11));
        Observer.Observe('route 12 true', Pairs(true, 12));
        Observer.Observe('route 12 false', Pairs(false, 12));
        Observer.Expect('route 8 true', 'No/No/Yes/No');
        Observer.Expect('route 8 false', 'No/No/Yes/No');
        Observer.Expect('route 9 true', 'Yes/No/No/No');
        Observer.Expect('route 9 false', 'Yes/No/No/No');
        Observer.Expect('route 10 true', 'No/No/Yes/No');
        Observer.Expect('route 10 false', 'Yes/No/No/No');
        Observer.Expect('route 11 true', 'Yes/No/No/No');
        Observer.Expect('route 11 false', 'Yes/No/No/No');
        Observer.Expect('route 12 true', 'Yes/No/No/No');
        Observer.Expect('route 12 false', 'Yes/No/No/No');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_1_ArrayElement()
    begin
        Observer.Observe('route 13 true', Pairs(true, 13));
        Observer.Observe('route 13 false', Pairs(false, 13));
        Observer.Expect('route 13 true', 'No/No/Yes/No');
        Observer.Expect('route 13 false', 'No/No/Yes/No');
        Observer.Verify();
    end;
}

codeunit 94254 "LT Y81 Label Variant 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    [TryFunction]
    local procedure TryDescribe(V: Variant; var R: Text)
    begin
        R := Format(V);
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryDescribe(V, R) then
            exit(R);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure ReturnNamed(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    exit(Describe(V));
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    exit(Describe(V));
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    exit(Describe(V));
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    exit(Describe(V));
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    exit(Describe(V));
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    exit(Describe(V));
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    exit(Describe(V));
                end;
            8:
                exit(Describe(Cond ? LblA : LblB));
            9:
                exit(Describe(Cond ? 'literal' : LblA));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
            13:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    exit(Describe(Arr[2]));
                end;
        end;
    end;

    local procedure Run(From: Integer; UpTo: Integer)
    var
        Route: Integer;
    begin
        for Route := From to UpTo do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_2_Assign_A()
    begin
        Observer.Observe('route 1 true', Pairs(true, 1));
        Observer.Observe('route 1 false', Pairs(false, 1));
        Observer.Observe('route 2 true', Pairs(true, 2));
        Observer.Observe('route 2 false', Pairs(false, 2));
        Observer.Observe('route 3 true', Pairs(true, 3));
        Observer.Observe('route 3 false', Pairs(false, 3));
        Observer.Observe('route 4 true', Pairs(true, 4));
        Observer.Observe('route 4 false', Pairs(false, 4));
        Observer.Expect('route 1 true', 'Label A');
        Observer.Expect('route 1 false', 'Label B');
        Observer.Expect('route 2 true', 'Label A');
        Observer.Expect('route 2 false', 'literal');
        Observer.Expect('route 3 true', 'literal');
        Observer.Expect('route 3 false', 'Label A');
        Observer.Expect('route 4 true', 'Label A');
        Observer.Expect('route 4 false', 'text var');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_2_Assign_B()
    begin
        Observer.Observe('route 5 true', Pairs(true, 5));
        Observer.Observe('route 5 false', Pairs(false, 5));
        Observer.Observe('route 6 true', Pairs(true, 6));
        Observer.Observe('route 6 false', Pairs(false, 6));
        Observer.Observe('route 7 true', Pairs(true, 7));
        Observer.Observe('route 7 false', Pairs(false, 7));
        Observer.Expect('route 5 true', 'text var');
        Observer.Expect('route 5 false', 'Label A');
        Observer.Expect('route 6 true', 'Label A');
        Observer.Expect('route 6 false', 'CODE VAR');
        Observer.Expect('route 7 true', 'CODE VAR');
        Observer.Expect('route 7 false', 'LABEL A');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_2_ParameterAndReturn()
    begin
        Observer.Observe('route 8 true', Pairs(true, 8));
        Observer.Observe('route 8 false', Pairs(false, 8));
        Observer.Observe('route 9 true', Pairs(true, 9));
        Observer.Observe('route 9 false', Pairs(false, 9));
        Observer.Observe('route 10 true', Pairs(true, 10));
        Observer.Observe('route 10 false', Pairs(false, 10));
        Observer.Observe('route 11 true', Pairs(true, 11));
        Observer.Observe('route 11 false', Pairs(false, 11));
        Observer.Observe('route 12 true', Pairs(true, 12));
        Observer.Observe('route 12 false', Pairs(false, 12));
        Observer.Expect('route 8 true', 'Label A');
        Observer.Expect('route 8 false', 'Label B');
        Observer.Expect('route 9 true', 'literal');
        Observer.Expect('route 9 false', 'Label A');
        Observer.Expect('route 10 true', 'Label A');
        Observer.Expect('route 10 false', 'text var');
        Observer.Expect('route 11 true', 'literal');
        Observer.Expect('route 11 false', 'Label A');
        Observer.Expect('route 12 true', 'Label A');
        Observer.Expect('route 12 false', 'literal');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_2_ArrayElement()
    begin
        Observer.Observe('route 13 true', Pairs(true, 13));
        Observer.Observe('route 13 false', Pairs(false, 13));
        Observer.Expect('route 13 true', 'Label A');
        Observer.Expect('route 13 false', 'Label B');
        Observer.Verify();
    end;
}

codeunit 94255 "LT Y81 Label Variant 3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    [TryFunction]
    local procedure TryDescribe(V: Variant; var R: Text)
    begin
        R := Format(V, 0, 9);
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryDescribe(V, R) then
            exit(R);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure ReturnNamed(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    exit(Describe(V));
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    exit(Describe(V));
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    exit(Describe(V));
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    exit(Describe(V));
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    exit(Describe(V));
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    exit(Describe(V));
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    exit(Describe(V));
                end;
            8:
                exit(Describe(Cond ? LblA : LblB));
            9:
                exit(Describe(Cond ? 'literal' : LblA));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
            13:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    exit(Describe(Arr[2]));
                end;
        end;
    end;

    local procedure Run(From: Integer; UpTo: Integer)
    var
        Route: Integer;
    begin
        for Route := From to UpTo do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_3_Assign_A()
    begin
        Observer.Observe('route 1 true', Pairs(true, 1));
        Observer.Observe('route 1 false', Pairs(false, 1));
        Observer.Observe('route 2 true', Pairs(true, 2));
        Observer.Observe('route 2 false', Pairs(false, 2));
        Observer.Observe('route 3 true', Pairs(true, 3));
        Observer.Observe('route 3 false', Pairs(false, 3));
        Observer.Observe('route 4 true', Pairs(true, 4));
        Observer.Observe('route 4 false', Pairs(false, 4));
        Observer.Expect('route 1 true', 'Label A');
        Observer.Expect('route 1 false', 'Label B');
        Observer.Expect('route 2 true', 'Label A');
        Observer.Expect('route 2 false', 'literal');
        Observer.Expect('route 3 true', 'literal');
        Observer.Expect('route 3 false', 'Label A');
        Observer.Expect('route 4 true', 'Label A');
        Observer.Expect('route 4 false', 'text var');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_3_Assign_B()
    begin
        Observer.Observe('route 5 true', Pairs(true, 5));
        Observer.Observe('route 5 false', Pairs(false, 5));
        Observer.Observe('route 6 true', Pairs(true, 6));
        Observer.Observe('route 6 false', Pairs(false, 6));
        Observer.Observe('route 7 true', Pairs(true, 7));
        Observer.Observe('route 7 false', Pairs(false, 7));
        Observer.Expect('route 5 true', 'text var');
        Observer.Expect('route 5 false', 'Label A');
        Observer.Expect('route 6 true', 'Label A');
        Observer.Expect('route 6 false', 'CODE VAR');
        Observer.Expect('route 7 true', 'CODE VAR');
        Observer.Expect('route 7 false', 'LABEL A');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_3_ParameterAndReturn()
    begin
        Observer.Observe('route 8 true', Pairs(true, 8));
        Observer.Observe('route 8 false', Pairs(false, 8));
        Observer.Observe('route 9 true', Pairs(true, 9));
        Observer.Observe('route 9 false', Pairs(false, 9));
        Observer.Observe('route 10 true', Pairs(true, 10));
        Observer.Observe('route 10 false', Pairs(false, 10));
        Observer.Observe('route 11 true', Pairs(true, 11));
        Observer.Observe('route 11 false', Pairs(false, 11));
        Observer.Observe('route 12 true', Pairs(true, 12));
        Observer.Observe('route 12 false', Pairs(false, 12));
        Observer.Expect('route 8 true', 'Label A');
        Observer.Expect('route 8 false', 'Label B');
        Observer.Expect('route 9 true', 'literal');
        Observer.Expect('route 9 false', 'Label A');
        Observer.Expect('route 10 true', 'Label A');
        Observer.Expect('route 10 false', 'text var');
        Observer.Expect('route 11 true', 'literal');
        Observer.Expect('route 11 false', 'Label A');
        Observer.Expect('route 12 true', 'Label A');
        Observer.Expect('route 12 false', 'literal');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_3_ArrayElement()
    begin
        Observer.Observe('route 13 true', Pairs(true, 13));
        Observer.Observe('route 13 false', Pairs(false, 13));
        Observer.Expect('route 13 true', 'Label A');
        Observer.Expect('route 13 false', 'Label B');
        Observer.Verify();
    end;
}

codeunit 94256 "LT Y81 Label Variant 4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    [TryFunction]
    local procedure TryDescribe(V: Variant; var R: Text)
    var
        T: Text;
    begin
        T := V;
        R := T + '|' + Format(StrLen(T));
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryDescribe(V, R) then
            exit(R);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure ReturnNamed(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    exit(Describe(V));
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    exit(Describe(V));
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    exit(Describe(V));
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    exit(Describe(V));
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    exit(Describe(V));
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    exit(Describe(V));
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    exit(Describe(V));
                end;
            8:
                exit(Describe(Cond ? LblA : LblB));
            9:
                exit(Describe(Cond ? 'literal' : LblA));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
            13:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    exit(Describe(Arr[2]));
                end;
        end;
    end;

    local procedure Run(From: Integer; UpTo: Integer)
    var
        Route: Integer;
    begin
        for Route := From to UpTo do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_4_Assign_A()
    begin
        Observer.Observe('route 1 true', Pairs(true, 1));
        Observer.Observe('route 1 false', Pairs(false, 1));
        Observer.Observe('route 2 true', Pairs(true, 2));
        Observer.Observe('route 2 false', Pairs(false, 2));
        Observer.Observe('route 3 true', Pairs(true, 3));
        Observer.Observe('route 3 false', Pairs(false, 3));
        Observer.Observe('route 4 true', Pairs(true, 4));
        Observer.Observe('route 4 false', Pairs(false, 4));
        Observer.Expect('route 1 true', 'Label A|7');
        Observer.Expect('route 1 false', 'Label B|7');
        Observer.Expect('route 2 true', 'Label A|7');
        Observer.Expect('route 2 false', 'literal|7');
        Observer.Expect('route 3 true', 'literal|7');
        Observer.Expect('route 3 false', 'Label A|7');
        Observer.Expect('route 4 true', 'Label A|7');
        Observer.Expect('route 4 false', 'text var|8');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_4_Assign_B()
    begin
        Observer.Observe('route 5 true', Pairs(true, 5));
        Observer.Observe('route 5 false', Pairs(false, 5));
        Observer.Observe('route 6 true', Pairs(true, 6));
        Observer.Observe('route 6 false', Pairs(false, 6));
        Observer.Observe('route 7 true', Pairs(true, 7));
        Observer.Observe('route 7 false', Pairs(false, 7));
        Observer.Expect('route 5 true', 'text var|8');
        Observer.Expect('route 5 false', 'Label A|7');
        Observer.Expect('route 6 true', 'Label A|7');
        Observer.Expect('route 6 false', 'CODE VAR|8');
        Observer.Expect('route 7 true', 'CODE VAR|8');
        Observer.Expect('route 7 false', 'LABEL A|7');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_4_ParameterAndReturn()
    begin
        Observer.Observe('route 8 true', Pairs(true, 8));
        Observer.Observe('route 8 false', Pairs(false, 8));
        Observer.Observe('route 9 true', Pairs(true, 9));
        Observer.Observe('route 9 false', Pairs(false, 9));
        Observer.Observe('route 10 true', Pairs(true, 10));
        Observer.Observe('route 10 false', Pairs(false, 10));
        Observer.Observe('route 11 true', Pairs(true, 11));
        Observer.Observe('route 11 false', Pairs(false, 11));
        Observer.Observe('route 12 true', Pairs(true, 12));
        Observer.Observe('route 12 false', Pairs(false, 12));
        Observer.Expect('route 8 true', 'Label A|7');
        Observer.Expect('route 8 false', 'Label B|7');
        Observer.Expect('route 9 true', 'literal|7');
        Observer.Expect('route 9 false', 'Label A|7');
        Observer.Expect('route 10 true', 'Label A|7');
        Observer.Expect('route 10 false', 'text var|8');
        Observer.Expect('route 11 true', 'literal|7');
        Observer.Expect('route 11 false', 'Label A|7');
        Observer.Expect('route 12 true', 'Label A|7');
        Observer.Expect('route 12 false', 'literal|7');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_4_ArrayElement()
    begin
        Observer.Observe('route 13 true', Pairs(true, 13));
        Observer.Observe('route 13 false', Pairs(false, 13));
        Observer.Expect('route 13 true', 'Label A|7');
        Observer.Expect('route 13 false', 'Label B|7');
        Observer.Verify();
    end;
}

codeunit 94257 "LT Y81 Label Variant 5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    [TryFunction]
    local procedure TryDescribe(V: Variant; var R: Text)
    var
        C: Code[20];
    begin
        C := V;
        R := C + '|' + Format(StrLen(C));
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryDescribe(V, R) then
            exit(R);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure ReturnNamed(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    exit(Describe(V));
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    exit(Describe(V));
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    exit(Describe(V));
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    exit(Describe(V));
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    exit(Describe(V));
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    exit(Describe(V));
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    exit(Describe(V));
                end;
            8:
                exit(Describe(Cond ? LblA : LblB));
            9:
                exit(Describe(Cond ? 'literal' : LblA));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
            13:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    exit(Describe(Arr[2]));
                end;
        end;
    end;

    local procedure Run(From: Integer; UpTo: Integer)
    var
        Route: Integer;
    begin
        for Route := From to UpTo do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_5_Assign_A()
    begin
        Observer.Observe('route 1 true', Pairs(true, 1));
        Observer.Observe('route 1 false', Pairs(false, 1));
        Observer.Observe('route 2 true', Pairs(true, 2));
        Observer.Observe('route 2 false', Pairs(false, 2));
        Observer.Observe('route 3 true', Pairs(true, 3));
        Observer.Observe('route 3 false', Pairs(false, 3));
        Observer.Observe('route 4 true', Pairs(true, 4));
        Observer.Observe('route 4 false', Pairs(false, 4));
        Observer.Expect('route 1 true', 'LABEL A|7');
        Observer.Expect('route 1 false', 'LABEL B|7');
        Observer.Expect('route 2 true', 'LABEL A|7');
        Observer.Expect('route 2 false', 'LITERAL|7');
        Observer.Expect('route 3 true', 'LITERAL|7');
        Observer.Expect('route 3 false', 'LABEL A|7');
        Observer.Expect('route 4 true', 'LABEL A|7');
        Observer.Expect('route 4 false', 'TEXT VAR|8');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_5_Assign_B()
    begin
        Observer.Observe('route 5 true', Pairs(true, 5));
        Observer.Observe('route 5 false', Pairs(false, 5));
        Observer.Observe('route 6 true', Pairs(true, 6));
        Observer.Observe('route 6 false', Pairs(false, 6));
        Observer.Observe('route 7 true', Pairs(true, 7));
        Observer.Observe('route 7 false', Pairs(false, 7));
        Observer.Expect('route 5 true', 'TEXT VAR|8');
        Observer.Expect('route 5 false', 'LABEL A|7');
        Observer.Expect('route 6 true', 'LABEL A|7');
        Observer.Expect('route 6 false', 'CODE VAR|8');
        Observer.Expect('route 7 true', 'CODE VAR|8');
        Observer.Expect('route 7 false', 'LABEL A|7');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_5_ParameterAndReturn()
    begin
        Observer.Observe('route 8 true', Pairs(true, 8));
        Observer.Observe('route 8 false', Pairs(false, 8));
        Observer.Observe('route 9 true', Pairs(true, 9));
        Observer.Observe('route 9 false', Pairs(false, 9));
        Observer.Observe('route 10 true', Pairs(true, 10));
        Observer.Observe('route 10 false', Pairs(false, 10));
        Observer.Observe('route 11 true', Pairs(true, 11));
        Observer.Observe('route 11 false', Pairs(false, 11));
        Observer.Observe('route 12 true', Pairs(true, 12));
        Observer.Observe('route 12 false', Pairs(false, 12));
        Observer.Expect('route 8 true', 'LABEL A|7');
        Observer.Expect('route 8 false', 'LABEL B|7');
        Observer.Expect('route 9 true', 'LITERAL|7');
        Observer.Expect('route 9 false', 'LABEL A|7');
        Observer.Expect('route 10 true', 'LABEL A|7');
        Observer.Expect('route 10 false', 'TEXT VAR|8');
        Observer.Expect('route 11 true', 'LITERAL|7');
        Observer.Expect('route 11 false', 'LABEL A|7');
        Observer.Expect('route 12 true', 'LABEL A|7');
        Observer.Expect('route 12 false', 'LITERAL|7');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_5_ArrayElement()
    begin
        Observer.Observe('route 13 true', Pairs(true, 13));
        Observer.Observe('route 13 false', Pairs(false, 13));
        Observer.Expect('route 13 true', 'LABEL A|7');
        Observer.Expect('route 13 false', 'LABEL B|7');
        Observer.Verify();
    end;
}

codeunit 94258 "LT Y81 Label Variant 6"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    [TryFunction]
    local procedure TryDescribe(V: Variant; var R: Text)
    var
        S: Text[5];
    begin
        S := V;
        R := S + '|' + Format(StrLen(S));
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        ClearLastError();
        if TryDescribe(V, R) then
            exit(R);
        exit('E ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    local procedure ReturnNamed(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
        Arr: array[2] of Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            1:
                begin
                    V := Cond ? LblA : LblB;
                    exit(Describe(V));
                end;
            2:
                begin
                    V := Cond ? LblA : 'literal';
                    exit(Describe(V));
                end;
            3:
                begin
                    V := Cond ? 'literal' : LblA;
                    exit(Describe(V));
                end;
            4:
                begin
                    V := Cond ? LblA : TxtVar;
                    exit(Describe(V));
                end;
            5:
                begin
                    V := Cond ? TxtVar : LblA;
                    exit(Describe(V));
                end;
            6:
                begin
                    V := Cond ? LblA : CodeVar;
                    exit(Describe(V));
                end;
            7:
                begin
                    V := Cond ? CodeVar : LblA;
                    exit(Describe(V));
                end;
            8:
                exit(Describe(Cond ? LblA : LblB));
            9:
                exit(Describe(Cond ? 'literal' : LblA));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
            13:
                begin
                    Arr[2] := Cond ? LblA : LblB;
                    exit(Describe(Arr[2]));
                end;
        end;
    end;

    local procedure Run(From: Integer; UpTo: Integer)
    var
        Route: Integer;
    begin
        for Route := From to UpTo do begin
            Observer.Observe('route ' + Format(Route) + ' true', Pairs(true, Route));
            Observer.Observe('route ' + Format(Route) + ' false', Pairs(false, Route));
        end;
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariant_6_Assign_A()
    begin
        Observer.Observe('route 1 true', Pairs(true, 1));
        Observer.Observe('route 1 false', Pairs(false, 1));
        Observer.Observe('route 2 true', Pairs(true, 2));
        Observer.Observe('route 2 false', Pairs(false, 2));
        Observer.Observe('route 3 true', Pairs(true, 3));
        Observer.Observe('route 3 false', Pairs(false, 3));
        Observer.Observe('route 4 true', Pairs(true, 4));
        Observer.Observe('route 4 false', Pairs(false, 4));
        Observer.Expect('route 1 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 1 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label B|StringLengthExceeded');
        Observer.Expect('route 2 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 2 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: literal|StringLengthExceeded');
        Observer.Expect('route 3 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: literal|StringLengthExceeded');
        Observer.Expect('route 3 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 4 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 4 false', 'E The length of the string is 8, but it must be less than or equal to 5 characters. Value: text var|StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_6_Assign_B()
    begin
        Observer.Observe('route 5 true', Pairs(true, 5));
        Observer.Observe('route 5 false', Pairs(false, 5));
        Observer.Observe('route 6 true', Pairs(true, 6));
        Observer.Observe('route 6 false', Pairs(false, 6));
        Observer.Observe('route 7 true', Pairs(true, 7));
        Observer.Observe('route 7 false', Pairs(false, 7));
        Observer.Expect('route 5 true', 'E The length of the string is 8, but it must be less than or equal to 5 characters. Value: text var|StringLengthExceeded');
        Observer.Expect('route 5 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 6 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 6 false', 'E The length of the string is 8, but it must be less than or equal to 5 characters. Value: CODE VAR|StringLengthExceeded');
        Observer.Expect('route 7 true', 'E The length of the string is 8, but it must be less than or equal to 5 characters. Value: CODE VAR|StringLengthExceeded');
        Observer.Expect('route 7 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: LABEL A|StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_6_ParameterAndReturn()
    begin
        Observer.Observe('route 8 true', Pairs(true, 8));
        Observer.Observe('route 8 false', Pairs(false, 8));
        Observer.Observe('route 9 true', Pairs(true, 9));
        Observer.Observe('route 9 false', Pairs(false, 9));
        Observer.Observe('route 10 true', Pairs(true, 10));
        Observer.Observe('route 10 false', Pairs(false, 10));
        Observer.Observe('route 11 true', Pairs(true, 11));
        Observer.Observe('route 11 false', Pairs(false, 11));
        Observer.Observe('route 12 true', Pairs(true, 12));
        Observer.Observe('route 12 false', Pairs(false, 12));
        Observer.Expect('route 8 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 8 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label B|StringLengthExceeded');
        Observer.Expect('route 9 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: literal|StringLengthExceeded');
        Observer.Expect('route 9 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 10 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 10 false', 'E The length of the string is 8, but it must be less than or equal to 5 characters. Value: text var|StringLengthExceeded');
        Observer.Expect('route 11 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: literal|StringLengthExceeded');
        Observer.Expect('route 11 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 12 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 12 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: literal|StringLengthExceeded');
        Observer.Verify();
    end;

    [Test]
    procedure Y81_LabelVariant_6_ArrayElement()
    begin
        Observer.Observe('route 13 true', Pairs(true, 13));
        Observer.Observe('route 13 false', Pairs(false, 13));
        Observer.Expect('route 13 true', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label A|StringLengthExceeded');
        Observer.Expect('route 13 false', 'E The length of the string is 7, but it must be less than or equal to 5 characters. Value: Label B|StringLengthExceeded');
        Observer.Verify();
    end;
}

// Not a test codeunit: nothing runs it. Loading it (calling any procedure of it) ends the session on SaaS BC 29.
codeunit 94259 "LT Y81 Label Variant Held"
{
    var
        LblA: Label 'Label A';

    procedure Suspect_ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    procedure Suspect_ArgumentLabelOrLiteral(Cond: Boolean): Text
    begin
        exit(Describe(Cond ? LblA : 'literal'));
    end;

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;
}
