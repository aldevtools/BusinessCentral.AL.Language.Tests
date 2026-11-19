// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-joker-integer-string-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper codeunit 96388 "FLN Fmt" (FormatLengthHelper.al); own temporary table 96390
// Probe: observe form (values not yet asserted).
// Facts: Format with a length in the standard formats other than 9 for a Date and a DateTime and other than 0 for an Integer, a Boolean (2) and a
//   negative Decimal; Format(Date2DMY(D, 2), 2); the format-string overload Format(X, L, '<Standard Format,0>') and '<Standard Format,9>' for every
//   scalar type; a Decimal table field with DecimalPlaces 2:2 and 0:3 and a plain one; a RecordRef (open and not open), a Record and a RecordId
//   with positive, negative and exact lengths.
// BC versions: measured locally, checked by the corpus CI matrix

table 96390 "FLN Amount Holder"
{
    TableType = Temporary;
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Amount; Decimal) { DecimalPlaces = 2 : 2; }
        field(3; Qty; Decimal) { DecimalPlaces = 0 : 3; }
        field(4; Plain; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 96389 "FLN Length Neighbors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Got: Text;

    [Test]
    procedure Date_Length_OtherFormats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('D N=1 plain', F.Date(D, 0, 1));
        Observer.Observe('D L=3 N=1', F.Date(D, 3, 1));
        Observer.Observe('D L=30 N=1', F.Date(D, 30, 1));
        Observer.Observe('D L=-3 N=1', F.Date(D, -3, 1));
        Observer.Observe('D L=exact N=1', F.Date(D, StrLen(Format(D, 0, 1)), 1));
        Observer.Observe('D N=2 plain', F.Date(D, 0, 2));
        Observer.Observe('D L=3 N=2', F.Date(D, 3, 2));
        Observer.Observe('D L=30 N=2', F.Date(D, 30, 2));
        Observer.Observe('D L=-3 N=2', F.Date(D, -3, 2));
        Observer.Observe('D L=exact N=2', F.Date(D, StrLen(Format(D, 0, 2)), 2));
        Observer.Observe('D N=3 plain', F.Date(D, 0, 3));
        Observer.Observe('D L=3 N=3', F.Date(D, 3, 3));
        Observer.Observe('D L=30 N=3', F.Date(D, 30, 3));
        Observer.Observe('D L=-3 N=3', F.Date(D, -3, 3));
        Observer.Observe('D L=exact N=3', F.Date(D, StrLen(Format(D, 0, 3)), 3));
        Observer.Observe('D N=4 plain', F.Date(D, 0, 4));
        Observer.Observe('D L=3 N=4', F.Date(D, 3, 4));
        Observer.Observe('D L=30 N=4', F.Date(D, 30, 4));
        Observer.Observe('D L=-3 N=4', F.Date(D, -3, 4));
        Observer.Observe('D L=exact N=4', F.Date(D, StrLen(Format(D, 0, 4)), 4));
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Length_OtherFormats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        DT: DateTime;
    begin
        DT := CreateDateTime(DMY2Date(15, 1, 2024), 134501T);
        Observer.Observe('DT N=0 plain', F.DateTime(DT, 0, 0));
        Observer.Observe('DT L=3 N=0', F.DateTime(DT, 3, 0));
        Observer.Observe('DT L=30 N=0', F.DateTime(DT, 30, 0));
        Observer.Observe('DT L=-3 N=0', F.DateTime(DT, -3, 0));
        Observer.Observe('DT L=exact N=0', F.DateTime(DT, StrLen(Format(DT, 0, 0)), 0));
        Observer.Observe('DT N=1 plain', F.DateTime(DT, 0, 1));
        Observer.Observe('DT L=3 N=1', F.DateTime(DT, 3, 1));
        Observer.Observe('DT L=30 N=1', F.DateTime(DT, 30, 1));
        Observer.Observe('DT L=-3 N=1', F.DateTime(DT, -3, 1));
        Observer.Observe('DT L=exact N=1', F.DateTime(DT, StrLen(Format(DT, 0, 1)), 1));
        Observer.Observe('DT N=4 plain', F.DateTime(DT, 0, 4));
        Observer.Observe('DT L=3 N=4', F.DateTime(DT, 3, 4));
        Observer.Observe('DT L=30 N=4', F.DateTime(DT, 30, 4));
        Observer.Observe('DT L=-3 N=4', F.DateTime(DT, -3, 4));
        Observer.Observe('DT L=exact N=4', F.DateTime(DT, StrLen(Format(DT, 0, 4)), 4));
        Observer.Finish();
    end;

    [Test]
    procedure Integer_Length_OtherFormats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        V: Integer;
    begin
        V := 1234567;
        Observer.Observe('int N=1 plain', F.Integer(V, 0, 1));
        Observer.Observe('int L=3 N=1', F.Integer(V, 3, 1));
        Observer.Observe('int L=10 N=1', F.Integer(V, 10, 1));
        Observer.Observe('int L=-3 N=1', F.Integer(V, -3, 1));
        Observer.Observe('int L=-10 N=1', F.Integer(V, -10, 1));
        Observer.Observe('int L=exact N=1', F.Integer(V, StrLen(Format(V, 0, 1)), 1));
        Observer.Observe('int N=2 plain', F.Integer(V, 0, 2));
        Observer.Observe('int L=3 N=2', F.Integer(V, 3, 2));
        Observer.Observe('int L=10 N=2', F.Integer(V, 10, 2));
        Observer.Observe('int L=-3 N=2', F.Integer(V, -3, 2));
        Observer.Observe('int L=-10 N=2', F.Integer(V, -10, 2));
        Observer.Observe('int L=exact N=2', F.Integer(V, StrLen(Format(V, 0, 2)), 2));
        Observer.Observe('int N=9 plain', F.Integer(V, 0, 9));
        Observer.Observe('int L=3 N=9', F.Integer(V, 3, 9));
        Observer.Observe('int L=10 N=9', F.Integer(V, 10, 9));
        Observer.Observe('int L=-3 N=9', F.Integer(V, -3, 9));
        Observer.Observe('int L=-10 N=9', F.Integer(V, -10, 9));
        Observer.Observe('int L=exact N=9', F.Integer(V, StrLen(Format(V, 0, 9)), 9));
        Observer.Finish();
    end;

    [Test]
    procedure Integer_Month_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('Format(Date2DMY(Jan 15, 2), 2)', F.Integer(Date2DMY(D, 2), 2, -1));
        Observer.Observe('Format(Date2DMY(Jan 15, 2), 1)', F.Integer(Date2DMY(D, 2), 1, -1));
        D := DMY2Date(15, 11, 2024);
        Observer.Observe('Format(Date2DMY(Nov 15, 2), 2)', F.Integer(Date2DMY(D, 2), 2, -1));
        Observer.Observe('Format(Date2DMY(Nov 15, 2), 1)', F.Integer(Date2DMY(D, 2), 1, -1));
        Observer.Observe('Format(Date2DMY(Nov 15, 2), -2)', F.Integer(Date2DMY(D, 2), -2, -1));
        Observer.Observe('Format(Date2DMY(Nov 15, 3), 4)', F.Integer(Date2DMY(D, 3), 4, -1));
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_Decimal_Length_OtherFormats()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        B: Boolean;
        V: Decimal;
    begin
        B := true;
        Observer.Observe('bool L=2 N=2', F.Boolean(B, 2, 2));
        Observer.Observe('bool L=-2 N=2', F.Boolean(B, -2, 2));
        Observer.Observe('bool L=10 N=2', F.Boolean(B, 10, 2));
        Observer.Observe('bool L=-10 N=2', F.Boolean(B, -10, 2));
        Observer.Observe('bool L=4 N=2', F.Boolean(B, 4, 2));
        Observer.Observe('bool L=-4 N=2', F.Boolean(B, -4, 2));
        Observer.Observe('bool N=2 plain', F.Boolean(B, 0, 2));
        V := -1234.5;
        Observer.Observe('dec -1234.5 L=-3 N=1', F.Decimal(V, -3, 1));
        Observer.Observe('dec -1234.5 L=-10 N=1', F.Decimal(V, -10, 1));
        Observer.Observe('dec -1234.5 L=3 N=1', F.Decimal(V, 3, 1));
        Observer.Observe('dec -1234.5 L=10 N=1', F.Decimal(V, 10, 1));
        Observer.Observe('dec -1234.5 L=-3 N=2', F.Decimal(V, -3, 2));
        Observer.Observe('dec -1234.5 L=-10 N=2', F.Decimal(V, -10, 2));
        Observer.Observe('dec -1234.5 L=3 N=2', F.Decimal(V, 3, 2));
        Observer.Observe('dec -1234.5 L=10 N=2', F.Decimal(V, 10, 2));
        Observer.Observe('dec -1234.5 L=-3 N=9', F.Decimal(V, -3, 9));
        Observer.Observe('dec -1234.5 L=-10 N=9', F.Decimal(V, -10, 9));
        Observer.Observe('dec -1234.5 L=3 N=9', F.Decimal(V, 3, 9));
        Observer.Observe('dec -1234.5 L=10 N=9', F.Decimal(V, 10, 9));
        Observer.Finish();
    end;

    [Test]
    procedure StandardFormatString_Length_1()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        VDate: Date;
        VDateTime: DateTime;
    begin
        VDate := 0D;
        Observer.Observe('0D L=10 S=<Standard Format,0>', F.DateS(VDate, 10, '<Standard Format,0>'));
        Observer.Observe('0D L=3 S=<Standard Format,0>', F.DateS(VDate, 3, '<Standard Format,0>'));
        Observer.Observe('0D L=-3 S=<Standard Format,0>', F.DateS(VDate, -3, '<Standard Format,0>'));
        Observer.Observe('0D L=-10 S=<Standard Format,0>', F.DateS(VDate, -10, '<Standard Format,0>'));
        Observer.Observe('0D L=10 N=0', F.Date(VDate, 10, 0));
        VDate := ClosingDate(DMY2Date(15, 1, 2024));
        Observer.Observe('closing L=10 S=<Standard Format,0>', F.DateS(VDate, 10, '<Standard Format,0>'));
        Observer.Observe('closing L=3 S=<Standard Format,0>', F.DateS(VDate, 3, '<Standard Format,0>'));
        Observer.Observe('closing L=-3 S=<Standard Format,0>', F.DateS(VDate, -3, '<Standard Format,0>'));
        Observer.Observe('closing L=-10 S=<Standard Format,0>', F.DateS(VDate, -10, '<Standard Format,0>'));
        Observer.Observe('closing L=10 N=0', F.Date(VDate, 10, 0));
        VDate := DMY2Date(15, 1, 2024);
        Observer.Observe('date L=10 S=<Standard Format,0>', F.DateS(VDate, 10, '<Standard Format,0>'));
        Observer.Observe('date L=3 S=<Standard Format,0>', F.DateS(VDate, 3, '<Standard Format,0>'));
        Observer.Observe('date L=-3 S=<Standard Format,0>', F.DateS(VDate, -3, '<Standard Format,0>'));
        Observer.Observe('date L=-10 S=<Standard Format,0>', F.DateS(VDate, -10, '<Standard Format,0>'));
        Observer.Observe('date L=10 N=0', F.Date(VDate, 10, 0));
        VDateTime := 0DT;
        Observer.Observe('0DT L=10 S=<Standard Format,0>', F.DateTimeS(VDateTime, 10, '<Standard Format,0>'));
        Observer.Observe('0DT L=3 S=<Standard Format,0>', F.DateTimeS(VDateTime, 3, '<Standard Format,0>'));
        Observer.Observe('0DT L=-3 S=<Standard Format,0>', F.DateTimeS(VDateTime, -3, '<Standard Format,0>'));
        Observer.Observe('0DT L=-10 S=<Standard Format,0>', F.DateTimeS(VDateTime, -10, '<Standard Format,0>'));
        Observer.Observe('0DT L=10 N=0', F.DateTime(VDateTime, 10, 0));
        Observer.Finish();
    end;

    [Test]
    procedure StandardFormatString_Length_2()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        VDuration: Duration;
        VChar: Char;
        VTime: Time;
        VBoolean: Boolean;
    begin
        VDuration := 3723004;
        Observer.Observe('dur L=10 S=<Standard Format,0>', F.DurationS(VDuration, 10, '<Standard Format,0>'));
        Observer.Observe('dur L=3 S=<Standard Format,0>', F.DurationS(VDuration, 3, '<Standard Format,0>'));
        Observer.Observe('dur L=-3 S=<Standard Format,0>', F.DurationS(VDuration, -3, '<Standard Format,0>'));
        Observer.Observe('dur L=-10 S=<Standard Format,0>', F.DurationS(VDuration, -10, '<Standard Format,0>'));
        Observer.Observe('dur L=10 N=0', F.Duration(VDuration, 10, 0));
        VChar := 'a';
        Observer.Observe('char a L=10 S=<Standard Format,0>', F.CharS(VChar, 10, '<Standard Format,0>'));
        Observer.Observe('char a L=3 S=<Standard Format,0>', F.CharS(VChar, 3, '<Standard Format,0>'));
        Observer.Observe('char a L=-3 S=<Standard Format,0>', F.CharS(VChar, -3, '<Standard Format,0>'));
        Observer.Observe('char a L=-10 S=<Standard Format,0>', F.CharS(VChar, -10, '<Standard Format,0>'));
        Observer.Observe('char a L=10 N=0', F.Char(VChar, 10, 0));
        VTime := 134501T;
        Observer.Observe('time L=10 S=<Standard Format,0>', F.TimeS(VTime, 10, '<Standard Format,0>'));
        Observer.Observe('time L=3 S=<Standard Format,0>', F.TimeS(VTime, 3, '<Standard Format,0>'));
        Observer.Observe('time L=-3 S=<Standard Format,0>', F.TimeS(VTime, -3, '<Standard Format,0>'));
        Observer.Observe('time L=-10 S=<Standard Format,0>', F.TimeS(VTime, -10, '<Standard Format,0>'));
        Observer.Observe('time L=10 N=0', F.Time(VTime, 10, 0));
        VBoolean := true;
        Observer.Observe('bool L=10 S=<Standard Format,0>', F.BooleanS(VBoolean, 10, '<Standard Format,0>'));
        Observer.Observe('bool L=3 S=<Standard Format,0>', F.BooleanS(VBoolean, 3, '<Standard Format,0>'));
        Observer.Observe('bool L=-3 S=<Standard Format,0>', F.BooleanS(VBoolean, -3, '<Standard Format,0>'));
        Observer.Observe('bool L=-10 S=<Standard Format,0>', F.BooleanS(VBoolean, -10, '<Standard Format,0>'));
        Observer.Observe('bool L=10 N=0', F.Boolean(VBoolean, 10, 0));
        Observer.Finish();
    end;

    [Test]
    procedure StandardFormatString_Length_3()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        VGuid: Guid;
        VBigInteger: BigInteger;
        VByte: Byte;
    begin
        Clear(VGuid);
        Observer.Observe('guid null L=10 S=<Standard Format,0>', F.GuidS(VGuid, 10, '<Standard Format,0>'));
        Observer.Observe('guid null L=3 S=<Standard Format,0>', F.GuidS(VGuid, 3, '<Standard Format,0>'));
        Observer.Observe('guid null L=-3 S=<Standard Format,0>', F.GuidS(VGuid, -3, '<Standard Format,0>'));
        Observer.Observe('guid null L=-10 S=<Standard Format,0>', F.GuidS(VGuid, -10, '<Standard Format,0>'));
        Observer.Observe('guid null L=10 N=0', F.Guid(VGuid, 10, 0));
        VBigInteger := 1234567890123L;
        Observer.Observe('bigint L=10 S=<Standard Format,0>', F.BigIntegerS(VBigInteger, 10, '<Standard Format,0>'));
        Observer.Observe('bigint L=3 S=<Standard Format,0>', F.BigIntegerS(VBigInteger, 3, '<Standard Format,0>'));
        Observer.Observe('bigint L=-3 S=<Standard Format,0>', F.BigIntegerS(VBigInteger, -3, '<Standard Format,0>'));
        Observer.Observe('bigint L=-10 S=<Standard Format,0>', F.BigIntegerS(VBigInteger, -10, '<Standard Format,0>'));
        Observer.Observe('bigint L=10 N=0', F.BigInteger(VBigInteger, 10, 0));
        VByte := 97;
        Observer.Observe('byte 97 L=10 S=<Standard Format,0>', F.ByteS(VByte, 10, '<Standard Format,0>'));
        Observer.Observe('byte 97 L=3 S=<Standard Format,0>', F.ByteS(VByte, 3, '<Standard Format,0>'));
        Observer.Observe('byte 97 L=-3 S=<Standard Format,0>', F.ByteS(VByte, -3, '<Standard Format,0>'));
        Observer.Observe('byte 97 L=-10 S=<Standard Format,0>', F.ByteS(VByte, -10, '<Standard Format,0>'));
        Observer.Observe('byte 97 L=10 N=0', F.Byte(VByte, 10, 0));
        Observer.Finish();
    end;

    [Test]
    procedure StandardFormatString_Length_4()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        VInteger: Integer;
        VDecimal: Decimal;
        VCode: Code[20];
    begin
        VInteger := 1234567;
        Observer.Observe('int L=10 S=<Standard Format,0>', F.IntegerS(VInteger, 10, '<Standard Format,0>'));
        Observer.Observe('int L=3 S=<Standard Format,0>', F.IntegerS(VInteger, 3, '<Standard Format,0>'));
        Observer.Observe('int L=-3 S=<Standard Format,0>', F.IntegerS(VInteger, -3, '<Standard Format,0>'));
        Observer.Observe('int L=-10 S=<Standard Format,0>', F.IntegerS(VInteger, -10, '<Standard Format,0>'));
        Observer.Observe('int L=10 N=0', F.Integer(VInteger, 10, 0));
        VDecimal := 1234.5;
        Observer.Observe('dec L=10 S=<Standard Format,0>', F.DecimalS(VDecimal, 10, '<Standard Format,0>'));
        Observer.Observe('dec L=3 S=<Standard Format,0>', F.DecimalS(VDecimal, 3, '<Standard Format,0>'));
        Observer.Observe('dec L=-3 S=<Standard Format,0>', F.DecimalS(VDecimal, -3, '<Standard Format,0>'));
        Observer.Observe('dec L=-10 S=<Standard Format,0>', F.DecimalS(VDecimal, -10, '<Standard Format,0>'));
        Observer.Observe('dec L=10 N=0', F.Decimal(VDecimal, 10, 0));
        VCode := 'ABC12';
        Observer.Observe('code L=10 S=<Standard Format,0>', F.CodeS(VCode, 10, '<Standard Format,0>'));
        Observer.Observe('code L=3 S=<Standard Format,0>', F.CodeS(VCode, 3, '<Standard Format,0>'));
        Observer.Observe('code L=-3 S=<Standard Format,0>', F.CodeS(VCode, -3, '<Standard Format,0>'));
        Observer.Observe('code L=-10 S=<Standard Format,0>', F.CodeS(VCode, -10, '<Standard Format,0>'));
        Observer.Observe('code L=10 N=0', F.Code(VCode, 10, 0));
        Observer.Finish();
    end;

    [Test]
    procedure StandardFormatString9_Length()
    var
        Observer: Codeunit "Probe Observer";
        F: Codeunit "FLN Fmt";
        D: Date;
    begin
        D := 0D;
        Observer.Observe('0D L=10 S=<Standard Format,9>', F.DateS(D, 10, '<Standard Format,9>'));
        Observer.Observe('0D L=3 S=<Standard Format,9>', F.DateS(D, 3, '<Standard Format,9>'));
        Observer.Observe('0D L=-10 S=<Standard Format,9>', F.DateS(D, -10, '<Standard Format,9>'));
        D := DMY2Date(15, 1, 2024);
        Observer.Observe('date L=10 S=<Standard Format,9>', F.DateS(D, 10, '<Standard Format,9>'));
        Observer.Observe('date L=3 S=<Standard Format,9>', F.DateS(D, 3, '<Standard Format,9>'));
        Observer.Observe('date L=12 S=<Standard Format,9>', F.DateS(D, 12, '<Standard Format,9>'));
        Observer.Observe('date L=-12 S=<Standard Format,9>', F.DateS(D, -12, '<Standard Format,9>'));
        Observer.Finish();
    end;

    [Test]
    procedure DecimalField_Length()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 1 to 20 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Finish();
    end;

    [Test]
    procedure Record_RecordRef_Length()
    var
        Observer: Codeunit "Probe Observer";
        N: Integer;
    begin
        for N := 21 to 42 do
            Observer.Observe(CellName(N), Cell(N));
        Observer.Finish();
    end;

    local procedure Cell(N: Integer): Text
    var
        Result: Text;
    begin
        Got := '';
        if TryCell(N) then
            exit('[' + Got + ']');
        Result := 'ERR ' + GetLastErrorText() + ' | ' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;

    local procedure CellName(N: Integer): Text
    begin
        case N of
            1:
                exit('Amount(2:2) 1234.5 L=0');
            2:
                exit('Amount(2:2) 1234.5 L=3');
            3:
                exit('Amount(2:2) 1234.5 L=10');
            4:
                exit('Amount(2:2) 1234.5 L=30');
            5:
                exit('Amount(2:2) 1234.5 L=-3');
            6:
                exit('Amount(2:2) 1234.5 L=-10');
            7:
                exit('Amount(2:2) 1234.5 L=exact');
            8:
                exit('Amount(2:2) 1234.5 L=3 N=1');
            9:
                exit('Amount(2:2) 1234.5 L=3 N=2');
            10:
                exit('Amount(2:2) 1234.5 L=3 N=9');
            11:
                exit('Amount(2:2) 1234.5 L=-3 N=9');
            12:
                exit('Amount(2:2) 1234.5 L=3 S=<Integer><Decimals>');
            13:
                exit('Amount(2:2) 1234.5 L=3 S=<Standard Format,0>');
            14:
                exit('Amount(2:2) 1234.5 L=30 S=<Standard Format,0>');
            15:
                exit('Qty(0:3) 1234.5 L=0');
            16:
                exit('Qty(0:3) 1234.5 L=3');
            17:
                exit('Qty(0:3) 1234.5 L=10');
            18:
                exit('Qty(0:3) 1234.5 L=-3');
            19:
                exit('Plain field 1234.5 L=3');
            20:
                exit('Plain field 1234.5 L=-3');
            21:
                exit('RecordRef open L=0');
            22:
                exit('RecordRef open L=3');
            23:
                exit('RecordRef open L=10');
            24:
                exit('RecordRef open L=40');
            25:
                exit('RecordRef open L=-3');
            26:
                exit('RecordRef open L=-40');
            27:
                exit('RecordRef open L=exact');
            28:
                exit('RecordRef not open L=0');
            29:
                exit('RecordRef not open L=5');
            30:
                exit('RecordRef not open L=-5');
            31:
                exit('Record L=0');
            32:
                exit('Record L=3');
            33:
                exit('Record L=40');
            34:
                exit('Record L=-3');
            35:
                exit('Record L=-40');
            36:
                exit('Record L=-exact');
            37:
                exit('RecordId L=0');
            38:
                exit('RecordId L=3');
            39:
                exit('RecordId L=-3');
            40:
                exit('RecordId L=40');
            41:
                exit('RecordId L=exact');
            42:
                exit('RecordId L=-exact');
        end;
    end;

    [TryFunction]
    local procedure TryCell(N: Integer)
    var
        Holder: Record "FLN Amount Holder";
        RRef: RecordRef;
        Closed: RecordRef;
    begin
        Holder.Init();
        Holder.Id := 1;
        Holder.Amount := 1234.5;
        Holder.Qty := 1234.5;
        Holder.Plain := 1234.5;
        RRef.GetTable(Holder);
        case N of
            1:
                Got := Format(Holder.Amount, 0);
            2:
                Got := Format(Holder.Amount, 3);
            3:
                Got := Format(Holder.Amount, 10);
            4:
                Got := Format(Holder.Amount, 30);
            5:
                Got := Format(Holder.Amount, -3);
            6:
                Got := Format(Holder.Amount, -10);
            7:
                Got := Format(Holder.Amount, StrLen(Format(Holder.Amount)));
            8:
                Got := Format(Holder.Amount, 3, 1);
            9:
                Got := Format(Holder.Amount, 3, 2);
            10:
                Got := Format(Holder.Amount, 3, 9);
            11:
                Got := Format(Holder.Amount, -3, 9);
            12:
                Got := Format(Holder.Amount, 3, '<Integer><Decimals>');
            13:
                Got := Format(Holder.Amount, 3, '<Standard Format,0>');
            14:
                Got := Format(Holder.Amount, 30, '<Standard Format,0>');
            15:
                Got := Format(Holder.Qty, 0);
            16:
                Got := Format(Holder.Qty, 3);
            17:
                Got := Format(Holder.Qty, 10);
            18:
                Got := Format(Holder.Qty, -3);
            19:
                Got := Format(Holder.Plain, 3);
            20:
                Got := Format(Holder.Plain, -3);
            21:
                Got := Format(RRef, 0);
            22:
                Got := Format(RRef, 3);
            23:
                Got := Format(RRef, 10);
            24:
                Got := Format(RRef, 40);
            25:
                Got := Format(RRef, -3);
            26:
                Got := Format(RRef, -40);
            27:
                Got := Format(RRef, StrLen(Format(RRef)));
            28:
                Got := Format(Closed, 0);
            29:
                Got := Format(Closed, 5);
            30:
                Got := Format(Closed, -5);
            31:
                Got := Format(Holder, 0);
            32:
                Got := Format(Holder, 3);
            33:
                Got := Format(Holder, 40);
            34:
                Got := Format(Holder, -3);
            35:
                Got := Format(Holder, -40);
            36:
                Got := Format(Holder, -StrLen(Format(Holder)));
            37:
                Got := Format(Holder.RecordId, 0);
            38:
                Got := Format(Holder.RecordId, 3);
            39:
                Got := Format(Holder.RecordId, -3);
            40:
                Got := Format(Holder.RecordId, 40);
            41:
                Got := Format(Holder.RecordId, StrLen(Format(Holder.RecordId)));
            42:
                Got := Format(Holder.RecordId, -StrLen(Format(Holder.RecordId)));
        end;
    end;
}
