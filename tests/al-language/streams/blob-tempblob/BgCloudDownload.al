// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-downloadfromstream-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 81353
// Probe: DownloadFromStream and UploadIntoStream from a Cloud app in a test session: the return value, ToFile / FromFile afterwards and the stream position. The return variable is preset before each call.
// An official Windows container returned Yes for DownloadFromStream and left ToFile unchanged on BC 27.5 and 29.0 (corpus runs 39125184978 and 39125190236). The Linux test runner accepts downloads and
// refuses uploads like the Windows client since MsDyn365Bc.On.Linux PR #127 (before, DownloadFromStream ended the session on BC 27 and returned No on BC 28+).
// Expected values: measured on official Microsoft Windows containers (onprem artifact, w1, en-US), BC 27.5 and 29.0, corpus runs 39216765049 and 39216768276 (both gave the same values).
// BC versions: 27, 28, 29
codeunit 81353 "LT BG Cloud Download"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TDownload(var InS: InStream; Title: Text; Folder: Text; Filter: Text; var ToFile: Text; var R: Boolean)
    begin
        R := DownloadFromStream(InS, Title, Folder, Filter, ToFile);
    end;

    [TryFunction]
    local procedure TUpload4(Title: Text; Folder: Text; Filter: Text; var FromFile: Text; var InS: InStream; var R: Boolean)
    begin
        R := UploadIntoStream(Title, Folder, Filter, FromFile, InS);
    end;

    [TryFunction]
    local procedure TUpload2(Filter: Text; var InS: InStream; var R: Boolean)
    begin
        R := UploadIntoStream(Filter, InS);
    end;

    local procedure DownloadCase(var Observer: Codeunit "Probe Observer"; Name: Text; Title: Text; Folder: Text; Filter: Text; ToFileIn: Text; Preset: Boolean)
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
        ToFile := ToFileIn;
        if TDownload(InS, Title, Folder, Filter, ToFile, R) then
            Observer.Observe(Name, 'ok ret=' + Format(R) + ' tofile=[' + ToFile + '] eos=' + Format(InS.EOS()))
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure BG_DownloadFromStream_Cloud_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DownloadCase(Observer, 'dls_title_preset_yes', 'Title', '', '', 'untouched', true);
        DownloadCase(Observer, 'dls_title_preset_no', 'Title', '', '', 'untouched', false);
        DownloadCase(Observer, 'dls_name_txt', '', '', '', 'lt-bg.txt', false);
        DownloadCase(Observer, 'dls_all_args', 'Title', '', 'Text files (*.txt)|*.txt', 'lt-bg.txt', false);
        DownloadCase(Observer, 'dls_blank', '', '', '', '', false);
        Observer.Expect('dls_title_preset_yes', 'ok ret=Yes tofile=[untouched] eos=No');
        Observer.Expect('dls_title_preset_no', 'ok ret=Yes tofile=[untouched] eos=No');
        Observer.Expect('dls_name_txt', 'ok ret=Yes tofile=[lt-bg.txt] eos=No');
        Observer.Expect('dls_all_args', 'ok ret=Yes tofile=[lt-bg.txt] eos=No');
        Observer.Expect('dls_blank', 'ok ret=Yes tofile=[] eos=No');
        Observer.Verify();
    end;

    [Test]
    procedure BG_UploadIntoStream_Cloud_Return()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        FromFile: Text;
        R: Boolean;
    begin
        R := true;
        FromFile := 'untouched';
        if TUpload4('Title', '', '', FromFile, InS, R) then
            Observer.Observe('uis_title', 'ok ret=' + Format(R) + ' fromfile=[' + FromFile + ']')
        else
            Observer.ObserveError('uis_title');
        R := true;
        if TUpload2('Text files (*.txt)|*.txt', InS, R) then
            Observer.Observe('uis2_txt', 'ok ret=' + Format(R))
        else
            Observer.ObserveError('uis2_txt');
        Observer.Expect('uis_title', 'ok ret=No fromfile=[untouched]');
        Observer.Expect('uis2_txt', 'ok ret=No');
        Observer.Verify();
    end;
}
