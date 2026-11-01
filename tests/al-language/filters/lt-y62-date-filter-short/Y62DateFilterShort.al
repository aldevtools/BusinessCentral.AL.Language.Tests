// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope. Record.SetFilter on a Date field with a text of month and day only, with impossible slash forms, and on a DateTime field with
//   text forms; a query DataItemTableFilter and ColumnFilter that hold 0D.
// Fixtures used: Probe Observer (69160); self-contained table 93260, queries 93260-93266, codeunit 93260
// Probe: gap cycle 6, spec G6-19 (writer Y62). Every literal asserted below is what BC produced (corpus CI 27.5, 28.5, 29.0; SaaS sandbox BC 29).
// Facts: see the test names and the asserted values. The default test language (en-US) is used; the session language is not changed. Two-part
//   texts take their year from a date: the tests set WorkDate to 2030 and 2031 (never this year) and read the year from the rows and filter text.
// Results (same on 27.5, 28.5, 29.0 and the SaaS sandbox): month/day texts (1/1, 1/28, 01/28, 1-28, 1.28, ranges, >, |) take the year of
//   WorkDate; 28/1, 99/99/9999, 13/13/2026, 02/30/2026, 00/00/0000 and 99/99 raise the 'does not match your device's date settings' filter
//   error (Filter:CSide); 1/1/0 reads as 01/01/00. DateTime texts in ISO and en-US forms filter to the minute; 2024-01-01 becomes the whole day.
//   In a query, 0D in DataItemTableFilter or ColumnFilter is the empty date (not today); filter(0D .. 20260101D) and filter(20260101D ..) raise
//   at Open (InvalidFilterExpression:Evaluate); a run-time Query.SetFilter(D, '0D') text means today.
// BC versions: 27, 28, 29

table 93260 "LT Y62 DF Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; Dt; DateTime) { }
        field(4; Amount; Decimal) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 93260 "LT Y62 DFQ NotZero"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            DataItemTableFilter = D = filter(<> 0D);
            column(Id; Id) { }
            column(D; D) { }
            column(Amount; Amount) { ColumnFilter = Amount = filter(> 0); }
        }
    }
}

query 93261 "LT Y62 DFQ Zero"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            DataItemTableFilter = D = filter(0D);
            column(Id; Id) { }
        }
    }
}

query 93262 "LT Y62 DFQ EqZero"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            DataItemTableFilter = D = filter(= 0D);
            column(Id; Id) { }
        }
    }
}

query 93263 "LT Y62 DFQ NotZeroNoSpace"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            DataItemTableFilter = D = filter(<>0D);
            column(Id; Id) { }
        }
    }
}

query 93264 "LT Y62 DFQ ZeroRange"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            DataItemTableFilter = D = filter(0D .. 20260101D);
            column(Id; Id) { }
        }
    }
}

query 93265 "LT Y62 DFQ OpenRange"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            DataItemTableFilter = D = filter(20260101D ..);
            column(Id; Id) { }
        }
    }
}

query 93266 "LT Y62 DFQ ColNotZero"
{
    OrderBy = ascending(Id);

    elements
    {
        dataitem(Row; "LT Y62 DF Row")
        {
            column(Id; Id) { }
            column(D; D) { ColumnFilter = D = filter(<> 0D); }
        }
    }
}

