// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-write-method
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); own codeunit 98350
// Probe: every literal asserted below is what BC produced in the corpus CI (Linux container); BC 27, 28 and 29 are checked by the CI legs.
// Settles corpus issue 645 item 6: the bytes File.Write(Text) puts in a file created with File.Create(Name, TextEncoding::UTF8 / Windows / UTF16)
//   for 'aé' (U+0061 U+00E9), in text mode and after File.TextMode(false), for a Text and a Text[10] variable; read back with a binary InStream.
//   (File.Open / Erase of a missing file: FileErrors.al P110_MissingFile; Copy / Rename onto an existing file: FileOps.al.)
// BC versions: 27, 28, 29

codeunit 98350 "LT AU File Write Bytes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TempName(): Text
    begin
        exit(TemporaryPath() + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp');
    end;

    local procedure HexOf(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    local procedure FileHex(Name: Text): Text
    var
        F: File;
        Ins: InStream;
        B: Byte;
        Hex: Text;
    begin
        F.Open(Name);
        F.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            Hex += HexOf(B);
        end;
        F.Close();
        exit(Hex);
    end;

    local procedure AE(): Text
    var
        T: Text;
    begin
        T[1] := 97;
        T[2] := 233;
        exit(T);
    end;

    [TryFunction]
    local procedure TryWrite(var F: File; Bounded: Boolean)
    var
        T: Text;
        T10: Text[10];
    begin
        if Bounded then begin
            T10 := CopyStr(AE(), 1, 10);
            F.Write(T10);
        end else begin
            T := AE();
            F.Write(T);
        end;
    end;

    // Creates a file with the encoding, sets the mode, writes 'aé' and returns the bytes or the error of the write.
    local procedure WriteCase(Enc: TextEncoding; TextMode: Boolean; Bounded: Boolean): Text
    var
        F: File;
        Name: Text;
        R: Text;
    begin
        Name := TempName();
        F.Create(Name, Enc);
        F.TextMode(TextMode);
        if TryWrite(F, Bounded) then
            R := 'ok'
        else
            R := 'error ' + GetLastErrorText() + ' code=' + GetLastErrorCode();
        F.Close();
        R += ' [' + FileHex(Name) + ']';
        File.Erase(Name);
        exit(R);
    end;

    [Test]
    procedure File_Write_AE_Utf8()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text_mode', WriteCase(TextEncoding::UTF8, true, false));
        Observer.Observe('text_mode_text10', WriteCase(TextEncoding::UTF8, true, true));
        Observer.Observe('binary_text10', WriteCase(TextEncoding::UTF8, false, true));
        Observer.Expect('text_mode', 'ok [61C3A90D0A]');
        Observer.Expect('text_mode_text10', 'ok [61C3A90D0A]');
        Observer.Expect('binary_text10', 'ok [61C3A900]');
        Observer.Verify();
    end;

    [Test]
    procedure File_Write_AE_Windows()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text_mode', WriteCase(TextEncoding::Windows, true, false));
        Observer.Observe('text_mode_text10', WriteCase(TextEncoding::Windows, true, true));
        Observer.Observe('binary_text10', WriteCase(TextEncoding::Windows, false, true));
        Observer.Expect('text_mode', 'ok [61E90D0A]');
        Observer.Expect('text_mode_text10', 'ok [61E90D0A]');
        Observer.Expect('binary_text10', 'ok [61E9000000000000000000]');
        Observer.Verify();
    end;

    [Test]
    procedure File_Write_AE_Utf16()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('text_mode', WriteCase(TextEncoding::UTF16, true, false));
        Observer.Observe('text_mode_text10', WriteCase(TextEncoding::UTF16, true, true));
        Observer.Observe('binary_text10', WriteCase(TextEncoding::UTF16, false, true));
        Observer.Expect('text_mode', 'ok [6100E9000D000A00]');
        Observer.Expect('text_mode_text10', 'ok [6100E9000D000A00]');
        Observer.Expect('binary_text10', 'ok [6100E9000000]');
        Observer.Verify();
    end;

    [Test]
    procedure File_Write_AE_BinaryUnboundedText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('utf8', WriteCase(TextEncoding::UTF8, false, false));
        Observer.Observe('utf16', WriteCase(TextEncoding::UTF16, false, false));
        Observer.Expect('utf8', 'error WRITE is not supported for Text without a maximum length. code=StreamWideTextMaxLength []');
        Observer.Expect('utf16', 'error WRITE is not supported for Text without a maximum length. code=StreamWideTextMaxLength []');
        Observer.Verify();
    end;
}
