// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/jsonobject/jsonobject-writeto-instream-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT PnC Blob (71095)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: JSON streams (fixes-7) "WriteTo(OutStream) then the bytes read back one by one, for TextEncoding::UTF8, Windows, UTF16, with and without non-ASCII text; ReadFrom of a stream with a BOM"
// BC versions: 29 (27 and 28 by CI)

codeunit 71135 "LT PnC Json Streams"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Bytes(var Buffer: Record "LT PnC Blob" temporary): Text
    var
        InS: InStream;
        B: Byte;
        Result: Text;
    begin
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        while not InS.EOS() do begin
            InS.Read(B);
            Result += Format(B) + ' ';
        end;
        exit(Result);
    end;

    local procedure WriteObject(Json: Text; Encoding: TextEncoding; var Buffer: Record "LT PnC Blob" temporary)
    var
        JO: JsonObject;
        OutS: OutStream;
    begin
        JO.ReadFrom(Json);
        Buffer.DeleteAll();
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS, Encoding);
        JO.WriteTo(OutS);
        Buffer.Modify();
    end;

    [Test]
    procedure WriteTo_Ascii_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
    begin
        WriteObject('{"a":1}', TextEncoding::UTF8, Buffer);
        Observer.Observe('utf8', Bytes(Buffer));
        WriteObject('{"a":1}', TextEncoding::Windows, Buffer);
        Observer.Observe('windows', Bytes(Buffer));
        WriteObject('{"a":1}', TextEncoding::MSDos, Buffer);
        Observer.Observe('msdos', Bytes(Buffer));
        WriteObject('{"a":1}', TextEncoding::UTF16, Buffer);
        Observer.Observe('utf16', Bytes(Buffer));
        Observer.Expect('utf8', '{ " a " : 1 } ');
        Observer.Expect('windows', '{ " a " : 1 } ');
        Observer.Expect('msdos', '{ " a " : 1 } ');
        Observer.Expect('utf16', '{ " a " : 1 } ');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_NonAscii_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
    begin
        WriteObject('{"a":"é€"}', TextEncoding::UTF8, Buffer);
        Observer.Observe('utf8', Bytes(Buffer));
        WriteObject('{"a":"é€"}', TextEncoding::Windows, Buffer);
        Observer.Observe('windows', Bytes(Buffer));
        WriteObject('{"a":"é€"}', TextEncoding::MSDos, Buffer);
        Observer.Observe('msdos', Bytes(Buffer));
        WriteObject('{"a":"é€"}', TextEncoding::UTF16, Buffer);
        Observer.Observe('utf16', Bytes(Buffer));
        Observer.Expect('utf8', '{ " a " : " “ \u0014 Ë é ¼ " } ');
        Observer.Expect('windows', '{ " a " : " “ \u0014 Ë é ¼ " } ');
        Observer.Expect('msdos', '{ " a " : " “ \u0014 Ë é ¼ " } ');
        Observer.Expect('utf16', '{ " a " : " “ \u0014 Ë é ¼ " } ');
        Observer.Verify();
    end;

    [Test]
    procedure WriteTo_DefaultStream_And_Appending()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        JO: JsonObject;
        JA: JsonArray;
        OutS: OutStream;
    begin
        JO.ReadFrom('{"a":1}');
        JA.ReadFrom('[1,2]');
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        JO.WriteTo(OutS);
        Buffer.Modify();
        Observer.Observe('defaultStream', Bytes(Buffer));
        Buffer.Data.CreateOutStream(OutS);
        JO.WriteTo(OutS);
        JA.WriteTo(OutS);
        Buffer.Modify();
        Observer.Observe('objectThenArray', Bytes(Buffer));
        Buffer.Data.CreateOutStream(OutS);
        JA.WriteTo(OutS);
        Buffer.Modify();
        Observer.Observe('arrayOnly', Bytes(Buffer));
        Observer.Expect('defaultStream', '{ " a " : 1 } ');
        Observer.Expect('objectThenArray', '[ 1 , 2 ] 1 } ');
        Observer.Expect('arrayOnly', '[ 1 , 2 ] 1 } ');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_WithAndWithoutBom()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        JO: JsonObject;
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        Ok: Boolean;
    begin
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        OutS.WriteText('{"a":1}');
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        Ok := JO.ReadFrom(InS);
        JO.WriteTo(Txt);
        Observer.Observe('plain', Format(Ok) + '|' + Txt);
        Buffer.Data.CreateOutStream(OutS);
        WriteBytes(OutS, 239, 187, 191);
        OutS.WriteText('{"a":2}');
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        Clear(JO);
        Ok := JO.ReadFrom(InS);
        Observer.Observe('utf8Bom', 'no error');
        Buffer.Data.CreateInStream(InS, TextEncoding::UTF8);
        Clear(JO);
        Ok := JO.ReadFrom(InS);
        Observer.Observe('utf8BomUtf8Stream', 'no error');
        Observer.Expect('plain', 'Yes|{"a":1}');
        Observer.Expect('utf8Bom', 'no error');
        Observer.Expect('utf8BomUtf8Stream', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure ReadFrom_RestOfStream()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        JO: JsonObject;
        OutS: OutStream;
        InS: InStream;
        Txt: Text;
        Rest: Text;
    begin
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
        OutS.WriteText('XX{"a":1}');
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        InS.ReadText(Txt, 2);
        JO.ReadFrom(InS);
        JO.WriteTo(Rest);
        Observer.Observe('afterTwoChars', Txt + '|' + Rest);
        Observer.Observe('eosAfter', Format(InS.EOS()));
        Buffer.Data.CreateInStream(InS);
        asserterror JO.ReadFrom(InS);
        Observer.ObserveError('prefixIncluded');
        Observer.Expect('afterTwoChars', 'XX|{"a":1}');
        Observer.Expect('eosAfter', 'No');
        Observer.Expect('prefixIncluded|text', 'The data does not represent a valid JSON token.');
        Observer.Expect('prefixIncluded|code', 'InvalidJsonData');
        Observer.Verify();
    end;

    local procedure WriteBytes(var OutS: OutStream; A: Byte; B: Byte; C: Byte)
    begin
        OutS.Write(A);
        OutS.Write(B);
        OutS.Write(C);
    end;
}

