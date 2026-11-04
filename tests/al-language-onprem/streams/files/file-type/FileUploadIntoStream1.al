// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File UploadIntoStream 1 (UI member, RISKY: may raise)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61273 "LT P110 File UlIntoStream1"
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

    local procedure Rec(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TUpload(Title: Text; Folder: Text; Filter: Text; var FromFile: Text; var InS: InStream; var R: Boolean)
    begin
        R := File.UploadIntoStream(Title, Folder, Filter, FromFile, InS);
    end;

    [Test]
    procedure P110_UploadIntoStream_4Args_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        FromFile: Text;
        InS: InStream;
        R: Boolean;
    begin
        Rec(Observer, 'upload_into_stream', TUpload('Title', '', '', FromFile, InS, R));
        Observer.Observe('from_file', '[' + FromFile + ']');
        Rec(Observer, 'upload_into_stream_filter', TUpload('', '', 'Text files (*.txt)|*.txt', FromFile, InS, R));
        Observer.Expect('upload_into_stream', 'ok');
        Observer.Expect('from_file', '[]');
        Observer.Expect('upload_into_stream_filter', 'ok');
        Observer.Verify();
    end;
}
