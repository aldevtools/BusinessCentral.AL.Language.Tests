// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File View (UI member, RISKY: may raise)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61277 "LT P110 File View"
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
    local procedure TView(FromFile: Text; var R: Boolean)
    begin
        R := File.View(FromFile);
    end;

    [TryFunction]
    local procedure TViewAllow(FromFile: Text; Allow: Boolean; var R: Boolean)
    begin
        R := File.View(FromFile, Allow);
    end;

    [Test]
    procedure P110_View_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        R: Boolean;
    begin
        Rec(Observer, 'view_missing', TView('/nonexistent/p110.txt', R));
        Rec(Observer, 'view_blank', TView('', R));
        Rec(Observer, 'view_missing_allow', TViewAllow('/nonexistent/p110.txt', true, R));
        Rec(Observer, 'view_missing_disallow', TViewAllow('/nonexistent/p110.txt', false, R));
        Observer.Expect('view_missing', 'ok');
        Observer.Expect('view_blank', 'ok');
        Observer.Expect('view_missing_allow', 'ok');
        Observer.Expect('view_missing_disallow', 'ok');
        Observer.Verify();
    end;
}
