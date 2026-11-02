codeunit 94259 "LT Y81 Label Variant Y6"
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
    procedure Y81_LabelVariantY6()
    begin
        Run(1, 3);
    end;
}



codeunit 94260 "LT Y81 Label Variant Y7"
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
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
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
    procedure Y81_LabelVariantY7()
    begin
        Run(4, 5);
    end;
}



codeunit 94261 "LT Y81 Label Variant Y8"
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
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
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
    procedure Y81_LabelVariantY8()
    begin
        Run(6, 7);
    end;
}



codeunit 94262 "LT Y81 Label Variant Y9"
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
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            8:
                exit(Describe(Cond ? LblA : LblB));
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
    procedure Y81_LabelVariantY9()
    begin
        Run(8, 8);
    end;
}



codeunit 94263 "LT Y81 Label Variant Y10"
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
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            9:
                exit(Describe(Cond ? LblA : 'literal'));
            10:
                exit(Describe(Cond ? LblA : TxtVar));
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
    procedure Y81_LabelVariantY10()
    begin
        Run(9, 10);
    end;
}



codeunit 94264 "LT Y81 Label Variant Y11"
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
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            11:
                exit(Describe(ReturnLabelOrLiteral(Cond)));
            12:
                exit(Describe(ReturnLiteralOrLabel(Cond)));
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
    procedure Y81_LabelVariantY11()
    begin
        Run(11, 12);
    end;
}



