// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfrom-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72505
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Added, measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, run 43121492269; the same on all three): raw and escaped control characters inside JSON strings, in JsonObject, JsonToken,
// JsonArray and JsonValue ReadFrom (TAB, LF, CR, 1, 8, 12, 27, 31, 127), a raw TAB in a key, in a single-quoted string and between tokens.
// BC versions: 29 (27 and 28 by CI)

codeunit 72505 "LT JsT ReadFrom"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure DoReadObj(Json: Text; var R: Text)
    var
        O: JsonObject;
    begin
        O.Add('pre', 1);
        R := 'ret=' + Format(O.ReadFrom(Json)) + ' ';
        O.WriteTo(Json);
        R += Json;
    end;

    local procedure ReadObj(Json: Text): Text
    var
        R: Text;
    begin
        if DoReadObj(Json, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoReadArr(Json: Text; var R: Text)
    var
        A: JsonArray;
    begin
        A.Add(1);
        R := 'ret=' + Format(A.ReadFrom(Json)) + ' ';
        A.WriteTo(Json);
        R += Json;
    end;

    local procedure ReadArr(Json: Text): Text
    var
        R: Text;
    begin
        if DoReadArr(Json, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoReadTok(Json: Text; var R: Text)
    var
        T: JsonToken;
    begin
        R := 'ret=' + Format(T.ReadFrom(Json)) + ' ';
        T.WriteTo(Json);
        R += Json;
    end;

    local procedure ReadTok(Json: Text): Text
    var
        R: Text;
    begin
        if DoReadTok(Json, R) then
            exit('ok:' + R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure ObjectReadFromErrors()
    begin
        Observer.Observe('valid', ReadObj('{"a":1}'));
        Observer.Observe('empty_obj_replaces', ReadObj('{}'));
        Observer.Observe('array', ReadObj('[1]'));
        Observer.Observe('scalar_number', ReadObj('1'));
        Observer.Observe('scalar_string', ReadObj('"x"'));
        Observer.Observe('null', ReadObj('null'));
        Observer.Observe('empty_text', ReadObj(''));
        Observer.Observe('blank', ReadObj('   '));
        Observer.Observe('garbage', ReadObj('abc'));
        Observer.Observe('unclosed', ReadObj('{"a":1'));
        Observer.Observe('trailing_comma', ReadObj('{"a":1,}'));
        Observer.Observe('single_quotes', ReadObj('{''a'':1}'));
        Observer.Observe('unquoted_key', ReadObj('{a:1}'));
        Observer.Observe('trailing_text', ReadObj('{"a":1} x'));
        Observer.Observe('two_objects', ReadObj('{"a":1}{"b":2}'));
        Observer.Observe('missing_value', ReadObj('{"a":}'));
        Observer.Observe('missing_colon', ReadObj('{"a" 1}'));
        Observer.Observe('leading_ws', ReadObj('  {"a":1}  '));
        Observer.Observe('comment', ReadObj('{"a":1/*c*/}'));
        Observer.Expect('valid', 'ok:ret=Yes {"a":1}');
        Observer.Expect('empty_obj_replaces', 'ok:ret=Yes {}');
        Observer.Expect('array', 'ok:ret=No {"pre":1}');
        Observer.Expect('scalar_number', 'ok:ret=No {"pre":1}');
        Observer.Expect('scalar_string', 'ok:ret=No {"pre":1}');
        Observer.Expect('null', 'ok:ret=No {"pre":1}');
        Observer.Expect('empty_text', 'ok:ret=No {"pre":1}');
        Observer.Expect('blank', 'ok:ret=No {"pre":1}');
        Observer.Expect('garbage', 'ok:ret=No {"pre":1}');
        Observer.Expect('unclosed', 'ok:ret=No {"pre":1}');
        Observer.Expect('trailing_comma', 'ok:ret=Yes {"a":1}');
        Observer.Expect('single_quotes', 'ok:ret=Yes {"a":1}');
        Observer.Expect('unquoted_key', 'ok:ret=Yes {"a":1}');
        Observer.Expect('trailing_text', 'ok:ret=Yes {"a":1}');
        Observer.Expect('two_objects', 'ok:ret=Yes {"a":1}');
        Observer.Expect('missing_value', 'ok:ret=No {"pre":1}');
        Observer.Expect('missing_colon', 'ok:ret=No {"pre":1}');
        Observer.Expect('leading_ws', 'ok:ret=Yes {"a":1}');
        Observer.Expect('comment', 'ok:ret=Yes {"a":1}');
        Observer.Verify();
    end;

    [Test]
    procedure ObjectDuplicateAndOrder()
    begin
        Observer.Observe('dup_keys', ReadObj('{"a":1,"a":2}'));
        Observer.Observe('dup_keys_case', ReadObj('{"a":1,"A":2}'));
        Observer.Observe('order', ReadObj('{"z":1,"a":2,"m":3}'));
        Observer.Observe('empty_key', ReadObj('{"":1}'));
        Observer.Observe('nested', ReadObj('{"a":{"b":{"c":[1,{"d":null}]}}}'));
        Observer.Observe('null_value', ReadObj('{"a":null}'));
        Observer.Observe('escapes', ReadObj('{"a":"\"\\\/\b\f\n\r\t"}'));
        Observer.Observe('unicode_escape', ReadObj('{"a":"ä€"}'));
        Observer.Observe('surrogate_pair', ReadObj('{"a":"😀"}'));
        Observer.Observe('bad_escape', ReadObj('{"a":"\x"}'));
        Observer.Observe('bad_unicode_escape', ReadObj('{"a":"\u12"}'));
        Observer.Observe('raw_newline_in_string', ReadObj('{"a":"x' + Lf() + 'y"}'));
        Observer.Expect('dup_keys', 'ok:ret=Yes {"a":2}');
        Observer.Expect('dup_keys_case', 'ok:ret=Yes {"a":1,"A":2}');
        Observer.Expect('order', 'ok:ret=Yes {"z":1,"a":2,"m":3}');
        Observer.Expect('empty_key', 'ok:ret=Yes {"":1}');
        Observer.Expect('nested', 'ok:ret=Yes {"a":{"b":{"c":[1,{"d":null}]}}}');
        Observer.Expect('null_value', 'ok:ret=Yes {"a":null}');
        Observer.Expect('escapes', 'ok:ret=Yes {"a":"\"\\/\b\f\n\r\t"}');
        Observer.Expect('unicode_escape', 'ok:ret=Yes {"a":"ä€"}');
        Observer.Expect('surrogate_pair', 'ok:ret=Yes {"a":"\uD83D\uDE00"}');
        Observer.Expect('bad_escape', 'ok:ret=No {"pre":1}');
        Observer.Expect('bad_unicode_escape', 'ok:ret=No {"pre":1}');
        Observer.Expect('raw_newline_in_string', 'ok:ret=Yes {"a":"x\ny"}');
        Observer.Verify();
    end;

    [Test]
    procedure NumberTextsRoundtrip()
    begin
        Observer.Observe('int', ReadArr('[1]'));
        Observer.Observe('neg', ReadArr('[-1]'));
        Observer.Observe('neg_zero', ReadArr('[-0]'));
        Observer.Observe('zero_point_zero', ReadArr('[0.0]'));
        Observer.Observe('one_point_zero', ReadArr('[1.0]'));
        Observer.Observe('one_point_five_zero', ReadArr('[1.50]'));
        Observer.Observe('exp', ReadArr('[1e3]'));
        Observer.Observe('exp_big', ReadArr('[1E+3]'));
        Observer.Observe('exp_neg', ReadArr('[1e-3]'));
        Observer.Observe('exp_float', ReadArr('[1.5e2]'));
        Observer.Observe('long_int', ReadArr('[9223372036854775807]'));
        Observer.Observe('over_long', ReadArr('[9223372036854775808]'));
        Observer.Observe('huge', ReadArr('[123456789012345678901234567890]'));
        Observer.Observe('many_decimals', ReadArr('[0.1234567890123456789]'));
        Observer.Observe('float_noise', ReadArr('[0.30000000000000004]'));
        Observer.Observe('leading_zero', ReadArr('[01]'));
        Observer.Observe('plus_sign', ReadArr('[+1]'));
        Observer.Observe('dot_start', ReadArr('[.5]'));
        Observer.Observe('dot_end', ReadArr('[5.]'));
        Observer.Observe('nan', ReadArr('[NaN]'));
        Observer.Observe('infinity', ReadArr('[Infinity]'));
        Observer.Observe('hex', ReadArr('[0x10]'));
        Observer.Observe('too_big_exp', ReadArr('[1e400]'));
        Observer.Expect('int', 'ok:ret=Yes [1]');
        Observer.Expect('neg', 'ok:ret=Yes [-1]');
        Observer.Expect('neg_zero', 'ok:ret=Yes [0]');
        Observer.Expect('zero_point_zero', 'ok:ret=Yes [0.0]');
        Observer.Expect('one_point_zero', 'ok:ret=Yes [1.0]');
        Observer.Expect('one_point_five_zero', 'ok:ret=Yes [1.5]');
        Observer.Expect('exp', 'ok:ret=Yes [1000.0]');
        Observer.Expect('exp_big', 'ok:ret=Yes [1000.0]');
        Observer.Expect('exp_neg', 'ok:ret=Yes [0.001]');
        Observer.Expect('exp_float', 'ok:ret=Yes [150.0]');
        Observer.Expect('long_int', 'ok:ret=Yes [9223372036854775807]');
        Observer.Expect('over_long', 'ok:ret=Yes [9223372036854775808]');
        Observer.Expect('huge', 'ok:ret=Yes [123456789012345678901234567890]');
        Observer.Expect('many_decimals', 'ok:ret=Yes [0.12345678901234568]');
        Observer.Expect('float_noise', 'ok:ret=Yes [0.30000000000000004]');
        Observer.Expect('leading_zero', 'ok:ret=Yes [1]');
        Observer.Expect('plus_sign', 'ok:ret=No [1]');
        Observer.Expect('dot_start', 'ok:ret=Yes [0.5]');
        Observer.Expect('dot_end', 'ok:ret=Yes [5.0]');
        Observer.Expect('nan', 'ok:ret=Yes ["NaN"]');
        Observer.Expect('infinity', 'ok:ret=Yes ["Infinity"]');
        Observer.Expect('hex', 'ok:ret=Yes [16]');
        Observer.Expect('too_big_exp', 'ok:ret=Yes ["Infinity"]');
        Observer.Verify();
    end;

    [Test]
    procedure ArrayReadFrom()
    begin
        Observer.Observe('empty_array', ReadArr('[]'));
        Observer.Observe('nested', ReadArr('[[],[[]],{}]'));
        Observer.Observe('mixed', ReadArr('[1,"a",true,null,{"k":[]}]'));
        Observer.Observe('trailing_comma', ReadArr('[1,]'));
        Observer.Observe('leading_comma', ReadArr('[,1]'));
        Observer.Observe('double_comma', ReadArr('[1,,2]'));
        Observer.Observe('unclosed', ReadArr('[1'));
        Observer.Observe('scalar', ReadArr('5'));
        Observer.Observe('blank', ReadArr(' '));
        Observer.Observe('object_text', ReadArr('{}'));
        Observer.Observe('deep', ReadArr('[[[[[[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]]]]]'));
        Observer.Expect('empty_array', 'ok:ret=Yes []');
        Observer.Expect('nested', 'ok:ret=Yes [[],[[]],{}]');
        Observer.Expect('mixed', 'ok:ret=Yes [1,"a",true,null,{"k":[]}]');
        Observer.Expect('trailing_comma', 'ok:ret=Yes [1]');
        Observer.Expect('leading_comma', 'ok:ret=Yes [undefined,1]');
        Observer.Expect('double_comma', 'ok:ret=Yes [1,undefined,2]');
        Observer.Expect('unclosed', 'ok:ret=No [1]');
        Observer.Expect('scalar', 'ok:ret=No [1]');
        Observer.Expect('blank', 'ok:ret=No [1]');
        Observer.Expect('object_text', 'ok:ret=No [1]');
        Observer.Expect('deep', 'ok:ret=Yes [[[[[[[[[[[[[[[[[[[[1]]]]]]]]]]]]]]]]]]]]');
        Observer.Verify();
    end;

    [Test]
    procedure TokenReadFromScalars()
    begin
        Observer.Observe('int', ReadTok('1'));
        Observer.Observe('string', ReadTok('"abc"'));
        Observer.Observe('true', ReadTok('true'));
        Observer.Observe('false', ReadTok('false'));
        Observer.Observe('null', ReadTok('null'));
        Observer.Observe('upper_true', ReadTok('True'));
        Observer.Observe('empty', ReadTok(''));
        Observer.Observe('blank', ReadTok('  '));
        Observer.Observe('bare_word', ReadTok('abc'));
        Observer.Observe('single_quoted', ReadTok('''abc'''));
        Observer.Observe('unterminated_string', ReadTok('"abc'));
        Observer.Observe('padded_int', ReadTok('  7  '));
        Observer.Observe('two_scalars', ReadTok('1 2'));
        Observer.Observe('undefined', ReadTok('undefined'));
        Observer.Observe('empty_string', ReadTok('""'));
        Observer.Observe('object', ReadTok('{"a":[]}'));
        Observer.Observe('array', ReadTok('[ ]'));
        Observer.Observe('pretty', ReadTok('{ "a" : [ 1 , 2 ] }'));
        Observer.Expect('int', 'ok:ret=Yes 1');
        Observer.Expect('string', 'ok:ret=Yes "abc"');
        Observer.Expect('true', 'ok:ret=Yes true');
        Observer.Expect('false', 'ok:ret=Yes false');
        Observer.Expect('null', 'ok:ret=Yes null');
        Observer.Expect('upper_true', 'ok:ret=No null');
        Observer.Expect('empty', 'ok:ret=No null');
        Observer.Expect('blank', 'ok:ret=No null');
        Observer.Expect('bare_word', 'ok:ret=No null');
        Observer.Expect('single_quoted', 'ok:ret=Yes "abc"');
        Observer.Expect('unterminated_string', 'ok:ret=No null');
        Observer.Expect('padded_int', 'ok:ret=Yes 7');
        Observer.Expect('two_scalars', 'ok:ret=Yes 1');
        Observer.Expect('undefined', 'ok:ret=Yes undefined');
        Observer.Expect('empty_string', 'ok:ret=Yes ""');
        Observer.Expect('object', 'ok:ret=Yes {"a":[]}');
        Observer.Expect('array', 'ok:ret=Yes []');
        Observer.Expect('pretty', 'ok:ret=Yes {"a":[1,2]}');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFromReplacesContent()
    var
        O: JsonObject;
        A: JsonArray;
        Txt: Text;
    begin
        O.Add('old', 1);
        O.ReadFrom('{"new":2}');
        O.WriteTo(Txt);
        Observer.Observe('object_replaced', Txt);
        asserterror O.ReadFrom('garbage');
        Observer.ObserveError('af206');
        O.WriteTo(Txt);
        Observer.Observe('object_after_failed_read', Txt);
        A.Add(1);
        A.ReadFrom('[2]');
        A.WriteTo(Txt);
        Observer.Observe('array_replaced', Txt);
        asserterror A.ReadFrom('garbage');
        Observer.ObserveError('af214');
        A.WriteTo(Txt);
        Observer.Observe('array_after_failed_read', Txt);
        Observer.Expect('object_replaced', '{"new":2}');
        Observer.Expect('af206|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('af206|code', 'InvalidJsonData');
        Observer.Expect('object_after_failed_read', '{"new":2}');
        Observer.Expect('array_replaced', '[2]');
        Observer.Expect('af214|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('af214|code', 'InvalidJsonData');
        Observer.Expect('array_after_failed_read', '[2]');
        Observer.Verify();
    end;

    // Control characters inside JSON strings (aldevtools/BusinessCentral.AL.Runner#7812): what each ReadFrom returns, the characters of
    // the string it read (len and character codes) and what WriteTo writes back.
    local procedure Ch(CharCode: Integer): Text
    var
        C: Text[1];
    begin
        C[1] := CharCode;
        exit(C);
    end;

    local procedure Codes(S: Text): Text
    var
        Index: Integer;
        CharCode: Integer;
        R: Text;
    begin
        R := 'len=' + Format(StrLen(S)) + ' codes=';
        for Index := 1 to StrLen(S) do begin
            if Index > 1 then
                R += ',';
            CharCode := S[Index];
            R += Format(CharCode);
        end;
        exit(R);
    end;

    [TryFunction]
    local procedure DoCtlObj(Src: Text; var R: Text)
    var
        O: JsonObject;
        T: JsonToken;
        Out: Text;
    begin
        R := 'ret=' + Format(O.ReadFrom(Src));
        if O.Get('a', T) then
            R += ' ' + Codes(T.AsValue().AsText());
        O.WriteTo(Out);
        R += ' out=' + Out;
    end;

    [TryFunction]
    local procedure DoCtlTok(Src: Text; var R: Text)
    var
        T: JsonToken;
        V: JsonToken;
        Out: Text;
    begin
        R := 'ret=' + Format(T.ReadFrom(Src));
        if T.IsObject() then
            if T.AsObject().Get('a', V) then
                R += ' ' + Codes(V.AsValue().AsText());
        T.WriteTo(Out);
        R += ' out=' + Out;
    end;

    [TryFunction]
    local procedure DoCtlArr(Src: Text; var R: Text)
    var
        A: JsonArray;
        T: JsonToken;
        Out: Text;
    begin
        R := 'ret=' + Format(A.ReadFrom(Src));
        if A.Get(0, T) then
            R += ' ' + Codes(T.AsValue().AsText());
        A.WriteTo(Out);
        R += ' out=' + Out;
    end;

    [TryFunction]
    local procedure DoCtlVal(Src: Text; var R: Text)
    var
        V: JsonValue;
        Ret: Boolean;
        Out: Text;
    begin
        Ret := V.ReadFrom(Src);
        R := 'ret=' + Format(Ret);
        if Ret then
            R += ' ' + Codes(V.AsText());
        V.WriteTo(Out);
        R += ' out=' + Out;
    end;

    local procedure Ctl(Kind: Text; Src: Text): Text
    var
        R: Text;
        Ok: Boolean;
    begin
        ClearLastError();
        case Kind of
            'obj':
                Ok := DoCtlObj(Src, R);
            'tok':
                Ok := DoCtlTok(Src, R);
            'arr':
                Ok := DoCtlArr(Src, R);
            'val':
                Ok := DoCtlVal(Src, R);
        end;
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure RawControls(Kind: Text; var Obs: Codeunit "Probe Observer")
    var
        Src: Text;
        CharCode: Integer;
        CodeList: List of [Integer];
    begin
        CodeList.AddRange(9, 10, 13, 1, 8, 12, 27, 31, 127);
        foreach CharCode in CodeList do begin
            case Kind of
                'obj', 'tok':
                    Src := '{"a":"x' + Ch(CharCode) + 'y"}';
                'arr':
                    Src := '["x' + Ch(CharCode) + 'y"]';
                'val':
                    Src := '"x' + Ch(CharCode) + 'y"';
            end;
            Obs.Observe(Kind + '_raw_' + Format(CharCode), Ctl(Kind, Src));
        end;
    end;

    [Test]
    procedure ObjectReadFromRawControlInString()
    var
        Obs: Codeunit "Probe Observer";
    begin
        RawControls('obj', Obs);
        Obs.Expect('obj_raw_9', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('obj_raw_10', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('obj_raw_13', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('obj_raw_1', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('obj_raw_8', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('obj_raw_12', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('obj_raw_27', 'ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('obj_raw_31', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Expect('obj_raw_127', 'ret=Yes len=3 codes=120,127,121 out={"a":"xy"}');
        Obs.Verify();
    end;

    [Test]
    procedure TokenReadFromRawControlInString()
    var
        Obs: Codeunit "Probe Observer";
    begin
        RawControls('tok', Obs);
        Obs.Expect('tok_raw_9', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('tok_raw_10', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('tok_raw_13', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('tok_raw_1', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('tok_raw_8', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('tok_raw_12', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('tok_raw_27', 'ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('tok_raw_31', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Expect('tok_raw_127', 'ret=Yes len=3 codes=120,127,121 out={"a":"xy"}');
        Obs.Verify();
    end;

    [Test]
    procedure ArrayReadFromRawControlInString()
    var
        Obs: Codeunit "Probe Observer";
    begin
        RawControls('arr', Obs);
        Obs.Expect('arr_raw_9', 'ret=Yes len=3 codes=120,9,121 out=["x\ty"]');
        Obs.Expect('arr_raw_10', 'ret=Yes len=3 codes=120,10,121 out=["x\ny"]');
        Obs.Expect('arr_raw_13', 'ret=Yes len=3 codes=120,13,121 out=["x\ry"]');
        Obs.Expect('arr_raw_1', 'ret=Yes len=3 codes=120,1,121 out=["x\u0001y"]');
        Obs.Expect('arr_raw_8', 'ret=Yes len=3 codes=120,8,121 out=["x\by"]');
        Obs.Expect('arr_raw_12', 'ret=Yes len=3 codes=120,12,121 out=["x\fy"]');
        Obs.Expect('arr_raw_27', 'ret=Yes len=3 codes=120,27,121 out=["x\u001by"]');
        Obs.Expect('arr_raw_31', 'ret=Yes len=3 codes=120,31,121 out=["x\u001fy"]');
        Obs.Expect('arr_raw_127', 'ret=Yes len=3 codes=120,127,121 out=["xy"]');
        Obs.Verify();
    end;

    [Test]
    procedure ValueReadFromRawControlInString()
    var
        Obs: Codeunit "Probe Observer";
    begin
        RawControls('val', Obs);
        Obs.Expect('val_raw_9', 'ret=Yes len=3 codes=120,9,121 out="x\ty"');
        Obs.Expect('val_raw_10', 'ret=Yes len=3 codes=120,10,121 out="x\ny"');
        Obs.Expect('val_raw_13', 'ret=Yes len=3 codes=120,13,121 out="x\ry"');
        Obs.Expect('val_raw_1', 'ret=Yes len=3 codes=120,1,121 out="x\u0001y"');
        Obs.Expect('val_raw_8', 'ret=Yes len=3 codes=120,8,121 out="x\by"');
        Obs.Expect('val_raw_12', 'ret=Yes len=3 codes=120,12,121 out="x\fy"');
        Obs.Expect('val_raw_27', 'ret=Yes len=3 codes=120,27,121 out="x\u001by"');
        Obs.Expect('val_raw_31', 'ret=Yes len=3 codes=120,31,121 out="x\u001fy"');
        Obs.Expect('val_raw_127', 'ret=Yes len=3 codes=120,127,121 out="xy"');
        Obs.Verify();
    end;

    [Test]
    procedure ReadFromEscapedControlInString()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('tok_esc_t', Ctl('tok', '{"a":"x\ty"}'));
        Obs.Observe('tok_esc_n', Ctl('tok', '{"a":"x\ny"}'));
        Obs.Observe('tok_esc_r', Ctl('tok', '{"a":"x\ry"}'));
        Obs.Observe('tok_esc_b', Ctl('tok', '{"a":"x\by"}'));
        Obs.Observe('tok_esc_f', Ctl('tok', '{"a":"x\fy"}'));
        Obs.Observe('tok_esc_u0001', Ctl('tok', '{"a":"x\u0001y"}'));
        Obs.Observe('tok_esc_u001f', Ctl('tok', '{"a":"x\u001fy"}'));
        Obs.Observe('val_esc_t', Ctl('val', '"x\ty"'));
        Obs.Observe('arr_esc_u0001', Ctl('arr', '["x\u0001y"]'));
        Obs.Expect('tok_esc_t', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('tok_esc_n', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('tok_esc_r', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('tok_esc_b', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('tok_esc_f', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('tok_esc_u0001', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('tok_esc_u001f', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Expect('val_esc_t', 'ret=Yes len=3 codes=120,9,121 out="x\ty"');
        Obs.Expect('arr_esc_u0001', 'ret=Yes len=3 codes=120,1,121 out=["x\u0001y"]');
        Obs.Verify();
    end;

    [Test]
    procedure ReadFromRawControlOtherPlaces()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Obs.Observe('tok_tab_in_key', Ctl('tok', '{"a' + Ch(9) + 'b":1,"a":"v"}'));
        Obs.Observe('tok_tab_single_quoted', Ctl('tok', '{''a'':''x' + Ch(9) + 'y''}'));
        Obs.Observe('tok_tab_between', Ctl('tok', '{"a":' + Ch(9) + '"v"}'));
        Obs.Observe('tok_1_between', Ctl('tok', '{"a":' + Ch(1) + '"v"}'));
        Obs.Observe('tok_12_between', Ctl('tok', '{"a":' + Ch(12) + '"v"}'));
        Obs.Observe('tok_tab_only_string', Ctl('tok', '{"a":"' + Ch(9) + '"}'));
        Obs.Observe('tok_lf_crlf_string', Ctl('tok', '{"a":"x' + Ch(13) + Ch(10) + 'y"}'));
        Obs.Expect('tok_tab_in_key', 'ret=Yes len=1 codes=118 out={"a\tb":1,"a":"v"}');
        Obs.Expect('tok_tab_single_quoted', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('tok_tab_between', 'ret=Yes len=1 codes=118 out={"a":"v"}');
        Obs.Expect('tok_1_between', 'ret=No out=null');
        Obs.Expect('tok_12_between', 'ret=Yes len=1 codes=118 out={"a":"v"}');
        Obs.Expect('tok_tab_only_string', 'ret=Yes len=1 codes=9 out={"a":"\t"}');
        Obs.Expect('tok_lf_crlf_string', 'ret=Yes len=4 codes=120,13,10,121 out={"a":"x\r\ny"}');
        Obs.Verify();
    end;
}
