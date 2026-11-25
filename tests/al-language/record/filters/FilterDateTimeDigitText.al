// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope. SetFilter on a DateTime and on a Date field with date texts written as digits only (2, 4, 6, 8 and 9 digits), in ranges, with operators and in an or-list, in the en-US session and under GlobalLanguage 1031.
// Fixtures used: Probe Observer (codeunit 69160); own objects 77802-77803 (FC DT Row, Filter DateTime Digit Text)
// Probe: from al-runner issue 8090 (DateTime SetFilter with '01012001'). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: a DateTime or Date filter written as 8 or 6 digits is read as day, month and year or month, day and year by the session's date order (and the language 1031 changes it); 8 digits that fit no order, or 9 digits, raise the error as asserted; the filter text GetFilter shows is asserted. The 4 and 2 digit forms depend on the current date and are not asserted.
// BC versions: 27, 28, 29

table 77802 "FC DT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; At; DateTime) { }
        field(3; D; Date) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

codeunit 77803 "Filter DateTime Digit Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Add(var Row: Record "FC DT Row"; RowCode: Code[20]; Day: Integer; Month: Integer; Year: Integer; Clock: Time)
    begin
        Row.Init();
        Row."Code" := RowCode;
        Row.D := DMY2Date(Day, Month, Year);
        Row.At := CreateDateTime(Row.D, Clock);
        Row.Insert();
    end;

    // R1 2001-01-01 00:00, R2 2001-01-01 12:00, R3 2001-01-01 23:59:59, R4 2001-01-02 00:00, R5 2001-12-01 08:00,
    // R6 2001-01-12 08:00, R7 2000-12-31 23:00, R8 2001-02-01 08:00 (session time zone).
    local procedure Seed(var Row: Record "FC DT Row")
    begin
        Row.Reset();
        Row.DeleteAll();
        Add(Row, 'R1', 1, 1, 2001, 000000T);
        Add(Row, 'R2', 1, 1, 2001, 120000T);
        Add(Row, 'R3', 1, 1, 2001, 235959T);
        Add(Row, 'R4', 2, 1, 2001, 000000T);
        Add(Row, 'R5', 1, 12, 2001, 080000T);
        Add(Row, 'R6', 12, 1, 2001, 080000T);
        Add(Row, 'R7', 31, 12, 2000, 230000T);
        Add(Row, 'R8', 1, 2, 2001, 080000T);
        Row.Reset();
    end;

    [TryFunction]
    local procedure TrySetFilter(var Row: Record "FC DT Row"; OnDate: Boolean; Filter: Text)
    begin
        if OnDate then
            Row.SetFilter(D, Filter)
        else
            Row.SetFilter(At, Filter);
    end;

    local procedure Probe(var Row: Record "FC DT Row"; OnDate: Boolean; Filter: Text): Text
    var
        Result: Text;
    begin
        Row.Reset();
        if not TrySetFilter(Row, OnDate, Filter) then
            exit('error: ' + GetLastErrorText());
        if Row.FindSet() then
            repeat
                Result += Row."Code" + ',';
            until Row.Next() = 0;
        if OnDate then
            exit(Result + '|' + Row.GetFilter(D));
        exit(Result + '|' + Row.GetFilter(At));
    end;

    local procedure ObserveAll(var Observer: Codeunit "Probe Observer"; var Row: Record "FC DT Row"; OnDate: Boolean)
    begin
        Observer.Observe('d8_01012001', Probe(Row, OnDate, '01012001'));
        Observer.Observe('d8_12012001', Probe(Row, OnDate, '12012001'));
        Observer.Observe('d8_01122001', Probe(Row, OnDate, '01122001'));
        Observer.Observe('d8_20010101', Probe(Row, OnDate, '20010101'));
        Observer.Observe('d8_31122000', Probe(Row, OnDate, '31122000'));
        Observer.Observe('d6_010101', Probe(Row, OnDate, '010101'));
        Observer.Observe('d6_120101', Probe(Row, OnDate, '120101'));
        Observer.Observe('range8', Probe(Row, OnDate, '01012001..02012001'));
        Observer.Observe('ge8', Probe(Row, OnDate, '>=01022001'));
        Observer.Observe('lt8', Probe(Row, OnDate, '<01012001'));
        Observer.Observe('or8', Probe(Row, OnDate, '01012001|12012001'));
        Observer.Observe('d9_010120011', Probe(Row, OnDate, '010120011'));
        Observer.Observe('d8_13132001', Probe(Row, OnDate, '13132001'));
    end;

    [Test]
    procedure SetFilter_DateTime_DigitTexts()
    var
        Row: Record "FC DT Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveAll(Observer, Row, false);
        Observer.Expect('d8_01012001', 'R1,R2,R3,|01/01/01 12:00 AM..01/01/01 11:59:59 PM');
        Observer.Expect('d8_12012001', 'R5,|12/01/01 12:00 AM..12/01/01 11:59:59 PM');
        Observer.Expect('d8_01122001', 'R6,|01/12/01 12:00 AM..01/12/01 11:59:59 PM');
        Observer.Expect('d8_20010101', 'error: The filter "20010101" is not valid for the At field on the FC DT Row table. The value "20010101" can''t be evaluated into type DateTime.');
        Observer.Expect('d8_31122000', 'error: The filter "31122000" is not valid for the At field on the FC DT Row table. The value "31122000" can''t be evaluated into type DateTime.');
        Observer.Expect('d6_010101', 'R1,R2,R3,|01/01/01 12:00 AM..01/01/01 11:59:59 PM');
        Observer.Expect('d6_120101', 'R5,|12/01/01 12:00 AM..12/01/01 11:59:59 PM');
        Observer.Expect('range8', 'R1,R2,R3,R4,R6,R8,|01/01/01 12:00 AM..02/01/01 11:59:59 PM');
        Observer.Expect('ge8', 'R4,R5,R6,R8,|>=01/02/01 12:00 AM');
        Observer.Expect('lt8', 'R7,|<01/01/01 12:00 AM');
        Observer.Expect('or8', 'R1,R2,R3,R5,|01/01/01 12:00 AM..01/01/01 11:59:59 PM|12/01/01 12:00 AM..12/01/01 11:59:59 PM');
        Observer.Expect('d9_010120011', 'error: The filter "010120011" is not valid for the At field on the FC DT Row table. The value "010120011" can''t be evaluated into type DateTime.');
        Observer.Expect('d8_13132001', 'error: The filter "13132001" is not valid for the At field on the FC DT Row table. The value "13132001" can''t be evaluated into type DateTime.');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_DigitTexts()
    var
        Row: Record "FC DT Row";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(Row);
        ObserveAll(Observer, Row, true);
        Observer.Expect('d8_01012001', 'R1,R2,R3,|01/01/01');
        Observer.Expect('d8_12012001', 'R5,|12/01/01');
        Observer.Expect('d8_01122001', 'R6,|01/12/01');
        Observer.Expect('d8_20010101', 'error: The filter "20010101" is not valid for the D field on the FC DT Row table. The format of the Date ''20010101'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('d8_31122000', 'error: The filter "31122000" is not valid for the D field on the FC DT Row table. The format of the Date ''31122000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('d6_010101', 'R1,R2,R3,|01/01/01');
        Observer.Expect('d6_120101', 'R5,|12/01/01');
        Observer.Expect('range8', 'R1,R2,R3,R4,R6,R8,|01/01/01..02/01/01');
        Observer.Expect('ge8', 'R4,R5,R6,R8,|>=01/02/01');
        Observer.Expect('lt8', 'R7,|<01/01/01');
        Observer.Expect('or8', 'R1,R2,R3,R5,|01/01/01|12/01/01');
        Observer.Expect('d9_010120011', 'error: The filter "010120011" is not valid for the D field on the FC DT Row table. The format of the Date ''010120011'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('d8_13132001', 'error: The filter "13132001" is not valid for the D field on the FC DT Row table. The format of the Date ''13132001'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_DateTime_DigitTexts_GlobalLanguage1031()
    var
        Row: Record "FC DT Row";
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Seed(Row);
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        Observer.Observe('d8_01012001', Probe(Row, false, '01012001'));
        Observer.Observe('d8_12012001', Probe(Row, false, '12012001'));
        Observer.Observe('d6_120101', Probe(Row, false, '120101'));
        Observer.Observe('range8', Probe(Row, false, '01012001..02012001'));
        GlobalLanguage(Saved);
        Observer.Expect('d8_01012001', 'R1,R2,R3,|01/01/01 12:00 AM..01/01/01 11:59:59 PM');
        Observer.Expect('d8_12012001', 'R5,|12/01/01 12:00 AM..12/01/01 11:59:59 PM');
        Observer.Expect('d6_120101', 'R5,|12/01/01 12:00 AM..12/01/01 11:59:59 PM');
        Observer.Expect('range8', 'R1,R2,R3,R4,R6,R8,|01/01/01 12:00 AM..02/01/01 11:59:59 PM');
        Observer.Verify();
    end;
}
