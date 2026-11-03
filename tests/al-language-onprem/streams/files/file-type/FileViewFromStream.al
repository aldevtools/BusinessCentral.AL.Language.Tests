// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File ViewFromStream (UI member, RISKY: may raise)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61278 "LT P110 File ViewFromStream"
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
    local procedure TView(var InS: InStream; Name: Text; var R: Boolean)
    begin
        R := File.ViewFromStream(InS, Name);
    end;

    [TryFunction]
    local procedure TViewAllow(var InS: InStream; Name: Text; Allow: Boolean; var R: Boolean)
    begin
        R := File.ViewFromStream(InS, Name, Allow);
    end;

    [Test]
    procedure P110_ViewFromStream_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        InS: InStream;
        R: Boolean;
    begin
        F.CreateTempFile();
        F.CreateOutStream(OutS);
        OutS.WriteText('stream content');
        F.CreateInStream(InS);
        Rec(Observer, 'view_stream', TView(InS, 'p110.txt', R));
        Rec(Observer, 'view_stream_blank_name', TView(InS, '', R));
        Rec(Observer, 'view_stream_allow', TViewAllow(InS, 'p110.txt', true, R));
        Rec(Observer, 'view_stream_disallow', TViewAllow(InS, 'p110.txt', false, R));
        F.Close();
        Observer.Expect('view_stream', 'ok');
        Observer.Expect('view_stream_blank_name', 'ok');
        Observer.Expect('view_stream_allow', 'ok');
        Observer.Expect('view_stream_disallow', 'ok');
        Observer.Verify();
    end;
}
