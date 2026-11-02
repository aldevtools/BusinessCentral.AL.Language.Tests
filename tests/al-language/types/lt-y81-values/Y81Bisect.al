codeunit 94259 "LT Y81 Label Variant W1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? LblA : LblB;
        exit(Describe(V));
    end;

    local procedure Go(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW1()
    begin
        Go(true);
    end;
}

codeunit 94260 "LT Y81 Label Variant W2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? LblA : LblB;
        exit(Describe(V));
    end;

    local procedure Run(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW2()
    begin
        Run(true);
    end;
}

codeunit 94261 "LT Y81 Label Variant W3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? LblA : 'literal';
        exit(Describe(V));
    end;

    local procedure Go(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW3()
    begin
        Go(true);
    end;
}

codeunit 94262 "LT Y81 Label Variant W4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? 'literal' : LblA;
        exit(Describe(V));
    end;

    local procedure Go(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW4()
    begin
        Go(true);
    end;
}

codeunit 94263 "LT Y81 Label Variant W5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? LblA : TxtVar;
        exit(Describe(V));
    end;

    local procedure Go(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW5()
    begin
        Go(true);
    end;
}

codeunit 94264 "LT Y81 Label Variant W6"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? LblA : CodeVar;
        exit(Describe(V));
    end;

    local procedure Go(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW6()
    begin
        Go(true);
    end;
}

codeunit 94265 "LT Y81 Label Variant W7"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';
        TxtVar: Text;
        CodeVar: Code[20];

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure Pairs(Cond: Boolean): Text
    var
        V: Variant;
    begin
        TxtVar := 'text var';
        CodeVar := 'code var';
        V := Cond ? LblA : LblB;
        exit(Describe(Cond ? LblA : LblB));
    end;

    local procedure Go(Cond: Boolean)
    begin
        Observer.Observe('r', Pairs(Cond));
        Observer.Finish();
    end;

    [Test]
    procedure Y81_LabelVariantW7()
    begin
        Go(true);
    end;
}

