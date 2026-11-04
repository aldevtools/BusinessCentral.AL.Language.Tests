// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: own enum 72292, table 72291, codeunit 72293
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Added by writer BN3 (corpus #664 item 39): table 83850 and BN3_ValuesAllowed_DecimalSpaceAfterMinus (ValuesAllowed on a Decimal field is not checked by Validate).

enum 72292 "LT P123 Kind"
{
    Extensible = false;
    value(0; Open) { }
    value(1; Released) { }
    value(2; Closed) { }
}

table 72291 "LT P123 VA"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT P123 Kind") { ValuesAllowed = Open, Released; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72293 "LT P123 TValuesAllowed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P123_ValuesAllowedOnTableField()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT P123 VA";
    begin
        T.DeleteAll();
        T.Init(); T.Id := 1;
        T.Validate(Kind, T.Kind::Released);
        Observer.Observe('allowed validate', Format(T.Kind));
        T.Validate(Kind, T.Kind::Closed);
        Observer.Observe('disallowed validate', 'no error');
        T.Kind := T.Kind::Closed;
        Observer.Observe('assign disallowed', Format(T.Kind));
        T.Insert();
        Observer.Observe('insert disallowed count', Format(T.Count()));
        Observer.Expect('allowed validate', 'Released');
        Observer.Expect('disallowed validate', 'no error');
        Observer.Expect('assign disallowed', 'Closed');
        Observer.Expect('insert disallowed count', '1');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure BN3_TryValidateSpaced(var T: Record "LT BN3 VA Dec"; V: Decimal)
    begin
        T.Validate(Spaced, V);
    end;

    [TryFunction]
    local procedure BN3_TryValidatePlain(var T: Record "LT BN3 VA Dec"; V: Decimal)
    begin
        T.Validate(Plain, V);
    end;

    local procedure BN3_Outcome(Ok: Boolean; Value: Decimal): Text
    begin
        if Ok then
            exit('ok|' + Format(Value));
        exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Corpus #664 item 39: `ValuesAllowed = - 0.5, 1` (space after the minus) compiles; Validate of allowed and other values on that field and on `-0.5, 1`.
    [Test]
    procedure BN3_ValuesAllowed_DecimalSpaceAfterMinus()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT BN3 VA Dec";
        Values: List of [Decimal];
        V: Decimal;
    begin
        Values.Add(-0.5);
        Values.Add(1);
        Values.Add(0.5);
        Values.Add(0.7);
        Values.Add(0);
        foreach V in Values do begin
            T.Init();
            Observer.Observe('spaced ' + Format(V), BN3_Outcome(BN3_TryValidateSpaced(T, V), T.Spaced));
            T.Init();
            Observer.Observe('plain ' + Format(V), BN3_Outcome(BN3_TryValidatePlain(T, V), T.Plain));
        end;
        T.Init();
        T.Spaced := 0.7;
        Observer.Observe('assign spaced 0.7', Format(T.Spaced));
        Observer.Expect('spaced -0.5', 'ok|-0.5');
        Observer.Expect('plain -0.5', 'ok|-0.5');
        Observer.Expect('spaced 1', 'ok|1');
        Observer.Expect('plain 1', 'ok|1');
        Observer.Expect('spaced 0.5', 'ok|0.5');
        Observer.Expect('plain 0.5', 'ok|0.5');
        Observer.Expect('spaced 0.7', 'ok|0.7');
        Observer.Expect('plain 0.7', 'ok|0.7');
        Observer.Expect('spaced 0', 'ok|0');
        Observer.Expect('plain 0', 'ok|0');
        Observer.Expect('assign spaced 0.7', '0.7');
        Observer.Verify();
    end;
}

// Corpus #664 item 39 (microsoft/AL issue 3721): ValuesAllowed on a Decimal field with a space between the minus and the number.
table 83850 "LT BN3 VA Dec"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Spaced; Decimal) { ValuesAllowed = - 0.5, 1; }
        field(3; Plain; Decimal) { ValuesAllowed = -0.5, 1; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
