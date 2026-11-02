// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-ternary-operator
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunits 94253-94258 (one per way of reading the Variant, so that a platform crash in one read does not hide the others)
// Probe (writer Y81): a conditional expression with a Label as one branch (against another Label, a text literal, a Text variable and a Code variable, both orders) that ends
// in a Variant through different routes: assignment, Variant parameter, return value, Variant array element (List of [Variant] and Dictionary of [Text, Variant]
// do not compile: AL0408, must-not-compile 2770 and 2771).
// The Variant is read in six ways, one per test codeunit: the kind flags (IsText, IsCode, IsTextConstant, IsChar), Format(V), Format(V, 0, 9), and the value taken back into a
// Text, a Code[20] and a Text[5].
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

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
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
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariant_1_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_1_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_1_ArrayElement()
    begin
        Run(13, 13);
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

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
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
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariant_2_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_2_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_2_ArrayElement()
    begin
        Run(13, 13);
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

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
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
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariant_3_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_3_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_3_ArrayElement()
    begin
        Run(13, 13);
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

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
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
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariant_4_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_4_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_4_ArrayElement()
    begin
        Run(13, 13);
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

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
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
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariant_5_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_5_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_5_ArrayElement()
    begin
        Run(13, 13);
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

    local procedure ReturnLabelOrLiteral(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure ReturnLiteralOrLabel(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
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
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariant_6_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_6_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_6_ArrayElement()
    begin
        Run(13, 13);
    end;
}
