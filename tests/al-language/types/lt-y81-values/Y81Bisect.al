codeunit 94259 "LT Y81 Label Variant X1"
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
    procedure Y81_LabelVariantX1()
    begin
        Run(1, 1);
    end;
}


codeunit 94260 "LT Y81 Label Variant X2"
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
        exit(Format(V.IsText()));
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
    procedure Y81_LabelVariantX2()
    begin
        Run(1, 1);
    end;
}


codeunit 94261 "LT Y81 Label Variant X3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    [Test]
    procedure Y81_LabelVariantX3()
    var
        V: Variant;
        Cond: Boolean;
    begin
        Cond := true;
        V := Cond ? LblA : LblB;
        Observer.Observe('x', Format(V.IsText()));
        Observer.Finish();
    end;
}

codeunit 94262 "LT Y81 Label Variant X4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    [Test]
    procedure Y81_LabelVariantX4()
    var
        V: Variant;
        Cond: Boolean;
    begin
        Cond := true;
        V := LblA;
        Observer.Observe('x', Format(V.IsText()));
        Observer.Finish();
    end;
}

codeunit 94263 "LT Y81 Label Variant X5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    [Test]
    procedure Y81_LabelVariantX5()
    var
        V: Variant;
        Cond: Boolean;
    begin
        Cond := true;
        V := Cond ? 'a' : 'b';
        Observer.Observe('x', Format(V.IsText()));
        Observer.Finish();
    end;
}
