// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.Write overloads by type
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61264 "LT P110 File Write Types"
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

    [TryFunction]
    local procedure W_bigint(var F: File; V: BigInteger)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_bigtext(var F: File; V: BigText)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_boolean(var F: File; V: Boolean)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_byte(var F: File; V: Byte)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_char(var F: File; V: Char)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_code(var F: File; V: Code[10])
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_date(var F: File; V: Date)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_dateformula(var F: File; V: DateFormula)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_datetime(var F: File; V: DateTime)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_decimal(var F: File; V: Decimal)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_duration(var F: File; V: Duration)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_guid(var F: File; V: Guid)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_integer(var F: File; V: Integer)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_option(var F: File; V: Option A,B,C)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_text(var F: File; V: Text)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_time(var F: File; V: Time)
    begin
        F.Write(V);
    end;

    [TryFunction]
    local procedure W_label(var F: File)
    begin
        F.Write(LblText);
    end;

    local procedure Step(var Observer: Codeunit "Probe Observer"; Obs: Boolean; var F: File; Name: Text; Ok: Boolean)
    begin
        if not Obs then
            exit;
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    local procedure WriteAll(var Observer: Codeunit "Probe Observer"; Obs: Boolean; var F: File)
    var
        BI: BigInteger;
        BT: BigText;
        Bo: Boolean;
        By: Byte;
        Ch: Char;
        Co: Code[10];
        D: Date;
        DF: DateFormula;
        DT: DateTime;
        Dec: Decimal;
        Du: Duration;
        G: Guid;
        I: Integer;
        Op: Option A,B,C;
        T: Text;
        Tm: Time;
    begin
        BI := 2147483647;
        BI := BI * 4;
        BT.AddText('bigtext value');
        Bo := true;
        By := 200;
        Ch := 65;
        Co := 'ABC123';
        D := DMY2Date(24, 12, 2020);
        Evaluate(DF, '<1M+CM>');
        DT := CreateDateTime(DMY2Date(1, 2, 2021), 143015T);
        Dec := -12345.6789;
        Du := 90061001;
        Evaluate(G, '{12345678-1234-1234-1234-123456789ABC}');
        I := -42;
        Op := Op::B;
        T := 'plain text';
        Tm := 235959T;
        Step(Observer, Obs, F, 'bigint', W_bigint(F, BI));
        Step(Observer, Obs, F, 'bigtext', W_bigtext(F, BT));
        Step(Observer, Obs, F, 'boolean', W_boolean(F, Bo));
        Step(Observer, Obs, F, 'byte', W_byte(F, By));
        Step(Observer, Obs, F, 'char', W_char(F, Ch));
        Step(Observer, Obs, F, 'code', W_code(F, Co));
        Step(Observer, Obs, F, 'date', W_date(F, D));
        Step(Observer, Obs, F, 'dateformula', W_dateformula(F, DF));
        Step(Observer, Obs, F, 'datetime', W_datetime(F, DT));
        Step(Observer, Obs, F, 'decimal', W_decimal(F, Dec));
        Step(Observer, Obs, F, 'duration', W_duration(F, Du));
        Step(Observer, Obs, F, 'guid', W_guid(F, G));
        Step(Observer, Obs, F, 'integer', W_integer(F, I));
        Step(Observer, Obs, F, 'label', W_label(F));
        Step(Observer, Obs, F, 'option', W_option(F, Op));
        Step(Observer, Obs, F, 'text', W_text(F, T));
        Step(Observer, Obs, F, 'time', W_time(F, Tm));
    end;

    [Test]
    procedure P110_WriteTypes_TextMode_Results()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        Observer.Observe('textmode_after_create', Format(F.TextMode()));
        F.TextMode(true);
        WriteAll(Observer, true, F);
        Observer.Observe('len', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('textmode_after_create', 'No');
        Observer.Expect('bigint', 'ok');
        Observer.Expect('bigtext', 'error: ALStream.ALWrite, invalid stream mode: FileText code=InvalidStreamMode');
        Observer.Expect('boolean', 'ok');
        Observer.Expect('byte', 'ok');
        Observer.Expect('char', 'ok');
        Observer.Expect('code', 'ok');
        Observer.Expect('date', 'ok');
        Observer.Expect('dateformula', 'ok');
        Observer.Expect('datetime', 'ok');
        Observer.Expect('decimal', 'ok');
        Observer.Expect('duration', 'ok');
        Observer.Expect('guid', 'ok');
        Observer.Expect('integer', 'ok');
        Observer.Expect('label', 'ok');
        Observer.Expect('option', 'ok');
        Observer.Expect('text', 'ok');
        Observer.Expect('time', 'ok');
        Observer.Expect('len', '212');
        Observer.Verify();
    end;

    [Test]
    procedure P110_WriteTypes_BinaryMode_Results()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(false);
        WriteAll(Observer, true, F);
        Observer.Observe('len', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('bigint', 'ok');
        Observer.Expect('bigtext', 'error: ALStream.ALWrite, invalid stream mode: FileBinary code=InvalidStreamMode');
        Observer.Expect('boolean', 'ok');
        Observer.Expect('byte', 'ok');
        Observer.Expect('char', 'ok');
        Observer.Expect('code', 'ok');
        Observer.Expect('date', 'ok');
        Observer.Expect('dateformula', 'ok');
        Observer.Expect('datetime', 'ok');
        Observer.Expect('decimal', 'ok');
        Observer.Expect('duration', 'ok');
        Observer.Expect('guid', 'ok');
        Observer.Expect('integer', 'ok');
        Observer.Expect('label', 'ok');
        Observer.Expect('option', 'ok');
        Observer.Expect('text', 'error: WRITE is not supported for Text without a maximum length. code=StreamWideTextMaxLength');
        Observer.Expect('time', 'ok');
        Observer.Expect('len', '129');
        Observer.Verify();
    end;

    [Test]
    procedure P110_WriteTypes_TextMode_ReadBack()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        Line: Text;
        N: Integer;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        WriteAll(Observer, false, F);
        F.Close();
        F.Open(P);
        F.TextMode(true);
        Observer.Observe('len', Format(F.Len()));
        while (F.Pos() < F.Len()) and (N < 20) do begin
            N += 1;
            Clear(Line);
            F.Read(Line);
            Observer.Observe('line' + Format(N), '[' + CopyStr(Line, 1, 200) + ']');
        end;
        F.Close();
        Cleanup(P);
        Observer.Expect('len', '212');
        Observer.Expect('line1', '[8589934588]');
        Observer.Expect('line2', '[Yes]');
        Observer.Expect('line3', '[˜]');
        Observer.Expect('line4', '[A]');
        Observer.Expect('line5', '[ABC123]');
        Observer.Expect('line6', '[12/24/20]');
        Observer.Expect('line7', '[1M+CM]');
        Observer.Expect('line8', '[02/01/21 02:30 PM]');
        Observer.Expect('line9', '[-12,345.6789]');
        Observer.Expect('line10', '[1 day 1 hour 1 minute 1 second 1 millisecond]');
        Observer.Expect('line11', '[{12345678-1234-1234-1234-123456789ABC}]');
        Observer.Expect('line12', '[-42]');
        Observer.Expect('line13', '[label text]');
        Observer.Expect('line14', '[B]');
        Observer.Expect('line15', '[plain text]');
        Observer.Expect('line16', '[11:59:59 PM]');
        Observer.Verify();
    end;
}
