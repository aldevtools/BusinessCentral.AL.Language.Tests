// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: leads of corpus issue 671 (part F, items 35, 38-42, 45): an array of JsonObject, the Decimal range through JSON, a many-digit Decimal round trip,
// Clear on a JsonObject / JsonArray that another variable also holds, ReadFrom on an object that sits inside a parent, a named JsonObject return value
// that the procedure never sets, and JsonArray.Add of an object that is cleared and filled again.
// Facts: see the Expect lines of each test.
// BC versions: 27, 28, 29

codeunit 85722 "LT DB Json Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Txt(O: JsonObject) Result: Text
    begin
        O.WriteTo(Result);
    end;

    local procedure TxtA(A: JsonArray) Result: Text
    begin
        A.WriteTo(Result);
    end;

    // Each step ends in Error('ok: ...') and runs under asserterror: in a first draft on a local BC 29 tier the Decimal range error of GetDecimal
    // ended the test although the call was inside a [TryFunction] (not asserted here).
    local procedure StepRead(Json: Text)
    var
        O: JsonObject;
        T: JsonToken;
        Written: Text;
    begin
        O.ReadFrom(Json);
        O.Get('d', T);
        T.WriteTo(Written);
        Error('ok: %1', Written);
    end;

    local procedure StepGetDecimal(Json: Text)
    var
        O: JsonObject;
        D: Decimal;
    begin
        O.ReadFrom(Json);
        D := O.GetDecimal('d');
        Error('ok: %1', Format(D, 0, 9));
    end;

    local procedure StepAsDecimal(Json: Text)
    var
        O: JsonObject;
        T: JsonToken;
        D: Decimal;
    begin
        O.ReadFrom(Json);
        O.Get('d', T);
        D := T.AsValue().AsDecimal();
        Error('ok: %1', Format(D, 0, 9));
    end;

    // Issue 671 item 38 (microsoft/AL#6172): ReadFrom, GetDecimal and AsValue().AsDecimal() on a number at and beyond the Decimal range.
    local procedure ReadDecimal(var Observer: Codeunit "Probe Observer"; Name: Text; Json: Text)
    begin
        asserterror StepRead(Json);
        Observer.ObserveError(Name + '_read');
        asserterror StepGetDecimal(Json);
        Observer.ObserveError(Name + '_get');
        asserterror StepAsDecimal(Json);
        Observer.ObserveError(Name + '_as');
    end;

    local procedure StepSetValue(D: Decimal)
    var
        V: JsonValue;
        T: Text;
    begin
        V.SetValue(D);
        V.WriteTo(T);
        Error('ok: %1 back %2', T, Format(V.AsDecimal(), 0, 9));
    end;

    local procedure StepAdd(D: Decimal)
    var
        O: JsonObject;
        T: Text;
    begin
        O.Add('d', D);
        O.WriteTo(T);
        Error('ok: %1 get %2', T, Format(O.GetDecimal('d'), 0, 9));
    end;

    local procedure StepMoreDigitLiteral()
    var
        D: Decimal;
    begin
        D := -9999999999999999.99;
        Error('ok: %1', Format(D, 0, 9));
    end;

    local procedure NewObjNamed() NewObj: JsonObject
    begin
    end;

    local procedure NewArrNamed() NewArr: JsonArray
    begin
    end;

    local procedure NewObjUnnamed(): JsonObject
    begin
    end;

    [TryFunction]
    local procedure TryAddP(var O: JsonObject)
    begin
        O.Add('p', 42);
    end;

    [TryFunction]
    local procedure TryAddArr(var A: JsonArray)
    begin
        A.Add(42);
    end;

    [Test]
    procedure ArrayOfJsonObject_ElementsAreSeparate()
    // Issue 671 item 35 (microsoft/AL#6279): do the slots of an Array[3] of JsonObject share one object?
    var
        Observer: Codeunit "Probe Observer";
        MyArray: array[3] of JsonObject;
        Added: array[3] of JsonObject;
    begin
        MyArray[1].ReadFrom('{"a":1}');
        MyArray[2].ReadFrom('{"b":2}');
        MyArray[3].ReadFrom('{"c":3}');
        Observer.Observe('read1_contains_a', Format(MyArray[1].Contains('a')));
        Observer.Observe('read1_contains_c', Format(MyArray[1].Contains('c')));
        Observer.Observe('read1', Txt(MyArray[1]));
        Observer.Observe('read2', Txt(MyArray[2]));
        Observer.Observe('read3', Txt(MyArray[3]));
        Added[1].Add('a', 1);
        Added[2].Add('b', 2);
        Added[3].Add('c', 3);
        Observer.Observe('add1', Txt(Added[1]));
        Observer.Observe('add2', Txt(Added[2]));
        Observer.Observe('add3', Txt(Added[3]));
        Added[2] := Added[1];
        Added[2].Add('x', 9);
        Observer.Observe('assigned_slot1', Txt(Added[1]));
        Observer.Observe('assigned_slot2', Txt(Added[2]));
        Clear(MyArray);
        Observer.Observe('cleared1', Txt(MyArray[1]));
        Observer.Observe('cleared3', Txt(MyArray[3]));
        Observer.Expect('read1_contains_a', 'Yes');
        Observer.Expect('read1_contains_c', 'No');
        Observer.Expect('read1', '{"a":1}');
        Observer.Expect('read2', '{"b":2}');
        Observer.Expect('read3', '{"c":3}');
        Observer.Expect('add1', '{"a":1}');
        Observer.Expect('add2', '{"b":2}');
        Observer.Expect('add3', '{"c":3}');
        Observer.Expect('assigned_slot1', '{"a":1,"x":9}');
        Observer.Expect('assigned_slot2', '{"a":1,"x":9}');
        Observer.Expect('cleared1', '{"a":1}');
        Observer.Expect('cleared3', '{"c":3}');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalRange_ReadFrom()
    // Issue 671 item 38 (microsoft/AL#6172).
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadDecimal(Observer, 'min', '{"d":-999999999999999.99}');
        ReadDecimal(Observer, 'max', '{"d":999999999999999.99}');
        ReadDecimal(Observer, 'min_more_digit', '{"d":-9999999999999999.99}');
        Observer.Expect('min_read|text', 'ok: -1000000000000000.0');
        Observer.Expect('min_read|code', 'Dialog');
        Observer.Expect('min_get|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: -1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('min_get|code', 'OutsidePermittedRange');
        Observer.Expect('min_as|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: -1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('min_as|code', 'OutsidePermittedRange');
        Observer.Expect('max_read|text', 'ok: 1000000000000000.0');
        Observer.Expect('max_read|code', 'Dialog');
        Observer.Expect('max_get|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('max_get|code', 'OutsidePermittedRange');
        Observer.Expect('max_as|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('max_as|code', 'OutsidePermittedRange');
        Observer.Expect('min_more_digit_read|text', 'ok: -10000000000000000.0');
        Observer.Expect('min_more_digit_read|code', 'Dialog');
        Observer.Expect('min_more_digit_get|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: -10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('min_more_digit_get|code', 'OutsidePermittedRange');
        Observer.Expect('min_more_digit_as|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: -10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('min_more_digit_as|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalRange_ReadFrom_Beyond()
    // Issue 671 item 38: numbers beyond the Decimal range.
    var
        Observer: Codeunit "Probe Observer";
    begin
        ReadDecimal(Observer, 'max_more_digit', '{"d":9999999999999999.99}');
        ReadDecimal(Observer, 'net_max', '{"d":79228162514264337593543950335}');
        ReadDecimal(Observer, 'exp40', '{"d":1e40}');
        Observer.Expect('max_more_digit_read|text', 'ok: 10000000000000000.0');
        Observer.Expect('max_more_digit_read|code', 'Dialog');
        Observer.Expect('max_more_digit_get|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('max_more_digit_get|code', 'OutsidePermittedRange');
        Observer.Expect('max_more_digit_as|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 10,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('max_more_digit_as|code', 'OutsidePermittedRange');
        Observer.Expect('net_max_read|text', 'ok: 79228162514264337593543950335');
        Observer.Expect('net_max_read|code', 'Dialog');
        Observer.Expect('net_max_get|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 79,228,162,514,264,337,500,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('net_max_get|code', 'OutsidePermittedRange');
        Observer.Expect('net_max_as|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 79,228,162,514,264,337,500,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('net_max_as|code', 'OutsidePermittedRange');
        Observer.Expect('exp40_read|text', 'ok: 1E+40');
        Observer.Expect('exp40_read|code', 'Dialog');
        Observer.Expect('exp40_get|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('exp40_get|code', 'Conversion');
        Observer.Expect('exp40_as|text', 'Unable to convert from Microsoft.Dynamics.Nav.Runtime.NavJsonValue to Microsoft.Dynamics.Nav.Runtime.Decimal18.');
        Observer.Expect('exp40_as|code', 'Conversion');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalRange_SetValueAndAdd()
    // Issue 671 item 38 (microsoft/AL#6172): the range ends written through JsonValue.SetValue and JsonObject.Add, read back.
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror StepSetValue(-999999999999999.99);
        Observer.ObserveError('setvalue_min');
        asserterror StepSetValue(999999999999999.99);
        Observer.ObserveError('setvalue_max');
        asserterror StepAdd(-999999999999999.99);
        Observer.ObserveError('add_min');
        asserterror StepAdd(999999999999999.99);
        Observer.ObserveError('add_max');
        asserterror StepMoreDigitLiteral();
        Observer.ObserveError('more_digit_literal');
        Observer.Expect('setvalue_min|text', 'ok: -999999999999999.99 back -999999999999999.99');
        Observer.Expect('setvalue_min|code', 'Dialog');
        Observer.Expect('setvalue_max|text', 'ok: 999999999999999.99 back 999999999999999.99');
        Observer.Expect('setvalue_max|code', 'Dialog');
        Observer.Expect('add_min|text', 'ok: {"d":-999999999999999.99} get -999999999999999.99');
        Observer.Expect('add_min|code', 'Dialog');
        Observer.Expect('add_max|text', 'ok: {"d":999999999999999.99} get 999999999999999.99');
        Observer.Expect('add_max|code', 'Dialog');
        Observer.Expect('more_digit_literal|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: -9,999,999,999,999,999.99. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('more_digit_literal|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure DecimalManyDigits_RoundTrip()
    // Issue 671 item 39 (microsoft/AL#7236): Add, WriteTo, ReadFrom and GetDecimal of a Decimal with 24 decimal places.
    var
        Observer: Codeunit "Probe Observer";
        J: JsonObject;
        J2: JsonObject;
        V: JsonValue;
        D: Decimal;
        D2: Decimal;
        T: Text;
    begin
        D := 0.123456789011111111111111;
        Observer.Observe('source', Format(D, 0, 9));
        J.Add('d', D);
        J.WriteTo(T);
        Observer.Observe('writeto', T);
        J2.ReadFrom(T);
        D2 := J2.GetDecimal('d');
        Observer.Observe('readback', Format(D2, 0, 9));
        Observer.Observe('equal', Format(D = D2));
        V.SetValue(D);
        V.WriteTo(T);
        Observer.Observe('value_writeto', T);
        J2.ReadFrom('{"d":0.123456789011111111111111}');
        Observer.Observe('read_literal', Format(J2.GetDecimal('d'), 0, 9));
        Observer.Observe('read_literal_text', Txt(J2));
        Observer.Expect('source', '0.123456789011111111');
        Observer.Expect('writeto', '{"d":0.123456789011111111}');
        Observer.Expect('readback', '0.123456789011111');
        Observer.Expect('equal', 'No');
        Observer.Expect('value_writeto', '0.123456789011111111');
        Observer.Expect('read_literal', '0.123456789011111');
        Observer.Expect('read_literal_text', '{"d":0.12345678901111111}');
        Observer.Verify();
    end;

    [Test]
    procedure Clear_ObjectAndArray_SharedVariable()
    // Issue 671 item 40 (microsoft/AL#1440): Clear(variable) on a JsonObject / JsonArray that a second variable also holds.
    // JsonObject and JsonArray have no RemoveAll and no Clear() method: must-not-compile cases 1816 to 1819.
    var
        Observer: Codeunit "Probe Observer";
        O: JsonObject;
        AliasO: JsonObject;
        A: JsonArray;
        AliasA: JsonArray;
    begin
        O.Add('a', 1);
        O.Add('b', 2);
        AliasO := O;
        Clear(O);
        Observer.Observe('obj_count', Format(O.Keys().Count()));
        Observer.Observe('obj', Txt(O));
        Observer.Observe('alias_obj', Txt(AliasO));
        O.Add('c', 3);
        Observer.Observe('obj_after_add', Txt(O));
        Observer.Observe('alias_obj_after_add', Txt(AliasO));
        A.Add(1);
        A.Add(2);
        AliasA := A;
        Clear(A);
        Observer.Observe('arr_count', Format(A.Count()));
        Observer.Observe('arr', TxtA(A));
        Observer.Observe('alias_arr', TxtA(AliasA));
        Observer.Expect('obj_count', '0');
        Observer.Expect('obj', '{}');
        Observer.Expect('alias_obj', '{"a":1,"b":2}');
        Observer.Expect('obj_after_add', '{"c":3}');
        Observer.Expect('alias_obj_after_add', '{"a":1,"b":2}');
        Observer.Expect('arr_count', '0');
        Observer.Expect('arr', '[]');
        Observer.Expect('alias_arr', '[1,2]');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_ChildInsideParent()
    // Issue 671 item 41 (Learn: ReadFrom replaces the content): ReadFrom on an object (and an array) that a parent holds.
    var
        Observer: Codeunit "Probe Observer";
        Parent: JsonObject;
        Child: JsonObject;
        ChildArr: JsonArray;
        Tok: JsonToken;
        ViaToken: JsonObject;
    begin
        Child.Add('a', 1);
        Parent.Add('in', Child);
        Child.Add('b', 2);
        Observer.Observe('shared_before', Txt(Parent));
        Child.ReadFrom('{"z":9}');
        Observer.Observe('parent_after_read', Txt(Parent));
        Observer.Observe('child_after_read', Txt(Child));
        Child.Add('after', 1);
        Observer.Observe('parent_after_child_add', Txt(Parent));
        Parent.Get('in', Tok);
        ViaToken := Tok.AsObject();
        ViaToken.ReadFrom('{"t":7}');
        Observer.Observe('parent_after_token_read', Txt(Parent));
        ChildArr.Add(1);
        Parent.Add('arr', ChildArr);
        ChildArr.ReadFrom('[5,6]');
        Observer.Observe('parent_after_array_read', Txt(Parent));
        Observer.Observe('array_after_read', TxtA(ChildArr));
        Observer.Expect('shared_before', '{"in":{"a":1,"b":2}}');
        Observer.Expect('parent_after_read', '{"in":{"a":1,"b":2}}');
        Observer.Expect('child_after_read', '{"z":9}');
        Observer.Expect('parent_after_child_add', '{"in":{"a":1,"b":2}}');
        Observer.Expect('parent_after_token_read', '{"in":{"a":1,"b":2}}');
        Observer.Expect('parent_after_array_read', '{"in":{"a":1,"b":2},"arr":[1]}');
        Observer.Expect('array_after_read', '[5,6]');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_FailedOnChildInsideParent()
    // Issue 671 item 41: a ReadFrom that fails (return value used) on an object that a parent holds.
    var
        Observer: Codeunit "Probe Observer";
        Parent: JsonObject;
        Child: JsonObject;
    begin
        Child.Add('a', 1);
        Parent.Add('in', Child);
        Observer.Observe('ret', Format(Child.ReadFrom('garbage')));
        Observer.Observe('child', Txt(Child));
        Child.Add('b', 2);
        Observer.Observe('parent_after_child_add', Txt(Parent));
        Observer.Expect('ret', 'No');
        Observer.Expect('child', '{"a":1}');
        Observer.Expect('parent_after_child_add', '{"in":{"a":1,"b":2}}');
        Observer.Verify();
    end;

    [Test]
    procedure NamedReturnJsonObject_NeverSet()
    // Issue 671 item 42 (microsoft/AL#6801): a named JsonObject / JsonArray return value the procedure never sets.
    var
        Observer: Codeunit "Probe Observer";
        J: JsonObject;
        J2: JsonObject;
        A: JsonArray;
    begin
        J := NewObjNamed();
        ClearLastError();
        if TryAddP(J) then
            Observer.Observe('named_add', 'ok ' + Txt(J))
        else
            Observer.ObserveError('named_add');
        Observer.Observe('named_count', Format(J.Keys().Count()));
        J2 := NewObjUnnamed();
        if TryAddP(J2) then
            Observer.Observe('unnamed_add', 'ok ' + Txt(J2))
        else
            Observer.ObserveError('unnamed_add');
        A := NewArrNamed();
        if TryAddArr(A) then
            Observer.Observe('named_array_add', 'ok ' + TxtA(A))
        else
            Observer.ObserveError('named_array_add');
        Observer.Expect('named_add', 'ok {"p":42}');
        Observer.Expect('named_count', '1');
        Observer.Expect('unnamed_add', 'ok {"p":42}');
        Observer.Expect('named_array_add', 'ok [42]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayAdd_ClearAndRefill_Loop()
    // Issue 671 item 45 (microsoft/AL#900): JArray.Add(JObject); Clear(JObject); JObject.Add('x', 1); JArray.Add(JObject), and a change to the object after Add.
    var
        Observer: Codeunit "Probe Observer";
        JArray: JsonArray;
        JObject: JsonObject;
        I: Integer;
    begin
        JObject.Add('x', 0);
        for I := 1 to 3 do begin
            JArray.Add(JObject);
            Clear(JObject);
            JObject.Add('x', I);
        end;
        Observer.Observe('loop_clear', TxtA(JArray));
        Clear(JArray);
        Clear(JObject);
        JObject.Add('x', 0);
        JArray.Add(JObject);
        JObject.Add('y', 1);
        Observer.Observe('change_after_add', TxtA(JArray));
        JArray.Add(JObject);
        JObject.Add('z', 2);
        Observer.Observe('add_again_then_change', TxtA(JArray));
        Observer.Expect('loop_clear', '[{"x":0},{"x":1},{"x":2}]');
        Observer.Expect('change_after_add', '[{"x":0,"y":1}]');
        Observer.Expect('add_again_then_change', '[{"x":0,"y":1,"z":2},{"x":0,"y":1}]');
        Observer.Verify();
    end;
}
