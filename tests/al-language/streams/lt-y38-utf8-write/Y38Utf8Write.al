// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/outstream/outstream-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained table 92587.
// Writer Y38 (gap cycle 3, C3-18): OutStream.Write(Text) of Cyrillic text on a UTF-8 stream of a table Blob (the Email message body shape:
// CreateOutStream(Out, TextEncoding::UTF8), Write, Insert, then CalcFields, CreateInStream(Ins, TextEncoding::UTF8) and Read(Text)), the
// same text on the other encodings, and the return value of Read(Text) on a UTF-8 stream of two zero-terminated texts. Neighbour of
// errors/lt-ms-refusals-132/P132OutStreamUnicode.al (Temp Blob, Japanese per encoding).

table 92587 "LT Y38 UW Blob"
{
    DataClassification = SystemMetadata;

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

codeunit 92588 "LT Y38 UW Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexOf(var Ins: InStream): Text
    var
        B: Byte;
        Digits: Text;
        Bytes: Text;
        Len: Integer;
    begin
        Digits := '0123456789ABCDEF';
        while not Ins.EOS() do begin
            Ins.Read(B);
            Len += 1;
            Bytes += CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1);
        end;
        exit(Format(Len) + ':' + Bytes);
    end;

    local procedure HexTemp(var TempBlob: Codeunit "Temp Blob"): Text
    var
        Ins: InStream;
    begin
        TempBlob.CreateInStream(Ins);
        exit(HexOf(Ins));
    end;

    local procedure WriteEnc(Enc: TextEncoding; Value: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Ret: Integer;
    begin
        TempBlob.CreateOutStream(Out, Enc);
        Ret := Out.Write(Value);
        exit(Format(Ret) + '|' + HexTemp(TempBlob));
    end;

    local procedure WriteNoEnc(Value: Text): Text
    var
        TempBlob: Codeunit "Temp Blob";
        Out: OutStream;
        Ret: Integer;
    begin
        TempBlob.CreateOutStream(Out);
        Ret := Out.Write(Value);
        exit(Format(Ret) + '|' + HexTemp(TempBlob));
    end;

    // N1: the table-Blob path with CalcFields.
    [Test]
    procedure UW_Write_Utf8_Cyrillic_TableBlob()
    var
        B: Record "LT Y38 UW Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        Original: Text;
        Back: Text;
        Ret: Integer;
        N: Integer;
    begin
        B.DeleteAll();
        Original := 'Привет мир';
        B.Id := 1;
        B.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Ret := Out.Write(Original);
        B.Insert();
        Observer.Observe('ret', Format(Ret));
        Clear(B);
        B.Get(1);
        B.CalcFields(Data);
        B.Data.CreateInStream(Ins);
        Observer.Observe('hex', HexOf(Ins));
        B.Data.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(Back);
        Observer.Observe('read', Format(N) + '|' + Back + '|' + Format(Back = Original) + '|eos=' + Format(Ins.EOS()));
        Observer.Expect('ret', '20');
        Observer.Expect('hex', '20:D09FD180D0B8D0B2D0B5D18220D0BCD0B8D18000');
        Observer.Expect('read', '20|Привет мир|Yes|eos=Yes');
        Observer.Verify();
    end;

    // N1b: the statement form of Read (result not used), as the Email message code does.
    [Test]
    procedure UW_Read_Utf8_Cyrillic_TableBlob_Statement()
    var
        B: Record "LT Y38 UW Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        Back: Text;
    begin
        B.DeleteAll();
        B.Id := 1;
        B.Data.CreateOutStream(Out, TextEncoding::UTF8);
        Out.Write('Привет мир');
        B.Insert();
        Clear(B);
        B.Get(1);
        B.CalcFields(Data);
        B.Data.CreateInStream(Ins, TextEncoding::UTF8);
        Ins.Read(Back);
        Observer.Observe('read', Back + '|len=' + Format(StrLen(Back)));
        Observer.Expect('read', 'Привет мир|len=10');
        Observer.Verify();
    end;

    // N2: Cyrillic on each encoding of a Temp Blob stream.
    [Test]
    procedure UW_Write_Cyrillic_PerEncoding()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8', WriteEnc(TextEncoding::UTF8, 'Привет'));
        Observer.Observe('utf16', WriteEnc(TextEncoding::UTF16, 'Привет'));
        Observer.Observe('windows', WriteEnc(TextEncoding::Windows, 'Привет'));
        Observer.Observe('msdos', WriteEnc(TextEncoding::MSDos, 'Привет'));
        Observer.Observe('none', WriteNoEnc('Привет'));
        Observer.Expect('utf8', '13|13:D09FD180D0B8D0B2D0B5D18200');
        Observer.Expect('utf16', '14|14:1F04400438043204350442040000');
        Observer.Expect('windows', '7|7:3F3F3F3F3F3F00');
        Observer.Expect('msdos', '7|7:3F3F3F3F3F3F00');
        Observer.Expect('none', '7|7:3F3F3F3F3F3F00');
        Observer.Verify();
    end;

    // N3: two zero-terminated texts on one UTF-8 stream, read back with the return value used, then once more at the end.
    [Test]
    procedure UW_Read_Utf8_Terminated_ReturnValue()
    var
        TempBlob: Codeunit "Temp Blob";
        Observer: Codeunit "Probe Observer";
        Out: OutStream;
        Ins: InStream;
        T: Text;
        N: Integer;
    begin
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Out.Write('Привет');
        Out.Write('ab');
        Observer.Observe('hex', HexTemp(TempBlob));
        TempBlob.CreateInStream(Ins, TextEncoding::UTF8);
        N := Ins.Read(T);
        Observer.Observe('read1', Format(N) + '|' + T + '|eos=' + Format(Ins.EOS()));
        N := Ins.Read(T);
        Observer.Observe('read2', Format(N) + '|' + T + '|eos=' + Format(Ins.EOS()));
        N := Ins.Read(T);
        Observer.Observe('read3', Format(N) + '|' + T + '|eos=' + Format(Ins.EOS()));
        Observer.Expect('hex', '16:D09FD180D0B8D0B2D0B5D18200616200');
        Observer.Expect('read1', '13|Привет|eos=No');
        Observer.Expect('read2', '3|ab|eos=Yes');
        Observer.Expect('read3', '1||eos=Yes');
        Observer.Verify();
    end;
}
