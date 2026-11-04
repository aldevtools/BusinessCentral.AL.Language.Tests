// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-download-method
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunit 98991
// Probe: the return value of File.Download and File.DownloadFromStream in a test session, and ToFile afterwards, on every version. FileQProbes.al (61276) pins them from BC 28 only and leaves the return values
// unasserted. An official Windows container returned Yes and left ToFile unchanged on BC 27.5 and 29.0 (corpus runs 39125184978 and 39125190236); the Linux image accepts the download the same way since
// MsDyn365Bc.On.Linux PR #127 (before, BC 27 on Linux ended the session with a NullReferenceException and BC 28+ returned No). The return variable is preset to No and to Yes before the calls.
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
codeunit 98991 "LT BG File Download"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TDownload(From: Text; Title: Text; Folder: Text; Filter: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.Download(From, Title, Folder, Filter, ToFile);
    end;

    [TryFunction]
    local procedure TDownloadStream(var InS: InStream; Title: Text; Folder: Text; Filter: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.DownloadFromStream(InS, Title, Folder, Filter, ToFile);
    end;

    local procedure TempName(): Text
    begin
        exit(TemporaryPath() + 'lt-bg-download-' + DelChr(Format(CreateGuid()), '=', '{}-') + '.txt');
    end;

    local procedure DownloadCase(var Observer: Codeunit "Probe Observer"; Name: Text; From: Text; Title: Text; Folder: Text; Filter: Text; Preset: Boolean)
    var
        ToFile: Text;
        R: Boolean;
    begin
        R := Preset;
        ToFile := 'untouched';
        if TDownload(From, Title, Folder, Filter, ToFile, R) then
            Observer.Observe(Name, 'ok ret=' + Format(R) + ' tofile=[' + ToFile + ']')
        else
            Observer.ObserveError(Name);
    end;

    local procedure StreamCase(var Observer: Codeunit "Probe Observer"; Name: Text; Title: Text; Folder: Text; Filter: Text; Preset: Boolean)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
        R: Boolean;
    begin
        TempBlob.CreateOutStream(OutS);
        OutS.WriteText('download content');
        TempBlob.CreateInStream(InS);
        R := Preset;
        ToFile := 'untouched';
        if TDownloadStream(InS, Title, Folder, Filter, ToFile, R) then
            Observer.Observe(Name, 'ok ret=' + Format(R) + ' tofile=[' + ToFile + ']')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure BG_File_Download_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('download content');
        F.Close();
        DownloadCase(Observer, 'dl_title_preset_yes', P, 'Title', '', '', true);
        DownloadCase(Observer, 'dl_title_preset_no', P, 'Title', '', '', false);
        DownloadCase(Observer, 'dl_all_args', P, 'Title', TemporaryPath(), 'Text files (*.txt)|*.txt', false);
        DownloadCase(Observer, 'dl_blank', P, '', '', '', false);
        DownloadCase(Observer, 'dl_missing', P + '.missing', 'Title', '', '', false);
        DownloadCase(Observer, 'dl_blank_from', '', 'Title', '', '', false);
        Observer.Observe('source_still_exists', Format(File.Exists(P)));
        if File.Exists(P) then
            File.Erase(P);
        Observer.Expect('dl_title_preset_yes', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dl_title_preset_no', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dl_all_args', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dl_blank', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dl_missing', 'ok ret=No tofile=[untouched]');
        Observer.Expect('dl_blank_from', 'ok ret=No tofile=[untouched]');
        Observer.Expect('source_still_exists', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BG_File_DownloadFromStream_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StreamCase(Observer, 'dls_title_preset_yes', 'Title', '', '', true);
        StreamCase(Observer, 'dls_title_preset_no', 'Title', '', '', false);
        StreamCase(Observer, 'dls_all_args', 'Title', TemporaryPath(), 'Text files (*.txt)|*.txt', false);
        StreamCase(Observer, 'dls_blank', '', '', '', false);
        Observer.Expect('dls_title_preset_yes', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dls_title_preset_no', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dls_all_args', 'ok ret=Yes tofile=[untouched]');
        Observer.Expect('dls_blank', 'ok ret=Yes tofile=[untouched]');
        Observer.Verify();
    end;
}
