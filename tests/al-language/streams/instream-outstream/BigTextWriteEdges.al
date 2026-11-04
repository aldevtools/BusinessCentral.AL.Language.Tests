// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/bigtext/bigtext-write-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), Temp Blob (codeunit 4100)
// Probe: written against BC on the corpus CI matrix; every literal asserted below is what that tier produced.
// Facts: BigText.Write into a Blob OutStream. Non-ASCII text (a with umlaut, euro sign, a Cyrillic letter) on a default stream and on a UTF-8 stream,
//   the bytes read back with InStream.Read(Byte); a stream that was written with WriteText before; WriteText after BigText.Write;
//   streams created with UTF16, Windows and MSDos for ASCII text; an empty BigText (Blob length and HasValue).
// Observed: a default stream (and MSDos) stores one byte per character in the OEM code page (84 B1 3F for a with umlaut, euro sign, Cyrillic: the Cyrillic letter becomes 3F),
//   Windows stores E4 80 3F, UTF-8 stores C3 A4 E2 82 AC D0 96 and UTF16 stores 16-bit units; BigText.Read decodes with the default (OEM) code page.
// BC versions: all (CI)

codeunit 67412 "LT BTW Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure HexOf(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure ObserveBlob(var Observer: Codeunit "Probe Observer"; Tag: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Ins: InStream;
        B: Byte;
        Hex: Text;
    begin
        Observer.Observe(Tag + '.len', Format(TempBlob.Length()));
        Observer.Observe(Tag + '.hasvalue', Format(TempBlob.HasValue()));
        TempBlob.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            if Hex <> '' then
                Hex += ' ';
            Hex += HexOf(B);
        end;
        Observer.Observe(Tag + '.bytes', '[' + Hex + ']');
    end;

    local procedure ObserveReadBack(var Observer: Codeunit "Probe Observer"; Tag: Text; var TempBlob: Codeunit "Temp Blob")
    var
        Ins: InStream;
        Back: BigText;
        T: Text;
        i: Integer;
        C: Integer;
        Codes: Text;
    begin
        TempBlob.CreateInStream(Ins);
        Back.Read(Ins);
        Observer.Observe(Tag + '.readlen', Format(Back.Length()));
        if Back.Length() > 0 then begin
            Back.GetSubText(T, 1);
            for i := 1 to StrLen(T) do begin
                if Codes <> '' then
                    Codes += ',';
                C := T[i];
                Codes += Format(C, 0, 9);
            end;
        end;
        Observer.Observe(Tag + '.readcodes', '[' + Codes + ']');
    end;

    local procedure NonAscii(): Text
    var
        T: Text;
    begin
        T[1] := 228;
        T[2] := 8364;
        T[3] := 1046;
        exit(T);
    end;

    [Test]
    procedure Write_NonAscii_DefaultStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText(NonAscii());
        TempBlob.CreateOutStream(Out);
        Big.Write(Out);
        ObserveBlob(Observer, 'default', TempBlob);
        ObserveReadBack(Observer, 'default', TempBlob);
        Observer.Expect('default.len', '3');
        Observer.Expect('default.hasvalue', 'Yes');
        Observer.Expect('default.bytes', '[84 B1 3F]');
        Observer.Expect('default.readlen', '3');
        Observer.Expect('default.readcodes', '[228,8364,63]');
        Observer.Verify();
    end;

    [Test]
    procedure Write_NonAscii_Utf8Stream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText(NonAscii());
        TempBlob.CreateOutStream(Out, TextEncoding::UTF8);
        Big.Write(Out);
        ObserveBlob(Observer, 'utf8', TempBlob);
        ObserveReadBack(Observer, 'utf8', TempBlob);
        Observer.Expect('utf8.len', '7');
        Observer.Expect('utf8.hasvalue', 'Yes');
        Observer.Expect('utf8.bytes', '[C3 A4 E2 82 AC D0 96]');
        Observer.Expect('utf8.readlen', '7');
        Observer.Expect('utf8.readcodes', '[8220,241,203,233,188,168,251]');
        Observer.Verify();
    end;

    [Test]
    procedure Write_NonAscii_ExplicitEncodings()
    var
        Observer: Codeunit "Probe Observer";
        Utf16Blob: Codeunit "Temp Blob";
        WindowsBlob: Codeunit "Temp Blob";
        MsDosBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText(NonAscii());
        Utf16Blob.CreateOutStream(Out, TextEncoding::UTF16);
        Big.Write(Out);
        ObserveBlob(Observer, 'utf16', Utf16Blob);
        ObserveReadBack(Observer, 'utf16', Utf16Blob);
        WindowsBlob.CreateOutStream(Out, TextEncoding::Windows);
        Big.Write(Out);
        ObserveBlob(Observer, 'windows', WindowsBlob);
        ObserveReadBack(Observer, 'windows', WindowsBlob);
        MsDosBlob.CreateOutStream(Out, TextEncoding::MSDos);
        Big.Write(Out);
        ObserveBlob(Observer, 'msdos', MsDosBlob);
        ObserveReadBack(Observer, 'msdos', MsDosBlob);
        Observer.Expect('utf16.len', '6');
        Observer.Expect('utf16.hasvalue', 'Yes');
        Observer.Expect('utf16.bytes', '[E4 00 AC 20 16 04]');
        Observer.Expect('utf16.readlen', '1');
        Observer.Expect('utf16.readcodes', '[205]');
        Observer.Expect('windows.len', '3');
        Observer.Expect('windows.hasvalue', 'Yes');
        Observer.Expect('windows.bytes', '[E4 80 3F]');
        Observer.Expect('windows.readlen', '3');
        Observer.Expect('windows.readcodes', '[205,199,63]');
        Observer.Expect('msdos.len', '3');
        Observer.Expect('msdos.hasvalue', 'Yes');
        Observer.Expect('msdos.bytes', '[84 B1 3F]');
        Observer.Expect('msdos.readlen', '3');
        Observer.Expect('msdos.readcodes', '[228,8364,63]');
        Observer.Verify();
    end;

    [Test]
    procedure Write_AfterWriteText_SameStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText('def');
        TempBlob.CreateOutStream(Out);
        Out.WriteText('abc');
        Big.Write(Out);
        ObserveBlob(Observer, 'after-writetext', TempBlob);
        Observer.Expect('after-writetext.len', '6');
        Observer.Expect('after-writetext.hasvalue', 'Yes');
        Observer.Expect('after-writetext.bytes', '[61 62 63 64 65 66]');
        Observer.Verify();
    end;

    [Test]
    procedure WriteText_AfterBigTextWrite_SameStream()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText('abc');
        TempBlob.CreateOutStream(Out);
        Big.Write(Out);
        Out.WriteText('xyz');
        ObserveBlob(Observer, 'before-writetext', TempBlob);
        Observer.Expect('before-writetext.len', '6');
        Observer.Expect('before-writetext.hasvalue', 'Yes');
        Observer.Expect('before-writetext.bytes', '[61 62 63 78 79 7A]');
        Observer.Verify();
    end;

    [Test]
    procedure Write_ExplicitEncodings_Ascii()
    var
        Observer: Codeunit "Probe Observer";
        Utf16Blob: Codeunit "Temp Blob";
        WindowsBlob: Codeunit "Temp Blob";
        MsDosBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        Big.AddText('abc');
        Utf16Blob.CreateOutStream(Out, TextEncoding::UTF16);
        Big.Write(Out);
        ObserveBlob(Observer, 'utf16', Utf16Blob);
        WindowsBlob.CreateOutStream(Out, TextEncoding::Windows);
        Big.Write(Out);
        ObserveBlob(Observer, 'windows', WindowsBlob);
        MsDosBlob.CreateOutStream(Out, TextEncoding::MSDos);
        Big.Write(Out);
        ObserveBlob(Observer, 'msdos', MsDosBlob);
        Observer.Expect('utf16.len', '6');
        Observer.Expect('utf16.hasvalue', 'Yes');
        Observer.Expect('utf16.bytes', '[61 00 62 00 63 00]');
        Observer.Expect('windows.len', '3');
        Observer.Expect('windows.hasvalue', 'Yes');
        Observer.Expect('windows.bytes', '[61 62 63]');
        Observer.Expect('msdos.len', '3');
        Observer.Expect('msdos.hasvalue', 'Yes');
        Observer.Expect('msdos.bytes', '[61 62 63]');
        Observer.Verify();
    end;

    [Test]
    procedure Write_EmptyBigText()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        Big: BigText;
        Out: OutStream;
    begin
        TempBlob.CreateOutStream(Out);
        Big.Write(Out);
        ObserveBlob(Observer, 'empty', TempBlob);
        Observer.Expect('empty.len', '0');
        Observer.Expect('empty.hasvalue', 'No');
        Observer.Expect('empty.bytes', '[]');
        Observer.Verify();
    end;
}
