// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File Upload (UI member, RISKY: may raise)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61272 "LT P110 File Upload"
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
    local procedure TUpload(Title: Text; Folder: Text; Filter: Text; FromFile: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.Upload(Title, Folder, Filter, FromFile, ToFile);
    end;

    [Test]
    procedure P110_Upload_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        ToFile: Text;
        R: Boolean;
    begin
        Rec(Observer, 'upload_title', TUpload('Title', '', '', '', ToFile, R));
        Observer.Observe('to_file', '[' + ToFile + ']');
        Rec(Observer, 'upload_all_args', TUpload('Title', TemporaryPath(), 'Text files (*.txt)|*.txt', 'a.txt', ToFile, R));
        Rec(Observer, 'upload_blank', TUpload('', '', '', '', ToFile, R));
        Observer.Expect('upload_title', 'ok');
        Observer.Expect('to_file', '[]');
        Observer.Expect('upload_all_args', 'ok');
        Observer.Expect('upload_blank', 'ok');
        Observer.Verify();
    end;
}
