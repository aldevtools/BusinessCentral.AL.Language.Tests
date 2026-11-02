codeunit 94260 "LT Y81 Label Variant R1"
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
    procedure Y81_LabelVariant_R1_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_R1_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_R1_ArrayElement()
    begin
        Run(13, 13);
    end;
}


codeunit 94261 "LT Y81 Label Variant R2"
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
    procedure Y81_LabelVariant_R2_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_R2_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_R2_ArrayElement()
    begin
        Run(13, 13);
    end;
}


codeunit 94262 "LT Y81 Label Variant R3"
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

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
            9:
                exit(Describe(Cond ? LblA : 'literal'));
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
    procedure Y81_LabelVariant_R3_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_R3_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_R3_ArrayElement()
    begin
        Run(13, 13);
    end;
}


codeunit 94263 "LT Y81 Label Variant R4"
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

    local procedure Pairs(Cond: Boolean; Route: Integer): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        case Route of
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
    procedure Y81_LabelVariant_R4_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_R4_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_R4_ArrayElement()
    begin
        Run(13, 13);
    end;
}


codeunit 94264 "LT Y81 Label Variant R5"
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
            11:
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
    procedure Y81_LabelVariant_R5_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_R5_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_R5_ArrayElement()
    begin
        Run(13, 13);
    end;
}


codeunit 94265 "LT Y81 Label Variant R6"
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
    procedure Y81_LabelVariant_R6_Assign()
    begin
        Run(1, 7);
    end;

    [Test]
    procedure Y81_LabelVariant_R6_ParameterAndReturn()
    begin
        Run(8, 12);
    end;

    [Test]
    procedure Y81_LabelVariant_R6_ArrayElement()
    begin
        Run(13, 13);
    end;
}


