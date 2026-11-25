// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-readfrom-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); Temp Blob (System Application); self-contained codeunit 86412
// Probe: raw control characters (codes 0 to 31) inside JSON strings (aldevtools/BusinessCentral.AL.Runner#7812). JsonReadFrom.al measured
// codes 1, 8, 9, 10, 12, 13, 27, 31 and 127 in a double-quoted value and only TAB in a key and in a single-quoted string; this file measures
// every code 0..31 in each place:
//   - ReadFrom(Text) with the raw code in a double-quoted value (JsonObject, JsonToken, JsonArray, JsonValue),
//   - ReadFrom(Text) with the raw code in a double-quoted key (JsonObject, JsonToken),
//   - ReadFrom(Text) with the raw code in a single-quoted value (JsonObject, JsonToken, JsonArray ['x?y'], JsonValue 'x?y'),
//   - ReadFrom(InStream) with the raw byte in a double-quoted value (the document written byte by byte into a Temp Blob),
//   - what C[1] := 0 leaves in a Text (so whether a Text can carry code 0 at all).
// Each observation is ret=<ReadFrom result> len=<length> codes=<character codes of the value or key read> out=<WriteTo text>, or
// error:<last error text>|<last error code>.
// BC versions: 27, 28, 29

codeunit 86412 "LT JsT ReadFrom CtlChars"
{
    Subtype = Test;
    TestPermissions = Disabled;

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

    local procedure FirstKey(O: JsonObject): Text
    var
        Keys: List of [Text];
    begin
        Keys := O.Keys();
        if Keys.Count() = 0 then
            exit('nokey');
        exit(Codes(Keys.Get(1)));
    end;

    // What the read left: the value under key a (or the first key when Part = 'key'), then WriteTo.
    local procedure DescribeObj(O: JsonObject; Part: Text): Text
    var
        T: JsonToken;
        Out: Text;
        R: Text;
    begin
        if Part = 'key' then
            R := ' ' + FirstKey(O)
        else
            if O.Get('a', T) then
                if T.IsValue() then
                    R := ' ' + Codes(T.AsValue().AsText());
        O.WriteTo(Out);
        exit(R + ' out=' + Out);
    end;

    local procedure DescribeTok(T: JsonToken; Part: Text): Text
    var
        Out: Text;
    begin
        if T.IsObject() then
            exit(DescribeObj(T.AsObject(), Part));
        T.WriteTo(Out);
        exit(' out=' + Out);
    end;

    local procedure DescribeArr(A: JsonArray): Text
    var
        T: JsonToken;
        Out: Text;
        R: Text;
    begin
        if A.Get(0, T) then
            if T.IsValue() then
                R := ' ' + Codes(T.AsValue().AsText());
        A.WriteTo(Out);
        exit(R + ' out=' + Out);
    end;

    local procedure DescribeVal(V: JsonValue; Ret: Boolean): Text
    var
        Out: Text;
        R: Text;
    begin
        if Ret then
            R := ' ' + Codes(V.AsText());
        V.WriteTo(Out);
        exit(R + ' out=' + Out);
    end;

    [TryFunction]
    local procedure DoText(Kind: Text; Part: Text; Src: Text; var R: Text)
    var
        O: JsonObject;
        T: JsonToken;
        A: JsonArray;
        V: JsonValue;
        Ret: Boolean;
    begin
        case Kind of
            'obj':
                begin
                    Ret := O.ReadFrom(Src);
                    R := 'ret=' + Format(Ret) + DescribeObj(O, Part);
                end;
            'tok':
                begin
                    Ret := T.ReadFrom(Src);
                    R := 'ret=' + Format(Ret) + DescribeTok(T, Part);
                end;
            'arr':
                begin
                    Ret := A.ReadFrom(Src);
                    R := 'ret=' + Format(Ret) + DescribeArr(A);
                end;
            'val':
                begin
                    Ret := V.ReadFrom(Src);
                    R := 'ret=' + Format(Ret) + DescribeVal(V, Ret);
                end;
        end;
    end;

    [TryFunction]
    local procedure DoStream(Kind: Text; var InS: InStream; var R: Text)
    var
        O: JsonObject;
        T: JsonToken;
        A: JsonArray;
        V: JsonValue;
        Ret: Boolean;
    begin
        case Kind of
            'obj':
                begin
                    Ret := O.ReadFrom(InS);
                    R := 'ret=' + Format(Ret) + DescribeObj(O, 'value');
                end;
            'tok':
                begin
                    Ret := T.ReadFrom(InS);
                    R := 'ret=' + Format(Ret) + DescribeTok(T, 'value');
                end;
            'arr':
                begin
                    Ret := A.ReadFrom(InS);
                    R := 'ret=' + Format(Ret) + DescribeArr(A);
                end;
            'val':
                begin
                    Ret := V.ReadFrom(InS);
                    R := 'ret=' + Format(Ret) + DescribeVal(V, Ret);
                end;
        end;
    end;

    local procedure RunText(Kind: Text; Part: Text; Src: Text): Text
    var
        R: Text;
    begin
        ClearLastError();
        if DoText(Kind, Part, Src, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure WriteAscii(var OutS: OutStream; S: Text)
    var
        Index: Integer;
    begin
        for Index := 1 to StrLen(S) do
            WriteByte(OutS, S[Index]);
    end;

    local procedure WriteByte(var OutS: OutStream; CharCode: Integer)
    var
        B: Byte;
    begin
        B := CharCode;
        OutS.Write(B);
    end;

    local procedure RunStream(Kind: Text; Pre: Text; CharCode: Integer; Post: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        R: Text;
    begin
        TempBlob.CreateOutStream(OutS);
        WriteAscii(OutS, Pre);
        WriteByte(OutS, CharCode);
        WriteAscii(OutS, Post);
        TempBlob.CreateInStream(InS);
        ClearLastError();
        if DoStream(Kind, InS, R) then
            exit('bytes=' + Format(TempBlob.Length()) + ' ' + R);
        exit('bytes=' + Format(TempBlob.Length()) + ' error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Place: dq = double-quoted value, key = double-quoted key, sq = single-quoted value.
    local procedure Sweep(Kind: Text; Place: Text; FromCode: Integer; ToCode: Integer; var Obs: Codeunit "Probe Observer")
    var
        CharCode: Integer;
        Src: Text;
        Part: Text;
    begin
        Part := 'value';
        for CharCode := FromCode to ToCode do begin
            case Kind + '_' + Place of
                'obj_dq', 'tok_dq':
                    Src := '{"a":"x' + Ch(CharCode) + 'y"}';
                'arr_dq':
                    Src := '["x' + Ch(CharCode) + 'y"]';
                'val_dq':
                    Src := '"x' + Ch(CharCode) + 'y"';
                'obj_key', 'tok_key':
                    begin
                        Src := '{"k' + Ch(CharCode) + 'z":"v"}';
                        Part := 'key';
                    end;
                'obj_sq', 'tok_sq':
                    Src := '{''a'':''x' + Ch(CharCode) + 'y''}';
                'arr_sq':
                    Src := '[''x' + Ch(CharCode) + 'y'']';
                'val_sq':
                    Src := '''x' + Ch(CharCode) + 'y''';
            end;
            Obs.Observe(Kind + '_' + Place + '_' + Format(CharCode), RunText(Kind, Part, Src));
        end;
    end;

    local procedure SweepStream(Kind: Text; FromCode: Integer; ToCode: Integer; var Obs: Codeunit "Probe Observer")
    var
        CharCode: Integer;
    begin
        for CharCode := FromCode to ToCode do
            case Kind of
                'obj', 'tok':
                    Obs.Observe(Kind + '_stream_' + Format(CharCode), RunStream(Kind, '{"a":"x', CharCode, 'y"}'));
                'arr':
                    Obs.Observe(Kind + '_stream_' + Format(CharCode), RunStream(Kind, '["x', CharCode, 'y"]'));
                'val':
                    Obs.Observe(Kind + '_stream_' + Format(CharCode), RunStream(Kind, '"x', CharCode, 'y"'));
            end;
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'dq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'dq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'dq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'dq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Array_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'dq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Array_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'dq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Value_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'dq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Value_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'dq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedKey_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'key', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedKey_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'key', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedKey_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'key', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedKey_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'key', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'sq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'sq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'sq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'sq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Array_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'sq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Array_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'sq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Value_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'sq', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Value_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'sq', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('obj', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Object_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('obj', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('tok', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Token_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('tok', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Array_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('arr', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Array_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('arr', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Value_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('val', 0, 15, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Value_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('val', 16, 31, Obs);
        Obs.Finish();
    end;

    [Test]
    procedure Text_CharCodeZero_WhatTextKeeps()
    var
        Obs: Codeunit "Probe Observer";
        C: Text[1];
        S: Text;
    begin
        C[1] := 0;
        Obs.Observe('text1_after_c1_0', Codes(C));
        C := 'q';
        C[1] := 0;
        Obs.Observe('text1_q_after_c1_0', Codes(C));
        S := 'abc';
        S[2] := 0;
        Obs.Observe('abc_after_s2_0', Codes(S));
        Obs.Observe('obj_dq_abc_s2_0', RunText('obj', 'value', '{"a":"' + S + '"}'));
        S := 'x' + Ch(0) + 'y';
        Obs.Observe('concat_x_ch0_y', Codes(S));
        Obs.Observe('obj_dq_ch0', RunText('obj', 'value', '{"a":"x' + Ch(0) + 'y"}'));
        Obs.Finish();
    end;
}
