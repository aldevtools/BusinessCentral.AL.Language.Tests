// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.Read into short Text/Code (may raise)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61266 "LT P110 File Read Short"
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

    [TryFunction]
    local procedure TryReadSmall(var F: File; var Small: Text[3])
    begin
        F.Read(Small);
    end;

    [TryFunction]
    local procedure TryReadCode(var F: File; var Co: Code[4])
    begin
        F.Read(Co);
    end;

    [Test]
    procedure P110_ReadIntoSmallText()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        Small: Text[3];
        Co: Code[4];
        Ok: Boolean;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        F.Write('abcdefgh');
        F.Write('xyzuvw');
        F.Close();
        F.Open(P);
        F.TextMode(true);
        Ok := TryReadSmall(F, Small);
        Observer.Observe('small_ok', Format(Ok) + ' [' + Small + ']');
        if not Ok then
            Observer.Observe('small_error', ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        Ok := TryReadCode(F, Co);
        Observer.Observe('code_ok', Format(Ok) + ' [' + Co + ']');
        if not Ok then
            Observer.Observe('code_error', ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        F.Close();
        Cleanup(P);
        Observer.Expect('small_ok', 'No []');
        Observer.Expect('small_error', 'The length of the string is 8, but it must be less than or equal to 3 characters. Value: abcdefgh code=StringLengthExceeded');
        Observer.Expect('code_ok', 'No []');
        Observer.Expect('code_error', 'The length of the string is 6, but it must be less than or equal to 4 characters. Value: xyzuvw code=StringLengthExceeded');
        Observer.Verify();
    end;
}
