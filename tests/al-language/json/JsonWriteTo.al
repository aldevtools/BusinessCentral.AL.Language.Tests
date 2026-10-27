// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-writeto-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 72506
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72506 "LT JsT WriteTo Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure Lf(): Text
    var
        C: Text[1];
    begin
        C[1] := 10;
        exit(C);
    end;

    [Test]
    procedure WriteToText()
    var
        O: JsonObject;
        A: JsonArray;
        Txt: Text;
    begin
        Observer.Observe('empty_obj_ret', Format(O.WriteTo(Txt)));
        Observer.Observe('empty_obj', Txt);
        A.WriteTo(Txt);
        Observer.Observe('empty_arr', Txt);
        O.Add('a', 1);
        O.Add('b', 'x');
        O.Add('c', A);
        O.Add('d', true);
        O.WriteTo(Txt);
        Observer.Observe('flat', Txt);
        Observer.Observe('format_obj', Format(O));
        Observer.Observe('format_arr', Format(A));
        Observer.Observe('has_spaces', Format(StrPos(Txt, ' ') > 0));
        Observer.Observe('has_newline', Format(StrPos(Txt, Lf()) > 0));
        Txt := 'prefilled';
        O.WriteTo(Txt);
        Observer.Observe('overwrites_text', Txt);
        Observer.Expect('empty_obj_ret', 'Yes');
        Observer.Expect('empty_obj', '{}');
        Observer.Expect('empty_arr', '[]');
        Observer.Expect('flat', '{"a":1,"b":"x","c":[],"d":true}');
        Observer.Expect('format_obj', '{"a":1,"b":"x","c":[],"d":true}');
        Observer.Expect('format_arr', '[]');
        Observer.Expect('has_spaces', 'No');
        Observer.Expect('has_newline', 'No');
        Observer.Expect('overwrites_text', '{"a":1,"b":"x","c":[],"d":true}');
        Observer.Verify();
    end;

    [Test]
    procedure WriteToTextVariants()
    var
        O: JsonObject;
        Txt: Text;
        Txt10: Text[10];
        C: Code[10];
    begin
        O.Add('a', 'abcdefghijklmnop');
        asserterror O.WriteTo(Txt10);
        Observer.Observe('writeto_text10_overflow|text starts', Format(GetLastErrorText().StartsWith('The length of the string is 24, but it must be less than or equal to 10 characters.')));
        Observer.Observe('writeto_text10_overflow|code', GetLastErrorCode());
        ClearLastError();
        O.WriteTo(Txt);
        Observer.Observe('text_len', Format(StrLen(Txt)));
        Clear(O);
        O.WriteTo(Txt);
        C := CopyStr(Txt, 1, 10);
        Observer.Observe('code', C);
        Observer.Expect('writeto_text10_overflow|text starts', 'Yes');
        Observer.Expect('writeto_text10_overflow|code', 'StringLengthExceeded');
        Observer.Expect('text_len', '24');
        Observer.Expect('code', '{}');
        Observer.Verify();
    end;

    [Test]
    procedure UnicodeAndEscapes()
    var
        O: JsonObject;
        Txt: Text;
        S: Text;
        Ch: Char;
    begin
        O.Add('quote', '"');
        O.Add('backslash', '\');
        O.Add('slash', '/');
        O.Add('lt_gt_amp', '<>&');
        O.Add('apostrophe', '''');
        O.Add('umlaut', 'äöüß');
        O.Add('euro', '€');
        O.Add('cjk', '日本語');
        O.Add('emoji', '😀');
        O.Add('nbsp', Format(Ch));
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Clear(O);
        S := ' ';
        S[1] := 1;
        O.Add('ctrl_01', S);
        S[1] := 8;
        O.Add('ctrl_08', S);
        S[1] := 9;
        O.Add('tab', S);
        S[1] := 10;
        O.Add('lf', S);
        S[1] := 12;
        O.Add('ff', S);
        S[1] := 13;
        O.Add('cr', S);
        S[1] := 31;
        O.Add('ctrl_1f', S);
        S[1] := 127;
        O.Add('del', S);
        S[1] := 8232;
        O.Add('line_sep', S);
        S[1] := 65535;
        O.Add('ffff', S);
        O.WriteTo(Txt);
        Observer.Observe('controls', Txt);
        Observer.Expect('text', '{"quote":"\"","backslash":"\\","slash":"/","lt_gt_amp":"<>&","apostrophe":"''","umlaut":"äöüß","euro":"€","cjk":"日本語","emoji":"\uD83D\uDE00","nbsp":"\u0000"}');
        Observer.Expect('controls', '{"ctrl_01":"\u0001","ctrl_08":"\b","tab":"\t","lf":"\n","ff":"\f","cr":"\r","ctrl_1f":"\u001f","del":"","line_sep":"\u2028","ffff":"\uFFFF"}');
        Observer.Verify();
    end;

    [Test]
    procedure KeysAreEscaped()
    var
        O: JsonObject;
        Txt: Text;
    begin
        O.Add('a"b', 1);
        O.Add('c\d', 2);
        O.Add('e' + Lf() + 'f', 3);
        O.Add('ü', 4);
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Expect('text', '{"a\"b":1,"c\\d":2,"e\nf":3,"ü":4}');
        Observer.Verify();
    end;

    [Test]
    procedure NumberFormattingInWriteTo()
    var
        A: JsonArray;
        Txt: Text;
        Dec: Decimal;
        Int: Integer;
        Big: BigInteger;
    begin
        A.Add(0.1 + 0.2);
        A.Add(1 / 3);
        A.Add(2 / 3);
        A.Add(100.0);
        A.Add(0.5);
        A.Add(1.23456789012345678);
        A.Add(1000000.0);
        A.Add(123456789012345.0);
        A.Add(0.000001);
        A.Add(0.0000001);
        Dec := 12345678901234567890.12345678;
        A.Add(Dec);
        Dec := 0;
        A.Add(Dec);
        Dec := -0.0;
        A.Add(Dec);
        Evaluate(Int, '2147483647');
        A.Add(Int);
        Evaluate(Big, '4611686018427387904');
        A.Add(Big);
        A.WriteTo(Txt);
        Observer.Observe('numbers', Txt);
        Observer.Expect('numbers', '[0.3,0.333333333333333333,0.666666666666666667,100.0,0.5,1.23456789012345678,1000000.0,123456789012345.0,0.000001,0.0000001,12345678901234567900.0,0.0,0.0,2147483647,4611686018427387904]');
        Observer.Verify();
    end;

    [Test]
    procedure PrettyAndPathStable()
    var
        O: JsonObject;
        Inner: JsonObject;
        Arr: JsonArray;
        Txt: Text;
    begin
        Inner.Add('x', 1);
        Arr.Add(Inner);
        Arr.Add(Arr.Count());
        O.Add('arr', Arr);
        O.Add('o', Inner);
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        Observer.Observe('len', Format(StrLen(Txt)));
        Observer.Expect('text', '{"arr":[{"x":1},1],"o":{"x":1}}');
        Observer.Expect('len', '31');
        Observer.Verify();
    end;

    [Test]
    procedure StreamRoundtrip()
    var
        O: JsonObject;
        O2: JsonObject;
        A: JsonArray;
        A2: JsonArray;
        T: JsonToken;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        O.Add('a', 'äö€');
        O.Add('n', 12.5);
        TempBlob.CreateOutStream(OutS, TextEncoding::UTF8);
        Observer.Observe('writeto_outstream', Format(O.WriteTo(OutS)));
        TempBlob.CreateInStream(InS, TextEncoding::UTF8);
        Observer.Observe('readfrom_instream', Format(O2.ReadFrom(InS)));
        O2.WriteTo(Txt);
        Observer.Observe('roundtrip', Txt);
        Observer.Observe('length_bytes', Format(TempBlob.Length()));
        A.Add(1);
        A.Add('x');
        Clear(TempBlob);
        Clear(OutS);
        TempBlob.CreateOutStream(OutS);
        A.WriteTo(OutS);
        TempBlob.CreateInStream(InS);
        Observer.Observe('array_readfrom_instream', Format(A2.ReadFrom(InS)));
        A2.WriteTo(Txt);
        Observer.Observe('array_roundtrip', Txt);
        Clear(TempBlob);
        Clear(OutS);
        TempBlob.CreateOutStream(OutS);
        O.AsToken().WriteTo(OutS);
        TempBlob.CreateInStream(InS);
        Observer.Observe('token_readfrom_instream', Format(T.ReadFrom(InS)));
        T.WriteTo(Txt);
        Observer.Observe('token_roundtrip', Txt);
        Observer.Expect('writeto_outstream', 'Yes');
        Observer.Expect('readfrom_instream', 'Yes');
        Observer.Expect('roundtrip', '{"a":"äö€","n":12.5}');
        Observer.Expect('length_bytes', '24');
        Observer.Expect('array_readfrom_instream', 'Yes');
        Observer.Expect('array_roundtrip', '[1,"x"]');
        Observer.Expect('token_readfrom_instream', 'Yes');
        Observer.Expect('token_roundtrip', '{"a":"äö€","n":12.5}');
        Observer.Verify();
    end;

    [Test]
    procedure StreamReadInvalid()
    var
        O: JsonObject;
        A: JsonArray;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
    begin
        TempBlob.CreateInStream(InS);
        Observer.Observe('empty_stream', Format(O.ReadFrom(InS)));
        Observer.Observe('empty_stream', 'no error');
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('not json');
        TempBlob.CreateInStream(InS);
        Observer.Observe('invalid_stream', Format(O.ReadFrom(InS)));
        Observer.Observe('invalid_stream', 'no error');
        Clear(TempBlob);
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('[1]');
        TempBlob.CreateInStream(InS);
        Observer.Observe('array_into_object', Format(O.ReadFrom(InS)));
        Observer.Observe('array_into_object', 'no error');
        Observer.Expect('empty_stream', 'No');
        Observer.Expect('empty_stream', 'no error');
        Observer.Expect('invalid_stream', 'No');
        Observer.Expect('invalid_stream', 'no error');
        Observer.Expect('array_into_object', 'No');
        Observer.Expect('array_into_object', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ForeachObjectKeys()
    var
        O: JsonObject;
        K: Text;
        T: JsonToken;
        All: Text;
        Txt: Text;
    begin
        O.ReadFrom('{"b":1,"a":"x","c":[1],"d":{"e":null}}');
        foreach K in O.Keys() do begin
            O.Get(K, T);
            T.WriteTo(Txt);
            All += K + '=' + Txt + ';';
        end;
        Observer.Observe('keys_and_values', All);
        All := '';
        foreach K in O.Keys() do
            if K = 'a' then
                O.Remove(K);
        foreach K in O.Keys() do
            All += K;
        Observer.Observe('after_remove_in_loop', All);
        Observer.Expect('keys_and_values', 'b=1;a="x";c=[1];d={"e":null};');
        Observer.Expect('after_remove_in_loop', 'bcd');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyNestedThroughToken()
    var
        O: JsonObject;
        T: JsonToken;
        Txt: Text;
    begin
        O.ReadFrom('{"a":{"b":[1,2,{"c":3}]}}');
        O.SelectToken('a.b[2]', T);
        T.AsObject().Replace('c', 'three');
        O.SelectToken('a.b', T);
        T.AsArray().Add(4);
        O.WriteTo(Txt);
        Observer.Observe('text', Txt);
        O.SelectToken('a.b[2].c', T);
        Observer.Observe('path', T.Path());
        T.AsValue().SetValue('direct');
        O.WriteTo(Txt);
        Observer.Observe('after_value_setvalue', Txt);
        Observer.Expect('text', '{"a":{"b":[1,2,{"c":"three"},4]}}');
        Observer.Expect('path', 'a.b[2].c');
        Observer.Expect('after_value_setvalue', '{"a":{"b":[1,2,{"c":"three"},4]}}');
        Observer.Verify();
    end;

    // ---- Writer SH, al-runner issue 5956: Format of a JsonArray that was never touched, read from '[]', or cleared after an Add.

    [Test]
    procedure FormatOfEmptyJsonArrays()
    var
        Untouched: JsonArray;
        ReadEmpty: JsonArray;
        Cleared: JsonArray;
        OneItem: JsonArray;
    begin
        Observer.Observe('untouched', Format(Untouched));
        ReadEmpty.ReadFrom('[]');
        Observer.Observe('read from []', Format(ReadEmpty));
        Cleared.Add(1);
        Observer.Observe('one item', Format(Cleared));
        Clear(Cleared);
        Observer.Observe('cleared after Add', Format(Cleared));
        OneItem.Add('a');
        OneItem.Add(2);
        Observer.Observe('two items', Format(OneItem));
        Observer.Observe('untouched format 9', Format(Untouched, 0, 9));
        Observer.Finish();
    end;
}
