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
// Measured by the corpus CI matrix (BC 27.5, 28.5, 29.0, the same on all three):
//   - every ReadFrom returns true for every raw code 1..31 in every place above and keeps the character (len 3); WriteTo writes
//     \b \t \n \f \r for 8, 9, 10, 12, 13 and \u00XX (lower-case hex) for the other codes.
//   - ReadFrom(InStream) with a raw byte 0 also returns true and keeps code 0 in the value (codes=120,0,121, WriteTo \u0000).
//   - a Text cannot carry code 0: C[1] := 0 leaves an empty Text[1], S[2] := 0 on 'abc' leaves 'a' (the Text ends at the
//     position written), and a concatenation with that empty text adds nothing; so ReadFrom(Text) never sees code 0.
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
        Obs.Expect('obj_dq_0', 'ret=Yes len=2 codes=120,121 out={"a":"xy"}');
        Obs.Expect('obj_dq_1', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('obj_dq_2', 'ret=Yes len=3 codes=120,2,121 out={"a":"x\u0002y"}');
        Obs.Expect('obj_dq_3', 'ret=Yes len=3 codes=120,3,121 out={"a":"x\u0003y"}');
        Obs.Expect('obj_dq_4', 'ret=Yes len=3 codes=120,4,121 out={"a":"x\u0004y"}');
        Obs.Expect('obj_dq_5', 'ret=Yes len=3 codes=120,5,121 out={"a":"x\u0005y"}');
        Obs.Expect('obj_dq_6', 'ret=Yes len=3 codes=120,6,121 out={"a":"x\u0006y"}');
        Obs.Expect('obj_dq_7', 'ret=Yes len=3 codes=120,7,121 out={"a":"x\u0007y"}');
        Obs.Expect('obj_dq_8', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('obj_dq_9', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('obj_dq_10', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('obj_dq_11', 'ret=Yes len=3 codes=120,11,121 out={"a":"x\u000by"}');
        Obs.Expect('obj_dq_12', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('obj_dq_13', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('obj_dq_14', 'ret=Yes len=3 codes=120,14,121 out={"a":"x\u000ey"}');
        Obs.Expect('obj_dq_15', 'ret=Yes len=3 codes=120,15,121 out={"a":"x\u000fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'dq', 16, 31, Obs);
        Obs.Expect('obj_dq_16', 'ret=Yes len=3 codes=120,16,121 out={"a":"x\u0010y"}');
        Obs.Expect('obj_dq_17', 'ret=Yes len=3 codes=120,17,121 out={"a":"x\u0011y"}');
        Obs.Expect('obj_dq_18', 'ret=Yes len=3 codes=120,18,121 out={"a":"x\u0012y"}');
        Obs.Expect('obj_dq_19', 'ret=Yes len=3 codes=120,19,121 out={"a":"x\u0013y"}');
        Obs.Expect('obj_dq_20', 'ret=Yes len=3 codes=120,20,121 out={"a":"x\u0014y"}');
        Obs.Expect('obj_dq_21', 'ret=Yes len=3 codes=120,21,121 out={"a":"x\u0015y"}');
        Obs.Expect('obj_dq_22', 'ret=Yes len=3 codes=120,22,121 out={"a":"x\u0016y"}');
        Obs.Expect('obj_dq_23', 'ret=Yes len=3 codes=120,23,121 out={"a":"x\u0017y"}');
        Obs.Expect('obj_dq_24', 'ret=Yes len=3 codes=120,24,121 out={"a":"x\u0018y"}');
        Obs.Expect('obj_dq_25', 'ret=Yes len=3 codes=120,25,121 out={"a":"x\u0019y"}');
        Obs.Expect('obj_dq_26', 'ret=Yes len=3 codes=120,26,121 out={"a":"x\u001ay"}');
        Obs.Expect('obj_dq_27', 'ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('obj_dq_28', 'ret=Yes len=3 codes=120,28,121 out={"a":"x\u001cy"}');
        Obs.Expect('obj_dq_29', 'ret=Yes len=3 codes=120,29,121 out={"a":"x\u001dy"}');
        Obs.Expect('obj_dq_30', 'ret=Yes len=3 codes=120,30,121 out={"a":"x\u001ey"}');
        Obs.Expect('obj_dq_31', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'dq', 0, 15, Obs);
        Obs.Expect('tok_dq_0', 'ret=Yes len=2 codes=120,121 out={"a":"xy"}');
        Obs.Expect('tok_dq_1', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('tok_dq_2', 'ret=Yes len=3 codes=120,2,121 out={"a":"x\u0002y"}');
        Obs.Expect('tok_dq_3', 'ret=Yes len=3 codes=120,3,121 out={"a":"x\u0003y"}');
        Obs.Expect('tok_dq_4', 'ret=Yes len=3 codes=120,4,121 out={"a":"x\u0004y"}');
        Obs.Expect('tok_dq_5', 'ret=Yes len=3 codes=120,5,121 out={"a":"x\u0005y"}');
        Obs.Expect('tok_dq_6', 'ret=Yes len=3 codes=120,6,121 out={"a":"x\u0006y"}');
        Obs.Expect('tok_dq_7', 'ret=Yes len=3 codes=120,7,121 out={"a":"x\u0007y"}');
        Obs.Expect('tok_dq_8', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('tok_dq_9', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('tok_dq_10', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('tok_dq_11', 'ret=Yes len=3 codes=120,11,121 out={"a":"x\u000by"}');
        Obs.Expect('tok_dq_12', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('tok_dq_13', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('tok_dq_14', 'ret=Yes len=3 codes=120,14,121 out={"a":"x\u000ey"}');
        Obs.Expect('tok_dq_15', 'ret=Yes len=3 codes=120,15,121 out={"a":"x\u000fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'dq', 16, 31, Obs);
        Obs.Expect('tok_dq_16', 'ret=Yes len=3 codes=120,16,121 out={"a":"x\u0010y"}');
        Obs.Expect('tok_dq_17', 'ret=Yes len=3 codes=120,17,121 out={"a":"x\u0011y"}');
        Obs.Expect('tok_dq_18', 'ret=Yes len=3 codes=120,18,121 out={"a":"x\u0012y"}');
        Obs.Expect('tok_dq_19', 'ret=Yes len=3 codes=120,19,121 out={"a":"x\u0013y"}');
        Obs.Expect('tok_dq_20', 'ret=Yes len=3 codes=120,20,121 out={"a":"x\u0014y"}');
        Obs.Expect('tok_dq_21', 'ret=Yes len=3 codes=120,21,121 out={"a":"x\u0015y"}');
        Obs.Expect('tok_dq_22', 'ret=Yes len=3 codes=120,22,121 out={"a":"x\u0016y"}');
        Obs.Expect('tok_dq_23', 'ret=Yes len=3 codes=120,23,121 out={"a":"x\u0017y"}');
        Obs.Expect('tok_dq_24', 'ret=Yes len=3 codes=120,24,121 out={"a":"x\u0018y"}');
        Obs.Expect('tok_dq_25', 'ret=Yes len=3 codes=120,25,121 out={"a":"x\u0019y"}');
        Obs.Expect('tok_dq_26', 'ret=Yes len=3 codes=120,26,121 out={"a":"x\u001ay"}');
        Obs.Expect('tok_dq_27', 'ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('tok_dq_28', 'ret=Yes len=3 codes=120,28,121 out={"a":"x\u001cy"}');
        Obs.Expect('tok_dq_29', 'ret=Yes len=3 codes=120,29,121 out={"a":"x\u001dy"}');
        Obs.Expect('tok_dq_30', 'ret=Yes len=3 codes=120,30,121 out={"a":"x\u001ey"}');
        Obs.Expect('tok_dq_31', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Array_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'dq', 0, 15, Obs);
        Obs.Expect('arr_dq_0', 'ret=Yes len=2 codes=120,121 out=["xy"]');
        Obs.Expect('arr_dq_1', 'ret=Yes len=3 codes=120,1,121 out=["x\u0001y"]');
        Obs.Expect('arr_dq_2', 'ret=Yes len=3 codes=120,2,121 out=["x\u0002y"]');
        Obs.Expect('arr_dq_3', 'ret=Yes len=3 codes=120,3,121 out=["x\u0003y"]');
        Obs.Expect('arr_dq_4', 'ret=Yes len=3 codes=120,4,121 out=["x\u0004y"]');
        Obs.Expect('arr_dq_5', 'ret=Yes len=3 codes=120,5,121 out=["x\u0005y"]');
        Obs.Expect('arr_dq_6', 'ret=Yes len=3 codes=120,6,121 out=["x\u0006y"]');
        Obs.Expect('arr_dq_7', 'ret=Yes len=3 codes=120,7,121 out=["x\u0007y"]');
        Obs.Expect('arr_dq_8', 'ret=Yes len=3 codes=120,8,121 out=["x\by"]');
        Obs.Expect('arr_dq_9', 'ret=Yes len=3 codes=120,9,121 out=["x\ty"]');
        Obs.Expect('arr_dq_10', 'ret=Yes len=3 codes=120,10,121 out=["x\ny"]');
        Obs.Expect('arr_dq_11', 'ret=Yes len=3 codes=120,11,121 out=["x\u000by"]');
        Obs.Expect('arr_dq_12', 'ret=Yes len=3 codes=120,12,121 out=["x\fy"]');
        Obs.Expect('arr_dq_13', 'ret=Yes len=3 codes=120,13,121 out=["x\ry"]');
        Obs.Expect('arr_dq_14', 'ret=Yes len=3 codes=120,14,121 out=["x\u000ey"]');
        Obs.Expect('arr_dq_15', 'ret=Yes len=3 codes=120,15,121 out=["x\u000fy"]');
        Obs.Verify();
    end;

    [Test]
    procedure Array_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'dq', 16, 31, Obs);
        Obs.Expect('arr_dq_16', 'ret=Yes len=3 codes=120,16,121 out=["x\u0010y"]');
        Obs.Expect('arr_dq_17', 'ret=Yes len=3 codes=120,17,121 out=["x\u0011y"]');
        Obs.Expect('arr_dq_18', 'ret=Yes len=3 codes=120,18,121 out=["x\u0012y"]');
        Obs.Expect('arr_dq_19', 'ret=Yes len=3 codes=120,19,121 out=["x\u0013y"]');
        Obs.Expect('arr_dq_20', 'ret=Yes len=3 codes=120,20,121 out=["x\u0014y"]');
        Obs.Expect('arr_dq_21', 'ret=Yes len=3 codes=120,21,121 out=["x\u0015y"]');
        Obs.Expect('arr_dq_22', 'ret=Yes len=3 codes=120,22,121 out=["x\u0016y"]');
        Obs.Expect('arr_dq_23', 'ret=Yes len=3 codes=120,23,121 out=["x\u0017y"]');
        Obs.Expect('arr_dq_24', 'ret=Yes len=3 codes=120,24,121 out=["x\u0018y"]');
        Obs.Expect('arr_dq_25', 'ret=Yes len=3 codes=120,25,121 out=["x\u0019y"]');
        Obs.Expect('arr_dq_26', 'ret=Yes len=3 codes=120,26,121 out=["x\u001ay"]');
        Obs.Expect('arr_dq_27', 'ret=Yes len=3 codes=120,27,121 out=["x\u001by"]');
        Obs.Expect('arr_dq_28', 'ret=Yes len=3 codes=120,28,121 out=["x\u001cy"]');
        Obs.Expect('arr_dq_29', 'ret=Yes len=3 codes=120,29,121 out=["x\u001dy"]');
        Obs.Expect('arr_dq_30', 'ret=Yes len=3 codes=120,30,121 out=["x\u001ey"]');
        Obs.Expect('arr_dq_31', 'ret=Yes len=3 codes=120,31,121 out=["x\u001fy"]');
        Obs.Verify();
    end;

    [Test]
    procedure Value_ReadFromText_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'dq', 0, 15, Obs);
        Obs.Expect('val_dq_0', 'ret=Yes len=2 codes=120,121 out="xy"');
        Obs.Expect('val_dq_1', 'ret=Yes len=3 codes=120,1,121 out="x\u0001y"');
        Obs.Expect('val_dq_2', 'ret=Yes len=3 codes=120,2,121 out="x\u0002y"');
        Obs.Expect('val_dq_3', 'ret=Yes len=3 codes=120,3,121 out="x\u0003y"');
        Obs.Expect('val_dq_4', 'ret=Yes len=3 codes=120,4,121 out="x\u0004y"');
        Obs.Expect('val_dq_5', 'ret=Yes len=3 codes=120,5,121 out="x\u0005y"');
        Obs.Expect('val_dq_6', 'ret=Yes len=3 codes=120,6,121 out="x\u0006y"');
        Obs.Expect('val_dq_7', 'ret=Yes len=3 codes=120,7,121 out="x\u0007y"');
        Obs.Expect('val_dq_8', 'ret=Yes len=3 codes=120,8,121 out="x\by"');
        Obs.Expect('val_dq_9', 'ret=Yes len=3 codes=120,9,121 out="x\ty"');
        Obs.Expect('val_dq_10', 'ret=Yes len=3 codes=120,10,121 out="x\ny"');
        Obs.Expect('val_dq_11', 'ret=Yes len=3 codes=120,11,121 out="x\u000by"');
        Obs.Expect('val_dq_12', 'ret=Yes len=3 codes=120,12,121 out="x\fy"');
        Obs.Expect('val_dq_13', 'ret=Yes len=3 codes=120,13,121 out="x\ry"');
        Obs.Expect('val_dq_14', 'ret=Yes len=3 codes=120,14,121 out="x\u000ey"');
        Obs.Expect('val_dq_15', 'ret=Yes len=3 codes=120,15,121 out="x\u000fy"');
        Obs.Verify();
    end;

    [Test]
    procedure Value_ReadFromText_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'dq', 16, 31, Obs);
        Obs.Expect('val_dq_16', 'ret=Yes len=3 codes=120,16,121 out="x\u0010y"');
        Obs.Expect('val_dq_17', 'ret=Yes len=3 codes=120,17,121 out="x\u0011y"');
        Obs.Expect('val_dq_18', 'ret=Yes len=3 codes=120,18,121 out="x\u0012y"');
        Obs.Expect('val_dq_19', 'ret=Yes len=3 codes=120,19,121 out="x\u0013y"');
        Obs.Expect('val_dq_20', 'ret=Yes len=3 codes=120,20,121 out="x\u0014y"');
        Obs.Expect('val_dq_21', 'ret=Yes len=3 codes=120,21,121 out="x\u0015y"');
        Obs.Expect('val_dq_22', 'ret=Yes len=3 codes=120,22,121 out="x\u0016y"');
        Obs.Expect('val_dq_23', 'ret=Yes len=3 codes=120,23,121 out="x\u0017y"');
        Obs.Expect('val_dq_24', 'ret=Yes len=3 codes=120,24,121 out="x\u0018y"');
        Obs.Expect('val_dq_25', 'ret=Yes len=3 codes=120,25,121 out="x\u0019y"');
        Obs.Expect('val_dq_26', 'ret=Yes len=3 codes=120,26,121 out="x\u001ay"');
        Obs.Expect('val_dq_27', 'ret=Yes len=3 codes=120,27,121 out="x\u001by"');
        Obs.Expect('val_dq_28', 'ret=Yes len=3 codes=120,28,121 out="x\u001cy"');
        Obs.Expect('val_dq_29', 'ret=Yes len=3 codes=120,29,121 out="x\u001dy"');
        Obs.Expect('val_dq_30', 'ret=Yes len=3 codes=120,30,121 out="x\u001ey"');
        Obs.Expect('val_dq_31', 'ret=Yes len=3 codes=120,31,121 out="x\u001fy"');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedKey_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'key', 0, 15, Obs);
        Obs.Expect('obj_key_0', 'ret=Yes len=2 codes=107,122 out={"kz":"v"}');
        Obs.Expect('obj_key_1', 'ret=Yes len=3 codes=107,1,122 out={"k\u0001z":"v"}');
        Obs.Expect('obj_key_2', 'ret=Yes len=3 codes=107,2,122 out={"k\u0002z":"v"}');
        Obs.Expect('obj_key_3', 'ret=Yes len=3 codes=107,3,122 out={"k\u0003z":"v"}');
        Obs.Expect('obj_key_4', 'ret=Yes len=3 codes=107,4,122 out={"k\u0004z":"v"}');
        Obs.Expect('obj_key_5', 'ret=Yes len=3 codes=107,5,122 out={"k\u0005z":"v"}');
        Obs.Expect('obj_key_6', 'ret=Yes len=3 codes=107,6,122 out={"k\u0006z":"v"}');
        Obs.Expect('obj_key_7', 'ret=Yes len=3 codes=107,7,122 out={"k\u0007z":"v"}');
        Obs.Expect('obj_key_8', 'ret=Yes len=3 codes=107,8,122 out={"k\bz":"v"}');
        Obs.Expect('obj_key_9', 'ret=Yes len=3 codes=107,9,122 out={"k\tz":"v"}');
        Obs.Expect('obj_key_10', 'ret=Yes len=3 codes=107,10,122 out={"k\nz":"v"}');
        Obs.Expect('obj_key_11', 'ret=Yes len=3 codes=107,11,122 out={"k\u000bz":"v"}');
        Obs.Expect('obj_key_12', 'ret=Yes len=3 codes=107,12,122 out={"k\fz":"v"}');
        Obs.Expect('obj_key_13', 'ret=Yes len=3 codes=107,13,122 out={"k\rz":"v"}');
        Obs.Expect('obj_key_14', 'ret=Yes len=3 codes=107,14,122 out={"k\u000ez":"v"}');
        Obs.Expect('obj_key_15', 'ret=Yes len=3 codes=107,15,122 out={"k\u000fz":"v"}');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromText_DoubleQuotedKey_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'key', 16, 31, Obs);
        Obs.Expect('obj_key_16', 'ret=Yes len=3 codes=107,16,122 out={"k\u0010z":"v"}');
        Obs.Expect('obj_key_17', 'ret=Yes len=3 codes=107,17,122 out={"k\u0011z":"v"}');
        Obs.Expect('obj_key_18', 'ret=Yes len=3 codes=107,18,122 out={"k\u0012z":"v"}');
        Obs.Expect('obj_key_19', 'ret=Yes len=3 codes=107,19,122 out={"k\u0013z":"v"}');
        Obs.Expect('obj_key_20', 'ret=Yes len=3 codes=107,20,122 out={"k\u0014z":"v"}');
        Obs.Expect('obj_key_21', 'ret=Yes len=3 codes=107,21,122 out={"k\u0015z":"v"}');
        Obs.Expect('obj_key_22', 'ret=Yes len=3 codes=107,22,122 out={"k\u0016z":"v"}');
        Obs.Expect('obj_key_23', 'ret=Yes len=3 codes=107,23,122 out={"k\u0017z":"v"}');
        Obs.Expect('obj_key_24', 'ret=Yes len=3 codes=107,24,122 out={"k\u0018z":"v"}');
        Obs.Expect('obj_key_25', 'ret=Yes len=3 codes=107,25,122 out={"k\u0019z":"v"}');
        Obs.Expect('obj_key_26', 'ret=Yes len=3 codes=107,26,122 out={"k\u001az":"v"}');
        Obs.Expect('obj_key_27', 'ret=Yes len=3 codes=107,27,122 out={"k\u001bz":"v"}');
        Obs.Expect('obj_key_28', 'ret=Yes len=3 codes=107,28,122 out={"k\u001cz":"v"}');
        Obs.Expect('obj_key_29', 'ret=Yes len=3 codes=107,29,122 out={"k\u001dz":"v"}');
        Obs.Expect('obj_key_30', 'ret=Yes len=3 codes=107,30,122 out={"k\u001ez":"v"}');
        Obs.Expect('obj_key_31', 'ret=Yes len=3 codes=107,31,122 out={"k\u001fz":"v"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedKey_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'key', 0, 15, Obs);
        Obs.Expect('tok_key_0', 'ret=Yes len=2 codes=107,122 out={"kz":"v"}');
        Obs.Expect('tok_key_1', 'ret=Yes len=3 codes=107,1,122 out={"k\u0001z":"v"}');
        Obs.Expect('tok_key_2', 'ret=Yes len=3 codes=107,2,122 out={"k\u0002z":"v"}');
        Obs.Expect('tok_key_3', 'ret=Yes len=3 codes=107,3,122 out={"k\u0003z":"v"}');
        Obs.Expect('tok_key_4', 'ret=Yes len=3 codes=107,4,122 out={"k\u0004z":"v"}');
        Obs.Expect('tok_key_5', 'ret=Yes len=3 codes=107,5,122 out={"k\u0005z":"v"}');
        Obs.Expect('tok_key_6', 'ret=Yes len=3 codes=107,6,122 out={"k\u0006z":"v"}');
        Obs.Expect('tok_key_7', 'ret=Yes len=3 codes=107,7,122 out={"k\u0007z":"v"}');
        Obs.Expect('tok_key_8', 'ret=Yes len=3 codes=107,8,122 out={"k\bz":"v"}');
        Obs.Expect('tok_key_9', 'ret=Yes len=3 codes=107,9,122 out={"k\tz":"v"}');
        Obs.Expect('tok_key_10', 'ret=Yes len=3 codes=107,10,122 out={"k\nz":"v"}');
        Obs.Expect('tok_key_11', 'ret=Yes len=3 codes=107,11,122 out={"k\u000bz":"v"}');
        Obs.Expect('tok_key_12', 'ret=Yes len=3 codes=107,12,122 out={"k\fz":"v"}');
        Obs.Expect('tok_key_13', 'ret=Yes len=3 codes=107,13,122 out={"k\rz":"v"}');
        Obs.Expect('tok_key_14', 'ret=Yes len=3 codes=107,14,122 out={"k\u000ez":"v"}');
        Obs.Expect('tok_key_15', 'ret=Yes len=3 codes=107,15,122 out={"k\u000fz":"v"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromText_DoubleQuotedKey_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'key', 16, 31, Obs);
        Obs.Expect('tok_key_16', 'ret=Yes len=3 codes=107,16,122 out={"k\u0010z":"v"}');
        Obs.Expect('tok_key_17', 'ret=Yes len=3 codes=107,17,122 out={"k\u0011z":"v"}');
        Obs.Expect('tok_key_18', 'ret=Yes len=3 codes=107,18,122 out={"k\u0012z":"v"}');
        Obs.Expect('tok_key_19', 'ret=Yes len=3 codes=107,19,122 out={"k\u0013z":"v"}');
        Obs.Expect('tok_key_20', 'ret=Yes len=3 codes=107,20,122 out={"k\u0014z":"v"}');
        Obs.Expect('tok_key_21', 'ret=Yes len=3 codes=107,21,122 out={"k\u0015z":"v"}');
        Obs.Expect('tok_key_22', 'ret=Yes len=3 codes=107,22,122 out={"k\u0016z":"v"}');
        Obs.Expect('tok_key_23', 'ret=Yes len=3 codes=107,23,122 out={"k\u0017z":"v"}');
        Obs.Expect('tok_key_24', 'ret=Yes len=3 codes=107,24,122 out={"k\u0018z":"v"}');
        Obs.Expect('tok_key_25', 'ret=Yes len=3 codes=107,25,122 out={"k\u0019z":"v"}');
        Obs.Expect('tok_key_26', 'ret=Yes len=3 codes=107,26,122 out={"k\u001az":"v"}');
        Obs.Expect('tok_key_27', 'ret=Yes len=3 codes=107,27,122 out={"k\u001bz":"v"}');
        Obs.Expect('tok_key_28', 'ret=Yes len=3 codes=107,28,122 out={"k\u001cz":"v"}');
        Obs.Expect('tok_key_29', 'ret=Yes len=3 codes=107,29,122 out={"k\u001dz":"v"}');
        Obs.Expect('tok_key_30', 'ret=Yes len=3 codes=107,30,122 out={"k\u001ez":"v"}');
        Obs.Expect('tok_key_31', 'ret=Yes len=3 codes=107,31,122 out={"k\u001fz":"v"}');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'sq', 0, 15, Obs);
        Obs.Expect('obj_sq_0', 'ret=Yes len=2 codes=120,121 out={"a":"xy"}');
        Obs.Expect('obj_sq_1', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('obj_sq_2', 'ret=Yes len=3 codes=120,2,121 out={"a":"x\u0002y"}');
        Obs.Expect('obj_sq_3', 'ret=Yes len=3 codes=120,3,121 out={"a":"x\u0003y"}');
        Obs.Expect('obj_sq_4', 'ret=Yes len=3 codes=120,4,121 out={"a":"x\u0004y"}');
        Obs.Expect('obj_sq_5', 'ret=Yes len=3 codes=120,5,121 out={"a":"x\u0005y"}');
        Obs.Expect('obj_sq_6', 'ret=Yes len=3 codes=120,6,121 out={"a":"x\u0006y"}');
        Obs.Expect('obj_sq_7', 'ret=Yes len=3 codes=120,7,121 out={"a":"x\u0007y"}');
        Obs.Expect('obj_sq_8', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('obj_sq_9', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('obj_sq_10', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('obj_sq_11', 'ret=Yes len=3 codes=120,11,121 out={"a":"x\u000by"}');
        Obs.Expect('obj_sq_12', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('obj_sq_13', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('obj_sq_14', 'ret=Yes len=3 codes=120,14,121 out={"a":"x\u000ey"}');
        Obs.Expect('obj_sq_15', 'ret=Yes len=3 codes=120,15,121 out={"a":"x\u000fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('obj', 'sq', 16, 31, Obs);
        Obs.Expect('obj_sq_16', 'ret=Yes len=3 codes=120,16,121 out={"a":"x\u0010y"}');
        Obs.Expect('obj_sq_17', 'ret=Yes len=3 codes=120,17,121 out={"a":"x\u0011y"}');
        Obs.Expect('obj_sq_18', 'ret=Yes len=3 codes=120,18,121 out={"a":"x\u0012y"}');
        Obs.Expect('obj_sq_19', 'ret=Yes len=3 codes=120,19,121 out={"a":"x\u0013y"}');
        Obs.Expect('obj_sq_20', 'ret=Yes len=3 codes=120,20,121 out={"a":"x\u0014y"}');
        Obs.Expect('obj_sq_21', 'ret=Yes len=3 codes=120,21,121 out={"a":"x\u0015y"}');
        Obs.Expect('obj_sq_22', 'ret=Yes len=3 codes=120,22,121 out={"a":"x\u0016y"}');
        Obs.Expect('obj_sq_23', 'ret=Yes len=3 codes=120,23,121 out={"a":"x\u0017y"}');
        Obs.Expect('obj_sq_24', 'ret=Yes len=3 codes=120,24,121 out={"a":"x\u0018y"}');
        Obs.Expect('obj_sq_25', 'ret=Yes len=3 codes=120,25,121 out={"a":"x\u0019y"}');
        Obs.Expect('obj_sq_26', 'ret=Yes len=3 codes=120,26,121 out={"a":"x\u001ay"}');
        Obs.Expect('obj_sq_27', 'ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('obj_sq_28', 'ret=Yes len=3 codes=120,28,121 out={"a":"x\u001cy"}');
        Obs.Expect('obj_sq_29', 'ret=Yes len=3 codes=120,29,121 out={"a":"x\u001dy"}');
        Obs.Expect('obj_sq_30', 'ret=Yes len=3 codes=120,30,121 out={"a":"x\u001ey"}');
        Obs.Expect('obj_sq_31', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'sq', 0, 15, Obs);
        Obs.Expect('tok_sq_0', 'ret=Yes len=2 codes=120,121 out={"a":"xy"}');
        Obs.Expect('tok_sq_1', 'ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('tok_sq_2', 'ret=Yes len=3 codes=120,2,121 out={"a":"x\u0002y"}');
        Obs.Expect('tok_sq_3', 'ret=Yes len=3 codes=120,3,121 out={"a":"x\u0003y"}');
        Obs.Expect('tok_sq_4', 'ret=Yes len=3 codes=120,4,121 out={"a":"x\u0004y"}');
        Obs.Expect('tok_sq_5', 'ret=Yes len=3 codes=120,5,121 out={"a":"x\u0005y"}');
        Obs.Expect('tok_sq_6', 'ret=Yes len=3 codes=120,6,121 out={"a":"x\u0006y"}');
        Obs.Expect('tok_sq_7', 'ret=Yes len=3 codes=120,7,121 out={"a":"x\u0007y"}');
        Obs.Expect('tok_sq_8', 'ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('tok_sq_9', 'ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('tok_sq_10', 'ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('tok_sq_11', 'ret=Yes len=3 codes=120,11,121 out={"a":"x\u000by"}');
        Obs.Expect('tok_sq_12', 'ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('tok_sq_13', 'ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('tok_sq_14', 'ret=Yes len=3 codes=120,14,121 out={"a":"x\u000ey"}');
        Obs.Expect('tok_sq_15', 'ret=Yes len=3 codes=120,15,121 out={"a":"x\u000fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('tok', 'sq', 16, 31, Obs);
        Obs.Expect('tok_sq_16', 'ret=Yes len=3 codes=120,16,121 out={"a":"x\u0010y"}');
        Obs.Expect('tok_sq_17', 'ret=Yes len=3 codes=120,17,121 out={"a":"x\u0011y"}');
        Obs.Expect('tok_sq_18', 'ret=Yes len=3 codes=120,18,121 out={"a":"x\u0012y"}');
        Obs.Expect('tok_sq_19', 'ret=Yes len=3 codes=120,19,121 out={"a":"x\u0013y"}');
        Obs.Expect('tok_sq_20', 'ret=Yes len=3 codes=120,20,121 out={"a":"x\u0014y"}');
        Obs.Expect('tok_sq_21', 'ret=Yes len=3 codes=120,21,121 out={"a":"x\u0015y"}');
        Obs.Expect('tok_sq_22', 'ret=Yes len=3 codes=120,22,121 out={"a":"x\u0016y"}');
        Obs.Expect('tok_sq_23', 'ret=Yes len=3 codes=120,23,121 out={"a":"x\u0017y"}');
        Obs.Expect('tok_sq_24', 'ret=Yes len=3 codes=120,24,121 out={"a":"x\u0018y"}');
        Obs.Expect('tok_sq_25', 'ret=Yes len=3 codes=120,25,121 out={"a":"x\u0019y"}');
        Obs.Expect('tok_sq_26', 'ret=Yes len=3 codes=120,26,121 out={"a":"x\u001ay"}');
        Obs.Expect('tok_sq_27', 'ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('tok_sq_28', 'ret=Yes len=3 codes=120,28,121 out={"a":"x\u001cy"}');
        Obs.Expect('tok_sq_29', 'ret=Yes len=3 codes=120,29,121 out={"a":"x\u001dy"}');
        Obs.Expect('tok_sq_30', 'ret=Yes len=3 codes=120,30,121 out={"a":"x\u001ey"}');
        Obs.Expect('tok_sq_31', 'ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Array_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'sq', 0, 15, Obs);
        Obs.Expect('arr_sq_0', 'ret=Yes len=2 codes=120,121 out=["xy"]');
        Obs.Expect('arr_sq_1', 'ret=Yes len=3 codes=120,1,121 out=["x\u0001y"]');
        Obs.Expect('arr_sq_2', 'ret=Yes len=3 codes=120,2,121 out=["x\u0002y"]');
        Obs.Expect('arr_sq_3', 'ret=Yes len=3 codes=120,3,121 out=["x\u0003y"]');
        Obs.Expect('arr_sq_4', 'ret=Yes len=3 codes=120,4,121 out=["x\u0004y"]');
        Obs.Expect('arr_sq_5', 'ret=Yes len=3 codes=120,5,121 out=["x\u0005y"]');
        Obs.Expect('arr_sq_6', 'ret=Yes len=3 codes=120,6,121 out=["x\u0006y"]');
        Obs.Expect('arr_sq_7', 'ret=Yes len=3 codes=120,7,121 out=["x\u0007y"]');
        Obs.Expect('arr_sq_8', 'ret=Yes len=3 codes=120,8,121 out=["x\by"]');
        Obs.Expect('arr_sq_9', 'ret=Yes len=3 codes=120,9,121 out=["x\ty"]');
        Obs.Expect('arr_sq_10', 'ret=Yes len=3 codes=120,10,121 out=["x\ny"]');
        Obs.Expect('arr_sq_11', 'ret=Yes len=3 codes=120,11,121 out=["x\u000by"]');
        Obs.Expect('arr_sq_12', 'ret=Yes len=3 codes=120,12,121 out=["x\fy"]');
        Obs.Expect('arr_sq_13', 'ret=Yes len=3 codes=120,13,121 out=["x\ry"]');
        Obs.Expect('arr_sq_14', 'ret=Yes len=3 codes=120,14,121 out=["x\u000ey"]');
        Obs.Expect('arr_sq_15', 'ret=Yes len=3 codes=120,15,121 out=["x\u000fy"]');
        Obs.Verify();
    end;

    [Test]
    procedure Array_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('arr', 'sq', 16, 31, Obs);
        Obs.Expect('arr_sq_16', 'ret=Yes len=3 codes=120,16,121 out=["x\u0010y"]');
        Obs.Expect('arr_sq_17', 'ret=Yes len=3 codes=120,17,121 out=["x\u0011y"]');
        Obs.Expect('arr_sq_18', 'ret=Yes len=3 codes=120,18,121 out=["x\u0012y"]');
        Obs.Expect('arr_sq_19', 'ret=Yes len=3 codes=120,19,121 out=["x\u0013y"]');
        Obs.Expect('arr_sq_20', 'ret=Yes len=3 codes=120,20,121 out=["x\u0014y"]');
        Obs.Expect('arr_sq_21', 'ret=Yes len=3 codes=120,21,121 out=["x\u0015y"]');
        Obs.Expect('arr_sq_22', 'ret=Yes len=3 codes=120,22,121 out=["x\u0016y"]');
        Obs.Expect('arr_sq_23', 'ret=Yes len=3 codes=120,23,121 out=["x\u0017y"]');
        Obs.Expect('arr_sq_24', 'ret=Yes len=3 codes=120,24,121 out=["x\u0018y"]');
        Obs.Expect('arr_sq_25', 'ret=Yes len=3 codes=120,25,121 out=["x\u0019y"]');
        Obs.Expect('arr_sq_26', 'ret=Yes len=3 codes=120,26,121 out=["x\u001ay"]');
        Obs.Expect('arr_sq_27', 'ret=Yes len=3 codes=120,27,121 out=["x\u001by"]');
        Obs.Expect('arr_sq_28', 'ret=Yes len=3 codes=120,28,121 out=["x\u001cy"]');
        Obs.Expect('arr_sq_29', 'ret=Yes len=3 codes=120,29,121 out=["x\u001dy"]');
        Obs.Expect('arr_sq_30', 'ret=Yes len=3 codes=120,30,121 out=["x\u001ey"]');
        Obs.Expect('arr_sq_31', 'ret=Yes len=3 codes=120,31,121 out=["x\u001fy"]');
        Obs.Verify();
    end;

    [Test]
    procedure Value_ReadFromText_SingleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'sq', 0, 15, Obs);
        Obs.Expect('val_sq_0', 'ret=Yes len=2 codes=120,121 out="xy"');
        Obs.Expect('val_sq_1', 'ret=Yes len=3 codes=120,1,121 out="x\u0001y"');
        Obs.Expect('val_sq_2', 'ret=Yes len=3 codes=120,2,121 out="x\u0002y"');
        Obs.Expect('val_sq_3', 'ret=Yes len=3 codes=120,3,121 out="x\u0003y"');
        Obs.Expect('val_sq_4', 'ret=Yes len=3 codes=120,4,121 out="x\u0004y"');
        Obs.Expect('val_sq_5', 'ret=Yes len=3 codes=120,5,121 out="x\u0005y"');
        Obs.Expect('val_sq_6', 'ret=Yes len=3 codes=120,6,121 out="x\u0006y"');
        Obs.Expect('val_sq_7', 'ret=Yes len=3 codes=120,7,121 out="x\u0007y"');
        Obs.Expect('val_sq_8', 'ret=Yes len=3 codes=120,8,121 out="x\by"');
        Obs.Expect('val_sq_9', 'ret=Yes len=3 codes=120,9,121 out="x\ty"');
        Obs.Expect('val_sq_10', 'ret=Yes len=3 codes=120,10,121 out="x\ny"');
        Obs.Expect('val_sq_11', 'ret=Yes len=3 codes=120,11,121 out="x\u000by"');
        Obs.Expect('val_sq_12', 'ret=Yes len=3 codes=120,12,121 out="x\fy"');
        Obs.Expect('val_sq_13', 'ret=Yes len=3 codes=120,13,121 out="x\ry"');
        Obs.Expect('val_sq_14', 'ret=Yes len=3 codes=120,14,121 out="x\u000ey"');
        Obs.Expect('val_sq_15', 'ret=Yes len=3 codes=120,15,121 out="x\u000fy"');
        Obs.Verify();
    end;

    [Test]
    procedure Value_ReadFromText_SingleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        Sweep('val', 'sq', 16, 31, Obs);
        Obs.Expect('val_sq_16', 'ret=Yes len=3 codes=120,16,121 out="x\u0010y"');
        Obs.Expect('val_sq_17', 'ret=Yes len=3 codes=120,17,121 out="x\u0011y"');
        Obs.Expect('val_sq_18', 'ret=Yes len=3 codes=120,18,121 out="x\u0012y"');
        Obs.Expect('val_sq_19', 'ret=Yes len=3 codes=120,19,121 out="x\u0013y"');
        Obs.Expect('val_sq_20', 'ret=Yes len=3 codes=120,20,121 out="x\u0014y"');
        Obs.Expect('val_sq_21', 'ret=Yes len=3 codes=120,21,121 out="x\u0015y"');
        Obs.Expect('val_sq_22', 'ret=Yes len=3 codes=120,22,121 out="x\u0016y"');
        Obs.Expect('val_sq_23', 'ret=Yes len=3 codes=120,23,121 out="x\u0017y"');
        Obs.Expect('val_sq_24', 'ret=Yes len=3 codes=120,24,121 out="x\u0018y"');
        Obs.Expect('val_sq_25', 'ret=Yes len=3 codes=120,25,121 out="x\u0019y"');
        Obs.Expect('val_sq_26', 'ret=Yes len=3 codes=120,26,121 out="x\u001ay"');
        Obs.Expect('val_sq_27', 'ret=Yes len=3 codes=120,27,121 out="x\u001by"');
        Obs.Expect('val_sq_28', 'ret=Yes len=3 codes=120,28,121 out="x\u001cy"');
        Obs.Expect('val_sq_29', 'ret=Yes len=3 codes=120,29,121 out="x\u001dy"');
        Obs.Expect('val_sq_30', 'ret=Yes len=3 codes=120,30,121 out="x\u001ey"');
        Obs.Expect('val_sq_31', 'ret=Yes len=3 codes=120,31,121 out="x\u001fy"');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('obj', 0, 15, Obs);
        Obs.Expect('obj_stream_0', 'bytes=11 ret=Yes len=3 codes=120,0,121 out={"a":"x\u0000y"}');
        Obs.Expect('obj_stream_1', 'bytes=11 ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('obj_stream_2', 'bytes=11 ret=Yes len=3 codes=120,2,121 out={"a":"x\u0002y"}');
        Obs.Expect('obj_stream_3', 'bytes=11 ret=Yes len=3 codes=120,3,121 out={"a":"x\u0003y"}');
        Obs.Expect('obj_stream_4', 'bytes=11 ret=Yes len=3 codes=120,4,121 out={"a":"x\u0004y"}');
        Obs.Expect('obj_stream_5', 'bytes=11 ret=Yes len=3 codes=120,5,121 out={"a":"x\u0005y"}');
        Obs.Expect('obj_stream_6', 'bytes=11 ret=Yes len=3 codes=120,6,121 out={"a":"x\u0006y"}');
        Obs.Expect('obj_stream_7', 'bytes=11 ret=Yes len=3 codes=120,7,121 out={"a":"x\u0007y"}');
        Obs.Expect('obj_stream_8', 'bytes=11 ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('obj_stream_9', 'bytes=11 ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('obj_stream_10', 'bytes=11 ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('obj_stream_11', 'bytes=11 ret=Yes len=3 codes=120,11,121 out={"a":"x\u000by"}');
        Obs.Expect('obj_stream_12', 'bytes=11 ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('obj_stream_13', 'bytes=11 ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('obj_stream_14', 'bytes=11 ret=Yes len=3 codes=120,14,121 out={"a":"x\u000ey"}');
        Obs.Expect('obj_stream_15', 'bytes=11 ret=Yes len=3 codes=120,15,121 out={"a":"x\u000fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Object_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('obj', 16, 31, Obs);
        Obs.Expect('obj_stream_16', 'bytes=11 ret=Yes len=3 codes=120,16,121 out={"a":"x\u0010y"}');
        Obs.Expect('obj_stream_17', 'bytes=11 ret=Yes len=3 codes=120,17,121 out={"a":"x\u0011y"}');
        Obs.Expect('obj_stream_18', 'bytes=11 ret=Yes len=3 codes=120,18,121 out={"a":"x\u0012y"}');
        Obs.Expect('obj_stream_19', 'bytes=11 ret=Yes len=3 codes=120,19,121 out={"a":"x\u0013y"}');
        Obs.Expect('obj_stream_20', 'bytes=11 ret=Yes len=3 codes=120,20,121 out={"a":"x\u0014y"}');
        Obs.Expect('obj_stream_21', 'bytes=11 ret=Yes len=3 codes=120,21,121 out={"a":"x\u0015y"}');
        Obs.Expect('obj_stream_22', 'bytes=11 ret=Yes len=3 codes=120,22,121 out={"a":"x\u0016y"}');
        Obs.Expect('obj_stream_23', 'bytes=11 ret=Yes len=3 codes=120,23,121 out={"a":"x\u0017y"}');
        Obs.Expect('obj_stream_24', 'bytes=11 ret=Yes len=3 codes=120,24,121 out={"a":"x\u0018y"}');
        Obs.Expect('obj_stream_25', 'bytes=11 ret=Yes len=3 codes=120,25,121 out={"a":"x\u0019y"}');
        Obs.Expect('obj_stream_26', 'bytes=11 ret=Yes len=3 codes=120,26,121 out={"a":"x\u001ay"}');
        Obs.Expect('obj_stream_27', 'bytes=11 ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('obj_stream_28', 'bytes=11 ret=Yes len=3 codes=120,28,121 out={"a":"x\u001cy"}');
        Obs.Expect('obj_stream_29', 'bytes=11 ret=Yes len=3 codes=120,29,121 out={"a":"x\u001dy"}');
        Obs.Expect('obj_stream_30', 'bytes=11 ret=Yes len=3 codes=120,30,121 out={"a":"x\u001ey"}');
        Obs.Expect('obj_stream_31', 'bytes=11 ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('tok', 0, 15, Obs);
        Obs.Expect('tok_stream_0', 'bytes=11 ret=Yes len=3 codes=120,0,121 out={"a":"x\u0000y"}');
        Obs.Expect('tok_stream_1', 'bytes=11 ret=Yes len=3 codes=120,1,121 out={"a":"x\u0001y"}');
        Obs.Expect('tok_stream_2', 'bytes=11 ret=Yes len=3 codes=120,2,121 out={"a":"x\u0002y"}');
        Obs.Expect('tok_stream_3', 'bytes=11 ret=Yes len=3 codes=120,3,121 out={"a":"x\u0003y"}');
        Obs.Expect('tok_stream_4', 'bytes=11 ret=Yes len=3 codes=120,4,121 out={"a":"x\u0004y"}');
        Obs.Expect('tok_stream_5', 'bytes=11 ret=Yes len=3 codes=120,5,121 out={"a":"x\u0005y"}');
        Obs.Expect('tok_stream_6', 'bytes=11 ret=Yes len=3 codes=120,6,121 out={"a":"x\u0006y"}');
        Obs.Expect('tok_stream_7', 'bytes=11 ret=Yes len=3 codes=120,7,121 out={"a":"x\u0007y"}');
        Obs.Expect('tok_stream_8', 'bytes=11 ret=Yes len=3 codes=120,8,121 out={"a":"x\by"}');
        Obs.Expect('tok_stream_9', 'bytes=11 ret=Yes len=3 codes=120,9,121 out={"a":"x\ty"}');
        Obs.Expect('tok_stream_10', 'bytes=11 ret=Yes len=3 codes=120,10,121 out={"a":"x\ny"}');
        Obs.Expect('tok_stream_11', 'bytes=11 ret=Yes len=3 codes=120,11,121 out={"a":"x\u000by"}');
        Obs.Expect('tok_stream_12', 'bytes=11 ret=Yes len=3 codes=120,12,121 out={"a":"x\fy"}');
        Obs.Expect('tok_stream_13', 'bytes=11 ret=Yes len=3 codes=120,13,121 out={"a":"x\ry"}');
        Obs.Expect('tok_stream_14', 'bytes=11 ret=Yes len=3 codes=120,14,121 out={"a":"x\u000ey"}');
        Obs.Expect('tok_stream_15', 'bytes=11 ret=Yes len=3 codes=120,15,121 out={"a":"x\u000fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Token_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('tok', 16, 31, Obs);
        Obs.Expect('tok_stream_16', 'bytes=11 ret=Yes len=3 codes=120,16,121 out={"a":"x\u0010y"}');
        Obs.Expect('tok_stream_17', 'bytes=11 ret=Yes len=3 codes=120,17,121 out={"a":"x\u0011y"}');
        Obs.Expect('tok_stream_18', 'bytes=11 ret=Yes len=3 codes=120,18,121 out={"a":"x\u0012y"}');
        Obs.Expect('tok_stream_19', 'bytes=11 ret=Yes len=3 codes=120,19,121 out={"a":"x\u0013y"}');
        Obs.Expect('tok_stream_20', 'bytes=11 ret=Yes len=3 codes=120,20,121 out={"a":"x\u0014y"}');
        Obs.Expect('tok_stream_21', 'bytes=11 ret=Yes len=3 codes=120,21,121 out={"a":"x\u0015y"}');
        Obs.Expect('tok_stream_22', 'bytes=11 ret=Yes len=3 codes=120,22,121 out={"a":"x\u0016y"}');
        Obs.Expect('tok_stream_23', 'bytes=11 ret=Yes len=3 codes=120,23,121 out={"a":"x\u0017y"}');
        Obs.Expect('tok_stream_24', 'bytes=11 ret=Yes len=3 codes=120,24,121 out={"a":"x\u0018y"}');
        Obs.Expect('tok_stream_25', 'bytes=11 ret=Yes len=3 codes=120,25,121 out={"a":"x\u0019y"}');
        Obs.Expect('tok_stream_26', 'bytes=11 ret=Yes len=3 codes=120,26,121 out={"a":"x\u001ay"}');
        Obs.Expect('tok_stream_27', 'bytes=11 ret=Yes len=3 codes=120,27,121 out={"a":"x\u001by"}');
        Obs.Expect('tok_stream_28', 'bytes=11 ret=Yes len=3 codes=120,28,121 out={"a":"x\u001cy"}');
        Obs.Expect('tok_stream_29', 'bytes=11 ret=Yes len=3 codes=120,29,121 out={"a":"x\u001dy"}');
        Obs.Expect('tok_stream_30', 'bytes=11 ret=Yes len=3 codes=120,30,121 out={"a":"x\u001ey"}');
        Obs.Expect('tok_stream_31', 'bytes=11 ret=Yes len=3 codes=120,31,121 out={"a":"x\u001fy"}');
        Obs.Verify();
    end;

    [Test]
    procedure Array_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('arr', 0, 15, Obs);
        Obs.Expect('arr_stream_0', 'bytes=7 ret=Yes len=3 codes=120,0,121 out=["x\u0000y"]');
        Obs.Expect('arr_stream_1', 'bytes=7 ret=Yes len=3 codes=120,1,121 out=["x\u0001y"]');
        Obs.Expect('arr_stream_2', 'bytes=7 ret=Yes len=3 codes=120,2,121 out=["x\u0002y"]');
        Obs.Expect('arr_stream_3', 'bytes=7 ret=Yes len=3 codes=120,3,121 out=["x\u0003y"]');
        Obs.Expect('arr_stream_4', 'bytes=7 ret=Yes len=3 codes=120,4,121 out=["x\u0004y"]');
        Obs.Expect('arr_stream_5', 'bytes=7 ret=Yes len=3 codes=120,5,121 out=["x\u0005y"]');
        Obs.Expect('arr_stream_6', 'bytes=7 ret=Yes len=3 codes=120,6,121 out=["x\u0006y"]');
        Obs.Expect('arr_stream_7', 'bytes=7 ret=Yes len=3 codes=120,7,121 out=["x\u0007y"]');
        Obs.Expect('arr_stream_8', 'bytes=7 ret=Yes len=3 codes=120,8,121 out=["x\by"]');
        Obs.Expect('arr_stream_9', 'bytes=7 ret=Yes len=3 codes=120,9,121 out=["x\ty"]');
        Obs.Expect('arr_stream_10', 'bytes=7 ret=Yes len=3 codes=120,10,121 out=["x\ny"]');
        Obs.Expect('arr_stream_11', 'bytes=7 ret=Yes len=3 codes=120,11,121 out=["x\u000by"]');
        Obs.Expect('arr_stream_12', 'bytes=7 ret=Yes len=3 codes=120,12,121 out=["x\fy"]');
        Obs.Expect('arr_stream_13', 'bytes=7 ret=Yes len=3 codes=120,13,121 out=["x\ry"]');
        Obs.Expect('arr_stream_14', 'bytes=7 ret=Yes len=3 codes=120,14,121 out=["x\u000ey"]');
        Obs.Expect('arr_stream_15', 'bytes=7 ret=Yes len=3 codes=120,15,121 out=["x\u000fy"]');
        Obs.Verify();
    end;

    [Test]
    procedure Array_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('arr', 16, 31, Obs);
        Obs.Expect('arr_stream_16', 'bytes=7 ret=Yes len=3 codes=120,16,121 out=["x\u0010y"]');
        Obs.Expect('arr_stream_17', 'bytes=7 ret=Yes len=3 codes=120,17,121 out=["x\u0011y"]');
        Obs.Expect('arr_stream_18', 'bytes=7 ret=Yes len=3 codes=120,18,121 out=["x\u0012y"]');
        Obs.Expect('arr_stream_19', 'bytes=7 ret=Yes len=3 codes=120,19,121 out=["x\u0013y"]');
        Obs.Expect('arr_stream_20', 'bytes=7 ret=Yes len=3 codes=120,20,121 out=["x\u0014y"]');
        Obs.Expect('arr_stream_21', 'bytes=7 ret=Yes len=3 codes=120,21,121 out=["x\u0015y"]');
        Obs.Expect('arr_stream_22', 'bytes=7 ret=Yes len=3 codes=120,22,121 out=["x\u0016y"]');
        Obs.Expect('arr_stream_23', 'bytes=7 ret=Yes len=3 codes=120,23,121 out=["x\u0017y"]');
        Obs.Expect('arr_stream_24', 'bytes=7 ret=Yes len=3 codes=120,24,121 out=["x\u0018y"]');
        Obs.Expect('arr_stream_25', 'bytes=7 ret=Yes len=3 codes=120,25,121 out=["x\u0019y"]');
        Obs.Expect('arr_stream_26', 'bytes=7 ret=Yes len=3 codes=120,26,121 out=["x\u001ay"]');
        Obs.Expect('arr_stream_27', 'bytes=7 ret=Yes len=3 codes=120,27,121 out=["x\u001by"]');
        Obs.Expect('arr_stream_28', 'bytes=7 ret=Yes len=3 codes=120,28,121 out=["x\u001cy"]');
        Obs.Expect('arr_stream_29', 'bytes=7 ret=Yes len=3 codes=120,29,121 out=["x\u001dy"]');
        Obs.Expect('arr_stream_30', 'bytes=7 ret=Yes len=3 codes=120,30,121 out=["x\u001ey"]');
        Obs.Expect('arr_stream_31', 'bytes=7 ret=Yes len=3 codes=120,31,121 out=["x\u001fy"]');
        Obs.Verify();
    end;

    [Test]
    procedure Value_ReadFromStream_DoubleQuotedValue_Codes0To15()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('val', 0, 15, Obs);
        Obs.Expect('val_stream_0', 'bytes=5 ret=Yes len=3 codes=120,0,121 out="x\u0000y"');
        Obs.Expect('val_stream_1', 'bytes=5 ret=Yes len=3 codes=120,1,121 out="x\u0001y"');
        Obs.Expect('val_stream_2', 'bytes=5 ret=Yes len=3 codes=120,2,121 out="x\u0002y"');
        Obs.Expect('val_stream_3', 'bytes=5 ret=Yes len=3 codes=120,3,121 out="x\u0003y"');
        Obs.Expect('val_stream_4', 'bytes=5 ret=Yes len=3 codes=120,4,121 out="x\u0004y"');
        Obs.Expect('val_stream_5', 'bytes=5 ret=Yes len=3 codes=120,5,121 out="x\u0005y"');
        Obs.Expect('val_stream_6', 'bytes=5 ret=Yes len=3 codes=120,6,121 out="x\u0006y"');
        Obs.Expect('val_stream_7', 'bytes=5 ret=Yes len=3 codes=120,7,121 out="x\u0007y"');
        Obs.Expect('val_stream_8', 'bytes=5 ret=Yes len=3 codes=120,8,121 out="x\by"');
        Obs.Expect('val_stream_9', 'bytes=5 ret=Yes len=3 codes=120,9,121 out="x\ty"');
        Obs.Expect('val_stream_10', 'bytes=5 ret=Yes len=3 codes=120,10,121 out="x\ny"');
        Obs.Expect('val_stream_11', 'bytes=5 ret=Yes len=3 codes=120,11,121 out="x\u000by"');
        Obs.Expect('val_stream_12', 'bytes=5 ret=Yes len=3 codes=120,12,121 out="x\fy"');
        Obs.Expect('val_stream_13', 'bytes=5 ret=Yes len=3 codes=120,13,121 out="x\ry"');
        Obs.Expect('val_stream_14', 'bytes=5 ret=Yes len=3 codes=120,14,121 out="x\u000ey"');
        Obs.Expect('val_stream_15', 'bytes=5 ret=Yes len=3 codes=120,15,121 out="x\u000fy"');
        Obs.Verify();
    end;

    [Test]
    procedure Value_ReadFromStream_DoubleQuotedValue_Codes16To31()
    var
        Obs: Codeunit "Probe Observer";
    begin
        SweepStream('val', 16, 31, Obs);
        Obs.Expect('val_stream_16', 'bytes=5 ret=Yes len=3 codes=120,16,121 out="x\u0010y"');
        Obs.Expect('val_stream_17', 'bytes=5 ret=Yes len=3 codes=120,17,121 out="x\u0011y"');
        Obs.Expect('val_stream_18', 'bytes=5 ret=Yes len=3 codes=120,18,121 out="x\u0012y"');
        Obs.Expect('val_stream_19', 'bytes=5 ret=Yes len=3 codes=120,19,121 out="x\u0013y"');
        Obs.Expect('val_stream_20', 'bytes=5 ret=Yes len=3 codes=120,20,121 out="x\u0014y"');
        Obs.Expect('val_stream_21', 'bytes=5 ret=Yes len=3 codes=120,21,121 out="x\u0015y"');
        Obs.Expect('val_stream_22', 'bytes=5 ret=Yes len=3 codes=120,22,121 out="x\u0016y"');
        Obs.Expect('val_stream_23', 'bytes=5 ret=Yes len=3 codes=120,23,121 out="x\u0017y"');
        Obs.Expect('val_stream_24', 'bytes=5 ret=Yes len=3 codes=120,24,121 out="x\u0018y"');
        Obs.Expect('val_stream_25', 'bytes=5 ret=Yes len=3 codes=120,25,121 out="x\u0019y"');
        Obs.Expect('val_stream_26', 'bytes=5 ret=Yes len=3 codes=120,26,121 out="x\u001ay"');
        Obs.Expect('val_stream_27', 'bytes=5 ret=Yes len=3 codes=120,27,121 out="x\u001by"');
        Obs.Expect('val_stream_28', 'bytes=5 ret=Yes len=3 codes=120,28,121 out="x\u001cy"');
        Obs.Expect('val_stream_29', 'bytes=5 ret=Yes len=3 codes=120,29,121 out="x\u001dy"');
        Obs.Expect('val_stream_30', 'bytes=5 ret=Yes len=3 codes=120,30,121 out="x\u001ey"');
        Obs.Expect('val_stream_31', 'bytes=5 ret=Yes len=3 codes=120,31,121 out="x\u001fy"');
        Obs.Verify();
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
        Obs.Expect('text1_after_c1_0', 'len=0 codes=');
        Obs.Expect('text1_q_after_c1_0', 'len=0 codes=');
        Obs.Expect('abc_after_s2_0', 'len=1 codes=97');
        Obs.Expect('obj_dq_abc_s2_0', 'ret=Yes len=1 codes=97 out={"a":"a"}');
        Obs.Expect('concat_x_ch0_y', 'len=2 codes=120,121');
        Obs.Expect('obj_dq_ch0', 'ret=Yes len=2 codes=120,121 out={"a":"xy"}');
        Obs.Verify();
    end;
}
