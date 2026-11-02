codeunit 94259 "LT Y81 Label Variant Z1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ1()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        V := Cond ? LblA : LblB;
        Observer.Observe('x', Describe(V));
        Observer.Finish();
    end;
}

codeunit 94260 "LT Y81 Label Variant Z2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ2()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        V := Cond ? LblA : LblB;
        Observer.Observe('x', DescribeVar(V));
        Observer.Finish();
    end;
}

codeunit 94261 "LT Y81 Label Variant Z3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ3()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        V := Cond ? LocalLbl : 'x';
        Observer.Observe('x', Format(V.IsText()));
        Observer.Finish();
    end;
}

codeunit 94262 "LT Y81 Label Variant Z4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ4()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        Observer.Observe('x', Describe(Cond ? LblA : LblB));
        Observer.Finish();
    end;
}

codeunit 94263 "LT Y81 Label Variant Z5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ5()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        V := LblA;
        Observer.Observe('x', Describe(V));
        Observer.Finish();
    end;
}

codeunit 94264 "LT Y81 Label Variant Z6"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ6()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        V := 'a';
        Observer.Observe('x', Describe(V));
        Observer.Finish();
    end;
}

codeunit 94265 "LT Y81 Label Variant Z7"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    local procedure DescribeVar(var V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantZ7()
    var
        V: Variant;
        Cond: Boolean;
        LocalLbl: Label 'Local';
    begin
        Cond := true;
        V := Cond ? 'a' : 'b';
        Observer.Observe('x', Describe(V));
        Observer.Finish();
    end;
}

