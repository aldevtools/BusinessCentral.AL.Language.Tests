// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.CreateInStream CreateOutStream
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61269 "LT P110 File Streams"
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

    [Test]
    procedure P110_OutStreamThenInStream()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        P: Text;
        T1: Text;
        T2: Text;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('line one');
        OutS.WriteText();
        OutS.WriteText('line two');
        F.Close();
        F.Open(P);
        Observer.Observe('len', Format(F.Len()));
        F.CreateInStream(InS);
        InS.ReadText(T1);
        Observer.Observe('read1', '[' + T1 + ']');
        InS.ReadText(T2);
        Observer.Observe('read2', '[' + T2 + ']');
        Observer.Observe('eos_after_two', Format(InS.EOS()));
        InS.ReadText(T2);
        Observer.Observe('read3', '[' + T2 + ']');
        Observer.Observe('eos_end', Format(InS.EOS()));
        F.Close();
        Cleanup(P);
        Observer.Expect('len', '18');
        Observer.Expect('read1', '[line one]');
        Observer.Expect('read2', '[line two]');
        Observer.Expect('eos_after_two', 'Yes');
        Observer.Expect('read3', '[]');
        Observer.Expect('eos_end', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P110_StreamPositionAndLen()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        OutS: OutStream;
        InS: InStream;
        P: Text;
        I: Integer;
        I2: Integer;
    begin
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.Write(I);
        I := 4711;
        OutS.Write(I);
        Observer.Observe('len_after_outstream_writes', Format(F.Len()));
        Observer.Observe('pos_after_outstream_writes', Format(F.Pos()));
        F.Close();
        F.Open(P);
        F.CreateInStream(InS);
        InS.Read(I2);
        Observer.Observe('first_int', Format(I2));
        InS.Read(I2);
        Observer.Observe('second_int', Format(I2));
        Observer.Observe('file_pos_after_instream_read', Format(F.Pos()));
        F.Close();
        Cleanup(P);
        Observer.Expect('len_after_outstream_writes', '8');
        Observer.Expect('pos_after_outstream_writes', '8');
        Observer.Expect('first_int', '0');
        Observer.Expect('second_int', '4711');
        Observer.Expect('file_pos_after_instream_read', '8');
        Observer.Verify();
    end;

    [Test]
    procedure P110_CreateInStreamFromEmptyFile()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        P: Text;
        T: Text;
    begin
        P := TempName();
        F.Create(P);
        F.Close();
        F.Open(P);
        F.CreateInStream(InS);
        Observer.Observe('eos', Format(InS.EOS()));
        InS.ReadText(T);
        Observer.Observe('read', '[' + T + ']');
        F.Close();
        Cleanup(P);
        Observer.Expect('eos', 'Yes');
        Observer.Expect('read', '[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TInStream(var F: File; var InS: InStream)
    begin
        F.CreateInStream(InS);
    end;

    [TryFunction]
    local procedure TOutStream(var F: File; var OutS: OutStream)
    begin
        F.CreateOutStream(OutS);
    end;

    [TryFunction]
    local procedure TWriteOut(var OutS: OutStream)
    begin
        OutS.WriteText('late');
    end;

    [TryFunction]
    local procedure TReadIn(var InS: InStream; var T: Text)
    begin
        InS.ReadText(T);
    end;

    local procedure Rec(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    [Test]
    procedure P110_StreamErrors()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        InS: InStream;
        OutS: OutStream;
        P: Text;
        T: Text;
    begin
        Rec(Observer, 'instream_unopened', TInStream(F, InS));
        Rec(Observer, 'outstream_unopened', TOutStream(F, OutS));
        P := TempName();
        F.Create(P);
        F.CreateOutStream(OutS);
        OutS.WriteText('abc');
        F.Close();
        Rec(Observer, 'write_to_outstream_after_close', TWriteOut(OutS));
        F.Open(P);
        F.CreateInStream(InS);
        F.Close();
        Rec(Observer, 'read_instream_after_close', TReadIn(InS, T));
        Rec(Observer, 'instream_after_close', TInStream(F, InS));
        Cleanup(P);
        Observer.Expect('instream_unopened', 'ok');
        Observer.Expect('outstream_unopened', 'error: The current setting of the WriteMode property is incompatible with the operation. code=StreamAccess');
        Observer.Expect('write_to_outstream_after_close', 'error: Microsoft.Dynamics.Nav.Runtime.NavOutStream variable not initialized. code=NotInitialized');
        Observer.Expect('read_instream_after_close', 'error: Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized. code=NotInitialized');
        Observer.Expect('instream_after_close', 'ok');
        Observer.Verify();
    end;
}
