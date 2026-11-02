codeunit 94259 "LT Y81 Label Variant B1"
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
    procedure Y81_LabelVariantB1()
    begin
        Run(1, 1);
    end;
}

codeunit 94260 "LT Y81 Label Variant B2"
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
    procedure Y81_LabelVariantB2()
    begin
        Run(2, 2);
    end;
}

codeunit 94261 "LT Y81 Label Variant B3"
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
    procedure Y81_LabelVariantB3()
    begin
        Run(3, 3);
    end;
}

codeunit 94262 "LT Y81 Label Variant B4"
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
    procedure Y81_LabelVariantB4()
    begin
        Run(4, 4);
    end;
}

codeunit 94263 "LT Y81 Label Variant B5"
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
    procedure Y81_LabelVariantB5()
    begin
        Run(5, 5);
    end;
}

codeunit 94264 "LT Y81 Label Variant B6"
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
    procedure Y81_LabelVariantB6()
    begin
        Run(6, 6);
    end;
}

codeunit 94265 "LT Y81 Label Variant B7"
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
    procedure Y81_LabelVariantB7()
    begin
        Run(7, 7);
    end;
}

codeunit 94266 "LT Y81 Label Variant B8"
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
    procedure Y81_LabelVariantB8()
    begin
        Run(8, 8);
    end;
}

codeunit 94267 "LT Y81 Label Variant B9"
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
    procedure Y81_LabelVariantB9()
    begin
        Run(9, 9);
    end;
}

codeunit 94268 "LT Y81 Label Variant B10"
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
    procedure Y81_LabelVariantB10()
    begin
        Run(10, 10);
    end;
}

codeunit 94269 "LT Y81 Label Variant B11"
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
    procedure Y81_LabelVariantB11()
    begin
        Run(11, 11);
    end;
}

codeunit 94270 "LT Y81 Label Variant B12"
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
    procedure Y81_LabelVariantB12()
    begin
        Run(12, 12);
    end;
}

codeunit 94271 "LT Y81 Label Variant B13"
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
    procedure Y81_LabelVariantB13()
    begin
        Run(13, 13);
    end;
}

