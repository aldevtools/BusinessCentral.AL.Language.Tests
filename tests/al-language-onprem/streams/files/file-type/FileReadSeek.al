// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.Read Seek Trunc
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61265 "LT P110 File Read Seek"
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
    local procedure TSeek(var F: File; Pos: Integer)
    begin
        F.Seek(Pos);
    end;

    [Test]
    procedure P110_BinaryWriteReadRoundtrip()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        I: Integer;
        I2: Integer;
        T: Text[20];
        T2: Text[20];
        Dec: Decimal;
        Dec2: Decimal;
        By: Byte;
        By2: Byte;
        D: Date;
        D2: Date;
        B: Boolean;
        B2: Boolean;
        Ret: Integer;
    begin
        P := TempName();
        I := 123456;
        T := 'hello';
        Dec := 3.14159;
        By := 77;
        D := DMY2Date(5, 6, 2019);
        B := true;
        F.Create(P);
        F.TextMode(false);
        F.Write(I);
        F.Write(T);
        F.Write(Dec);
        F.Write(By);
        F.Write(D);
        F.Write(B);
        Observer.Observe('len', Format(F.Len()));
        F.Close();
        F.Open(P);
        F.TextMode(false);
        Observer.Observe('pos_open', Format(F.Pos()));
        Ret := F.Read(I2);
        Observer.Observe('read_int', Format(I2) + ' ret=' + Format(Ret));
        Observer.Observe('pos_after_int', Format(F.Pos()));
        Ret := F.Read(T2);
        Observer.Observe('read_text', T2 + ' ret=' + Format(Ret));
        Observer.Observe('pos_after_text', Format(F.Pos()));
        Ret := F.Read(Dec2);
        Observer.Observe('read_dec', Format(Dec2) + ' ret=' + Format(Ret));
        Ret := F.Read(By2);
        Observer.Observe('read_byte', Format(By2) + ' ret=' + Format(Ret));
        Ret := F.Read(D2);
        Observer.Observe('read_date', Format(D2) + ' ret=' + Format(Ret));
        Ret := F.Read(B2);
        Observer.Observe('read_bool', Format(B2) + ' ret=' + Format(Ret));
        Observer.Observe('pos_end', Format(F.Pos()));
        asserterror F.Read(I2);
        Observer.ObserveError('read_at_eof');
        F.Close();
        Cleanup(P);
        Observer.Expect('len', '46');
        Observer.Expect('pos_open', '0');
        Observer.Expect('read_int', '123456 ret=4');
        Observer.Expect('pos_after_int', '4');
        Observer.Expect('read_text', 'hello ret=21');
        Observer.Expect('pos_after_text', '25');
        Observer.Expect('read_dec', '3.14159 ret=12');
        Observer.Expect('read_byte', 'M ret=1');
        Observer.Expect('read_date', '06/05/19 ret=4');
        Observer.Expect('read_bool', 'Yes ret=4');
        Observer.Expect('pos_end', '46');
        Observer.Expect('read_at_eof|text', 'Invalid data encountered in stream, unable to read text.');
        Observer.Expect('read_at_eof|code', 'InvalidStreamData');
        Observer.Verify();
    end;

    [Test]
    procedure P110_Seek()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        I: Integer;
        Ret: Integer;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(false);
        for I := 1 to 5 do
            F.Write(I * 100);
        Observer.Observe('len', Format(F.Len()));
        F.Seek(0);
        Observer.Observe('pos_seek0', Format(F.Pos()));
        Ret := F.Read(I);
        Observer.Observe('read_first', Format(I) + ' ret=' + Format(Ret));
        F.Seek(8);
        Observer.Observe('pos_seek8', Format(F.Pos()));
        Ret := F.Read(I);
        Observer.Observe('read_at8', Format(I) + ' ret=' + Format(Ret));
        F.Seek(F.Len());
        Observer.Observe('pos_seek_len', Format(F.Pos()));
        F.Seek(F.Len() + 10);
        Observer.Observe('pos_seek_beyond', Format(F.Pos()));
        Observer.Observe('len_after_seek_beyond', Format(F.Len()));
        if TSeek(F, -1) then
            Observer.Observe('seek_negative', 'ok pos=' + Format(F.Pos()))
        else
            Observer.Observe('seek_negative', 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
        F.Close();
        Cleanup(P);
        Observer.Expect('len', '20');
        Observer.Expect('pos_seek0', '0');
        Observer.Expect('read_first', '100 ret=4');
        Observer.Expect('pos_seek8', '8');
        Observer.Expect('read_at8', '300 ret=4');
        Observer.Expect('pos_seek_len', '20');
        Observer.Expect('pos_seek_beyond', '30');
        Observer.Expect('len_after_seek_beyond', '20');
        Observer.Expect('seek_negative', 'error: Invalid argument :  code=StreamIO:IO');
        Observer.Verify();
    end;

    [Test]
    procedure P110_Trunc()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        I: Integer;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(false);
        for I := 1 to 5 do
            F.Write(I);
        Observer.Observe('len_before', Format(F.Len()));
        F.Seek(8);
        F.Trunc();
        Observer.Observe('len_after_trunc_at8', Format(F.Len()));
        Observer.Observe('pos_after_trunc', Format(F.Pos()));
        F.Seek(0);
        F.Trunc();
        Observer.Observe('len_after_trunc_at0', Format(F.Len()));
        F.Close();
        F.Open(P);
        Observer.Observe('len_reopen', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('len_before', '20');
        Observer.Expect('len_after_trunc_at8', '8');
        Observer.Expect('pos_after_trunc', '8');
        Observer.Expect('len_after_trunc_at0', '0');
        Observer.Expect('len_reopen', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P110_TextReadLines()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        L1: Text;
        L2: Text;
        L3: Text;
        Ret: Integer;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        F.Write('first line');
        F.Write('');
        F.Write('third line');
        Observer.Observe('len', Format(F.Len()));
        F.Close();
        F.Open(P);
        F.TextMode(true);
        Ret := F.Read(L1);
        Observer.Observe('line1', '[' + L1 + '] ret=' + Format(Ret));
        Observer.Observe('pos1', Format(F.Pos()));
        Ret := F.Read(L2);
        Observer.Observe('line2', '[' + L2 + '] ret=' + Format(Ret));
        Ret := F.Read(L3);
        Observer.Observe('line3', '[' + L3 + '] ret=' + Format(Ret));
        Observer.Observe('pos_end', Format(F.Pos()));
        Clear(L1);
        Ret := F.Read(L1);
        Observer.Observe('read_past_end', '[' + L1 + '] ret=' + Format(Ret));
        F.Close();
        Cleanup(P);
        Observer.Expect('len', '26');
        Observer.Expect('line1', '[first line] ret=10');
        Observer.Expect('pos1', '12');
        Observer.Expect('line2', '[] ret=0');
        Observer.Expect('line3', '[third line] ret=10');
        Observer.Expect('pos_end', '26');
        Observer.Expect('read_past_end', '[] ret=0');
        Observer.Verify();
    end;
}