codeunit 71136 "LT PnC InStream Read Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Fill(var Buffer: Record "LT PnC Blob" temporary; var OutS: OutStream)
    begin
        Buffer.DeleteAll();
        Buffer.Insert();
        Buffer.Data.CreateOutStream(OutS);
    end;

    [Test]
    procedure Read_Text_AfterWriteText()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        T: Text;
        n: Integer;
    begin
        Fill(Buffer, OutS);
        T := 'abc';
        OutS.Write(T);
        T := 'de';
        OutS.Write(T);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        Clear(T);
        n := InS.Read(T);
        Observer.Observe('first', '[' + T + ']' + Format(n));
        Observer.Observe('first.eos', Format(InS.EOS()));
        n := InS.Read(T);
        Observer.Observe('second', '[' + T + ']' + Format(n));
        Observer.Observe('second.eos', Format(InS.EOS()));
        Observer.Expect('first', '[abc]4');
        Observer.Expect('first.eos', 'No');
        Observer.Expect('second', '[de]3');
        Observer.Expect('second.eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Text_NoTerminator()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        T: Text;
        n: Integer;
    begin
        Fill(Buffer, OutS);
        OutS.WriteText('abc');
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        n := InS.Read(T);
        Observer.Observe('writeText', '[' + T + ']' + Format(n));
        Observer.Observe('eos', Format(InS.EOS()));
        Observer.Expect('writeText', '[abc]3');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Text_NonAscii()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        T: Text;
        n: Integer;
    begin
        Fill(Buffer, OutS);
        T := 'é€x';
        OutS.Write(T);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        Clear(T);
        n := InS.Read(T);
        Observer.Observe('nonAscii', '[' + T + ']' + Format(n) + '|' + Format(StrLen(T)));
        Observer.Expect('nonAscii', '[é€x]4|3');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Text_EmptyAndMixed()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        T: Text;
        I: Integer;
        n: Integer;
    begin
        Fill(Buffer, OutS);
        T := '';
        OutS.Write(T);
        I := 42;
        OutS.Write(I);
        T := 'z';
        OutS.Write(T);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        Clear(T);
        n := InS.Read(T);
        Observer.Observe('empty', '[' + T + ']' + Format(n));
        Clear(I);
        n := InS.Read(I);
        Observer.Observe('integer', Format(I) + '|' + Format(n));
        n := InS.Read(T);
        Observer.Observe('last', '[' + T + ']' + Format(n));
        Observer.Observe('eos', Format(InS.EOS()));
        n := InS.Read(T);
        Observer.Observe('pastEnd', '[' + T + ']' + Format(n));
        Observer.Expect('empty', '[]1');
        Observer.Expect('integer', '42|4');
        Observer.Expect('last', '[z]2');
        Observer.Expect('eos', 'Yes');
        Observer.Expect('pastEnd', '[]0');
        Observer.Verify();
    end;

    [Test]
    procedure Read_Text_IntoCode_And_Length()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "LT PnC Blob" temporary;
        OutS: OutStream;
        InS: InStream;
        T: Text;
        C: Code[5];
        n: Integer;
    begin
        Fill(Buffer, OutS);
        T := 'abcdefgh';
        OutS.Write(T);
        Buffer.Modify();
        Buffer.CalcFields(Data);
        Buffer.Data.CreateInStream(InS);
        n := InS.Read(C);
        Observer.Observe('code5', '[' + C + ']' + Format(n));
        Clear(T);
        n := InS.Read(T, 2);
        Observer.Observe('lengthTwo', '[' + T + ']' + Format(n));
        Observer.Expect('code5', '[ABCDE]5');
        Observer.Expect('lengthTwo', '[fg]2');
        Observer.Verify();
    end;
}
