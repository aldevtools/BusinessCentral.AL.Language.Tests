// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.CreateTempFile IsPathTemporary
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61270 "LT P110 File Temp"
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
    procedure P110_CreateTempFile()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        N: Text;
        V: Text;
    begin
        Observer.Observe('create_temp', Format(F.CreateTempFile()));
        N := F.Name();
        Observer.Observe('name_nonempty', Format(N <> ''));
        Observer.Observe('name_is_temporary_path', Format(File.IsPathTemporary(N)));
        Observer.Observe('exists_while_open', Format(File.Exists(N)));
        Observer.Observe('len_new', Format(F.Len()));
        F.TextMode(true);
        F.Write('temp content');
        Observer.Observe('len_after_write', Format(F.Len()));
        F.Seek(0);
        F.Read(V);
        Observer.Observe('read_back', '[' + V + ']');
        F.Close();
        Observer.Observe('exists_after_close', Format(File.Exists(N)));
        Cleanup(N);
        Observer.Expect('create_temp', 'Yes');
        Observer.Expect('name_nonempty', 'Yes');
        Observer.Expect('name_is_temporary_path', 'Yes');
        Observer.Expect('exists_while_open', 'Yes');
        Observer.Expect('len_new', '0');
        Observer.Expect('len_after_write', '14');
        Observer.Expect('read_back', '[temp content]');
        Observer.Expect('exists_after_close', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CreateTempFile_Encoding()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        V: Text;
        N: Text;
    begin
        Observer.Observe('utf8', Format(F.CreateTempFile(TextEncoding::UTF8)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_utf8', Format(F.Len()));
        N := F.Name();
        F.Close();
        Cleanup(N);
        Observer.Observe('utf16', Format(F.CreateTempFile(TextEncoding::UTF16)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_utf16', Format(F.Len()));
        N := F.Name();
        F.Close();
        Cleanup(N);
        Observer.Observe('msdos', Format(F.CreateTempFile(TextEncoding::MSDos)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_msdos', Format(F.Len()));
        N := F.Name();
        F.Close();
        Cleanup(N);
        Observer.Observe('windows', Format(F.CreateTempFile(TextEncoding::Windows)));
        F.TextMode(true);
        F.Write('äöü');
        Observer.Observe('len_windows', Format(F.Len()));
        N := F.Name();
        F.Close();
        Cleanup(N);
        Observer.Expect('utf8', 'Yes');
        Observer.Expect('len_utf8', '8');
        Observer.Expect('utf16', 'Yes');
        Observer.Expect('len_utf16', '10');
        Observer.Expect('msdos', 'Yes');
        Observer.Expect('len_msdos', '5');
        Observer.Expect('windows', 'Yes');
        Observer.Expect('len_windows', '5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TIsTemp(P: Text; var R: Boolean)
    begin
        R := File.IsPathTemporary(P);
    end;

    local procedure TryIsTemp(var Observer: Codeunit "Probe Observer"; Name: Text; P: Text)
    var
        R: Boolean;
    begin
        if TIsTemp(P, R) then
            Observer.Observe(Name, Format(R))
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    [Test]
    procedure P110_IsPathTemporary()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('temporary_path_file', Format(File.IsPathTemporary(TempName())));
        Observer.Observe('temporary_path_dir', Format(File.IsPathTemporary(TemporaryPath())));
        TryIsTemp(Observer, 'empty', '');
        TryIsTemp(Observer, 'relative', 'relative.txt');
        TryIsTemp(Observer, 'root', '/');
        TryIsTemp(Observer, 'etc_passwd', '/etc/passwd');
        TryIsTemp(Observer, 'temporary_path_dotdot', TemporaryPath() + '../x.tmp');
        Observer.Expect('temporary_path_file', 'Yes');
        Observer.Expect('temporary_path_dir', 'Yes');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('relative', 'Yes');
        // Linux container differs from Windows BC (run 39125184978 / 39125190236): Windows says No for "/" (root); Linux says Yes. root, etc_passwd and temporary_path_dotdot are not asserted.
        Observer.Ignore('root');
        Observer.Ignore('etc_passwd');
        Observer.Ignore('temporary_path_dotdot');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CreateTempFile_ReuseVar()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        N1: Text;
        N2: Text;
    begin
        F.CreateTempFile();
        N1 := F.Name();
        F.Close();
        F.CreateTempFile();
        N2 := F.Name();
        F.Close();
        Observer.Observe('names_differ', Format(N1 <> N2));
        Observer.Observe('first_still_exists', Format(File.Exists(N1)));
        Cleanup(N1);
        Cleanup(N2);
        Observer.Expect('names_differ', 'Yes');
        Observer.Expect('first_still_exists', 'No');
        Observer.Verify();
    end;
}