codeunit 93260 "LT Y62 Date Filter Short"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed(WithToday: Boolean)
    var
        Row: Record "LT Y62 DF Row";
    begin
        Row.DeleteAll();
        AddRow(1, 0D, 0DT);
        AddRow(2, 20260101D, CreateDateTime(20240101D, 103000T));
        AddRow(3, 20260128D, CreateDateTime(20260128D, 103000T));
        AddRow(4, 20260202D, CreateDateTime(20260202D, 103000T));
        AddRow(6, 20300101D, CreateDateTime(20300101D, 103000T));
        AddRow(7, 20300128D, CreateDateTime(20300128D, 103000T));
        AddRow(8, 20310128D, CreateDateTime(20310128D, 103000T));
        if WithToday then
            AddRow(5, Today(), CreateDateTime(Today(), 103000T));
    end;

    local procedure AddRow(NewId: Integer; NewDate: Date; NewDt: DateTime)
    var
        Row: Record "LT Y62 DF Row";
    begin
        Row.Id := NewId;
        Row.D := NewDate;
        Row.Dt := NewDt;
        Row.Amount := 1;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryFilter(var Row: Record "LT Y62 DF Row"; Txt: Text)
    begin
        Row.SetFilter(D, Txt);
    end;

    [TryFunction]
    local procedure TryFilterDt(var Row: Record "LT Y62 DF Row"; Txt: Text)
    begin
        Row.SetFilter(Dt, Txt);
    end;

    local procedure Scrub(Txt: Text): Text
    begin
        exit(Txt.Replace(Format(Today()), '<today>'));
    end;

    local procedure Ids(var Row: Record "LT Y62 DF Row"): Text
    var
        Txt: Text;
    begin
        if Row.FindSet() then
            repeat
                if Row.Id = 5 then
                    Txt += 'today,'
                else
                    Txt += Format(Row.Id) + ',';
            until Row.Next() = 0;
        exit(Txt);
    end;

    local procedure Failed(): Text
    begin
        exit('error:' + Scrub(GetLastErrorText()) + '|' + GetLastErrorCode());
    end;

    local procedure Apply(Txt: Text): Text
    var
        Row: Record "LT Y62 DF Row";
    begin
        ClearLastError();
        if TryFilter(Row, Txt) then
            exit('ok|filter=' + Scrub(Row.GetFilter(D)) + '|rows=' + Ids(Row));
        exit(Failed());
    end;

    local procedure ApplyDt(Txt: Text): Text
    var
        Row: Record "LT Y62 DF Row";
    begin
        ClearLastError();
        if TryFilterDt(Row, Txt) then
            exit('ok|filter=' + Scrub(Row.GetFilter(Dt)) + '|rows=' + Ids(Row));
        exit(Failed());
    end;

    local procedure ObserveList(var Observer: Codeunit "Probe Observer"; Texts: List of [Text]; Prefix: Text)
    var
        i: Integer;
    begin
        for i := 1 to Texts.Count() do
            Observer.Observe(Prefix + Format(i) + '[' + Texts.Get(i) + ']', Apply(Texts.Get(i)));
    end;

    local procedure MonthDayTexts() Texts: List of [Text]
    begin
        Texts.Add('1/1');
        Texts.Add('1/28');
        Texts.Add('01/28');
        Texts.Add('28/1');
        Texts.Add('1-28');
        Texts.Add('1.28');
        Texts.Add('1/1..2/2');
        Texts.Add('>1/28');
        Texts.Add('1/28|2/2');
    end;

    [Test]
    procedure SetFilter_Date_MonthDayOnly_WorkDate2030()
    var
        Observer: Codeunit "Probe Observer";
        OldWorkDate: Date;
    begin
        Seed(false);
        OldWorkDate := WorkDate();
        WorkDate(20300615D);
        ObserveList(Observer, MonthDayTexts(), 'a');
        WorkDate(OldWorkDate);
        Observer.Expect('a1[1/1]', 'ok|filter=01/01/30|rows=6,');
        Observer.Expect('a2[1/28]', 'ok|filter=01/28/30|rows=7,');
        Observer.Expect('a3[01/28]', 'ok|filter=01/28/30|rows=7,');
        Observer.Expect('a4[28/1]', 'error:The filter "28/1" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''28/1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('a5[1-28]', 'ok|filter=01/28/30|rows=7,');
        Observer.Expect('a6[1.28]', 'ok|filter=01/28/30|rows=7,');
        Observer.Expect('a7[1/1..2/2]', 'ok|filter=01/01/30..02/02/30|rows=6,7,');
        Observer.Expect('a8[>1/28]', 'ok|filter=>01/28/30|rows=8,');
        Observer.Expect('a9[1/28|2/2]', 'ok|filter=01/28/30|02/02/30|rows=7,');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_MonthDayOnly_WorkDate2031()
    var
        Observer: Codeunit "Probe Observer";
        OldWorkDate: Date;
    begin
        Seed(false);
        OldWorkDate := WorkDate();
        WorkDate(20310615D);
        ObserveList(Observer, MonthDayTexts(), 'b');
        WorkDate(OldWorkDate);
        Observer.Expect('b1[1/1]', 'ok|filter=01/01/31|rows=');
        Observer.Expect('b2[1/28]', 'ok|filter=01/28/31|rows=8,');
        Observer.Expect('b3[01/28]', 'ok|filter=01/28/31|rows=8,');
        Observer.Expect('b4[28/1]', 'error:The filter "28/1" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''28/1'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('b5[1-28]', 'ok|filter=01/28/31|rows=8,');
        Observer.Expect('b6[1.28]', 'ok|filter=01/28/31|rows=8,');
        Observer.Expect('b7[1/1..2/2]', 'ok|filter=01/01/31..02/02/31|rows=8,');
        Observer.Expect('b8[>1/28]', 'ok|filter=>01/28/31|rows=');
        Observer.Expect('b9[1/28|2/2]', 'ok|filter=01/28/31|02/02/31|rows=8,');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_SlashWithYear()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        OldWorkDate: Date;
    begin
        Seed(false);
        OldWorkDate := WorkDate();
        WorkDate(20300615D);
        Texts.Add('1/1/2026..2/2/2026');
        Texts.Add('>1/1/2026');
        Texts.Add('<=' + Format(20260128D));
        Texts.Add('1/1/26');
        Texts.Add('1/28/2030');
        ObserveList(Observer, Texts, 'y');
        Observer.Observe('formatted', Format(20260128D));
        WorkDate(OldWorkDate);
        Observer.Expect('y1[1/1/2026..2/2/2026]', 'ok|filter=01/01/26..02/02/26|rows=2,3,4,');
        Observer.Expect('y2[>1/1/2026]', 'ok|filter=>01/01/26|rows=3,4,6,7,8,');
        Observer.Expect('y3[<=01/28/26]', 'ok|filter=<=01/28/26|rows=1,2,3,');
        Observer.Expect('y4[1/1/26]', 'ok|filter=01/01/26|rows=2,');
        Observer.Expect('y5[1/28/2030]', 'ok|filter=01/28/30|rows=7,');
        Observer.Expect('formatted', '01/28/26');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_ImpossibleSlashForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        OldWorkDate: Date;
    begin
        Seed(false);
        OldWorkDate := WorkDate();
        WorkDate(20300615D);
        Texts.Add('99/99/9999');
        Texts.Add('13/13/2026');
        Texts.Add('02/30/2026');
        Texts.Add('00/00/0000');
        ObserveList(Observer, Texts, 'i');
        WorkDate(OldWorkDate);
        Observer.Expect('i1[99/99/9999]', 'error:The filter "99/99/9999" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''99/99/9999'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i2[13/13/2026]', 'error:The filter "13/13/2026" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''13/13/2026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i3[02/30/2026]', 'error:The filter "02/30/2026" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''02/30/2026'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('i4[00/00/0000]', 'error:The filter "00/00/0000" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''00/00/0000'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_Date_ImpossibleShortForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        OldWorkDate: Date;
    begin
        Seed(false);
        OldWorkDate := WorkDate();
        WorkDate(20300615D);
        Texts.Add('1/1/0');
        Texts.Add('99/99');
        Texts.Add('not a date');
        Texts.Add('1/1/99999');
        ObserveList(Observer, Texts, 'j');
        WorkDate(OldWorkDate);
        Observer.Expect('j1[1/1/0]', 'ok|filter=01/01/00|rows=');
        Observer.Expect('j2[99/99]', 'error:The filter "99/99" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''99/99'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('j3[not a date]', 'error:The filter "not a date" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''not a date'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Expect('j4[1/1/99999]', 'error:The filter "1/1/99999" is not valid for the D field on the LT Y62 DF Row table. The format of the Date ''1/1/99999'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.|Filter:CSide');
        Observer.Verify();
    end;

    [Test]
    procedure SetFilter_DateTime_TextForms()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        i: Integer;
    begin
        Seed(false);
        Texts.Add('2024-01-01 10:30:00');
        Texts.Add('01/01/24 10:30:00');
        Texts.Add('01/01/2024 10:30:00 AM');
        Texts.Add('99/99/9999 99:99:99');
        Texts.Add('not a datetime');
        Texts.Add('2024-01-01');
        for i := 1 to Texts.Count() do
            Observer.Observe('t' + Format(i) + '[' + Texts.Get(i) + ']', ApplyDt(Texts.Get(i)));
        Observer.Expect('t1[2024-01-01 10:30:00]', 'ok|filter=01/01/24 10:30 AM|rows=2,');
        Observer.Expect('t2[01/01/24 10:30:00]', 'ok|filter=01/01/24 10:30 AM|rows=2,');
        Observer.Expect('t3[01/01/2024 10:30:00 AM]', 'ok|filter=01/01/24 10:30 AM|rows=2,');
        Observer.Expect('t4[99/99/9999 99:99:99]', 'error:The filter "99/99/9999 99:99:99" is not valid for the Dt field on the LT Y62 DF Row table. The value "99/99/9999 99:99:99" can''t be evaluated into type DateTime.|Filter:CSide');
        Observer.Expect('t5[not a datetime]', 'error:The filter "not a datetime" is not valid for the Dt field on the LT Y62 DF Row table. The value "not a datetime" can''t be evaluated into type DateTime.|Filter:CSide');
        Observer.Expect('t6[2024-01-01]', 'ok|filter=01/01/24 12:00 AM..01/01/24 11:59:59 PM|rows=2,');
        Observer.Verify();
    end;

    local procedure ReadNotZero(var Q: Query "LT Y62 DFQ NotZero"): Text
    var
        Txt: Text;
    begin
        Q.Open();
        while Q.Read() do
            if Q.Id = 5 then
                Txt += 'today,'
            else
                Txt += Format(Q.Id) + ',';
        Q.Close();
        exit(Txt);
    end;

    [TryFunction]
    local procedure TryNotZero(var Txt: Text)
    var
        Q: Query "LT Y62 DFQ NotZero";
    begin
        Txt := ReadNotZero(Q);
    end;

    [Test]
    procedure Query_DataItemTableFilter_NotZeroDate()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y62 DF Row";
        Txt: Text;
    begin
        Seed(false);
        Row.Get(4);
        Row.Amount := 0;
        Row.Modify();
        if TryNotZero(Txt) then
            Observer.Observe('rows', Txt)
        else
            Observer.ObserveError('rows');
        Seed(true);
        Txt := '';
        if TryNotZero(Txt) then
            Observer.Observe('rows with today', Txt)
        else
            Observer.ObserveError('rows with today');
        Observer.Expect('rows', '2,3,6,7,8,');
        Observer.Expect('rows with today', '2,3,4,today,6,7,8,');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRead(QueryNo: Integer; var Txt: Text)
    var
        QZero: Query "LT Y62 DFQ Zero";
        QEq: Query "LT Y62 DFQ EqZero";
        QNs: Query "LT Y62 DFQ NotZeroNoSpace";
        QRange: Query "LT Y62 DFQ ZeroRange";
        QOpen: Query "LT Y62 DFQ OpenRange";
    begin
        Txt := '';
        case QueryNo of
            1:
                begin
                    QZero.Open();
                    while QZero.Read() do
                        Txt += IdText(QZero.Id);
                end;
            2:
                begin
                    QEq.Open();
                    while QEq.Read() do
                        Txt += IdText(QEq.Id);
                end;
            3:
                begin
                    QNs.Open();
                    while QNs.Read() do
                        Txt += IdText(QNs.Id);
                end;
            4:
                begin
                    QRange.Open();
                    while QRange.Read() do
                        Txt += IdText(QRange.Id);
                end;
            5:
                begin
                    QOpen.Open();
                    while QOpen.Read() do
                        Txt += IdText(QOpen.Id);
                end;
        end;
    end;

    local procedure IdText(Id: Integer): Text
    begin
        if Id = 5 then
            exit('today,');
        exit(Format(Id) + ',');
    end;

    [Test]
    procedure Query_DataItemTableFilter_ZeroDateForms()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
        Txt: Text;
        i: Integer;
    begin
        Seed(true);
        Names.Add('filter(0D)');
        Names.Add('filter(= 0D)');
        Names.Add('filter(<>0D)');
        Names.Add('filter(0D .. 20260101D)');
        Names.Add('filter(20260101D ..)');
        for i := 1 to Names.Count() do
            if TryRead(i, Txt) then
                Observer.Observe(Names.Get(i), Txt)
            else
                Observer.ObserveError(Names.Get(i));
        Observer.Expect('filter(0D)', '1,');
        Observer.Expect('filter(= 0D)', '1,');
        Observer.Expect('filter(<>0D)', '2,3,4,today,6,7,8,');
        Observer.Expect('filter(0D .. 20260101D)|text', 'The format of the Date ''20260101D'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('filter(0D .. 20260101D)|code', 'InvalidFilterExpression:Evaluate');
        Observer.Expect('filter(20260101D ..)|text', 'The format of the Date ''20260101D'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('filter(20260101D ..)|code', 'InvalidFilterExpression:Evaluate');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryColumn(Mode: Integer; var Txt: Text)
    var
        Q: Query "LT Y62 DFQ ColNotZero";
    begin
        Txt := '';
        case Mode of
            2:
                Q.SetFilter(D, '<>%1', 0D);
            3:
                Q.SetFilter(D, '0D');
            4:
                Q.SetRange(D, 0D);
        end;
        Q.Open();
        while Q.Read() do
            Txt += IdText(Q.Id);
    end;

    [Test]
    procedure Query_ColumnFilter_ZeroDate_AndRuntimeFilters()
    var
        Observer: Codeunit "Probe Observer";
        Names: List of [Text];
        Txt: Text;
        i: Integer;
    begin
        Seed(true);
        Names.Add('static ColumnFilter <> 0D');
        Names.Add('SetFilter <>%1 with 0D');
        Names.Add('SetFilter text 0D');
        Names.Add('SetRange 0D');
        for i := 1 to Names.Count() do
            if TryColumn(i, Txt) then
                Observer.Observe(Names.Get(i), Txt)
            else
                Observer.ObserveError(Names.Get(i));
        Observer.Expect('static ColumnFilter <> 0D', '2,3,4,today,6,7,8,');
        Observer.Expect('SetFilter <>%1 with 0D', '2,3,4,today,6,7,8,');
        Observer.Expect('SetFilter text 0D', 'today,');
        Observer.Expect('SetRange 0D', '1,');
        Observer.Verify();
    end;
}
