// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained table 91620, test codeunit 91621
// Probe: observe probe (writer Y13, 2026-10-31, runtime asks from partner-app triage); every literal asserted below is what the BC service tier produced.
// Facts: FieldRef.Value() of an Integer, Decimal and BigInteger field, and of field 0 (the timestamp, a BigInteger), assigned to a Text, a
//   Text[30], a Code[20] and a Code[3] variable: the stored text, or the error text and code. The text and code field cases are pinned
//   in TestFieldRefValue.al.
// BC versions: 27, 28, 29

table 91620 "LT Y13 FV Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Int; Integer) { }
        field(3; Dec; Decimal) { }
        field(4; Big; BigInteger) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 91621 "LT Y13 FV Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryAssign(var FldRef: FieldRef; Target: Text; var Result: Text)
    var
        Txt: Text;
        Txt30: Text[30];
        Code20: Code[20];
        Code3: Code[3];
    begin
        case Target of
            'Text':
                begin
                    Txt := FldRef.Value();
                    Result := Txt;
                end;
            'Text30':
                begin
                    Txt30 := FldRef.Value();
                    Result := Txt30;
                end;
            'Code20':
                begin
                    Code20 := FldRef.Value();
                    Result := Code20;
                end;
            'Code3':
                begin
                    Code3 := FldRef.Value();
                    Result := Code3;
                end;
        end;
    end;

    local procedure Assigned(var FldRef: FieldRef; Target: Text): Text
    var
        Result: Text;
    begin
        if TryAssign(FldRef, Target, Result) then
            exit('ok [' + Result + ']');
        exit('error ' + GetLastErrorText() + ' (' + GetLastErrorCode() + ')');
    end;

    local procedure Seed(var RecRef: RecordRef)
    var
        Row: Record "LT Y13 FV Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Int := 1234567;
        Row.Dec := 12.5;
        Row.Big := 9876543210L;
        Row.Insert();
        RecRef.Open(91620);
        RecRef.FindFirst();
    end;

    local procedure All(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        FldRef: FieldRef;
        Result: Text;
        Target: Text;
    begin
        FldRef := RecRef.Field(FieldNo);
        foreach Target in 'Text,Text30,Code20,Code3'.Split(',') do
            Result += Target + '=' + Assigned(FldRef, Target) + ' ';
        exit(Result);
    end;

    [Test]
    procedure Y13_FV_IntegerDecimal()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Seed(RecRef);
        Observer.Observe('Integer', All(RecRef, 2));
        Observer.Observe('Decimal', All(RecRef, 3));
        Observer.Expect('Integer', 'Text=ok [1234567] Text30=ok [1234567] Code20=ok [1234567] Code3=error The length of the string is 7, but it must be less than or equal to 3 characters. Value: 1234567 (StringLengthExceeded) ');
        Observer.Expect('Decimal', 'Text=ok [12.5] Text30=ok [12.5] Code20=ok [12.5] Code3=error The length of the string is 4, but it must be less than or equal to 3 characters. Value: 12.5 (StringLengthExceeded) ');
        Observer.Verify();
    end;

    [Test]
    procedure Y13_FV_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Seed(RecRef);
        Observer.Observe('BigInteger', All(RecRef, 4));
        Observer.Expect('BigInteger', 'Text=ok [9876543210] Text30=ok [9876543210] Code20=ok [9876543210] Code3=error The length of the string is 10, but it must be less than or equal to 3 characters. Value: 9876543210 (StringLengthExceeded) ');
        Observer.Verify();
    end;

    // Field 0 is the timestamp: the value differs per run, so only its relation to Format() and the error code are pinned.
    [Test]
    procedure Y13_FV_TimestampField0()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Result: Text;
        Target: Text;
        Shapes: Text;
        AsFormat: Text;
    begin
        Seed(RecRef);
        FldRef := RecRef.Field(0);
        AsFormat := Format(FldRef.Value());
        foreach Target in 'Text,Text30,Code20,Code3'.Split(',') do begin
            Result := Assigned(FldRef, Target);
            if Result.Contains('StringLengthExceeded') then
                Result := 'error StringLengthExceeded';
            if Result.StartsWith('ok [') then
                Result := 'ok, same as Format: ' + Format(Result = 'ok [' + AsFormat + ']');
            Shapes += Target + '=' + Result + ' ';
        end;
        Observer.Observe('timestamp', Shapes);
        Observer.Observe('timestamp type', Format(FldRef.Type()));
        Observer.Expect('timestamp', 'Text=ok, same as Format: Yes Text30=ok, same as Format: Yes Code20=ok, same as Format: Yes Code3=error StringLengthExceeded ');
        Observer.Expect('timestamp type', 'BigInteger');
        Observer.Verify();
    end;
}

