// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/instream/instream-read-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 72525, table 72526
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed rows (Probe round 6, types and JSON): "InStream.Read(Text, Length) - Pinned only for a Windows-encoded stream";
// (Probe fixes) "InStream.Read(Text) - Reads up to the zero byte ..." and "JSON on streams - ReadFrom(InStream) of 5, true, null, invalid UTF-8, UTF-16 with BOM"
// Facts: Read(Text) and Read(Text, Length) on UTF-8 / UTF-16 / Windows streams, at the end of the stream; JsonObject/JsonArray/JsonToken ReadFrom(InStream) of odd first tokens
// Writer TO: TO_ReadText_NonAscii_NoTerminator was measured on a BC 29.0 online sandbox (Read(Text) of non-ASCII on UTF-8, UTF-16 and MS-DOS streams).
// BC versions: 29 (27 and 28 by CI)

table 72526 "LT PnE Stream Rec"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Data; Blob) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 72525 "LT PnE Stream Read"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexVal(c: Char): Integer
    begin
        exit(StrPos('0123456789ABCDEF', UpperCase(Format(c))) - 1);
    end;

    // Stores the bytes given as hex text in the blob of a fresh row.
    local procedure PutBytes(var Rec: Record "LT PnE Stream Rec"; Hex: Text; Enc: TextEncoding)
    var
        Out: OutStream;
        B: Byte;
        i: Integer;
    begin
        Rec.DeleteAll();
        Rec.Init();
        Rec.Id := 1;
        Rec.Data.CreateOutStream(Out, Enc);
        i := 1;
        while i < StrLen(Hex) do begin
            B := HexVal(Hex[i]) * 16 + HexVal(Hex[i + 1]);
            Out.Write(B);
            i += 2;
        end;
        Rec.Insert();
    end;

    local procedure Dump(Txt: Text): Text
    var
        i: Integer;
        Ord: Integer;
        R: Text;
    begin
        for i := 1 to StrLen(Txt) do begin
            Ord := Txt[i];
            R += Format(Ord) + ' ';
        end;
        exit(Format(StrLen(Txt)) + ':' + R);
    end;

    [Test]
    procedure ReadText_Utf8_WithTerminator()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        PutBytes(Rec, '68656C6C6F00776F726C6400', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T);
        Observer.Observe('first', Format(N) + '|' + T);
        N := Ins.Read(T);
        Observer.Observe('second', Format(N) + '|' + T);
        Observer.Observe('eos', Format(Ins.EOS()));
        N := Ins.Read(T);
        Observer.Observe('atEnd', Format(N) + '|' + T);
        Rec.DeleteAll();
        Observer.Expect('first', '6|hello');
        Observer.Expect('second', '6|world');
        Observer.Expect('eos', 'Yes');
        Observer.Expect('atEnd', '1|');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_Utf8_NoTerminator()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        PutBytes(Rec, '68656C6C6F', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T);
        Observer.Observe('noTerminator', Format(N) + '|' + T);
        Observer.Observe('eos', Format(Ins.EOS()));
        N := Ins.Read(T);
        Observer.Observe('atEnd', Format(N) + '|' + T);
        Rec.DeleteAll();
        Observer.Expect('noTerminator', '6|hello');
        Observer.Expect('eos', 'Yes');
        Observer.Expect('atEnd', '1|');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_Utf8_NonAscii()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        PutBytes(Rec, '77C3B6726C6400', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T);
        Observer.Observe('utf8', Format(N) + '|' + Dump(T));
        Rec.DeleteAll();
        Observer.Expect('utf8', '7|5:119 246 114 108 100 ');
        Observer.Verify();
    end;

    [Test]
    procedure TO_ReadText_NonAscii_NoTerminator()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        // Writer TO: Read(Text) of non-ASCII characters with no zero byte after them, on UTF-8 and UTF-16 streams,
        // then once more at the end; and two texts with non-ASCII characters one after the other.
        PutBytes(Rec, '77C3B6726C64', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T);
        Observer.Observe('utf8', Format(N) + '|' + Dump(T));
        N := Ins.Read(T);
        Observer.Observe('utf8atEnd', Format(N) + '|' + Dump(T));
        PutBytes(Rec, 'C3A4C3B600E282AC4100', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T);
        Observer.Observe('utf8first', Format(N) + '|' + Dump(T));
        N := Ins.Read(T);
        Observer.Observe('utf8second', Format(N) + '|' + Dump(T));
        PutBytes(Rec, '7700F6007200', TextEncoding::UTF16);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        N := Ins.Read(T);
        Observer.Observe('utf16', Format(N) + '|' + Dump(T));
        PutBytes(Rec, '7700F60072000000', TextEncoding::UTF16);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        N := Ins.Read(T);
        Observer.Observe('utf16terminated', Format(N) + '|' + Dump(T));
        PutBytes(Rec, '77F6726C6400', TextEncoding::MSDos);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::MSDos);
        N := Ins.Read(T);
        Observer.Observe('msdos', Format(N) + '|' + Dump(T));
        Rec.DeleteAll();
        Observer.Expect('utf8', '7|5:119 246 114 108 100 ');
        Observer.Expect('utf8atEnd', '1|0:');
        Observer.Expect('utf8first', '5|2:228 246 ');
        Observer.Expect('utf8second', '5|2:8364 65 ');
        Observer.Expect('utf16', '4|1:119 ');
        Observer.Expect('utf16terminated', '4|1:119 ');
        Observer.Expect('msdos', '6|5:119 247 114 108 100 ');
        Observer.Verify();
    end;

    [Test]
    procedure ReadText_Utf16()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        PutBytes(Rec, '680065006C006C006F000000', TextEncoding::UTF16);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        N := Ins.Read(T);
        Observer.Observe('utf16', Format(N) + '|' + Dump(T));
        Observer.Observe('eos', Format(Ins.EOS()));
        Rec.DeleteAll();
        Observer.Expect('utf16', '12|5:104 101 108 108 111 ');
        Observer.Expect('eos', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ReadTextLength_Encodings()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        // bytes 80 and 9F lie in 128..159; E4 is above
        PutBytes(Rec, '416280419FE4', TextEncoding::Windows);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::Windows);
        N := Ins.Read(T, 6);
        Observer.Observe('windows6', Format(N) + '|' + Dump(T));
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        asserterror N := Ins.Read(T, 6);
        Observer.ObserveError('af163');
        Observer.Observe('utf8Invalid6', Format(N) + '|' + Dump(T));
        PutBytes(Rec, '68C3A4C3B6C3BC21', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T, 3);
        Observer.Observe('utf8len3', Format(N) + '|' + Dump(T));
        N := Ins.Read(T, 100);
        Observer.Observe('utf8rest', Format(N) + '|' + Dump(T));
        N := Ins.Read(T, 5);
        Observer.Observe('utf8atEnd', Format(N) + '|' + Dump(T));
        PutBytes(Rec, '6800650079002100', TextEncoding::UTF16);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        N := Ins.Read(T, 4);
        Observer.Observe('utf16len4', Format(N) + '|' + Dump(T));
        Rec.DeleteAll();
        Observer.Expect('windows6', '6|6:65 98 8364 65 376 228 ');
        Observer.Expect('af163|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('af163|code', 'InvalidStreamData');
        Observer.Expect('utf8Invalid6', '6|6:65 98 8364 65 376 228 ');
        Observer.Expect('utf8len3', '6|3:104 228 246 ');
        Observer.Expect('utf8rest', '4|2:252 33 ');
        Observer.Expect('utf8atEnd', '1|0:');
        Observer.Expect('utf16len4', '4|1:104 ');
        Observer.Verify();
    end;

    [Test]
    procedure JsonReadFromStream_InvalidBytesAndUtf16()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT PnE Stream Rec";
        Ins: InStream;
        Obj: JsonObject;
        R: Text;
        Ok: Boolean;
    begin
        // {"a":"\xE4"} with the byte E4 alone (invalid UTF-8)
        PutBytes(Rec, '7B2261223A22E4227D', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        Ok := Obj.ReadFrom(Ins);
        Observer.Observe('invalidUtf8', 'no error');
        // {"a":1} as UTF-16LE with a byte order mark
        PutBytes(Rec, 'FFFE7B002200610022003A0031007D00', TextEncoding::UTF16);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF16);
        Ok := Obj.ReadFrom(Ins);
        Observer.Observe('utf16Bom', 'no error');
        // UTF-8 with a byte order mark
        PutBytes(Rec, 'EFBBBF7B2261223A317D', TextEncoding::UTF8);
        Rec.CalcFields(Data);
        Rec.Data.CreateInStream(Ins, TextEncoding::UTF8);
        Ok := Obj.ReadFrom(Ins);
        Obj.WriteTo(R);
        Observer.Observe('utf8Bom', Format(Ok) + '|' + R);
        Rec.DeleteAll();
        Observer.Expect('invalidUtf8', 'no error');
        Observer.Expect('utf16Bom', 'no error');
        Observer.Expect('utf8Bom', 'Yes|{"a":1}');
        Observer.Verify();
    end;
}
