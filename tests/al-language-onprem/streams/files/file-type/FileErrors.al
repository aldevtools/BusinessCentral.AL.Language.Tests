// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File errors (missing file, wrong mode, closed)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61267 "LT P110 File Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TTextMode(var F: File; Set: Boolean; Mode: Boolean; var R: Boolean)
    begin
        if Set then
            R := F.TextMode(Mode)
        else
            R := F.TextMode();
    end;

    [TryFunction]
    local procedure TWriteMode(var F: File; Set: Boolean; Mode: Boolean; var R: Boolean)
    begin
        if Set then
            R := F.WriteMode(Mode)
        else
            R := F.WriteMode();
    end;

    local procedure TM(var F: File; Set: Boolean; Mode: Boolean): Text
    var
        R: Boolean;
    begin
        if TTextMode(F, Set, Mode, R) then
            exit(Format(R));
        exit('error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    local procedure WM(var F: File; Set: Boolean; Mode: Boolean): Text
    var
        R: Boolean;
    begin
        if TWriteMode(F, Set, Mode, R) then
            exit(Format(R));
        exit('error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

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

    local procedure Rec(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TOpen(var F: File; P: Text)
    begin
        F.Open(P);
    end;

    [TryFunction]
    local procedure TCreate(var F: File; P: Text)
    begin
        F.Create(P);
    end;

    [TryFunction]
    local procedure TWriteText(var F: File; V: Text)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure TReadText(var F: File; var V: Text)
    begin
        F.Read(V);
    end;

    [TryFunction]
    local procedure TReadInt(var F: File; var V: Integer)
    begin
        F.Read(V);
    end;

    [TryFunction]
    local procedure TWriteInt(var F: File; V: Integer)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure TClose(var F: File)
    begin
        F.Close();
    end;

    [TryFunction]
    local procedure TLen(var F: File; var L: Integer)
    begin
        L := F.Len();
    end;

    [TryFunction]
    local procedure TPos(var F: File; var L: Integer)
    begin
        L := F.Pos();
    end;

    [TryFunction]
    local procedure TSeek(var F: File; Pos: Integer)
    begin
        F.Seek(Pos);
    end;

    [TryFunction]
    local procedure TTrunc(var F: File)
    begin
        F.Trunc();
    end;

    [TryFunction]
    local procedure TName(var F: File; var N: Text)
    begin
        N := F.Name();
    end;

    [TryFunction]
    local procedure TErase(P: Text)
    begin
        File.Erase(P);
    end;

    [TryFunction]
    local procedure TRename(P1: Text; P2: Text)
    begin
        File.Rename(P1, P2);
    end;

    [TryFunction]
    local procedure TCopy(P1: Text; P2: Text)
    begin
        File.Copy(P1, P2);
    end;

    [TryFunction]
    local procedure TGetStamp(P: Text; var D: Date; var T: Time)
    begin
        File.GetStamp(P, D, T);
    end;

    [TryFunction]
    local procedure TSetStamp(P: Text; D: Date; T: Time)
    begin
        File.SetStamp(P, D, T);
    end;

    [Test]
    procedure P110_MissingFile()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        P2: Text;
        D: Date;
        T: Time;
    begin
        P := TempName();
        P2 := TempName();
        Rec(Observer, 'open_missing', TOpen(F, P));
        Rec(Observer, 'erase_missing', TErase(P));
        Rec(Observer, 'rename_missing', TRename(P, P2));
        Rec(Observer, 'copy_missing', TCopy(P, P2));
        Rec(Observer, 'getstamp_missing', TGetStamp(P, D, T));
        Rec(Observer, 'setstamp_missing', TSetStamp(P, DMY2Date(1, 1, 2020), 120000T));
        Observer.Observe('exists_p2', Format(File.Exists(P2)));
        Cleanup(P);
        Cleanup(P2);
        Observer.Expect('open_missing', 'error: File  code=FileNotFound');
        Observer.Expect('erase_missing', 'error: File  code=FileNotFound');
        Observer.Expect('rename_missing', 'error: File  code=FileNotFound');
        Observer.Expect('copy_missing', 'error: File  code=FileNotFound');
        Observer.Expect('getstamp_missing', 'error: File  code=FileNotFound');
        Observer.Expect('setstamp_missing', 'error: File  code=FileNotFound');
        Observer.Expect('exists_p2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P110_InvalidPaths()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        Dir: Text;
    begin
        Rec(Observer, 'create_empty_name', TCreate(F, ''));
        Rec(Observer, 'open_empty_name', TOpen(F, ''));
        Observer.Observe('exists_empty', Format(File.Exists('')));
        Dir := TemporaryPath() + 'p110nodir' + DelChr(Format(CreateGuid()), '=', '{}-') + '/x.tmp';
        Rec(Observer, 'create_in_missing_dir', TCreate(F, Dir));
        Rec(Observer, 'open_in_missing_dir', TOpen(F, Dir));
        Observer.Observe('exists_in_missing_dir', Format(File.Exists(Dir)));
        Rec(Observer, 'erase_empty_name', TErase(''));
        if File.Exists(Dir) then
            File.Erase(Dir);
        Observer.Expect('create_empty_name', 'error: File name was not specified. code=MissingFileName');
        Observer.Expect('open_empty_name', 'error: File name was not specified. code=MissingFileName');
        Observer.Expect('exists_empty', 'No');
        // Windows BC 29.0 (corpus probe branch al-runtime-rs-winprobe-63c, cu 98998): a write into a missing folder fails and
        // does not create the folder. Full text: "Could not find a part of the path '<TemporaryPath>p110nodir<guid>\x.tmp'."
        Observer.Expect('create_in_missing_dir', 'error: Could not find a part of the path  code=InvalidPath');
        Observer.Expect('open_in_missing_dir', 'error: Could not find a part of the path  code=InvalidPath');
        Observer.Expect('exists_in_missing_dir', 'No');
        Observer.Expect('erase_empty_name', 'error: The value cannot be an empty string. (Parameter  code=InvalidPath');
        Observer.Verify();
    end;

    [Test]
    procedure P110_ClosedFileUse()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        N: Text;
        I: Integer;
        V: Text;
    begin
        P := TempName();
        F.Create(P);
        F.Write('abc');
        F.Close();
        Rec(Observer, 'write_after_close', TWriteText(F, 'x'));
        Rec(Observer, 'read_after_close', TReadText(F, V));
        Rec(Observer, 'len_after_close', TLen(F, I));
        Rec(Observer, 'pos_after_close', TPos(F, I));
        Rec(Observer, 'seek_after_close', TSeek(F, 0));
        Rec(Observer, 'trunc_after_close', TTrunc(F));
        Rec(Observer, 'name_after_close', TName(F, N));
        Rec(Observer, 'close_after_close', TClose(F));
        Cleanup(P);
        Observer.Expect('write_after_close', 'error: WRITE is not supported for Text without a maximum length. code=StreamWideTextMaxLength');
        Observer.Expect('read_after_close', 'error: Arithmetic operation resulted in an overflow. code=AL:Overflow');
        Observer.Expect('len_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('pos_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('seek_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('trunc_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('name_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('close_after_close', 'error: The file is not open. code=FileNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure P110_NeverOpenedUse()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        N: Text;
        I: Integer;
        V: Text;
    begin
        Rec(Observer, 'write_unopened', TWriteText(F, 'x'));
        Rec(Observer, 'read_unopened', TReadText(F, V));
        Rec(Observer, 'len_unopened', TLen(F, I));
        Rec(Observer, 'pos_unopened', TPos(F, I));
        Rec(Observer, 'seek_unopened', TSeek(F, 0));
        Rec(Observer, 'trunc_unopened', TTrunc(F));
        Rec(Observer, 'name_unopened', TName(F, N));
        Rec(Observer, 'close_unopened', TClose(F));
        Observer.Expect('write_unopened', 'error: WRITE is not supported for Text without a maximum length. code=StreamWideTextMaxLength');
        Observer.Expect('read_unopened', 'error: Arithmetic operation resulted in an overflow. code=AL:Overflow');
        Observer.Expect('len_unopened', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('pos_unopened', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('seek_unopened', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('trunc_unopened', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('name_unopened', 'error: The file is not open. code=FileNotOpened');
        Observer.Expect('close_unopened', 'error: The file is not open. code=FileNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure P110_WrongMode()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        V: Text;
        I: Integer;
    begin
        P := TempName();
        F.Create(P);
        F.Write('abc');
        F.Close();
        // opened for reading only after WriteMode(false)
        F.WriteMode(false);
        F.Open(P);
        Observer.Observe('writemode_after_open', WM(F, false, false));
        Rec(Observer, 'write_readonly', TWriteText(F, 'zzz'));
        F.Close();
        // read from a file opened in write-only mode
        F.WriteMode(true);
        F.Open(P);
        Observer.Observe('set_writemode_while_open', WM(F, true, true));
        Observer.Observe('set_textmode_while_open', TM(F, true, true));
        Rec(Observer, 'read_writemode', TReadText(F, V));
        F.Close();
        // text read of an Integer, binary read of a Text from a short file
        F.WriteMode(false);
        F.Open(P);
        Observer.Observe('set_textmode_false', TM(F, true, false));
        Rec(Observer, 'read_int_binary_3_bytes_file', TReadInt(F, I));
        Observer.Observe('int_value', Format(I));
        F.Close();
        F.WriteMode(true);
        F.Create(P);
        F.Close();
        F.Open(P);
        Rec(Observer, 'read_empty_file', TReadText(F, V));
        F.Close();
        Cleanup(P);
        Observer.Expect('writemode_after_open', 'No');
        Observer.Expect('write_readonly', 'error: WRITE is not supported for Text without a maximum length. code=StreamWideTextMaxLength');
        Observer.Expect('set_writemode_while_open', 'error: The operation cannot be performed while the file is open. code=FileAlreadyOpened');
        Observer.Expect('set_textmode_while_open', 'Yes');
        Observer.Expect('read_writemode', 'ok');
        Observer.Expect('set_textmode_false', 'No');
        Observer.Expect('read_int_binary_3_bytes_file', 'ok');
        Observer.Expect('int_value', '6513249');
        Observer.Expect('read_empty_file', 'error: Arithmetic operation resulted in an overflow. code=AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CreateTwiceWithoutClose()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        P2: Text;
    begin
        P := TempName();
        P2 := TempName();
        F.Create(P);
        Rec(Observer, 'create_second_on_open_var', TCreate(F, P2));
        Rec(Observer, 'open_on_open_var', TOpen(F, P));
        F.Close();
        Cleanup(P);
        Cleanup(P2);
        Observer.Expect('create_second_on_open_var', 'error: The operation cannot be performed while the file is open. code=FileAlreadyOpened');
        Observer.Expect('open_on_open_var', 'error: The operation cannot be performed while the file is open. code=FileAlreadyOpened');
        Observer.Verify();
    end;

    [Test]
    procedure P110_SameFileTwoVars()
    var
        F1: File;
        F2: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F1.Create(P);
        F1.Write('abc');
        Rec(Observer, 'open_second_var_while_open', TOpen(F2, P));
        Rec(Observer, 'erase_while_open', TErase(P));
        F1.Close();
        Rec(Observer, 'close_second_var', TClose(F2));
        Cleanup(P);
        Observer.Expect('open_second_var_while_open', 'error: The process cannot access the file  code=StreamIO:IO');
        Observer.Expect('erase_while_open', 'ok');
        Observer.Expect('close_second_var', 'error: The file is not open. code=FileNotOpened');
        Observer.Verify();
    end;
}
