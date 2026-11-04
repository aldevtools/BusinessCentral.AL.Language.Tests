// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-ispathtemporary-method
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98990
// Probe: File.IsPathTemporary for paths outside the service tier's temporary folder: other drive letters, a UNC path, the root "/", an absolute path outside the folder and a path that climbs out of it with "..".
// The paths C:\, D:\, Z:/, UNC and "/" are the ones of FileEraseAndTempPath.al (61275) and FileTemp.al (61270), which leave them unasserted. An official Windows container answered No for each of them on BC 27.5 and 29.0
// (corpus runs 39125184978 and 39125190236); the Linux image answers the same since MsDyn365Bc.On.Linux PR #127 (before, every path was temporary on Linux).
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
codeunit 98990 "LT BG IsPathTemporary Outside"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TIsTemp(P: Text; var R: Boolean)
    begin
        R := File.IsPathTemporary(P);
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
    procedure BG_IsPathTemporary_OutsideTemporaryFolder()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TempCase(Observer, 'other_drive_c', 'C:\lt-other.tmp');
        TempCase(Observer, 'other_drive_d', 'D:\lt-other.tmp');
        TempCase(Observer, 'other_drive_z_slash', 'Z:/lt-other.tmp');
        TempCase(Observer, 'unc', '\\lt-server\share\lt-other.tmp');
        TempCase(Observer, 'root', '/');
        TempCase(Observer, 'drive_c_root', 'C:\');
        TempCase(Observer, 'etc_passwd', '/etc/passwd');
        TempCase(Observer, 'temporary_path_dotdot', TemporaryPath() + '../lt-bg-x.tmp');
        TempCase(Observer, 'temporary_path_file', TemporaryPath() + 'lt-bg-inside.tmp');
        Observer.Expect('other_drive_c', 'No');
        Observer.Expect('other_drive_d', 'No');
        Observer.Expect('other_drive_z_slash', 'No');
        Observer.Expect('unc', 'No');
        Observer.Expect('root', 'No');
        Observer.Expect('drive_c_root', 'No');
        Observer.Expect('etc_passwd', 'No');
        Observer.Expect('temporary_path_dotdot', 'Yes');
        Observer.Expect('temporary_path_file', 'Yes');
        Observer.Verify();
    end;
}
