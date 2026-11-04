// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/enum/enum-fromInteger-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); enum 67070
// Probe: Enum.FromInteger with a Variant argument: a Variant that holds an Integer, an Enum value, an Option-like Text and a Decimal. Outcome (value or error
// text and code) of each. Complements the plain FromInteger probes. Object ids 67070 - 67071.

enum 67070 "LT FI Color"
{
    Extensible = true;

    value(0; Red) { }
    value(1; Green) { }
    value(5; Blue) { }
}

codeunit 67071 "LT FI Variant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFromVariant(Source: Variant; var Result: Text)
    var
        Color: Enum "LT FI Color";
    begin
        Color := Enum::"LT FI Color".FromInteger(Source);
        Result := Format(Color) + '|' + Format(Color.AsInteger());
    end;

    local procedure Outcome(Source: Variant): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFromVariant(Source, Result) then
            exit('ok:' + Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure FromInteger_VariantHolding()
    var
        Observer: Codeunit "Probe Observer";
        IntValue: Integer;
        DecValue: Decimal;
        TextValue: Text;
        Color: Enum "LT FI Color";
    begin
        IntValue := 5;
        DecValue := 1;
        TextValue := '1';
        Color := Color::Green;
        Observer.Observe('integer', Outcome(IntValue));
        Observer.Observe('integer_undefined', Outcome(7));
        Observer.Observe('enum', Outcome(Color));
        Observer.Observe('decimal', Outcome(DecValue));
        Observer.Observe('text', Outcome(TextValue));
        Observer.Expect('integer', 'ok:Blue|5');
        Observer.Expect('integer_undefined', 'ok:7|7');
        Observer.Expect('enum', 'ok:Green|1');
        Observer.Expect('decimal', 'ok:Green|1');
        Observer.Expect('text', 'ok:Green|1');
        Observer.Verify();
    end;
}
