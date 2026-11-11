// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonvalue/jsonvalue-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: observe form, measured by the corpus CI matrix (BC 27.5, 28.5, 29.0).
// Facts: what every typed getter of JsonValue (AsBoolean, AsInteger, AsBigInteger, AsDecimal, AsText, AsCode, AsChar, AsByte,
//   AsOption, AsDate, AsTime, AsDateTime, AsDuration) does on a JSON null: a null read from text, a JsonValue never assigned, and a
//   JsonValue after SetValueToNull. Each getter answers a value or raises an error (text and code observed). The null read from
//   text is the repro of aldevtools/BusinessCentral.AL.Runner#7778 and #7775 (Part A, item 6).
// BC versions: 27.5, 28.5, 29.0

codeunit 77110 "JSN Null Getters Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGet(V: JsonValue; Getter: Text; var Result: Text)
    begin
        case Getter of
            'boolean':
                Result := Format(V.AsBoolean());
            'integer':
                Result := Format(V.AsInteger());
            'biginteger':
                Result := Format(V.AsBigInteger());
            'decimal':
                Result := Format(V.AsDecimal());
            'text':
                Result := V.AsText();
            'code':
                Result := V.AsCode();
            'char':
                Result := Format(V.AsChar());
            'byte':
                Result := Format(V.AsByte());
            'option':
                Result := Format(V.AsOption());
            'date':
                Result := Format(V.AsDate(), 0, 9);
            'time':
                Result := Format(V.AsTime(), 0, 9);
            'datetime':
                Result := Format(V.AsDateTime(), 0, 9);
            'duration':
                Result := Format(V.AsDuration());
        end;
    end;

    local procedure ObserveGetter(var Observer: Codeunit "Probe Observer"; V: JsonValue; Getter: Text)
    var
        Result: Text;
    begin
        ClearLastError();
        if TryGet(V, Getter, Result) then
            Observer.Observe(Getter, 'ok:' + Result)
        else
            Observer.Observe(Getter, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; V: JsonValue)
    begin
        Observer.Observe('isnull', Format(V.IsNull()));
        Observer.Observe('isundefined', Format(V.IsUndefined()));
        ObserveGetter(Observer, V, 'boolean');
        ObserveGetter(Observer, V, 'integer');
        ObserveGetter(Observer, V, 'biginteger');
        ObserveGetter(Observer, V, 'decimal');
        ObserveGetter(Observer, V, 'text');
        ObserveGetter(Observer, V, 'code');
        ObserveGetter(Observer, V, 'char');
        ObserveGetter(Observer, V, 'byte');
        ObserveGetter(Observer, V, 'option');
        ObserveGetter(Observer, V, 'date');
        ObserveGetter(Observer, V, 'time');
        ObserveGetter(Observer, V, 'datetime');
        ObserveGetter(Observer, V, 'duration');
    end;

    [Test]
    procedure NullFromText_EveryGetter()
    var
        Observer: Codeunit "Probe Observer";
        J: JsonObject;
        T: JsonToken;
    begin
        J.ReadFrom('{"a":null}');
        J.Get('a', T);
        ObserveAll(Observer, T.AsValue());
        Observer.Finish();
    end;

    [Test]
    procedure NeverAssigned_EveryGetter()
    var
        Observer: Codeunit "Probe Observer";
        V: JsonValue;
    begin
        ObserveAll(Observer, V);
        Observer.Finish();
    end;

    [Test]
    procedure SetValueToNull_EveryGetter()
    var
        Observer: Codeunit "Probe Observer";
        V: JsonValue;
    begin
        V.SetValue(5);
        V.SetValueToNull();
        ObserveAll(Observer, V);
        Observer.Finish();
    end;
}
