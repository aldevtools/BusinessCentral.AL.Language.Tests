// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfrom-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 80504
// Probe: observe probe; every literal asserted below is what the corpus CI service tiers produced.
// Facts: JsonObject.ReadFrom(Text) / JsonArray.ReadFrom(Text) with a // line comment (before a value, after a value, at the end without a line break),
// an empty array element inside an object, Infinity / -Infinity / NaN as property values, and numbers with leading zeros and a fraction: the Boolean
// returned, the text written back and the JSON type of the value. JsonReadFrom.al pins /* */ comments, [1,,2], [Infinity] and [01].
// BC versions: 27, 28, 29 (corpus CI)

codeunit 80504 "LT AY Json ReadFrom Tolerant"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryObj(Src: Text; var O: JsonObject; var Ret: Boolean)
    begin
        Ret := O.ReadFrom(Src);
    end;

    [TryFunction]
    local procedure TryArr(Src: Text; var A: JsonArray; var Ret: Boolean)
    begin
        Ret := A.ReadFrom(Src);
    end;

    local procedure Kind(T: JsonToken): Text
    var
        V: JsonValue;
    begin
        if T.IsObject() then
            exit('object');
        if T.IsArray() then
            exit('array');
        V := T.AsValue();
        if V.IsNull() then
            exit('null');
        if V.IsUndefined() then
            exit('undefined');
        exit('value');
    end;

    local procedure Obj(var Observer: Codeunit "Probe Observer"; ObsKey: Text; Src: Text)
    var
        O: JsonObject;
        T: JsonToken;
        Ret: Boolean;
        Out: Text;
    begin
        ClearLastError();
        if TryObj(Src, O, Ret) then begin
            O.WriteTo(Out);
            if O.Get('a', T) then
                Out += ' a:' + Kind(T);
            Observer.Observe(ObsKey, Format(Ret) + ' ' + Out);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure Arr(var Observer: Codeunit "Probe Observer"; ObsKey: Text; Src: Text)
    var
        A: JsonArray;
        T: JsonToken;
        Ret: Boolean;
        Out: Text;
    begin
        ClearLastError();
        if TryArr(Src, A, Ret) then begin
            A.WriteTo(Out);
            if A.Get(0, T) then
                Out += ' 0:' + Kind(T) + '/' + Format(T);
            Observer.Observe(ObsKey, Format(Ret) + ' ' + Out);
        end else
            Observer.ObserveError(ObsKey);
    end;

    local procedure Lf(): Text
    var
        C: Char;
    begin
        C := 10;
        exit(Format(C));
    end;

    [Test]
    procedure ReadFrom_LineComments_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obj(Observer, 'comment_after_value', '{"a":1 // c' + Lf() + '}');
        Obj(Observer, 'comment_before_key', '{// c' + Lf() + '"a":1}');
        Obj(Observer, 'comment_at_end_no_lf', '{"a":1} // c');
        Observer.Expect('comment_after_value', 'Yes {"a":1} a:value');
        Observer.Expect('comment_before_key', 'Yes {"a":1} a:value');
        Observer.Expect('comment_at_end_no_lf', 'Yes {"a":1} a:value');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_LineComments_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obj(Observer, 'comment_unclosed_object', '{"a":1 // c }');
        Obj(Observer, 'comment_in_string', '{"a":"x // y"}');
        Arr(Observer, 'arr_comment', '[1, // c' + Lf() + '2]');
        Observer.Expect('comment_unclosed_object', 'No {}');
        Observer.Expect('comment_in_string', 'Yes {"a":"x // y"} a:value');
        Observer.Expect('arr_comment', 'Yes [1,2] 0:value/1');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_EmptyElementsAndSpecialNumbers_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obj(Observer, 'obj_empty_elem', '{"a":[1,,2]}');
        Obj(Observer, 'obj_only_comma', '{"a":[,]}');
        Obj(Observer, 'obj_infinity', '{"a":Infinity}');
        Observer.Expect('obj_empty_elem', 'Yes {"a":[1,undefined,2]} a:array');
        Observer.Expect('obj_only_comma', 'Yes {"a":[undefined]} a:array');
        Observer.Expect('obj_infinity', 'Yes {"a":"Infinity"} a:value');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_EmptyElementsAndSpecialNumbers_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Obj(Observer, 'obj_neg_infinity', '{"a":-Infinity}');
        Obj(Observer, 'obj_nan', '{"a":NaN}');
        Arr(Observer, 'arr_neg_infinity', '[-Infinity]');
        Observer.Expect('obj_neg_infinity', 'Yes {"a":"-Infinity"} a:value');
        Observer.Expect('obj_nan', 'Yes {"a":"NaN"} a:value');
        Observer.Expect('arr_neg_infinity', 'Yes ["-Infinity"] 0:value/"-Infinity"');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_LeadingZerosWithFraction_1()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Arr(Observer, 'zero_one_point_five', '[01.5]');
        Arr(Observer, 'zero_zero_point_five', '[00.5]');
        Arr(Observer, 'zero_zero_seven', '[007]');
        Observer.Expect('zero_one_point_five', 'No []');
        Observer.Expect('zero_zero_point_five', 'No []');
        Observer.Expect('zero_zero_seven', 'Yes [7] 0:value/7');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_LeadingZerosWithFraction_2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Arr(Observer, 'neg_zero_one_point_five', '[-01.5]');
        Arr(Observer, 'zero_one_e2', '[01e2]');
        Obj(Observer, 'obj_zero_one_point_five', '{"a":01.50}');
        Observer.Expect('neg_zero_one_point_five', 'Yes [-1.5] 0:value/-1.5');
        Observer.Expect('zero_one_e2', 'No []');
        Observer.Expect('obj_zero_one_point_five', 'No {}');
        Observer.Verify();
    end;
}
