codeunit 94260 "LT Y81 Label Variant Q1"
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
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
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
    procedure Y81_LabelVariant_Q1_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_Q1_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_Q1_ArrayElement()
    begin
        Run(13, 13);
    end;
}

codeunit 94261 "LT Y81 Label Variant Q2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure TryDescribe(V: Variant; var R: Text)
    begin
        R := Format(V.IsText()) + '/' + Format(V.IsCode()) + '/' + Format(V.IsTextConstant()) + '/' + Format(V.IsChar());
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        TryDescribe(V, R);
        exit(R);
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
                exit(Describe(Cond ? LblA : 'literal'));
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
    procedure Y81_LabelVariant_Q2_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_Q2_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_Q2_ArrayElement()
    begin
        Run(13, 13);
    end;
}

codeunit 94262 "LT Y81 Label Variant Q3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure TryDescribe(V: Variant; var R: Text)
    begin
        R := Format(V.IsText()) + '/' + Format(V.IsCode()) + '/' + Format(V.IsTextConstant()) + '/' + Format(V.IsChar());
    end;

    local procedure Describe(V: Variant): Text
    var
        R: Text;
    begin
        TryDescribe(V, R);
        exit(R);
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
                exit(Describe(ReturnLiteralOrLabel(Cond)));
            12:
                exit(Describe(ReturnNamed(Cond)));
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
    procedure Y81_LabelVariant_Q3_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_Q3_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_Q3_ArrayElement()
    begin
        Run(13, 13);
    end;
}

