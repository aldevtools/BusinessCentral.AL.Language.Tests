// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), enum 89960, own table 89961, test codeunit 89962
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Option to Decimal implicit assignment (Option field to Decimal field, Option variable, Enum value) gives the ordinal; arithmetic, comparison, argument, Validate, Format/Evaluate of the ordinal (al-runner issue 6060)
// BC versions: 29 (27 and 28 by CI)

enum 89960 "LT TL Kind"
{
    Extensible = true;
    value(0; Salary) { }
    value(1; Bonus) { }
    value(5; Age) { }
}

table 89961 "LT TL Rec"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = Salary,Bonus,Age; }
        field(3; Amount; Decimal) { }
        field(4; EnumKind; Enum "LT TL Kind") { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 89962 "LT TL Option To Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TakeDecimal(D: Decimal): Text
    begin
        exit(Format(D));
    end;

    [Test]
    procedure OptionField_ToDecimalField()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT TL Rec";
        Target: Record "LT TL Rec" temporary;
    begin
        Source.Kind := Source.Kind::Age;
        Target.Amount := Source.Kind;
        Observer.Observe('age', Format(Target.Amount));
        Source.Kind := Source.Kind::Salary;
        Target.Amount := Source.Kind;
        Observer.Observe('salary', Format(Target.Amount));
        Source.Kind := Source.Kind::Bonus;
        Target.Amount := Source.Kind;
        Observer.Observe('bonus', Format(Target.Amount));
        Observer.Expect('age', '2');
        Observer.Expect('salary', '0');
        Observer.Expect('bonus', '1');
        Observer.Verify();
    end;

    [Test]
    procedure OptionVariable_ToDecimalVariable()
    var
        Observer: Codeunit "Probe Observer";
        O: Option A,B,C;
        D: Decimal;
    begin
        O := O::C;
        D := O;
        Observer.Observe('c', Format(D));
        O := O::A;
        D := O;
        Observer.Observe('a', Format(D));
        Observer.Expect('c', '2');
        Observer.Expect('a', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EnumValue_ToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        K: Enum "LT TL Kind";
        D: Decimal;
    begin
        K := K::Age;
        D := K;
        Observer.Observe('var', Format(D));
        D := "LT TL Kind"::Bonus;
        Observer.Observe('literal', Format(D));
        Observer.Expect('var', '5');
        Observer.Expect('literal', '1');
        Observer.Verify();
    end;

    [Test]
    procedure EnumField_ToDecimalField()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT TL Rec";
        Target: Record "LT TL Rec" temporary;
    begin
        Source.EnumKind := Source.EnumKind::Age;
        Target.Amount := Source.EnumKind;
        Observer.Observe('enumfield', Format(Target.Amount));
        Observer.Expect('enumfield', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Arithmetic_WithOrdinal()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT TL Rec";
        D: Decimal;
        O: Option A,B,C;
    begin
        Source.Kind := Source.Kind::Age;
        O := O::C;
        D := Source.Kind * 2.5;
        Observer.Observe('field*2.5', Format(D));
        D := O / 4;
        Observer.Observe('var/4', Format(D));
        D := 0.5;
        D := D + Source.Kind;
        Observer.Observe('0.5+field', Format(D));
        D := 10;
        D -= O;
        Observer.Observe('10-=var', Format(D));
        Observer.Observe('eq', Format(Source.Kind = 2));
        Observer.Expect('field*2.5', '5');
        Observer.Expect('var/4', '0.5');
        Observer.Expect('0.5+field', '2.5');
        Observer.Expect('10-=var', '8');
        Observer.Expect('eq', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Argument_AndValidate()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT TL Rec";
        Target: Record "LT TL Rec";
        O: Option A,B,C;
    begin
        Source.Kind := Source.Kind::Age;
        O := O::B;
        Observer.Observe('arg field', TakeDecimal(Source.Kind));
        Observer.Observe('arg var', TakeDecimal(O));
        Target.Validate(Amount, Source.Kind);
        Observer.Observe('validate', Format(Target.Amount));
        Observer.Expect('arg field', '2');
        Observer.Expect('arg var', '1');
        Observer.Expect('validate', '2');
        Observer.Verify();
    end;

    [Test]
    procedure FormatAndEvaluate_Ordinal()
    var
        Observer: Codeunit "Probe Observer";
        Source: Record "LT TL Rec";
        D: Decimal;
        Ok: Boolean;
    begin
        Source.Kind := Source.Kind::Age;
        D := Source.Kind;
        Observer.Observe('format', Format(D));
        Observer.Observe('format option', Format(Source.Kind));
        Ok := Evaluate(D, Format(Source.Kind, 0, 2));
        Observer.Observe('evaluate ordinal', Format(Ok) + '/' + Format(D));
        Ok := Evaluate(D, Format(Source.Kind));
        Observer.Observe('evaluate name', Format(Ok));
        Observer.Expect('format', '2');
        Observer.Expect('format option', 'Age');
        Observer.Expect('evaluate ordinal', 'Yes/2');
        Observer.Expect('evaluate name', 'No');
        Observer.Verify();
    end;
}
