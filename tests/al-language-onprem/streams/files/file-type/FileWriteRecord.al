// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/file/file-data-type
// Scope: in-scope (OnPrem test app only: the File type is Scope = OnPrem; temporary paths only)
// Fixtures used: Probe Observer (69160); P110 File.Write Record and RecordId (own table)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
table 61279 "LT P110 File Rec"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Amount; Decimal) { }
        field(3; Note; Text[30]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 61280 "LT P110 File Write Rec"
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
    local procedure TWriteRec(var F: File; var R: Record "LT P110 File Rec")
    begin
        F.Write(R);
    end;

    [TryFunction]
    local procedure TWriteRecId(var F: File; Id: RecordId)
    begin
        F.Write(Id);
    end;

    local procedure Rec(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.Observe(Name, 'error: ' + ErrHead(GetLastErrorText()) + ' code=' + GetLastErrorCode());
    end;

    [Test]
    procedure P110_WriteRecord_TextMode()
    var
        R: Record "LT P110 File Rec";
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        V: Text;
    begin
        R.DeleteAll();
        R.Code := 'A1';
        R.Amount := 12.5;
        R.Note := 'note';
        R.Insert();
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        Rec(Observer, 'write_record', TWriteRec(F, R));
        Observer.Observe('len', Format(F.Len()));
        F.Close();
        F.Open(P);
        F.TextMode(true);
        if F.Len() > 0 then begin
            F.Read(V);
            Observer.Observe('line', '[' + CopyStr(V, 1, 200) + ']');
        end;
        F.Close();
        Cleanup(P);
        Observer.Expect('write_record', 'ok');
        Observer.Expect('len', '14');
        Observer.Expect('line', '[A1\t12.5\tnote]');
        Observer.Verify();
    end;

    [Test]
    procedure P110_WriteRecordId_TextMode()
    var
        R: Record "LT P110 File Rec";
        F: File;
        Observer: Codeunit "Probe Observer";
        P: Text;
        V: Text;
    begin
        R.DeleteAll();
        R.Code := 'B2';
        R.Insert();
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        Rec(Observer, 'write_recordid', TWriteRecId(F, R.RecordId));
        F.Close();
        F.Open(P);
        F.TextMode(true);
        if F.Len() > 0 then begin
            F.Read(V);
            Observer.Observe('line', '[' + CopyStr(V, 1, 200) + ']');
        end;
        F.Close();
        Cleanup(P);
        Observer.Expect('write_recordid', 'ok');
        Observer.Expect('line', '[LT P110 File Rec: B2]');
        Observer.Verify();
    end;

    [Test]
    procedure P110_WriteRecordId_Blank()
    var
        F: File;
        Observer: Codeunit "Probe Observer";
        Id: RecordId;
        P: Text;
        V: Text;
    begin
        P := TempName();
        F.Create(P);
        F.TextMode(true);
        Rec(Observer, 'write_blank_recordid', TWriteRecId(F, Id));
        Observer.Observe('len', Format(F.Len()));
        F.Close();
        Cleanup(P);
        Observer.Expect('write_blank_recordid', 'ok');
        Observer.Expect('len', '2');
        Observer.Verify();
    end;
}
