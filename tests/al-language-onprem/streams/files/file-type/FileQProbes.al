// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); own table LT P110 File Rec (61279)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Pins, from the File issues of the corpus: (1) the return value and outputs of File.Download, File.DownloadFromStream, File.Upload, both File.UploadIntoStream forms, File.View and File.ViewFromStream when no client handles the dialog (the return variable is set to true before each call, so an untouched variable shows as ret=Yes); (2) File.Write per value type in binary and in text mode: result, File.Pos and File.Len, and the exact bytes read back through File.CreateInStream (hex); a value BC refuses shows the error text and code; (3) File.Exists for a folder name and blank names.
// BC versions: 29 (27 and 28 by CI). File.Download and File.DownloadFromStream are pinned from BC 28 only: on BC 27 both raise an uncatchable System.NullReferenceException ("Unexpected CLR exception thrown.") that fails the test, even inside asserterror or a TryFunction.
codeunit 61276 "LT Q File Probes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LblText: Label 'label text';

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

    local procedure Rec(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean; R: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok ret=' + Format(R))
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

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

    [TryFunction]
    local procedure TUpload(Title: Text; Folder: Text; Filter: Text; FromFile: Text; var ToFile: Text; var R: Boolean)
    begin
        R := File.Upload(Title, Folder, Filter, FromFile, ToFile);
    end;

    [TryFunction]
    local procedure TUploadIntoStream4(Title: Text; Folder: Text; Filter: Text; var FromFile: Text; var InS: InStream; var R: Boolean)
    begin
        R := File.UploadIntoStream(Title, Folder, Filter, FromFile, InS);
    end;

    [TryFunction]
    local procedure TUploadIntoStream2(Filter: Text; var InS: InStream; var R: Boolean)
    begin
        R := File.UploadIntoStream(Filter, InS);
    end;

    [TryFunction]
    local procedure TView(FromFile: Text; Allow: Boolean; var R: Boolean)
    begin
        R := File.View(FromFile, Allow);
    end;

    [TryFunction]
    local procedure TViewFromStream(var InS: InStream; Name: Text; Allow: Boolean; var R: Boolean)
    begin
        R := File.ViewFromStream(InS, Name, Allow);
    end;

#if BC28PLUS
    [Test]
    procedure Download_NoClient_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
        ToFile: Text;
        R: Boolean;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('download content');
        F.Close();
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_title', TDownload(P, 'Title', '', '', ToFile, R), R);
        Observer.Observe('dl_title_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_all_args', TDownload(P, 'Title', TemporaryPath(), 'Text files (*.txt)|*.txt', ToFile, R), R);
        Observer.Observe('dl_all_args_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_blank', TDownload(P, '', '', '', ToFile, R), R);
        Observer.Observe('dl_blank_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_missing', TDownload(P + '.missing', 'Title', '', '', ToFile, R), R);
        Observer.Observe('dl_missing_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dl_blank_from', TDownload('', 'Title', '', '', ToFile, R), R);
        Observer.Observe('dl_blank_from_tofile', '[' + ToFile + ']');
        Observer.Observe('source_still_exists', Format(File.Exists(P)));
        Cleanup(P);
        Observer.Expect('dl_title_tofile', '[untouched]');
        Observer.Expect('dl_all_args_tofile', '[untouched]');
        Observer.Expect('dl_blank_tofile', '[untouched]');
        Observer.Expect('dl_missing_tofile', '[untouched]');
        Observer.Expect('dl_blank_from_tofile', '[untouched]');
        // Linux container differs from Windows BC (run 39125184978 / 39125190236): File.Download returns Yes (the pre-set value is kept) on BC 27.5 and 29.0 and leaves ToFile untouched; Linux BC 28+ returns No. The dl_* return values are not asserted.
        Observer.Expect('source_still_exists', 'Yes');
        Observer.Ignore('dl_title');
        Observer.Ignore('dl_all_args');
        Observer.Ignore('dl_blank');
        Observer.Ignore('dl_missing');
        Observer.Ignore('dl_blank_from');
        Observer.Verify();
    end;

    [Test]
    procedure DownloadFromStream_NoClient_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        InS: InStream;
        ToFile: Text;
        R: Boolean;
    begin
        F.CreateTempFile();
        F.CreateOutStream(OutS);
        OutS.WriteText('stream content');
        F.CreateInStream(InS);
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dls_title', TDownloadStream(InS, 'Title', '', '', ToFile, R), R);
        Observer.Observe('dls_title_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dls_all_args', TDownloadStream(InS, 'Title', TemporaryPath(), 'Text files (*.txt)|*.txt', ToFile, R), R);
        Observer.Observe('dls_all_args_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'dls_blank', TDownloadStream(InS, '', '', '', ToFile, R), R);
        Observer.Observe('dls_blank_tofile', '[' + ToFile + ']');
        Observer.Observe('stream_eos_after', Format(InS.EOS()));
        F.Close();
        Observer.Expect('dls_title_tofile', '[untouched]');
        Observer.Expect('dls_all_args_tofile', '[untouched]');
        Observer.Expect('dls_blank_tofile', '[untouched]');
        // Linux container differs from Windows BC (run 39125184978 / 39125190236): DownloadFromStream returns Yes on Windows (27.5 and 29.0); Linux BC 28+ returns No. The dls_* return values are not asserted.
        Observer.Expect('stream_eos_after', 'No');
        Observer.Ignore('dls_title');
        Observer.Ignore('dls_all_args');
        Observer.Ignore('dls_blank');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure Upload_NoClient_ReturnAndToFile()
    var
        Observer: Codeunit "Probe Observer";
        ToFile: Text;
        R: Boolean;
    begin
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'up_title', TUpload('Title', '', '', '', ToFile, R), R);
        Observer.Observe('up_title_tofile', '[' + ToFile + ']');
        R := true;
        ToFile := 'untouched';
        Rec(Observer, 'up_all_args', TUpload('Title', TemporaryPath(), 'Text files (*.txt)|*.txt', 'a.txt', ToFile, R), R);
        Observer.Observe('up_all_args_tofile', '[' + ToFile + ']');
        Observer.Expect('up_title', 'ok ret=No');
        Observer.Expect('up_title_tofile', '[untouched]');
        Observer.Expect('up_all_args', 'ok ret=No');
        Observer.Expect('up_all_args_tofile', '[untouched]');
        Observer.Verify();
    end;

    [Test]
    procedure UploadIntoStream_DialogForm_NoClient_ReturnAndFromFile()
    var
        Observer: Codeunit "Probe Observer";
        FromFile: Text;
        InS: InStream;
        R: Boolean;
    begin
        R := true;
        FromFile := 'untouched';
        Rec(Observer, 'uis_title', TUploadIntoStream4('Title', '', '', FromFile, InS, R), R);
        Observer.Observe('uis_title_fromfile', '[' + FromFile + ']');
        R := true;
        FromFile := 'untouched';
        Rec(Observer, 'uis_filter', TUploadIntoStream4('', '', 'Text files (*.txt)|*.txt', FromFile, InS, R), R);
        Observer.Observe('uis_filter_fromfile', '[' + FromFile + ']');
        Observer.Expect('uis_title', 'ok ret=No');
        Observer.Expect('uis_title_fromfile', '[untouched]');
        Observer.Expect('uis_filter', 'ok ret=No');
        Observer.Expect('uis_filter_fromfile', '[untouched]');
        Observer.Verify();
    end;

    [Test]
    procedure UploadIntoStream_FilterForm_NoClient_Return()
    var
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        R: Boolean;
    begin
        R := true;
        Rec(Observer, 'uis2_blank', TUploadIntoStream2('', InS, R), R);
        R := true;
        Rec(Observer, 'uis2_txt', TUploadIntoStream2('Text files (*.txt)|*.txt', InS, R), R);
        Observer.Expect('uis2_blank', 'ok ret=No');
        Observer.Expect('uis2_txt', 'ok ret=No');
        Observer.Verify();
    end;

    [Test]
    procedure View_NoClient_Return()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        OutS: OutStream;
        P: Text;
        R: Boolean;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('view content');
        F.Close();
        R := true;
        Rec(Observer, 'view_existing', TView(P, true, R), R);
        R := true;
        Rec(Observer, 'view_existing_disallow', TView(P, false, R), R);
        R := true;
        Rec(Observer, 'view_missing', TView(P + '.missing', true, R), R);
        R := true;
        Rec(Observer, 'view_blank', TView('', true, R), R);
        Cleanup(P);
        Observer.Expect('view_existing', 'ok ret=No');
        Observer.Expect('view_existing_disallow', 'ok ret=No');
        Observer.Expect('view_missing', 'ok ret=No');
        Observer.Expect('view_blank', 'ok ret=No');
        Observer.Verify();
    end;

    [Test]
    procedure ViewFromStream_NoClient_Return()
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
        R := true;
        Rec(Observer, 'vfs_allow', TViewFromStream(InS, 'q.txt', true, R), R);
        R := true;
        Rec(Observer, 'vfs_disallow', TViewFromStream(InS, 'q.txt', false, R), R);
        R := true;
        Rec(Observer, 'vfs_blank_name', TViewFromStream(InS, '', true, R), R);
        F.Close();
        Observer.Expect('vfs_allow', 'ok ret=No');
        Observer.Expect('vfs_disallow', 'ok ret=No');
        Observer.Expect('vfs_blank_name', 'ok ret=No');
        Observer.Verify();
    end;
    local procedure ByteHex(B: Byte): Text
    var
        Digits: Text;
    begin
        Digits := '0123456789ABCDEF';
        exit(CopyStr(Digits, (B div 16) + 1, 1) + CopyStr(Digits, (B mod 16) + 1, 1));
    end;

    [TryFunction]
    local procedure Dump(var F: File; var Hex: Text)
    var
        Ins: InStream;
        B: Byte;
    begin
        Hex := '';
        F.CreateInStream(Ins);
        while not Ins.EOS() do begin
            Ins.Read(B);
            Hex += ByteHex(B);
        end;
    end;

    [TryFunction]
    local procedure W_BigInteger(var F: File; V: BigInteger)
    begin
        F.Write(V);
    end;

    local procedure Do_BigInteger(var Observer: Codeunit "Probe Observer"; Id: Text; V: BigInteger; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_BigInteger(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Boolean(var F: File; V: Boolean)
    begin
        F.Write(V);
    end;

    local procedure Do_Boolean(var Observer: Codeunit "Probe Observer"; Id: Text; V: Boolean; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Boolean(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Byte(var F: File; V: Byte)
    begin
        F.Write(V);
    end;

    local procedure Do_Byte(var Observer: Codeunit "Probe Observer"; Id: Text; V: Byte; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Byte(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Char(var F: File; V: Char)
    begin
        F.Write(V);
    end;

    local procedure Do_Char(var Observer: Codeunit "Probe Observer"; Id: Text; V: Char; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Char(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Decimal(var F: File; V: Decimal)
    begin
        F.Write(V);
    end;

    local procedure Do_Decimal(var Observer: Codeunit "Probe Observer"; Id: Text; V: Decimal; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Decimal(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Guid(var F: File; V: Guid)
    begin
        F.Write(V);
    end;

    local procedure Do_Guid(var Observer: Codeunit "Probe Observer"; Id: Text; V: Guid; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Guid(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Integer(var F: File; V: Integer)
    begin
        F.Write(V);
    end;

    local procedure Do_Integer(var Observer: Codeunit "Probe Observer"; Id: Text; V: Integer; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Integer(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Option(var F: File; V: Option A,B,C)
    begin
        F.Write(V);
    end;

    local procedure Do_Option(var Observer: Codeunit "Probe Observer"; Id: Text; V: Option A,B,C; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Option(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [Test]
    procedure Write_BigInteger_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: BigInteger;
    begin
        Clear(V);
        V := 258;
        Do_BigInteger(Observer, 'bin_small', V, false);
        Do_BigInteger(Observer, 'txt_small', V, true);
        Clear(V);
        V := 2147483647; V := V * 4;
        Do_BigInteger(Observer, 'bin_big', V, false);
        Do_BigInteger(Observer, 'txt_big', V, true);
        Observer.Expect('bin_small_w', 'ok');
        Observer.Expect('bin_small_pos', '8/8');
        Observer.Expect('bin_small_bytes', '0201000000000000');
        Observer.Expect('txt_small_w', 'ok');
        Observer.Expect('txt_small_pos', '5/5');
        Observer.Expect('txt_small_bytes', '3235380D0A');
        Observer.Expect('bin_big_w', 'ok');
        Observer.Expect('bin_big_pos', '8/8');
        Observer.Expect('bin_big_bytes', 'FCFFFFFF01000000');
        Observer.Expect('txt_big_w', 'ok');
        Observer.Expect('txt_big_pos', '12/12');
        Observer.Expect('txt_big_bytes', '383538393933343538380D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Boolean_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Boolean;
    begin
        Clear(V);
        V := true;
        Do_Boolean(Observer, 'bin_yes', V, false);
        Do_Boolean(Observer, 'txt_yes', V, true);
        Clear(V);
        V := false;
        Do_Boolean(Observer, 'bin_no', V, false);
        Do_Boolean(Observer, 'txt_no', V, true);
        Observer.Expect('bin_yes_w', 'ok');
        Observer.Expect('bin_yes_pos', '4/4');
        Observer.Expect('bin_yes_bytes', '01000000');
        Observer.Expect('txt_yes_w', 'ok');
        Observer.Expect('txt_yes_pos', '5/5');
        Observer.Expect('txt_yes_bytes', '5965730D0A');
        Observer.Expect('bin_no_w', 'ok');
        Observer.Expect('bin_no_pos', '4/4');
        Observer.Expect('bin_no_bytes', '00000000');
        Observer.Expect('txt_no_w', 'ok');
        Observer.Expect('txt_no_pos', '4/4');
        Observer.Expect('txt_no_bytes', '4E6F0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Byte_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Byte;
    begin
        Clear(V);
        V := 200;
        Do_Byte(Observer, 'bin_b200', V, false);
        Do_Byte(Observer, 'txt_b200', V, true);
        Clear(V);
        V := 0;
        Do_Byte(Observer, 'bin_b0', V, false);
        Do_Byte(Observer, 'txt_b0', V, true);
        Observer.Expect('bin_b200_w', 'ok');
        Observer.Expect('bin_b200_pos', '1/1');
        Observer.Expect('bin_b200_bytes', 'C8');
        Observer.Expect('txt_b200_w', 'ok');
        Observer.Expect('txt_b200_pos', '3/3');
        Observer.Expect('txt_b200_bytes', 'C80D0A');
        Observer.Expect('bin_b0_w', 'ok');
        Observer.Expect('bin_b0_pos', '1/1');
        Observer.Expect('bin_b0_bytes', '00');
        Observer.Expect('txt_b0_w', 'ok');
        Observer.Expect('txt_b0_pos', '3/3');
        Observer.Expect('txt_b0_bytes', '000D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Char_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Char;
    begin
        Clear(V);
        V := 65;
        Do_Char(Observer, 'bin_a', V, false);
        Do_Char(Observer, 'txt_a', V, true);
        Clear(V);
        V := 8364;
        Do_Char(Observer, 'bin_euro', V, false);
        Do_Char(Observer, 'txt_euro', V, true);
        Observer.Expect('bin_a_w', 'ok');
        Observer.Expect('bin_a_pos', '1/1');
        Observer.Expect('bin_a_bytes', '41');
        Observer.Expect('txt_a_w', 'ok');
        Observer.Expect('txt_a_pos', '3/3');
        Observer.Expect('txt_a_bytes', '410D0A');
        Observer.Expect('bin_euro_w', 'ok');
        Observer.Expect('bin_euro_pos', '1/1');
        Observer.Expect('bin_euro_bytes', 'B1');
        Observer.Expect('txt_euro_w', 'ok');
        Observer.Expect('txt_euro_pos', '3/3');
        Observer.Expect('txt_euro_bytes', 'B10D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Decimal_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Decimal;
    begin
        Clear(V);
        V := -12345.6789;
        Do_Decimal(Observer, 'bin_neg', V, false);
        Do_Decimal(Observer, 'txt_neg', V, true);
        Clear(V);
        V := 0;
        Do_Decimal(Observer, 'bin_zero', V, false);
        Do_Decimal(Observer, 'txt_zero', V, true);
        Observer.Expect('bin_neg_w', 'ok');
        Observer.Expect('bin_neg_pos', '12/12');
        Observer.Expect('bin_neg_bytes', 'C40000000090785634120000');
        Observer.Expect('txt_neg_w', 'ok');
        Observer.Expect('txt_neg_pos', '14/14');
        Observer.Expect('txt_neg_bytes', '2D31322C3334352E363738390D0A');
        Observer.Expect('bin_zero_w', 'ok');
        Observer.Expect('bin_zero_pos', '12/12');
        Observer.Expect('bin_zero_bytes', '000000000000000000000000');
        Observer.Expect('txt_zero_w', 'ok');
        Observer.Expect('txt_zero_pos', '3/3');
        Observer.Expect('txt_zero_bytes', '300D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Guid_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Guid;
    begin
        Clear(V);
        Evaluate(V, '{12345678-1234-1234-1234-123456789ABC}');
        Do_Guid(Observer, 'bin_g', V, false);
        Do_Guid(Observer, 'txt_g', V, true);
        Observer.Expect('bin_g_w', 'ok');
        Observer.Expect('bin_g_pos', '16/16');
        Observer.Expect('bin_g_bytes', '78563412341234121234123456789ABC');
        Observer.Expect('txt_g_w', 'ok');
        Observer.Expect('txt_g_pos', '40/40');
        Observer.Expect('txt_g_bytes', '7B31323334353637382D313233342D313233342D313233342D3132333435363738394142437D0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Integer_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Integer;
    begin
        Clear(V);
        V := -42;
        Do_Integer(Observer, 'bin_neg', V, false);
        Do_Integer(Observer, 'txt_neg', V, true);
        Clear(V);
        V := 258;
        Do_Integer(Observer, 'bin_n258', V, false);
        Do_Integer(Observer, 'txt_n258', V, true);
        Observer.Expect('bin_neg_w', 'ok');
        Observer.Expect('bin_neg_pos', '4/4');
        Observer.Expect('bin_neg_bytes', 'D6FFFFFF');
        Observer.Expect('txt_neg_w', 'ok');
        Observer.Expect('txt_neg_pos', '5/5');
        Observer.Expect('txt_neg_bytes', '2D34320D0A');
        Observer.Expect('bin_n258_w', 'ok');
        Observer.Expect('bin_n258_pos', '4/4');
        Observer.Expect('bin_n258_bytes', '02010000');
        Observer.Expect('txt_n258_w', 'ok');
        Observer.Expect('txt_n258_pos', '5/5');
        Observer.Expect('txt_n258_bytes', '3235380D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Option_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Option A,B,C;
    begin
        Clear(V);
        V := V::B;
        Do_Option(Observer, 'bin_b', V, false);
        Do_Option(Observer, 'txt_b', V, true);
        Observer.Expect('bin_b_w', 'ok');
        Observer.Expect('bin_b_pos', '4/4');
        Observer.Expect('bin_b_bytes', '01000000');
        Observer.Expect('txt_b_w', 'ok');
        Observer.Expect('txt_b_pos', '3/3');
        Observer.Expect('txt_b_bytes', '420D0A');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure W_Code(var F: File; V: Code[10])
    begin
        F.Write(V);
    end;

    local procedure Do_Code(var Observer: Codeunit "Probe Observer"; Id: Text; V: Code[10]; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Code(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Date(var F: File; V: Date)
    begin
        F.Write(V);
    end;

    local procedure Do_Date(var Observer: Codeunit "Probe Observer"; Id: Text; V: Date; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Date(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_DateFormula(var F: File; V: DateFormula)
    begin
        F.Write(V);
    end;

    local procedure Do_DateFormula(var Observer: Codeunit "Probe Observer"; Id: Text; V: DateFormula; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_DateFormula(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_DateTime(var F: File; V: DateTime)
    begin
        F.Write(V);
    end;

    local procedure Do_DateTime(var Observer: Codeunit "Probe Observer"; Id: Text; V: DateTime; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_DateTime(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Duration(var F: File; V: Duration)
    begin
        F.Write(V);
    end;

    local procedure Do_Duration(var Observer: Codeunit "Probe Observer"; Id: Text; V: Duration; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Duration(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Text(var F: File; V: Text)
    begin
        F.Write(V);
    end;

    local procedure Do_Text(var Observer: Codeunit "Probe Observer"; Id: Text; V: Text; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Text(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_Time(var F: File; V: Time)
    begin
        F.Write(V);
    end;

    local procedure Do_Time(var Observer: Codeunit "Probe Observer"; Id: Text; V: Time; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Time(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [TryFunction]
    local procedure W_BigText(var F: File; V: BigText)
    begin
        F.Write(V);
    end;

    local procedure Do_BigText(var Observer: Codeunit "Probe Observer"; Id: Text; V: BigText; AsText: Boolean)
    var
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_BigText(F, V) then
            Observer.Observe(Id + '_w', 'ok')
        else
            Observer.ObserveError(Id + '_w');
        Observer.Observe(Id + '_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_bytes', Hex)
        else
            Observer.ObserveError(Id + '_bytes');
        F.Close();
        Cleanup(P);
    end;

    [Test]
    procedure Write_Code_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Code[10];
    begin
        Clear(V);
        V := 'ABC123';
        Do_Code(Observer, 'bin_abc', V, false);
        Do_Code(Observer, 'txt_abc', V, true);
        Clear(V);
        V := '';
        Do_Code(Observer, 'bin_empty', V, false);
        Do_Code(Observer, 'txt_empty', V, true);
        Observer.Expect('bin_abc_w', 'ok');
        Observer.Expect('bin_abc_pos', '12/12');
        Observer.Expect('bin_abc_bytes', 'FF4142433132330000000000');
        Observer.Expect('txt_abc_w', 'ok');
        Observer.Expect('txt_abc_pos', '8/8');
        Observer.Expect('txt_abc_bytes', '4142433132330D0A');
        Observer.Expect('bin_empty_w', 'ok');
        Observer.Expect('bin_empty_pos', '12/12');
        Observer.Expect('bin_empty_bytes', '000000000000000000000000');
        Observer.Expect('txt_empty_w', 'ok');
        Observer.Expect('txt_empty_pos', '2/2');
        Observer.Expect('txt_empty_bytes', '0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Date_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Date;
    begin
        Clear(V);
        V := DMY2Date(24, 12, 2020);
        Do_Date(Observer, 'bin_d', V, false);
        Do_Date(Observer, 'txt_d', V, true);
        Clear(V);
        V := 0D;
        Do_Date(Observer, 'bin_blank', V, false);
        Do_Date(Observer, 'txt_blank', V, true);
        Observer.Expect('bin_d_w', 'ok');
        Observer.Expect('bin_d_pos', '4/4');
        Observer.Expect('bin_d_bytes', 'C9861600');
        Observer.Expect('txt_d_w', 'ok');
        Observer.Expect('txt_d_pos', '10/10');
        Observer.Expect('txt_d_bytes', '31322F32342F32300D0A');
        Observer.Expect('bin_blank_w', 'ok');
        Observer.Expect('bin_blank_pos', '4/4');
        Observer.Expect('bin_blank_bytes', '00000000');
        Observer.Expect('txt_blank_w', 'ok');
        Observer.Expect('txt_blank_pos', '2/2');
        Observer.Expect('txt_blank_bytes', '0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_DateFormula_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: DateFormula;
    begin
        Clear(V);
        Evaluate(V, '<1M+CM>');
        Do_DateFormula(Observer, 'bin_f', V, false);
        Do_DateFormula(Observer, 'txt_f', V, true);
        Observer.Expect('bin_f_w', 'ok');
        Observer.Expect('bin_f_pos', '32/32');
        Observer.Expect('bin_f_bytes', '31052B0105000000000000000000000000000000000000000000000000000000');
        Observer.Expect('txt_f_w', 'ok');
        Observer.Expect('txt_f_pos', '7/7');
        Observer.Expect('txt_f_bytes', '314D2B434D0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_DateTime_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        Clear(V);
        V := CreateDateTime(DMY2Date(1, 2, 2021), 143015T);
        Do_DateTime(Observer, 'bin_dt', V, false);
        Do_DateTime(Observer, 'txt_dt', V, true);
        Clear(V);
        V := 0DT;
        Do_DateTime(Observer, 'bin_blank', V, false);
        Do_DateTime(Observer, 'txt_blank', V, true);
        Observer.Expect('bin_dt_w', 'ok');
        Observer.Expect('bin_dt_pos', '8/8');
        Observer.Expect('bin_dt_bytes', 'D9B004CD013A0000');
        Observer.Expect('txt_dt_w', 'ok');
        Observer.Expect('txt_dt_pos', '19/19');
        Observer.Expect('txt_dt_bytes', '30322F30312F32312030323A333020504D0D0A');
        Observer.Expect('bin_blank_w', 'ok');
        Observer.Expect('bin_blank_pos', '8/8');
        Observer.Expect('bin_blank_bytes', '0000000000000000');
        Observer.Expect('txt_blank_w', 'ok');
        Observer.Expect('txt_blank_pos', '2/2');
        Observer.Expect('txt_blank_bytes', '0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Duration_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Duration;
    begin
        Clear(V);
        V := 90061001;
        Do_Duration(Observer, 'bin_d', V, false);
        Do_Duration(Observer, 'txt_d', V, true);
        Clear(V);
        V := 0;
        Do_Duration(Observer, 'bin_zero', V, false);
        Do_Duration(Observer, 'txt_zero', V, true);
        Observer.Expect('bin_d_w', 'ok');
        Observer.Expect('bin_d_pos', '8/8');
        Observer.Expect('bin_d_bytes', 'C9385E0500000000');
        Observer.Expect('txt_d_w', 'ok');
        Observer.Expect('txt_d_pos', '46/46');
        Observer.Expect('txt_d_bytes', '3120646179203120686F75722031206D696E7574652031207365636F6E642031206D696C6C697365636F6E640D0A');
        Observer.Expect('bin_zero_w', 'ok');
        Observer.Expect('bin_zero_pos', '8/8');
        Observer.Expect('bin_zero_bytes', '0000000000000000');
        Observer.Expect('txt_zero_w', 'ok');
        Observer.Expect('txt_zero_pos', '2/2');
        Observer.Expect('txt_zero_bytes', '0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Text_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Text;
    begin
        Clear(V);
        V := 'plain text';
        Do_Text(Observer, 'bin_plain', V, false);
        Do_Text(Observer, 'txt_plain', V, true);
        Clear(V);
        V := '';
        Do_Text(Observer, 'bin_empty', V, false);
        Do_Text(Observer, 'txt_empty', V, true);
        Observer.Expect('bin_plain_w|text', 'WRITE is not supported for Text without a maximum length.');
        Observer.Expect('bin_plain_w|code', 'StreamWideTextMaxLength');
        Observer.Expect('bin_plain_pos', '0/0');
        Observer.Expect('bin_plain_bytes', '');
        Observer.Expect('txt_plain_w', 'ok');
        Observer.Expect('txt_plain_pos', '12/12');
        Observer.Expect('txt_plain_bytes', '706C61696E20746578740D0A');
        Observer.Expect('bin_empty_w|text', 'WRITE is not supported for Text without a maximum length.');
        Observer.Expect('bin_empty_w|code', 'StreamWideTextMaxLength');
        Observer.Expect('bin_empty_pos', '0/0');
        Observer.Expect('bin_empty_bytes', '');
        Observer.Expect('txt_empty_w', 'ok');
        Observer.Expect('txt_empty_pos', '2/2');
        Observer.Expect('txt_empty_bytes', '0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_Time_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: Time;
    begin
        Clear(V);
        V := 235959T;
        Do_Time(Observer, 'bin_t', V, false);
        Do_Time(Observer, 'txt_t', V, true);
        Clear(V);
        V := 0T;
        Do_Time(Observer, 'bin_blank', V, false);
        Do_Time(Observer, 'txt_blank', V, true);
        Observer.Expect('bin_t_w', 'ok');
        Observer.Expect('bin_t_pos', '4/4');
        Observer.Expect('bin_t_bytes', '19582605');
        Observer.Expect('txt_t_w', 'ok');
        Observer.Expect('txt_t_pos', '13/13');
        Observer.Expect('txt_t_bytes', '31313A35393A353920504D0D0A');
        Observer.Expect('bin_blank_w', 'ok');
        Observer.Expect('bin_blank_pos', '4/4');
        Observer.Expect('bin_blank_bytes', '00000000');
        Observer.Expect('txt_blank_w', 'ok');
        Observer.Expect('txt_blank_pos', '2/2');
        Observer.Expect('txt_blank_bytes', '0D0A');
        Observer.Verify();
    end;

    [Test]
    procedure Write_BigText_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        V: BigText;
    begin
        Clear(V);
        V.AddText('bigtext value');
        Do_BigText(Observer, 'bin_bt', V, false);
        Do_BigText(Observer, 'txt_bt', V, true);
        Observer.Expect('bin_bt_w|text', 'ALStream.ALWrite, invalid stream mode: FileBinary');
        Observer.Expect('bin_bt_w|code', 'InvalidStreamMode');
        Observer.Expect('bin_bt_pos', '0/0');
        Observer.Expect('bin_bt_bytes', '');
        Observer.Expect('txt_bt_w|text', 'ALStream.ALWrite, invalid stream mode: FileText');
        Observer.Expect('txt_bt_w|code', 'InvalidStreamMode');
        Observer.Expect('txt_bt_pos', '0/0');
        Observer.Expect('txt_bt_bytes', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure W_Label(var F: File)
    begin
        F.Write(LblText);
    end;

    [Test]
    procedure Write_Label_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        P: Text;
        Hex: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(false);
        if W_Label(F) then
            Observer.Observe('bin_w', 'ok')
        else
            Observer.ObserveError('bin_w');
        Observer.Observe('bin_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe('bin_bytes', Hex)
        else
            Observer.ObserveError('bin_bytes');
        F.Close();
        Cleanup(P);
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        if W_Label(F) then
            Observer.Observe('txt_w', 'ok')
        else
            Observer.ObserveError('txt_w');
        Observer.Observe('txt_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe('txt_bytes', Hex)
        else
            Observer.ObserveError('txt_bytes');
        F.Close();
        Cleanup(P);
        Observer.Expect('bin_w', 'ok');
        Observer.Expect('bin_pos', '11/11');
        Observer.Expect('bin_bytes', '6C6162656C207465787400');
        Observer.Expect('txt_w', 'ok');
        Observer.Expect('txt_pos', '12/12');
        Observer.Expect('txt_bytes', '6C6162656C20746578740D0A');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure W_Record(var F: File; var R: Record "LT P110 File Rec")
    begin
        F.Write(R);
    end;

    [TryFunction]
    local procedure W_RecordId(var F: File; Id: RecordId)
    begin
        F.Write(Id);
    end;

    local procedure Do_Record(var Observer: Codeunit "Probe Observer"; Id: Text; AsText: Boolean)
    var
        R: Record "LT P110 File Rec";
        F: File;
        P: Text;
        Hex: Text;
    begin
        R.Code := 'A1';
        R.Amount := 12.5;
        R.Note := 'note';
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_Record(F, R) then
            Observer.Observe(Id + '_rec_w', 'ok')
        else
            Observer.ObserveError(Id + '_rec_w');
        Observer.Observe(Id + '_rec_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_rec_bytes', Hex)
        else
            Observer.ObserveError(Id + '_rec_bytes');
        F.Close();
        Cleanup(P);
        P := TempName();
        F.Create(P);
        F.TextMode(AsText);
        if W_RecordId(F, R.RecordId()) then
            Observer.Observe(Id + '_rid_w', 'ok')
        else
            Observer.ObserveError(Id + '_rid_w');
        Observer.Observe(Id + '_rid_pos', Format(F.Pos()) + '/' + Format(F.Len()));
        if Dump(F, Hex) then
            Observer.Observe(Id + '_rid_bytes', Hex)
        else
            Observer.ObserveError(Id + '_rid_bytes');
        F.Close();
        Cleanup(P);
    end;

    [Test]
    procedure Write_Record_RecordId_BinaryAndTextMode()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Do_Record(Observer, 'bin', false);
        Do_Record(Observer, 'txt', true);
        Observer.Expect('bin_rec_w|text', 'ALStream.ALWrite, invalid stream mode: FileBinary');
        Observer.Expect('bin_rec_w|code', 'InvalidStreamMode');
        Observer.Expect('bin_rec_pos', '0/0');
        Observer.Expect('bin_rec_bytes', '');
        Observer.Expect('bin_rid_w|text', 'ALStream.ALWrite, invalid stream mode: FileBinary');
        Observer.Expect('bin_rid_w|code', 'InvalidStreamMode');
        Observer.Expect('bin_rid_pos', '0/0');
        Observer.Expect('bin_rid_bytes', '');
        Observer.Expect('txt_rec_w', 'ok');
        Observer.Expect('txt_rec_pos', '14/14');
        Observer.Expect('txt_rec_bytes', '41310931322E35096E6F74650D0A');
        Observer.Expect('txt_rid_w', 'ok');
        Observer.Expect('txt_rid_pos', '22/22');
        Observer.Expect('txt_rid_bytes', '4C5420503131302046696C65205265633A2041310D0A');
        Observer.Verify();
    end;
    [Test]
    procedure Exists_Folder_And_Blank_Names()
    var
        Observer: Codeunit "Probe Observer";
        F: File;
        P: Text;
        Dir: Text;
    begin
        Dir := TemporaryPath();
        Observer.Observe('folder', Format(File.Exists(Dir)));
        Observer.Observe('folder_trimmed', Format(File.Exists(CopyStr(Dir, 1, StrLen(Dir) - 1))));
        Observer.Observe('blank', Format(File.Exists(' ')));
        P := Dir + DelChr(Format(CreateGuid()), '=', '{}-') + '.tmp';
        F.Create(P);
        F.Close();
        Observer.Observe('file', Format(File.Exists(P)));
        Observer.Observe('file_leading_blank', Format(File.Exists(' ' + P)));
        File.Erase(P);
        Observer.Observe('file_erased', Format(File.Exists(P)));
        Observer.Expect('folder', 'No');
        Observer.Expect('folder_trimmed', 'No');
        Observer.Expect('blank', 'No');
        Observer.Expect('file', 'Yes');
        Observer.Expect('file_leading_blank', 'No');
        Observer.Expect('file_erased', 'No');
        Observer.Verify();
    end;
}
