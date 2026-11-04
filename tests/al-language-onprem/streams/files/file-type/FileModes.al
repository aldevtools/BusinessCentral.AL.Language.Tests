// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.TextMode WriteMode Create/Open encoding
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61271 "LT P110 File Modes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ErrHead(T: Text): Text
    var
        P1: Integer;
        P2: Integer;
        Cut: Integer;
    begin
        P1 := StrPos(T, '/');
        P2 := StrPos(T, '''');
        Cut := P1;
        if (Cut = 0) or ((P2 > 0) and (P2 < Cut)) then
            Cut := P2;
        if Cut > 0 then
            exit(CopyStr(T, 1, Cut - 1));
        exit(CopyStr(T, 1, 200));
    end;

    [TryFunction]
    local procedure TTextMode(var F: File; Set: Boolean; Mode: Boolean; var R: Boolean)
    begin
        if Set then
            R := F.TextMode(Mode)
        else
            R := F.TextMode();
    end;

    [TryFunction]
    local procedure TWriteMode(var F: File; Set: Boolean; Mode: Boolean; var R: Boolean)
    begin
        if Set then
            R := F.WriteMode(Mode)
        else
            R := F.WriteMode();
    end;

    local procedure TM(var F: File; Set: Boolean; Mode: Boolean): Text
    var
        R: Boolean;
    begin
        if TTextMode(F, Set, Mode, R) then
            exit(Format(R));
        exit('error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    local procedure WM(var F: File; Set: Boolean; Mode: Boolean): Text
    var
        R: Boolean;
    begin
        if TWriteMode(F, Set, Mode, R) then
            exit(Format(R));
        exit('error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    local procedure TempName(): Text
    begin
        exit(TemporaryPath() + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp');
    end;

    local procedure Cleanup(Name: Text)
    begin
        if File.Exists(Name) then
            File.Erase(Name);
    end;

    [Test]
    procedure P110_TextModeWriteModeDefaults()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        Observer.Observe('set_writemode_false_unopened', WM(F, true, false));
        Observer.Observe('set_writemode_true_unopened', WM(F, true, true));
        Observer.Observe('textmode_unopened', TM(F, false, false));
        Observer.Observe('writemode_unopened', WM(F, false, false));
        F.Create(P);
        Observer.Observe('textmode_after_create', TM(F, false, false));
        Observer.Observe('writemode_after_create', WM(F, false, false));
        Observer.Observe('set_textmode_true_returns', TM(F, true, true));
        Observer.Observe('textmode_now', TM(F, false, false));
        Observer.Observe('set_textmode_false_returns', TM(F, true, false));
        Observer.Observe('textmode_now2', TM(F, false, false));
        Observer.Observe('set_writemode_false_returns_open', WM(F, true, false));
        Observer.Observe('writemode_now', WM(F, false, false));
        Observer.Observe('set_writemode_true_returns_open', WM(F, true, true));
        Observer.Observe('writemode_now2', WM(F, false, false));
        F.Close();
        F.Open(P);
        Observer.Observe('textmode_after_open', TM(F, false, false));
        Observer.Observe('writemode_after_open', WM(F, false, false));
        F.Close();
        Cleanup(P);
        Observer.Expect('set_writemode_false_unopened', 'No');
        Observer.Expect('set_writemode_true_unopened', 'Yes');
        Observer.Expect('textmode_unopened', 'No');
        Observer.Expect('writemode_unopened', 'Yes');
        Observer.Expect('textmode_after_create', 'No');
        Observer.Expect('writemode_after_create', 'Yes');
        Observer.Expect('set_textmode_true_returns', 'Yes');
        Observer.Expect('textmode_now', 'Yes');
        Observer.Expect('set_textmode_false_returns', 'No');
        Observer.Expect('textmode_now2', 'No');
        Observer.Expect('set_writemode_false_returns_open', 'error: The operation cannot be performed while the file is open. code=FileAlreadyOpened');
        Observer.Expect('writemode_now', 'Yes');
        Observer.Expect('set_writemode_true_returns_open', 'error: The operation cannot be performed while the file is open. code=FileAlreadyOpened');
        Observer.Expect('writemode_now2', 'Yes');
        Observer.Expect('textmode_after_open', 'No');
        Observer.Expect('writemode_after_open', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P110_TextModeAffectsWriteBytes()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        F.Write('abc');
        Observer.Observe('len_text_mode_abc', Format(F.Len()));
        F.Write('');
        Observer.Observe('len_text_mode_empty_line', Format(F.Len()));
        F.TextMode(false);
        F.Write('abc');
        Observer.Observe('len_binary_mode_abc', Format(F.Len()));
        F.Write('');
        Observer.Observe('len_binary_mode_empty', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('len_text_mode_abc', '5');
        Observer.Expect('len_text_mode_empty_line', '7');
        Observer.Expect('len_binary_mode_abc', '11');
        Observer.Expect('len_binary_mode_empty', '12');
        Observer.Verify();
    end;

    [Test]
    procedure P110_WriteModeOpenForWrite()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        V: Text;
    begin
        P := TempName();
        F.WriteMode(true);
        F.Create(P);
        F.Write('original');
        F.Close();
        F.WriteMode(true);
        Observer.Observe('open_writemode_true', Format(F.Open(P)));
        F.Seek(F.Len());
        F.Write('+more');
        F.Close();
        F.Open(P);
        F.TextMode(true);
        F.Read(V);
        Observer.Observe('after_append', '[' + V + ']');
        F.Close();
        Cleanup(P);
        Observer.Expect('open_writemode_true', 'Yes');
        Observer.Expect('after_append', '[original]');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CreateOpenEncodingVariants()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        V: Text;
    begin
        P := TempName();
        Observer.Observe('create_utf8', Format(F.Create(P, TextEncoding::UTF8)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_utf8', Format(F.Len()));
        F.Close();
        Observer.Observe('open_utf8', Format(F.Open(P, TextEncoding::UTF8)));
        F.TextMode(true);
        F.Read(V);
        Observer.Observe('read_utf8', '[' + V + ']');
        F.Close();
        Observer.Observe('open_utf16_of_utf8_file', Format(F.Open(P, TextEncoding::UTF16)));
        Observer.Observe('len_open_utf16', Format(F.Len()));
        F.Close();
        Observer.Observe('create_utf16', Format(F.Create(P, TextEncoding::UTF16)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_utf16', Format(F.Len()));
        F.Close();
        Observer.Observe('create_msdos', Format(F.Create(P, TextEncoding::MSDos)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_msdos', Format(F.Len()));
        F.Close();
        Observer.Observe('create_windows', Format(F.Create(P, TextEncoding::Windows)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_windows', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('create_utf8', 'Yes');
        Observer.Expect('len_utf8', '8');
        Observer.Expect('open_utf8', 'Yes');
        Observer.Expect('read_utf8', '[äöü]');
        Observer.Expect('open_utf16_of_utf8_file', 'Yes');
        Observer.Expect('len_open_utf16', '8');
        Observer.Expect('create_utf16', 'Yes');
        Observer.Expect('len_utf16', '10');
        Observer.Expect('create_msdos', 'Yes');
        Observer.Expect('len_msdos', '5');
        Observer.Expect('create_windows', 'Yes');
        Observer.Expect('len_windows', '5');
        Observer.Verify();
    end;
}
