// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); File.Erase of an empty name (full error text) and File.IsPathTemporary for the temporary path, a file in it, relative, empty and drive-letter paths (issue 581 items 4 and 5)
// BC versions: 27+
codeunit 61275 "LT File Erase And Temp Path"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TErase(P: Text)
    begin
        File.Erase(P);
    end;

    [TryFunction]
    local procedure TIsTemp(P: Text; var R: Boolean)
    begin
        R := File.IsPathTemporary(P);
    end;

    local procedure EraseCase(var Observer: Codeunit "Probe Observer"; Name: Text; P: Text)
    begin
        if TErase(P) then
            Observer.Observe(Name, 'ok')
        else begin
            Observer.Observe(Name, 'error');
            Observer.ObserveError(Name + '_error');
        end;
    end;

    local procedure TempCase(var Observer: Codeunit "Probe Observer"; Name: Text; P: Text)
    var
        R: Boolean;
    begin
        if TIsTemp(P, R) then
            Observer.Observe(Name, Format(R))
        else begin
            Observer.Observe(Name, 'error');
            Observer.ObserveError(Name + '_error');
        end;
    end;

    [Test]
    procedure Erase_EmptyName_FullErrorText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EraseCase(Observer, 'empty', '');
        Observer.Observe('exists_empty', Format(File.Exists('')));
        Observer.Expect('empty', 'error');
        Observer.Expect('empty_error|text', 'The value cannot be an empty string. (Parameter ''path'')');
        Observer.Expect('empty_error|code', 'InvalidPath');
        Observer.Expect('exists_empty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure IsPathTemporary_Paths()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Text;
    begin
        Temp := TemporaryPath();
        Observer.Observe('temporary_path_ends_with_separator', Format(Temp.EndsWith('/') or Temp.EndsWith('\')));
        TempCase(Observer, 'temporary_path', Temp);
        TempCase(Observer, 'file_in_temporary_path', Temp + 'lt-ispathtemp.tmp');
        TempCase(Observer, 'subfolder_file_in_temporary_path', Temp + 'lt-sub/lt-ispathtemp.tmp');
        TempCase(Observer, 'relative', 'lt-relative.tmp');
        TempCase(Observer, 'relative_subfolder', 'lt-sub/lt-relative.tmp');
        TempCase(Observer, 'empty', '');
        TempCase(Observer, 'blank', ' ');
        TempCase(Observer, 'other_drive_c', 'C:\lt-other.tmp');
        TempCase(Observer, 'other_drive_d', 'D:\lt-other.tmp');
        TempCase(Observer, 'other_drive_z_slash', 'Z:/lt-other.tmp');
        TempCase(Observer, 'unc', '\\lt-server\share\lt-other.tmp');
        TempCase(Observer, 'root', '/');
        Observer.Expect('temporary_path_ends_with_separator', 'Yes');
        Observer.Expect('temporary_path', 'Yes');
        Observer.Expect('file_in_temporary_path', 'Yes');
        Observer.Expect('subfolder_file_in_temporary_path', 'Yes');
        Observer.Expect('relative', 'Yes');
        Observer.Expect('relative_subfolder', 'Yes');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('blank', 'Yes');
        // Linux container differs from Windows BC (run 39125184978 / 39125190236): Windows says No for C:\, D:\, Z:/, a UNC path and "/"; Linux says Yes. other_drive_c, other_drive_d, other_drive_z_slash, unc and root are not asserted.
        Observer.Ignore('other_drive_c');
        Observer.Ignore('other_drive_c_error|text');
        Observer.Ignore('other_drive_c_error|code');
        Observer.Ignore('other_drive_d');
        Observer.Ignore('other_drive_d_error|text');
        Observer.Ignore('other_drive_d_error|code');
        Observer.Ignore('other_drive_z_slash');
        Observer.Ignore('other_drive_z_slash_error|text');
        Observer.Ignore('other_drive_z_slash_error|code');
        Observer.Ignore('unc');
        Observer.Ignore('unc_error|text');
        Observer.Ignore('unc_error|code');
        Observer.Ignore('root');
        Observer.Ignore('root_error|text');
        Observer.Ignore('root_error|code');
        Observer.Verify();
    end;
}
