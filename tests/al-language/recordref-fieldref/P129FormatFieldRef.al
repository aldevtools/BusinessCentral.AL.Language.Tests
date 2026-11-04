// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained enum 73323, table 73301 and codeunit 73302
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of a FieldRef (the FieldRef itself, not its Value) with no format number and with the standard formats 0, 1, 2, 3 and 9, and with a length, for fields of type Integer, BigInteger, Decimal, Duration,
// Date, Time, DateTime, Boolean, Option, Code, Text and Enum, with a value and with the blank value.
// BC versions: 29 (27 and 28 by CI)

enum 73323 "LT P129 FR Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; "Big Kind") { }
}

table 73301 "LT P129 FR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Big; BigInteger) { }
        field(3; Dec; Decimal) { }
        field(4; Dur; Duration) { }
        field(5; D; Date) { }
        field(6; T; Time) { }
        field(7; Dt; DateTime) { }
        field(8; Flag; Boolean) { }
        field(9; Opt; Option)
        {
            OptionMembers = Zero,One,Two;
            OptionCaption = 'Nil,Uno,Dos';
        }
        field(10; Cd; Code[10]) { }
        field(11; Txt; Text[30]) { }
        field(12; Kind; Enum "LT P129 FR Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// Corpus issue 672 item 24: Decimal fields with a DecimalPlaces property, a Blob and a Date, for Format(FieldRef) against
// Format(FieldRef.Value).
table 83351 "LT BT FR Places"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Dec22; Decimal) { DecimalPlaces = 2 : 2; }
        field(3; Dec05; Decimal) { DecimalPlaces = 0 : 5; }
        field(4; Dec33; Decimal) { DecimalPlaces = 3 : 3; }
        field(5; Bin; Blob) { }
        field(6; D; Date) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 73302 "LT P129 Format FieldRef"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Filled(var RecRef: RecordRef)
    var
        Row: Record "LT P129 FR Row";
    begin
        Row.Id := 1234;
        Row.Big := 2147483647;
        Row.Big := Row.Big * 2 + 1000;
        Row.Dec := 1234.5;
        Row.Dur := 90061000;
        Row.D := 20240305D;
        Row.T := 134506T;
        Row.Dt := CreateDateTime(20240305D, 134506T);
        Row.Flag := true;
        Row.Opt := Row.Opt::Two;
        Row.Cd := 'abc';
        Row.Txt := 'Hello world';
        Row.Kind := Row.Kind::"Big Kind";
        RecRef.GetTable(Row);
    end;

    local procedure Blank(var RecRef: RecordRef)
    var
        Row: Record "LT P129 FR Row";
    begin
        RecRef.GetTable(Row);
    end;

    local procedure Fmt(var RecRef: RecordRef; FieldNo: Integer; Standard: Integer): Text
    var
        FR: FieldRef;
    begin
        FR := RecRef.Field(FieldNo);
        if Standard < 0 then
            exit(Format(FR));
        exit(Format(FR, 0, Standard));
    end;

    local procedure FmtLen(var RecRef: RecordRef; FieldNo: Integer; Length: Integer): Text
    var
        FR: FieldRef;
    begin
        FR := RecRef.Field(FieldNo);
        exit(Format(FR, Length));
    end;

    [Test]
    procedure P129_FormatFieldRef_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Standard: Integer;
        FieldNo: Integer;
        FieldList: List of [Integer];
    begin
        Filled(RecRef);
        FieldList := GetNumberFields();
        foreach FieldNo in FieldList do
            for Standard := -1 to 9 do
                if Standard in [-1, 0, 1, 2, 9] then
                    Observer.Observe('f' + Format(FieldNo) + ' std ' + Format(Standard), Fmt(RecRef, FieldNo, Standard));
        Observer.Expect('f1 std -1', '1234');
        Observer.Expect('f1 std 0', '1234');
        Observer.Expect('f1 std 1', '1234');
        Observer.Expect('f1 std 2', '1234');
        Observer.Expect('f1 std 9', '1234');
        Observer.Expect('f2 std -1', '4294968294');
        Observer.Expect('f2 std 0', '4294968294');
        Observer.Expect('f2 std 1', '4294968294');
        Observer.Expect('f2 std 2', '4294968294');
        Observer.Expect('f2 std 9', '4294968294');
        Observer.Expect('f3 std -1', '1,234.5');
        Observer.Expect('f3 std 0', '1,234.5');
        Observer.Expect('f3 std 1', '1234.5');
        Observer.Expect('f3 std 2', '1234.5');
        Observer.Expect('f3 std 9', '1234.5');
        Observer.Expect('f4 std -1', '1 day 1 hour 1 minute 1 second');
        Observer.Expect('f4 std 0', '1 day 1 hour 1 minute 1 second');
        Observer.Expect('f4 std 1', '1 day 1 hour 1 minute 1 second');
        Observer.Expect('f4 std 2', '1 0 1 2 1 4 1 6');
        Observer.Expect('f4 std 9', 'P1DT1H1M1.0S');
        Observer.Verify();
    end;

    local procedure GetNumberFields() Result: List of [Integer]
    begin
        Result.Add(1);
        Result.Add(2);
        Result.Add(3);
        Result.Add(4);
    end;

    local procedure GetTemporalFields() Result: List of [Integer]
    begin
        Result.Add(5);
        Result.Add(6);
        Result.Add(7);
    end;

    local procedure GetOtherFields() Result: List of [Integer]
    begin
        Result.Add(8);
        Result.Add(9);
        Result.Add(10);
        Result.Add(11);
        Result.Add(12);
    end;

    [Test]
    procedure P129_FormatFieldRef_BooleanOptionCodeTextEnum()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Standard: Integer;
        FieldNo: Integer;
        FieldList: List of [Integer];
    begin
        Filled(RecRef);
        FieldList := GetOtherFields();
        foreach FieldNo in FieldList do
            for Standard := -1 to 9 do
                if Standard in [-1, 0, 2, 9] then
                    Observer.Observe('f' + Format(FieldNo) + ' std ' + Format(Standard), Fmt(RecRef, FieldNo, Standard));
        Observer.Expect('f8 std -1', 'Yes');
        Observer.Expect('f8 std 0', 'Yes');
        Observer.Expect('f8 std 2', '1');
        Observer.Expect('f8 std 9', 'true');
        Observer.Expect('f9 std -1', 'Dos');
        Observer.Expect('f9 std 0', 'Dos');
        Observer.Expect('f9 std 2', '2');
        Observer.Expect('f9 std 9', '2');
        Observer.Expect('f10 std -1', 'ABC');
        Observer.Expect('f10 std 0', 'ABC');
        Observer.Expect('f10 std 2', 'ABC');
        Observer.Expect('f10 std 9', 'ABC');
        Observer.Expect('f11 std -1', 'Hello world');
        Observer.Expect('f11 std 0', 'Hello world');
        Observer.Expect('f11 std 2', 'Hello world');
        Observer.Expect('f11 std 9', 'Hello world');
        Observer.Expect('f12 std -1', 'Big Kind');
        Observer.Expect('f12 std 0', 'Big Kind');
        Observer.Expect('f12 std 2', '1');
        Observer.Expect('f12 std 9', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P129_FormatFieldRef_WithLength()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        Filled(RecRef);
        Observer.Observe('text 5', FmtLen(RecRef, 11, 5));
        Observer.Observe('text 20', FmtLen(RecRef, 11, 20));
        Observer.Observe('code 5', FmtLen(RecRef, 10, 5));
        Observer.Observe('int 2', FmtLen(RecRef, 1, 2));
        Observer.Observe('int 8', FmtLen(RecRef, 1, 8));
        Observer.Observe('dec 4', FmtLen(RecRef, 3, 4));
        Observer.Observe('option 2', FmtLen(RecRef, 9, 2));
        Observer.Observe('date 5', FmtLen(RecRef, 5, 5));
        Observer.Expect('text 5', 'Hello');
        Observer.Expect('text 20', 'Hello world         ');
        Observer.Expect('code 5', 'ABC  ');
        Observer.Expect('int 2', '12');
        Observer.Expect('int 8', '    1234');
        Observer.Expect('dec 4', '1,23');
        Observer.Expect('option 2', 'Do');
        Observer.Expect('date 5', '03/05');
        Observer.Verify();
    end;

    [Test]
    procedure P129_FormatFieldRef_BlankValues()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        FieldNo: Integer;
    begin
        Blank(RecRef);
        for FieldNo := 1 to 12 do begin
            Observer.Observe('blank f' + Format(FieldNo) + ' default', Fmt(RecRef, FieldNo, -1));
            Observer.Observe('blank f' + Format(FieldNo) + ' std 9', Fmt(RecRef, FieldNo, 9));
        end;
        Observer.Expect('blank f1 default', '0');
        Observer.Expect('blank f1 std 9', '0');
        Observer.Expect('blank f2 default', '0');
        Observer.Expect('blank f2 std 9', '0');
        Observer.Expect('blank f3 default', '0');
        Observer.Expect('blank f3 std 9', '0');
        Observer.Expect('blank f4 default', '');
        Observer.Expect('blank f4 std 9', 'P0DT0H0M0.0S');
        Observer.Expect('blank f5 default', '');
        Observer.Expect('blank f5 std 9', '');
        Observer.Expect('blank f6 default', '');
        Observer.Expect('blank f6 std 9', '');
        Observer.Expect('blank f7 default', '');
        Observer.Expect('blank f7 std 9', '');
        Observer.Expect('blank f8 default', 'No');
        Observer.Expect('blank f8 std 9', 'false');
        Observer.Expect('blank f9 default', 'Nil');
        Observer.Expect('blank f9 std 9', '0');
        Observer.Expect('blank f10 default', '');
        Observer.Expect('blank f10 std 9', '');
        Observer.Expect('blank f11 default', '');
        Observer.Expect('blank f11 std 9', '');
        Observer.Expect('blank f12 default', 'None');
        Observer.Expect('blank f12 std 9', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFormatOne(var RecRef: RecordRef; FieldNo: Integer; Form: Integer; var Result: Text)
    var
        FR: FieldRef;
    begin
        FR := RecRef.Field(FieldNo);
        case Form of
            0:
                Result := Format(FR);
            1:
                Result := Format(FR.Value);
            2:
                Result := Format(FR, 0, 1);
            3:
                Result := Format(FR.Value, 0, 1);
            4:
                Result := Format(FR, 0, 9);
            5:
                Result := Format(FR.Value, 0, 9);
        end;
    end;

    local procedure FieldVsValue(var RecRef: RecordRef; FieldNo: Integer): Text
    var
        Form: Integer;
        One: Text;
        Result: Text;
    begin
        for Form := 0 to 5 do begin
            ClearLastError();
            if not TryFormatOne(RecRef, FieldNo, Form, One) then
                One := 'err:' + GetLastErrorText() + ':' + GetLastErrorCode();
            if Form > 0 then
                Result += '|';
            Result += One;
        end;
        exit(Result);
    end;

    // Corpus issue 672 item 24: Format(FieldRef) against Format(FieldRef.Value), each with no format number, format 1 and format 9
    // (FR | FR.Value | FR 0,1 | FR.Value 0,1 | FR 0,9 | FR.Value 0,9), for Decimal fields with DecimalPlaces 2:2, 0:5 and 3:3 and a Date (also after
    // GlobalLanguage(1031)); Format(Rec.Field) for the Decimals.
    [Test]
    procedure BT_FormatFieldRef_AgainstFormatValue()
    var
        Observer: Codeunit "Probe Observer";
        Places: Record "LT BT FR Places";
        RecRef: RecordRef;
        Saved: Integer;
    begin
        Places.Id := 1;
        Places.Dec22 := 1234.5;
        Places.Dec05 := 1234.5;
        Places.Dec33 := 2;
        Places.D := 20240305D;
        Observer.Observe('rec dec22', Format(Places.Dec22) + '|' + Format(Places.Dec22, 0, 1));
        Observer.Observe('rec dec05', Format(Places.Dec05));
        Observer.Observe('rec dec33', Format(Places.Dec33));
        RecRef.GetTable(Places);
        Observer.Observe('dec22', FieldVsValue(RecRef, 2));
        Observer.Observe('dec05', FieldVsValue(RecRef, 3));
        Observer.Observe('dec33', FieldVsValue(RecRef, 4));
        Observer.Observe('date', FieldVsValue(RecRef, 6));
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('date 1031', FieldVsValue(RecRef, 6));
        Observer.Observe('dec22 1031', FieldVsValue(RecRef, 2));
        GlobalLanguage(Saved);
        Observer.Expect('rec dec22', '1,234.50|1234.50');
        Observer.Expect('rec dec05', '1,234.5');
        Observer.Expect('rec dec33', '2.000');
        Observer.Expect('dec22', '1,234.5|1,234.5|1234.5|1234.5|1234.5|1234.5');
        Observer.Expect('dec05', '1,234.5|1,234.5|1234.5|1234.5|1234.5|1234.5');
        Observer.Expect('dec33', '2|2|2|2|2|2');
        Observer.Expect('date', '03/05/24|03/05/24|03/05/24|03/05/24|2024-03-05|2024-03-05');
        Observer.Expect('date 1031', '03/05/24|03/05/24|03/05/24|03/05/24|2024-03-05|2024-03-05');
        Observer.Expect('dec22 1031', '1,234.5|1,234.5|1234.5|1234.5|1234.5|1234.5');
        Observer.Verify();
    end;

    // Corpus issue 672 item 24, second part: the same comparison for a Blob with content, an Option with captions and an Enum.
    [Test]
    procedure BT_FormatFieldRef_AgainstFormatValue_BlobOptionEnum()
    var
        Observer: Codeunit "Probe Observer";
        Places: Record "LT BT FR Places";
        RecRef: RecordRef;
        OutS: OutStream;
    begin
        Places.Id := 1;
        Places.Bin.CreateOutStream(OutS);
        OutS.WriteText('abc');
        RecRef.GetTable(Places);
        Observer.Observe('blob', FieldVsValue(RecRef, 5));
        Clear(RecRef);
        Filled(RecRef);
        Observer.Observe('option', FieldVsValue(RecRef, 9));
        Observer.Observe('enum', FieldVsValue(RecRef, 12));
        Observer.Expect('blob', '*|*|*|*|*|*');
        Observer.Expect('option', 'Dos|Dos|Dos|Dos|2|2');
        Observer.Expect('enum', 'Big Kind|Big Kind|Big Kind|Big Kind|1|1');
        Observer.Verify();
    end;
}
