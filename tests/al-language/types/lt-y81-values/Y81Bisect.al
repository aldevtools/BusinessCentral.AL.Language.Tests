codeunit 94259 "LT Y81 Label Variant S1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    [Test]
    procedure Y81_LabelVariantS1()
    begin
        Observer.Observe('r', 'not called');
        Observer.Finish();
    end;
}

codeunit 94260 "LT Y81 Label Variant S2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : 'literal');
    end;

    local procedure Describe(V: Variant): Text
    begin
        exit(Format(V.IsText()));
    end;

    [Test]
    procedure Y81_LabelVariantS2()
    begin
        Observer.Observe('r', Format(Describe(R(true))));
        Observer.Finish();
    end;
}

codeunit 94261 "LT Y81 Label Variant S3"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean): Variant
    begin
        exit(Cond ? 'literal' : LblA);
    end;

    [Test]
    procedure Y81_LabelVariantS3()
    begin
        Observer.Observe('r', 'not called');
        Observer.Finish();
    end;
}

codeunit 94262 "LT Y81 Label Variant S4"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean): Variant
    begin
        exit(Cond ? LblA : LblB);
    end;

    [Test]
    procedure Y81_LabelVariantS4()
    begin
        Observer.Observe('r', 'not called');
        Observer.Finish();
    end;
}

codeunit 94263 "LT Y81 Label Variant S5"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean): Text
    begin
        exit(Cond ? LblA : 'literal');
    end;

    [Test]
    procedure Y81_LabelVariantS5()
    begin
        Observer.Observe('r', R(true));
        Observer.Finish();
    end;
}

codeunit 94264 "LT Y81 Label Variant S6"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean) V: Variant
    begin
        V := Cond ? LblA : 'literal';
    end;

    [Test]
    procedure Y81_LabelVariantS6()
    begin
        Observer.Observe('r', 'not called');
        Observer.Finish();
    end;
}

codeunit 94265 "LT Y81 Label Variant S7"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        LblA: Label 'Label A';
        LblB: Label 'Label B';

    local procedure R(Cond: Boolean): Variant
    begin
        exit('literal');
    end;

    [Test]
    procedure Y81_LabelVariantS7()
    begin
        Observer.Observe('r', 'not called');
        Observer.Finish();
    end;
}

