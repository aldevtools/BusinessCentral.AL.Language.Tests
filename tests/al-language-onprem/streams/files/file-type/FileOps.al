// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.Rename Copy GetStamp SetStamp Exists Erase
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61268 "LT P110 File Ops"
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

    local procedure MakeFile(P: Text; Content: Text)
    var
        F: File;
    begin
        F.Create(P);
        F.TextMode(true);
        F.Write(Content);
        F.Close();
    end;

    local procedure LenOf(P: Text): Integer
    var
        F: File;
        L: Integer;
    begin
        F.Open(P);
        L := F.Len();
        F.Close();
        exit(L);
    end;

    [Test]
    procedure P110_Rename()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
        B: Text;
    begin
        A := TempName();
        B := TempName();
        MakeFile(A, 'content');
        Observer.Observe('rename', Format(File.Rename(A, B)));
        Observer.Observe('exists_old', Format(File.Exists(A)));
        Observer.Observe('exists_new', Format(File.Exists(B)));
        Observer.Observe('len_new', Format(LenOf(B)));
        Cleanup(A);
        Cleanup(B);
        Observer.Expect('rename', 'Yes');
        Observer.Expect('exists_old', 'No');
        Observer.Expect('exists_new', 'Yes');
        Observer.Expect('len_new', '9');
        Observer.Verify();
    end;

    [Test]
    procedure P110_RenameOntoExisting()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
        B: Text;
        TryOk: Boolean;
    begin
        A := TempName();
        B := TempName();
        MakeFile(A, 'aaaa');
        MakeFile(B, 'bb');
        TryOk := TryRename(A, B);
        Observer.Observe('rename_onto_existing_ok', Format(TryOk));
        if not TryOk then
            Observer.Observe('rename_onto_existing_error', ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        Observer.Observe('exists_a', Format(File.Exists(A)));
        Observer.Observe('len_b', Format(LenOf(B)));
        Cleanup(A);
        Cleanup(B);
        Observer.Expect('rename_onto_existing_ok', 'No');
        Observer.Expect('rename_onto_existing_error', 'The file  code=StreamIO:IO');
        Observer.Expect('exists_a', 'Yes');
        Observer.Expect('len_b', '4');
        Observer.Verify();
    end;

    [Test]
    procedure P110_Copy()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
        B: Text;
    begin
        A := TempName();
        B := TempName();
        MakeFile(A, 'copy me');
        Observer.Observe('copy', Format(File.Copy(A, B)));
        Observer.Observe('exists_a', Format(File.Exists(A)));
        Observer.Observe('exists_b', Format(File.Exists(B)));
        Observer.Observe('len_a', Format(LenOf(A)));
        Observer.Observe('len_b', Format(LenOf(B)));
        Cleanup(A);
        Cleanup(B);
        Observer.Expect('copy', 'Yes');
        Observer.Expect('exists_a', 'Yes');
        Observer.Expect('exists_b', 'Yes');
        Observer.Expect('len_a', '9');
        Observer.Expect('len_b', '9');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CopyOntoExisting()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
        B: Text;
        TryOk: Boolean;
    begin
        A := TempName();
        B := TempName();
        MakeFile(A, 'aaaa');
        MakeFile(B, 'b');
        TryOk := TryCopy(A, B);
        Observer.Observe('copy_onto_existing_ok', Format(TryOk));
        if not TryOk then
            Observer.Observe('copy_onto_existing_error', ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        Observer.Observe('len_b', Format(LenOf(B)));
        Cleanup(A);
        Cleanup(B);
        Observer.Expect('copy_onto_existing_ok', 'Yes');
        Observer.Expect('len_b', '6');
        Observer.Verify();
    end;

    [Test]
    procedure P110_EraseExistsReturnValues()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
    begin
        A := TempName();
        MakeFile(A, 'x');
        Observer.Observe('exists', Format(File.Exists(A)));
        Observer.Observe('erase', Format(File.Erase(A)));
        Observer.Observe('exists_after', Format(File.Exists(A)));
        Observer.Observe('exists_directory', Format(File.Exists(TemporaryPath())));
        Cleanup(A);
        Observer.Expect('exists', 'Yes');
        Observer.Expect('erase', 'Yes');
        Observer.Expect('exists_after', 'No');
        Observer.Expect('exists_directory', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P110_SetStampGetStamp()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
        D: Date;
        T: Time;
        D2: Date;
    begin
        A := TempName();
        MakeFile(A, 'x');
        Observer.Observe('setstamp_date_time', Format(File.SetStamp(A, DMY2Date(15, 3, 2019), 101112T)));
        Observer.Observe('getstamp', Format(File.GetStamp(A, D, T)));
        Observer.Observe('date', Format(D, 0, 9));
        Observer.Observe('time', Format(T, 0, 9));
        Observer.Observe('setstamp_date_only', Format(File.SetStamp(A, DMY2Date(1, 1, 2020))));
        Observer.Observe('getstamp_date_only', Format(File.GetStamp(A, D2)));
        Observer.Observe('date2', Format(D2, 0, 9));
        Observer.Observe('getstamp_time_after_date_only', Format(File.GetStamp(A, D, T)));
        Observer.Observe('time_after_date_only', Format(T, 0, 9));
        Cleanup(A);
        Observer.Expect('setstamp_date_time', 'Yes');
        Observer.Expect('getstamp', 'Yes');
        Observer.Expect('date', '2019-03-15');
        Observer.Expect('time', '10:11:12');
        Observer.Expect('setstamp_date_only', 'Yes');
        Observer.Expect('getstamp_date_only', 'Yes');
        Observer.Expect('date2', '2020-01-01');
        Observer.Expect('getstamp_time_after_date_only', 'Yes');
        Observer.Expect('time_after_date_only', '00:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure P110_SetStampEdges()
    var
        Observer: Codeunit "Probe Observer";
        A: Text;
        D: Date;
        T: Time;
        TryOk: Boolean;
    begin
        A := TempName();
        MakeFile(A, 'x');
        TryOk := TrySet(A, 0D, 0T);
        Observer.Observe('set_blank_ok', Format(TryOk));
        if not TryOk then
            Observer.Observe('set_blank_error', ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        TryOk := TrySet(A, DMY2Date(1, 1, 1970), 0T);
        Observer.Observe('set_1970_ok', Format(TryOk));
        if File.GetStamp(A, D, T) then
            Observer.Observe('stamp_1970', Format(D, 0, 9) + ' ' + Format(T, 0, 9));
        TryOk := TrySet(A, DMY2Date(1, 1, 1950), 120000T);
        Observer.Observe('set_1950_ok', Format(TryOk));
        if not TryOk then
            Observer.Observe('set_1950_error', ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        Cleanup(A);
        Observer.Expect('set_blank_ok', 'Yes');
        Observer.Expect('set_1970_ok', 'Yes');
        Observer.Expect('stamp_1970', '1970-01-01 00:00:00');
        Observer.Expect('set_1950_ok', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRename(A: Text; B: Text)
    begin
        File.Rename(A, B);
    end;

    [TryFunction]
    local procedure TryCopy(A: Text; B: Text)
    begin
        File.Copy(A, B);
    end;

    [TryFunction]
    local procedure TrySet(P: Text; D: Date; T: Time)
    begin
        File.SetStamp(P, D, T);
    end;
}
