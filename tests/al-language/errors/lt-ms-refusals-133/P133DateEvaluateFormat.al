// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-dmy2date-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); declares enum 74044, table 74045
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: DMY2Date with one or two arguments (day, then day and month; the rest comes from today or from WorkDate, compared as relations, never as dates of today); Evaluate of decimal-looking text into Integer and BigInteger; Format of a Record with a field of every scalar type (defaults, filled, temporary, with a length, with standard formats)
// BC versions: 29 (27 and 28 by CI)

enum 74044 "LT P133 Kind"
{
    Extensible = true;

    value(0; None) { }
    value(1; First) { Caption = 'First Caption'; }
    value(2; Second) { }
}

table 74045 "LT P133 All Types"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Txt; Text[20]) { }
        field(3; Cd; Code[10]) { }
        field(4; Dec; Decimal) { }
        field(5; Bool; Boolean) { }
        field(6; Opt; Option) { OptionMembers = Zero,One,Two; }
        field(7; Kind; Enum "LT P133 Kind") { }
        field(8; Dt; Date) { }
        field(9; Tm; Time) { }
        field(10; DtTm; DateTime) { }
        field(11; Big; BigInteger) { }
        field(12; G; Guid) { }
        field(13; Dur; Duration) { }
        field(14; Bl; Blob) { }
        field(15; Rid; RecordId) { }
        field(16; Int2; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 90541 "LT NP3 Fmt Flow"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Cd; Code[10]) { }
        field(3; Dt; Date) { }
        field(4; Total; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT P133 All Types");
        }
        field(5; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74046 "LT P133 Date Eval Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDay(Day: Integer; var Result: Date)
    begin
        Result := DMY2Date(Day);
    end;

    [TryFunction]
    local procedure TryDayMonth(Day: Integer; Month: Integer; var Result: Date)
    begin
        Result := DMY2Date(Day, Month);
    end;

    [TryFunction]
    local procedure TryDayMonthYear(Day: Integer; Month: Integer; Year: Integer; var Result: Date)
    begin
        Result := DMY2Date(Day, Month, Year);
    end;

    // The text of an error with the year of today hidden.
    local procedure Scrubbed(): Text
    begin
        exit(GetLastErrorText().Replace(Format(Date2DMY(Today(), 3)), '<year>'));
    end;

    local procedure Relation(Value: Date; Reference: Date; DayOf: Integer): Text
    begin
        exit(Format(Date2DMY(Value, 1)) + '|month same=' + Format(Date2DMY(Value, 2) = Date2DMY(Reference, 2)) + '|year same=' + Format(Date2DMY(Value, 3) = Date2DMY(Reference, 3)));
    end;

    [Test]
    procedure P133_DMY2Date_DayOnly_And_DayMonth_RelativeToToday()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('day 15', Relation(DMY2Date(15), Today(), 15));
        Observer.Observe('day 1', Relation(DMY2Date(1), Today(), 1));
        Observer.Observe('day 28', Relation(DMY2Date(28), Today(), 28));
        Observer.Observe('day 15 month 3', Format(Date2DMY(DMY2Date(15, 3), 1)) + '/' + Format(Date2DMY(DMY2Date(15, 3), 2)));
        Observer.Observe('day 15 month 3 year is today year', Format(Date2DMY(DMY2Date(15, 3), 3) = Date2DMY(Today(), 3)));
        Observer.Observe('day 1 month 12 year is today year', Format(Date2DMY(DMY2Date(1, 12), 3) = Date2DMY(Today(), 3)));
        Observer.Observe('day 28 month 2 year is today year', Format(Date2DMY(DMY2Date(28, 2), 3) = Date2DMY(Today(), 3)));
        Observer.Observe('three args same as two for the year of today', Format(DMY2Date(15, 3) = DMY2Date(15, 3, Date2DMY(Today(), 3))));
        Observer.Observe('one arg same as three for month and year of today', Format(DMY2Date(15) = DMY2Date(15, Date2DMY(Today(), 2), Date2DMY(Today(), 3))));
        Observer.Observe('day 15 ok', Format(TryDay(15, D)));
        Observer.Expect('day 15', '15|month same=Yes|year same=Yes');
        Observer.Expect('day 1', '1|month same=Yes|year same=Yes');
        Observer.Expect('day 28', '28|month same=Yes|year same=Yes');
        Observer.Expect('day 15 month 3', '15/3');
        Observer.Expect('day 15 month 3 year is today year', 'Yes');
        Observer.Expect('day 1 month 12 year is today year', 'Yes');
        Observer.Expect('day 28 month 2 year is today year', 'Yes');
        Observer.Expect('three args same as two for the year of today', 'Yes');
        Observer.Expect('one arg same as three for month and year of today', 'Yes');
        Observer.Expect('day 15 ok', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P133_DMY2Date_DayOnly_FollowsWorkDateOrToday()
    var
        Observer: Codeunit "Probe Observer";
        OldWorkDate: Date;
    begin
        OldWorkDate := WorkDate();
        WorkDate(DMY2Date(10, 2, 2000));
        Observer.Observe('day only: month is workdate month', Format(Date2DMY(DMY2Date(15), 2) = 2));
        Observer.Observe('day only: year is workdate year', Format(Date2DMY(DMY2Date(15), 3) = 2000));
        Observer.Observe('day only: month is today month', Format(Date2DMY(DMY2Date(15), 2) = Date2DMY(Today(), 2)));
        Observer.Observe('day only: year is today year', Format(Date2DMY(DMY2Date(15), 3) = Date2DMY(Today(), 3)));
        Observer.Observe('day month: year is workdate year', Format(Date2DMY(DMY2Date(15, 3), 3) = 2000));
        Observer.Observe('day month: year is today year', Format(Date2DMY(DMY2Date(15, 3), 3) = Date2DMY(Today(), 3)));
        WorkDate(OldWorkDate);
        Observer.Expect('day only: month is workdate month', 'No');
        Observer.Expect('day only: year is workdate year', 'No');
        Observer.Expect('day only: month is today month', 'Yes');
        Observer.Expect('day only: year is today year', 'Yes');
        Observer.Expect('day month: year is workdate year', 'No');
        Observer.Expect('day month: year is today year', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P133_DMY2Date_ShortForms_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('day 0 ok', Format(TryDay(0, D)));
        Observer.Observe('day 0 error', Scrubbed());
        ClearLastError();
        Observer.Observe('day 32 ok', Format(TryDay(32, D)));
        Observer.Observe('day 32 error', Scrubbed());
        ClearLastError();
        Observer.Observe('day -1 ok', Format(TryDay(-1, D)));
        Observer.Observe('day -1 error', Scrubbed());
        ClearLastError();
        Observer.Observe('15 month 0 ok', Format(TryDayMonth(15, 0, D)));
        Observer.Observe('15 month 0 error', Scrubbed());
        ClearLastError();
        Observer.Observe('15 month 13 ok', Format(TryDayMonth(15, 13, D)));
        Observer.Observe('15 month 13 error', Scrubbed());
        ClearLastError();
        Observer.Observe('0 month 3 ok', Format(TryDayMonth(0, 3, D)));
        Observer.Observe('0 month 3 error', Scrubbed());
        ClearLastError();
        Observer.Observe('32 month 3 ok', Format(TryDayMonth(32, 3, D)));
        Observer.Observe('32 month 3 error', Scrubbed());
        ClearLastError();
        Observer.Observe('31 month 4 ok', Format(TryDayMonth(31, 4, D)));
        Observer.Observe('31 month 4 error', Scrubbed());
        ClearLastError();
        Observer.Observe('30 month 2 ok', Format(TryDayMonth(30, 2, D)));
        Observer.Observe('30 month 2 error', Scrubbed());
        ClearLastError();
        Observer.Observe('all three 30.2.2023 ok', Format(TryDayMonthYear(30, 2, 2023, D)));
        Observer.Observe('all three 30.2.2023 error', GetLastErrorText());
        ClearLastError();
        Observer.Expect('day 0 ok', 'No');
        Observer.Expect('day 0 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 31.');
        Observer.Expect('day 32 ok', 'No');
        Observer.Expect('day 32 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 32. The permitted range is: from 1 to 31.');
        Observer.Expect('day -1 ok', 'No');
        Observer.Expect('day -1 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: -1. The permitted range is: from 1 to 31.');
        Observer.Expect('15 month 0 ok', 'No');
        Observer.Expect('15 month 0 error', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 12.');
        Observer.Expect('15 month 13 ok', 'No');
        Observer.Expect('15 month 13 error', 'The value of DMY2Date parameter 2 is outside of the permitted range. The current value is: 13. The permitted range is: from 1 to 12.');
        Observer.Expect('0 month 3 ok', 'No');
        Observer.Expect('0 month 3 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 31.');
        Observer.Expect('32 month 3 ok', 'No');
        Observer.Expect('32 month 3 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 32. The permitted range is: from 1 to 31.');
        Observer.Expect('31 month 4 ok', 'No');
        Observer.Expect('31 month 4 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 31. The permitted range is: from 1 to 30.');
        Observer.Expect('30 month 2 ok', 'No');
        Observer.Expect('30 month 2 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 30. The permitted range is: from 1 to 28.');
        Observer.Expect('all three 30.2.2023 ok', 'No');
        Observer.Expect('all three 30.2.2023 error', 'The value of DMY2Date parameter 1 is outside of the permitted range. The current value is: 30. The permitted range is: from 1 to 28.');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Evaluate_DecimalText_IntoInteger()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Ok: Boolean;
    begin
        I := 99;
        Ok := Evaluate(I, '110.74398');
        Observer.Observe('110.74398', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '110.0');
        Observer.Observe('110.0', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '110.');
        Observer.Observe('110.', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '-110.5');
        Observer.Observe('-110.5', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '.5');
        Observer.Observe('.5', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '1E3');
        Observer.Observe('1E3', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '110,74398');
        Observer.Observe('110,74398', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '0.00001');
        Observer.Observe('0.00001', Format(Ok) + '|' + Format(I));
        I := 99;
        Ok := Evaluate(I, '682.12312');
        Observer.Observe('682.12312', Format(Ok) + '|' + Format(I));
        I := 99;
        asserterror Evaluate(I, '110.74398', 9);
        Observer.ObserveError('xml format 110.74398');
        I := 99;
        Ok := Evaluate(I, '110.74398', 9);
        Observer.Observe('xml format result', Format(Ok) + '|' + Format(I));
        Observer.Expect('110.74398', 'No|99');
        Observer.Expect('110.0', 'Yes|110');
        Observer.Expect('110.', 'Yes|110');
        Observer.Expect('-110.5', 'No|99');
        Observer.Expect('.5', 'No|99');
        Observer.Expect('1E3', 'Yes|1000');
        Observer.Expect('110,74398', 'Yes|11074398');
        Observer.Expect('0.00001', 'No|99');
        Observer.Expect('682.12312', 'No|99');
        Observer.Expect('xml format 110.74398|text', 'The value "110.74398" can''t be evaluated into type Integer.');
        Observer.Expect('xml format 110.74398|code', 'Evaluate');
        Observer.Expect('xml format result', 'No|99');
        Observer.Verify();
    end;

    [Test]
    procedure P133_Evaluate_DecimalText_IntoBigIntegerAndDecimal()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
        D: Decimal;
        Ok: Boolean;
    begin
        B := 99;
        Ok := Evaluate(B, '110.74398');
        Observer.Observe('big 110.74398', Format(Ok) + '|' + Format(B));
        B := 99;
        Ok := Evaluate(B, '110.0');
        Observer.Observe('big 110.0', Format(Ok) + '|' + Format(B));
        B := 99;
        Ok := Evaluate(B, '-3.5');
        Observer.Observe('big -3.5', Format(Ok) + '|' + Format(B));
        D := 99;
        Ok := Evaluate(D, '110.74398');
        Observer.Observe('dec 110.74398', Format(Ok) + '|' + Format(D));
        D := 99;
        Ok := Evaluate(D, '110.');
        Observer.Observe('dec 110.', Format(Ok) + '|' + Format(D));
        D := 99;
        Ok := Evaluate(D, '.5');
        Observer.Observe('dec .5', Format(Ok) + '|' + Format(D));
        Observer.Expect('big 110.74398', 'No|99');
        Observer.Expect('big 110.0', 'Yes|110');
        Observer.Expect('big -3.5', 'No|99');
        Observer.Expect('dec 110.74398', 'Yes|110.74398');
        Observer.Expect('dec 110.', 'Yes|110');
        Observer.Expect('dec .5', 'Yes|0.5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryFormat(var Rec: Record "LT P133 All Types"; Length: Integer; Standard: Integer; var Res: Text)
    begin
        Res := Format(Rec, Length, Standard);
    end;

    local procedure FillAll(var Rec: Record "LT P133 All Types")
    var
        G: Guid;
    begin
        Rec.Id := 7;
        Rec.Txt := 'text value';
        Rec.Cd := 'CODE1';
        Rec.Dec := 2.5;
        Rec.Bool := true;
        Rec.Opt := Rec.Opt::Two;
        Rec.Kind := Rec.Kind::First;
        Rec.Dt := DMY2Date(5, 3, 2024);
        Rec.Tm := 143015T;
        Rec.DtTm := CreateDateTime(DMY2Date(5, 3, 2024), 143015T);
        Rec.Big := 123456789;
        Evaluate(G, '{12345678-1234-1234-1234-123456789012}');
        Rec.G := G;
        Rec.Dur := 90000;
        Rec.Int2 := -4;
    end;

    [Test]
    procedure P133_FormatRecord_Defaults_EachFieldType()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P133 All Types";
    begin
        Rec.DeleteAll();
        Observer.Observe('init record', Format(Rec));
        Rec.Init();
        Observer.Observe('after Init', Format(Rec));
        Rec.Id := 1;
        Observer.Observe('only id', Format(Rec));
        Rec.Insert();
        Rec.Get(1);
        Observer.Observe('after Insert and Get', Format(Rec));
        Observer.Observe('length 5', Format(Rec, 5));
        Observer.Observe('length 0', Format(Rec, 0));
        Observer.Observe('length 20', Format(Rec, 20));
        Observer.Expect('init record', '0\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('after Init', '0\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('only id', '1\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('after Insert and Get', '1\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('length 5', '1\t\t\t0');
        Observer.Expect('length 0', '1\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('length 20', '1\t\t\t0\tNo\tZero\tNone\t\t');
        Observer.Verify();
    end;

    [Test]
    procedure P133_FormatRecord_FilledFields()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P133 All Types";
    begin
        Rec.DeleteAll();
        FillAll(Rec);
        Observer.Observe('filled, not inserted', Format(Rec));
        Rec.Insert();
        Rec.Get(7);
        Observer.Observe('filled, after Get', Format(Rec));
        Rec.Rid := Rec.RecordId;
        Observer.Observe('with record id', Format(Rec));
        Observer.Expect('filled, not inserted', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('filled, after Get', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('with record id', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \tLT P133 All Types: 7\t-4');
        Observer.Verify();
    end;

    [Test]
    procedure P133_FormatRecord_Temporary_AndCopies()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT P133 All Types" temporary;
        Other: Record "LT P133 All Types";
    begin
        FillAll(Temp);
        Temp.Insert();
        Observer.Observe('temporary', Format(Temp));
        Other := Temp;
        Observer.Observe('copy of temporary', Format(Other));
        Temp.SetRange(Id, 99);
        Observer.Observe('temporary with filter', Format(Temp));
        Clear(Temp);
        Observer.Observe('empty after Clear', Format(Temp));
        Observer.Expect('temporary', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('copy of temporary', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('temporary with filter', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('empty after Clear', '0\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Verify();
    end;

    [Test]
    procedure P133_FormatRecord_StandardFormats()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P133 All Types";
        Res: Text;
    begin
        Rec.DeleteAll();
        FillAll(Rec);
        Observer.Observe('format 0 ok', Format(TryFormat(Rec, 0, 0, Res)));
        Observer.Observe('format 0', Res);
        Observer.Observe('format 1 ok', Format(TryFormat(Rec, 0, 1, Res)));
        Observer.Observe('format 1', Res);
        Observer.Observe('format 2 ok', Format(TryFormat(Rec, 0, 2, Res)));
        Observer.Observe('format 2', Res);
        Observer.Observe('format 9 ok', Format(TryFormat(Rec, 0, 9, Res)));
        Observer.Observe('format 9', Res);
        Observer.Observe('format 3 ok', Format(TryFormat(Rec, 0, 3, Res)));
        Observer.Observe('format 3', Res);
        Observer.Observe('format 0 length 12 ok', Format(TryFormat(Rec, 12, 0, Res)));
        Observer.Observe('format 0 length 12', Res);
        Observer.Expect('format 0 ok', 'Yes');
        Observer.Expect('format 0', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('format 1 ok', 'Yes');
        Observer.Expect('format 1', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('format 2 ok', 'Yes');
        Observer.Expect('format 2', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('format 9 ok', 'Yes');
        Observer.Expect('format 9', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('format 3 ok', 'No');
        Observer.Expect('format 3', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('format 0 length 12 ok', 'Yes');
        Observer.Expect('format 0 length 12', '7\ttext value');
        Observer.Verify();
    end;

    [Test]
    procedure NP3_FormatRecord_StandardFormats_0And9()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P133 All Types";
    begin
        Rec.DeleteAll();
        Observer.Observe('blank_0', Format(Rec, 0, 0));
        Observer.Observe('blank_9', Format(Rec, 0, 9));
        FillAll(Rec);
        Observer.Observe('filled_0', Format(Rec, 0, 0));
        Observer.Observe('filled_9', Format(Rec, 0, 9));
        Rec.Insert();
        Rec.Get(7);
        Rec.Rid := Rec.RecordId;
        Observer.Observe('with_recordid_9', Format(Rec, 0, 9));
        Observer.Expect('blank_0', '0\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('blank_9', '0\t\t\t0\tNo\tZero\tNone\t\t\t\t0\t{00000000-0000-0000-0000-000000000000}\t\t \t\t0');
        Observer.Expect('filled_0', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('filled_9', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \t\t-4');
        Observer.Expect('with_recordid_9', '7\ttext value\tCODE1\t2.5\tYes\tTwo\tFirst Caption\t03/05/24\t 2:30:15 PM\t03/05/24 02:30 PM\t123456789\t{12345678-1234-1234-1234-123456789012}\t1 minute 30 seconds\t \tLT P133 All Types: 7\t-4');
        Observer.Verify();
    end;

    [Test]
    procedure NP3_FormatRecord_Temporary_AndFlowField_0And9()
    var
        Observer: Codeunit "Probe Observer";
        Temp: Record "LT P133 All Types" temporary;
        Flow: Record "LT NP3 Fmt Flow";
        Stored: Record "LT P133 All Types";
    begin
        FillAll(Temp);
        Temp.Insert();
        Observer.Observe('temporary_9', Format(Temp, 0, 9));
        Flow.DeleteAll();
        Flow.Id := 3;
        Flow.Cd := 'ABC';
        Flow.Dt := DMY2Date(5, 3, 2024);
        Flow.Amount := 12.5;
        Flow.Insert();
        Stored.DeleteAll();
        Stored.Id := 1;
        Stored.Insert();
        Stored.Id := 2;
        Stored.Insert();
        Observer.Observe('flow_0', Format(Flow, 0, 0));
        Observer.Observe('flow_9', Format(Flow, 0, 9));
        Flow.CalcFields(Total);
        Observer.Observe('flow_calculated_0', Format(Flow, 0, 0));
        Observer.Observe('flow_calculated_9', Format(Flow, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure NP3_FormatRecordRef_StandardFormats_0And9()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT P133 All Types";
        Temp: Record "LT P133 All Types" temporary;
        Flow: Record "LT NP3 Fmt Flow";
        Stored: Record "LT P133 All Types";
        RecRef: RecordRef;
    begin
        Rec.DeleteAll();
        RecRef.GetTable(Rec);
        Observer.Observe('blank_default', Format(RecRef));
        Observer.Observe('blank_0', Format(RecRef, 0, 0));
        Observer.Observe('blank_9', Format(RecRef, 0, 9));
        FillAll(Rec);
        RecRef.GetTable(Rec);
        Observer.Observe('filled_default', Format(RecRef));
        Observer.Observe('filled_0', Format(RecRef, 0, 0));
        Observer.Observe('filled_9', Format(RecRef, 0, 9));
        FillAll(Temp);
        Temp.Insert();
        RecRef.GetTable(Temp);
        Observer.Observe('temporary_9', Format(RecRef, 0, 9));
        Flow.DeleteAll();
        Flow.Id := 3;
        Flow.Cd := 'ABC';
        Flow.Dt := DMY2Date(5, 3, 2024);
        Flow.Amount := 12.5;
        Flow.Insert();
        Stored.Id := 1;
        Stored.Insert();
        Stored.Id := 2;
        Stored.Insert();
        RecRef.GetTable(Flow);
        Observer.Observe('flow_0', Format(RecRef, 0, 0));
        Observer.Observe('flow_9', Format(RecRef, 0, 9));
        RecRef.Field(4).CalcField();
        Observer.Observe('flow_calculated_9', Format(RecRef, 0, 9));
        Observer.Finish();
    end;

    [Test]
    procedure NP3_FormatRecordRef_NotOpen()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Txt: Text;
    begin
        Txt := Format(RecRef, 0, 9);
        Observer.Observe('not_open_9', Txt);
        Txt := Format(RecRef);
        Observer.Observe('not_open_default', Txt);
        Observer.Expect('not_open_9', '');
        Observer.Expect('not_open_default', '');
        Observer.Verify();
    end;
}
