// Fixtures used: Probe Observer (69160); self-contained helper "LT Y21 Row Dump" (92151) and table "LT Y21 Lock Row" (92152)
// Helper of Y21EnvColumns.al: writes the rows of a platform table as text, with every time-like column reduced to a rule
// (blank, past or future), so the text can be asserted.
codeunit 92151 "LT Y21 Row Dump"
{
    // One row as <field no>=<value>;. DateTime: blank, past or future (against CurrentDateTime); Date: blank, today, past or future;
    // Time: blank or set; Guid: null or guid; Blob: blob:<bytes>; other types Format(Value, 0, 9) cut to 120 characters.
    procedure Row(var RecRef: RecordRef): Text
    var
        Fld: FieldRef;
        I: Integer;
        Result: Text;
    begin
        for I := 1 to RecRef.FieldCount() do begin
            Fld := RecRef.FieldIndex(I);
            if Fld.Number() < 2000000000 then
                Result += Format(Fld.Number()) + '=' + Value(Fld) + ';';
        end;
        exit(Result);
    end;

    procedure Value(var Fld: FieldRef): Text
    var
        Dt: DateTime;
        D: Date;
        T: Time;
        G: Guid;
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        Bytes: Text;
    begin
        case Fld.Type() of
            FieldType::DateTime:
                begin
                    Dt := Fld.Value();
                    exit(DtRule(Dt));
                end;
            FieldType::Date:
                begin
                    D := Fld.Value();
                    if D = 0D then
                        exit('blank');
                    if D = Today() then
                        exit('today');
                    if D < Today() then
                        exit('past');
                    exit('future');
                end;
            FieldType::Time:
                begin
                    T := Fld.Value();
                    if T = 0T then
                        exit('blank');
                    exit('set');
                end;
            FieldType::Guid:
                begin
                    G := Fld.Value();
                    if IsNullGuid(G) then
                        exit('null');
                    exit('guid');
                end;
            FieldType::Blob:
                begin
                    Fld.CalcField();
                    TempBlob.FromFieldRef(Fld);
                    exit('blob:' + Format(TempBlob.Length()));
                end;
        end;
        exit(CopyStr(Format(Fld.Value(), 0, 9), 1, 120));
    end;

    procedure DtRule(Dt: DateTime): Text
    begin
        if Dt = 0DT then
            exit('blank');
        if Dt <= CurrentDateTime() then
            exit('past');
        exit('future');
    end;

    // Count, then up to MaxRows rows.
    procedure Dump(var RecRef: RecordRef; MaxRows: Integer): Text
    var
        Result: Text;
        N: Integer;
    begin
        Result := 'n=' + Format(RecRef.Count()) + ';';
        if RecRef.FindSet() then
            repeat
                N += 1;
                Result += '[' + Row(RecRef) + ']';
            until (RecRef.Next() = 0) or (N >= MaxRows);
        exit(Result);
    end;

    procedure Hash(Value: Text; var State: BigInteger)
    var
        Ch: Char;
        I: Integer;
        Code: Integer;
    begin
        for I := 1 to StrLen(Value) do begin
            Ch := Value[I];
            Code := Ch;
            State := (State * 31 + Code) mod 2147483629;
        end;
    end;
}

table 92152 "LT Y21 Lock Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
