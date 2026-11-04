// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: own table 73548, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: SetFilter on a Date field with a literal TEXT (no %1): the session's own formatted date (Format(D) and Format(D, 0, 0..9)), custom formats, 6 and 8 digit forms,
//   separators, month names, operators with those texts, an empty text, '', <>'', blanks, date words and formulas (T, W, CM, 1M ...), count and GetFilter, or the error text and code
// Settles issue 130 reasons 7, 14, 21, 22 (SetFilter: text filter value for Date: an empty '', a formula such as 1M, a region's date format)
// BC versions: 29 (27 and 28 by CI)

table 73548 "LT P130 Filter Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Dt; Date) { }
        field(3; Gd; Guid) { }
        field(4; Tm; Time) { }
        field(5; Dtm; DateTime) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 73549 "LT P130 Date Filters"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        Add(1, 20240102D);
        Add(2, 20240103D);
        Add(3, 20240104D);
        Add(4, 20240301D);
        Add(5, 20240305D);
        Add(6, 20241231D);
        Add(7, 0D);
    end;

    local procedure Add(Id: Integer; D: Date)
    var
        R: Record "LT P130 Filter Row";
    begin
        R.Id := Id;
        R.Dt := D;
        R.Insert();
    end;

    [TryFunction]
    local procedure TrySet(var R: Record "LT P130 Filter Row"; FilterText: Text)
    begin
        R.SetFilter(Dt, FilterText);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Name: Text; FilterText: Text)
    var
        R: Record "LT P130 Filter Row";
    begin
        if TrySet(R, FilterText) then
            Observer.Observe(Name, 'ok count=' + Format(R.Count()) + ' filter=' + R.GetFilter(Dt))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;





    [Test]
    procedure P130_DateFilter_OperatorsWithSessionFormat()
    var
        Observer: Codeunit "Probe Observer";
        D1: Date;
        D2: Date;
    begin
        Seed();
        D1 := 20240103D;
        D2 := 20240301D;
        Probe(Observer, 'ge', '>=' + Format(D1));
        Probe(Observer, 'gt', '>' + Format(D1));
        Probe(Observer, 'le', '<=' + Format(D1));
        Probe(Observer, 'lt', '<' + Format(D1));
        Probe(Observer, 'ne', '<>' + Format(D1));
        Probe(Observer, 'range', Format(D1) + '..' + Format(D2));
        Probe(Observer, 'open_start', '..' + Format(D1));
        Probe(Observer, 'open_end', Format(D1) + '..');
        Probe(Observer, 'or', Format(D1) + '|' + Format(D2));
        Probe(Observer, 'range_or_single', Format(D1) + '..' + Format(D2) + '|' + Format(20241231D));
        Probe(Observer, 'and_ge_le', '>=' + Format(D1) + '&<=' + Format(D2));
        Probe(Observer, 'ne_or', '<>' + Format(D1) + '&<>' + Format(D2));
        Probe(Observer, 'range_reversed', Format(D2) + '..' + Format(D1));
        Probe(Observer, 'spaces_around_range', ' ' + Format(D1) + ' .. ' + Format(D2) + ' ');
        Probe(Observer, 'iso_range', '2024-01-03..2024-03-01');
        Probe(Observer, 'iso_ge', '>=2024-01-03');
        Observer.Expect('ge', 'ok count=5 filter=>=01/03/24');
        Observer.Expect('gt', 'ok count=4 filter=>01/03/24');
        Observer.Expect('le', 'ok count=3 filter=<=01/03/24');
        Observer.Expect('lt', 'ok count=2 filter=<01/03/24');
        Observer.Expect('ne', 'ok count=6 filter=<>01/03/24');
        Observer.Expect('range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('open_start', 'ok count=3 filter=..01/03/24');
        Observer.Expect('open_end', 'ok count=5 filter=01/03/24..');
        Observer.Expect('or', 'ok count=2 filter=01/03/24|03/01/24');
        Observer.Expect('range_or_single', 'ok count=4 filter=01/03/24..03/01/24|12/31/24');
        Observer.Expect('and_ge_le', 'ok count=3 filter=>=01/03/24&<=03/01/24');
        Observer.Expect('ne_or', 'ok count=5 filter=<>01/03/24&<>03/01/24');
        Observer.Expect('range_reversed', 'ok count=0 filter=03/01/24..01/03/24');
        Observer.Expect('spaces_around_range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('iso_range', 'ok count=3 filter=01/03/24..03/01/24');
        Observer.Expect('iso_ge', 'ok count=5 filter=>=01/03/24');
        Observer.Verify();
    end;

    // Corpus issue 672 item 2 (AL issue 7325): the value of a DateTime and a Time field after Insert, read back with Get into another
    // record variable, for 1 to 9, 998 and 999 milliseconds (value read back | read back = value written | written variable = value).
    [Test]
    procedure BT_DateTimeAndTime_MillisecondsAfterWrite()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P130 Filter Row";
        Back: Record "LT P130 Filter Row";
        Ms: List of [Integer];
        M: Integer;
        T: Time;
        DT: DateTime;
    begin
        R.DeleteAll();
        Ms.AddRange(1, 2, 3, 4, 5, 6, 7, 8, 9, 998, 999);
        foreach M in Ms do begin
            T := 000000T + M;
            DT := CreateDateTime(20240325D, T);
            R.Init();
            R.Id := M;
            R.Tm := T;
            R.Dtm := DT;
            R.Insert();
            Back.Get(M);
            Observer.Observe('dtm ' + Format(M), Format(Back.Dtm, 0, 9) + '|' + Format(Back.Dtm = DT) + '|' + Format(R.Dtm = DT));
            Observer.Observe('tm ' + Format(M), Format(Back.Tm, 0, 9) + '|' + Format(Back.Tm = T) + '|' + Format(R.Tm = T));
        end;
        Observer.Expect('dtm 1', '2024-03-25T00:00:00Z|No|Yes');
        Observer.Expect('tm 1', '00:00:00|No|Yes');
        Observer.Expect('dtm 2', '2024-03-25T00:00:00.003Z|No|Yes');
        Observer.Expect('tm 2', '00:00:00.003|No|Yes');
        Observer.Expect('dtm 3', '2024-03-25T00:00:00.003Z|Yes|Yes');
        Observer.Expect('tm 3', '00:00:00.003|Yes|Yes');
        Observer.Expect('dtm 4', '2024-03-25T00:00:00.003Z|No|Yes');
        Observer.Expect('tm 4', '00:00:00.003|No|Yes');
        Observer.Expect('dtm 5', '2024-03-25T00:00:00.007Z|No|Yes');
        Observer.Expect('tm 5', '00:00:00.007|No|Yes');
        Observer.Expect('dtm 6', '2024-03-25T00:00:00.007Z|No|Yes');
        Observer.Expect('tm 6', '00:00:00.007|No|Yes');
        Observer.Expect('dtm 7', '2024-03-25T00:00:00.007Z|Yes|Yes');
        Observer.Expect('tm 7', '00:00:00.007|Yes|Yes');
        Observer.Expect('dtm 8', '2024-03-25T00:00:00.007Z|No|Yes');
        Observer.Expect('tm 8', '00:00:00.007|No|Yes');
        Observer.Expect('dtm 9', '2024-03-25T00:00:00.01Z|No|Yes');
        Observer.Expect('tm 9', '00:00:00.01|No|Yes');
        Observer.Expect('dtm 998', '2024-03-25T00:00:00.997Z|No|Yes');
        Observer.Expect('tm 998', '00:00:00.997|No|Yes');
        Observer.Expect('dtm 999', '2024-03-25T00:00:01Z|No|Yes');
        Observer.Expect('tm 999', '00:00:01|No|Yes');
        Observer.Verify();
    end;

    // Corpus issue 672 item 2: a DateTime range whose upper end is 23:59:59.999 (rows stored at 2024-03-25 00:00:00.000 and at
    // 2024-03-24 23:59:59.997), GetFilters of that range, and equality filters with a millisecond the database cannot hold.
    [Test]
    procedure BT_DateTimeFilter_999Milliseconds()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P130 Filter Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.Dtm := CreateDateTime(20240325D, 000000T);
        R.Insert();
        R.Init();
        R.Id := 2;
        R.Dtm := CreateDateTime(20240324D, 235959.997T);
        R.Insert();
        R.Init();
        R.Id := 3;
        R.Tm := 120000T;
        R.Insert();
        R.Reset();
        R.SetRange(Dtm, CreateDateTime(20240301D, 000000T), CreateDateTime(20240324D, 235959.999T));
        Observer.Observe('to .999 count', Format(R.Count()));
        Observer.Observe('to .999 getfilters', R.GetFilters());
        R.SetRange(Dtm, CreateDateTime(20240301D, 000000T), CreateDateTime(20240324D, 235959.998T));
        Observer.Observe('to .998 count', Format(R.Count()));
        R.SetRange(Dtm, CreateDateTime(20240301D, 000000T), CreateDateTime(20240324D, 235959.996T));
        Observer.Observe('to .996 count', Format(R.Count()));
        R.SetRange(Dtm, CreateDateTime(20240325D, 000000.001T));
        Observer.Observe('eq .001 count', Format(R.Count()));
        R.SetRange(Dtm, CreateDateTime(20240324D, 235959.999T));
        Observer.Observe('eq prev .999 count', Format(R.Count()));
        R.SetRange(Dtm);
        R.SetRange(Tm, 120000.001T);
        Observer.Observe('time eq .001 count', Format(R.Count()));
        R.SetRange(Tm, 120000.002T);
        Observer.Observe('time eq .002 count', Format(R.Count()));
        Observer.Expect('to .999 count', '2');
        Observer.Expect('to .999 getfilters', 'Dtm: 03/01/24 12:00 AM..03/24/24 11:59:59.999 PM');
        Observer.Expect('to .998 count', '1');
        Observer.Expect('to .996 count', '1');
        Observer.Expect('eq .001 count', '1');
        Observer.Expect('eq prev .999 count', '1');
        Observer.Expect('time eq .001 count', '1');
        Observer.Expect('time eq .002 count', '0');
        Observer.Verify();
    end;

    // Builds the values inside the asserterror (DMY2Date, ClosingDate, CreateDateTime), so an error of any step is captured; Stage names
    // the step that ran last.
    local procedure StoreDates(var Observer: Codeunit "Probe Observer"; Name: Text; Y: Integer; Mo: Integer; Dd: Integer; Closing: Boolean; DtY: Integer; DtMo: Integer; DtDd: Integer; DtTime: Time)
    var
        R: Record "LT P130 Filter Row";
        Back: Record "LT P130 Filter Row";
        D: Date;
        DT: DateTime;
        Stage: Text;
    begin
        R.DeleteAll();
        ClearLastError();
        asserterror begin
            Stage := 'date';
            if Y <> 0 then
                D := DMY2Date(Dd, Mo, Y);
            Stage := 'closingdate';
            if Closing then
                D := ClosingDate(D);
            Stage := 'createdatetime';
            if DtY <> 0 then
                DT := CreateDateTime(DMY2Date(DtDd, DtMo, DtY), DtTime);
            Stage := 'insert';
            R.Init();
            R.Id := 900;
            R.Dt := D;
            R.Dtm := DT;
            R.Insert();
            Stage := 'get';
            Back.Get(900);
            Stage := 'stored';
            Error('stored:' + Format(Back.Dt, 0, 9) + '|' + Format(Back.Dtm, 0, 9) + '|' + Format(Back.Dt = D) + '|' + Format(Back.Dtm = DT));
        end;
        Observer.Observe(Name + '|stage', Stage);
        Observer.ObserveError(Name);
    end;

    // Corpus issue 672 item 8: Insert of a Date and a DateTime outside the SQL datetime range (before 1753-01-01, after
    // 9999-12-31 23:59:59.997) and of 0D / 0DT: the step that failed and its error, or what Get reads back
    // (stored:Dt | Dtm | Dt = written | Dtm = written).
    [Test]
    procedure BT_DateAndDateTime_SqlRangeOnInsert()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoreDates(Observer, 'blank', 0, 0, 0, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date 1753-01-01', 1753, 1, 1, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date 1752-12-31', 1752, 12, 31, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date 0001-01-01', 1, 1, 1, false, 0, 0, 0, 0T);
        StoreDates(Observer, 'date closing 1752-12-31', 1752, 12, 31, true, 0, 0, 0, 0T);
        StoreDates(Observer, 'datetime 1753-01-01 00:00', 0, 0, 0, false, 1753, 1, 1, 000000T);
        StoreDates(Observer, 'datetime 1752-12-31 12:00', 0, 0, 0, false, 1752, 12, 31, 120000T);
        Observer.Expect('blank|stage', 'stored');
        Observer.Expect('blank|text', 'stored:||Yes|Yes');
        Observer.Expect('blank|code', 'Dialog');
        Observer.Expect('date 1753-01-01|stage', 'get');
        Observer.Expect('date 1753-01-01|text', 'Cannot write the value 01/01/1753 to the field Dt in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('date 1753-01-01|code', 'NDBCS:BadCSideData');
        Observer.Expect('date 1752-12-31|stage', 'get');
        Observer.Expect('date 1752-12-31|text', 'Cannot write the value 12/31/1752 to the field Dt in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('date 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('date 0001-01-01|stage', 'stored');
        Observer.Expect('date 0001-01-01|text', 'stored:||Yes|Yes');
        Observer.Expect('date 0001-01-01|code', 'Dialog');
        Observer.Expect('date closing 1752-12-31|stage', 'get');
        Observer.Expect('date closing 1752-12-31|text', 'Cannot write the value C12/31/1752 to the field Dt in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('date closing 1752-12-31|code', 'NDBCS:BadCSideData');
        Observer.Expect('datetime 1753-01-01 00:00|stage', 'get');
        Observer.Expect('datetime 1753-01-01 00:00|text', 'Cannot write the value 01/01/1753 12:00 AM to the field Dtm in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('datetime 1753-01-01 00:00|code', 'NDBCS:BadCSideData');
        Observer.Expect('datetime 1752-12-31 12:00|stage', 'get');
        Observer.Expect('datetime 1752-12-31 12:00|text', 'Cannot write the value 12/31/1752 12:00 PM to the field Dtm in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('datetime 1752-12-31 12:00|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    // Corpus issue 672 item 8, upper end of the SQL datetime range (same form as BT_DateAndDateTime_SqlRangeOnInsert).
    [Test]
    procedure BT_DateAndDateTime_SqlRangeOnInsert_Max()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StoreDates(Observer, 'datetime 9999-12-31 23:59:59.997', 0, 0, 0, false, 9999, 12, 31, 235959.997T);
        StoreDates(Observer, 'datetime 9999-12-31 23:59:59.999', 0, 0, 0, false, 9999, 12, 31, 235959.999T);
        Observer.Expect('datetime 9999-12-31 23:59:59.997|stage', 'stored');
        Observer.Expect('datetime 9999-12-31 23:59:59.997|text', 'stored:|9999-12-31T23:59:59.997Z|Yes|Yes');
        Observer.Expect('datetime 9999-12-31 23:59:59.997|code', 'Dialog');
        Observer.Expect('datetime 9999-12-31 23:59:59.999|stage', 'get');
        Observer.Expect('datetime 9999-12-31 23:59:59.999|text', 'Cannot write the value 12/31/9999 11:59 PM to the field Dtm in the table LT P130 Filter Row because the value is either too long or the content is invalid.');
        Observer.Expect('datetime 9999-12-31 23:59:59.999|code', 'NDBCS:BadCSideData');
        Observer.Verify();
    end;

    // al-runtime-rs backlog (partner gap, owner 2026-10-20, writer QA): a TEMPORARY record's Time and DateTime fields holding milliseconds that the SQL
    // column of a database table rounds (1/300 s; .999 rolls over, see BT_DateTimeAndTime_MillisecondsAfterWrite above): the value after assignment,
    // after Insert (the variable), after Get, a SetRange on the exact value, and after Modify then Get. Each value is Format(Tm, 0, 9)|Format(Dtm, 0, 9).
    // Measured on 27.5, 28.5 and 29.0 (the same): a temporary table keeps the milliseconds whole (.001, .998, .999, 23:59:59.999 do not round or roll
    // over); the rounding happens when the value is written to a database table (Insert of TransferFields, Copy or := of the temporary record).
    local procedure TmDtm(var R: Record "LT P130 Filter Row"): Text
    begin
        exit(Format(R.Tm, 0, 9) + '|' + Format(R.Dtm, 0, 9));
    end;

    [Test]
    procedure QA_TempRecord_Milliseconds_InsertGetModify()
    var
        Observer: Codeunit "Probe Observer";
        TempR: Record "LT P130 Filter Row" temporary;
        Ms: List of [Integer];
        M: Integer;
        T: Time;
        DT: DateTime;
        N: Text;
    begin
        Ms.AddRange(1, 998, 999);
        foreach M in Ms do begin
            N := Format(M) + ' ';
            T := 000000T + M;
            DT := CreateDateTime(20240325D, T);
            TempR.Init();
            TempR.Id := M;
            TempR.Tm := T;
            TempR.Dtm := DT;
            Observer.Observe(N + 'assign', TmDtm(TempR));
            TempR.Insert();
            Observer.Observe(N + 'insert', TmDtm(TempR));
            TempR.Init();
            TempR.Get(M);
            Observer.Observe(N + 'get', TmDtm(TempR) + '|' + Format(TempR.Tm = T) + '|' + Format(TempR.Dtm = DT));
            TempR.SetRange(Tm, T);
            Observer.Observe(N + 'setrange tm', Format(TempR.Count()));
            TempR.SetRange(Tm);
            TempR.SetRange(Dtm, DT);
            Observer.Observe(N + 'setrange dtm', Format(TempR.Count()));
            TempR.SetRange(Dtm);
            TempR.Get(M);
            TempR.Tm := 000001T + M;
            TempR.Dtm := CreateDateTime(20240326D, 000001T + M);
            TempR.Modify();
            TempR.Init();
            TempR.Get(M);
            Observer.Observe(N + 'modify get', TmDtm(TempR));
        end;
        TempR.Init();
        TempR.Id := 5000;
        TempR.Tm := 235959.999T;
        TempR.Dtm := CreateDateTime(20240325D, 235959.999T);
        TempR.Insert();
        TempR.Init();
        TempR.Get(5000);
        Observer.Observe('235959.999 get', TmDtm(TempR));
        Observer.Expect('1 assign', '00:00:00.001|2024-03-25T00:00:00.001Z');
        Observer.Expect('1 insert', '00:00:00.001|2024-03-25T00:00:00.001Z');
        Observer.Expect('1 get', '00:00:00.001|2024-03-25T00:00:00.001Z|Yes|Yes');
        Observer.Expect('1 setrange tm', '1');
        Observer.Expect('1 setrange dtm', '1');
        Observer.Expect('1 modify get', '00:00:01.001|2024-03-26T00:00:01.001Z');
        Observer.Expect('998 assign', '00:00:00.998|2024-03-25T00:00:00.998Z');
        Observer.Expect('998 insert', '00:00:00.998|2024-03-25T00:00:00.998Z');
        Observer.Expect('998 get', '00:00:00.998|2024-03-25T00:00:00.998Z|Yes|Yes');
        Observer.Expect('998 setrange tm', '1');
        Observer.Expect('998 setrange dtm', '1');
        Observer.Expect('998 modify get', '00:00:01.998|2024-03-26T00:00:01.998Z');
        Observer.Expect('999 assign', '00:00:00.999|2024-03-25T00:00:00.999Z');
        Observer.Expect('999 insert', '00:00:00.999|2024-03-25T00:00:00.999Z');
        Observer.Expect('999 get', '00:00:00.999|2024-03-25T00:00:00.999Z|Yes|Yes');
        Observer.Expect('999 setrange tm', '1');
        Observer.Expect('999 setrange dtm', '1');
        Observer.Expect('999 modify get', '00:00:01.999|2024-03-26T00:00:01.999Z');
        Observer.Expect('235959.999 get', '23:59:59.999|2024-03-25T23:59:59.999Z');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryCopy(var Target: Record "LT P130 Filter Row"; var Source: Record "LT P130 Filter Row")
    begin
        Target.Copy(Source);
    end;

    // The same values carried from a temporary record into a database record (TransferFields, Copy, :=, then Insert and Get), and from a database record
    // into a temporary one (TransferFields of the written variable and of the row read back, then Insert and Get of the temporary record).
    [Test]
    procedure QA_TempRecord_Milliseconds_ToAndFromDatabaseRecord()
    var
        Observer: Codeunit "Probe Observer";
        TempR: Record "LT P130 Filter Row" temporary;
        Real: Record "LT P130 Filter Row";
        RealC: Record "LT P130 Filter Row";
        RealA: Record "LT P130 Filter Row";
        RealD: Record "LT P130 Filter Row";
        Back: Record "LT P130 Filter Row";
        Ms: List of [Integer];
        M: Integer;
        T: Time;
        DT: DateTime;
        N: Text;
    begin
        Real.DeleteAll();
        Ms.AddRange(1, 998, 999);
        foreach M in Ms do begin
            N := Format(M) + ' ';
            T := 000000T + M;
            DT := CreateDateTime(20240325D, T);
            TempR.Init();
            TempR.Id := M;
            TempR.Tm := T;
            TempR.Dtm := DT;
            TempR.Insert();
            // temporary -> database
            Real.Init();
            Real.TransferFields(TempR);
            Observer.Observe(N + 'tf var', TmDtm(Real));
            Real.Insert();
            Back.Get(M);
            Observer.Observe(N + 'tf get', TmDtm(Back));
            RealC.Init();
            ClearLastError();
            if TryCopy(RealC, TempR) then begin
                Observer.Observe(N + 'copy var', TmDtm(RealC) + '|temporary=' + Format(RealC.IsTemporary()));
                if not RealC.IsTemporary() then begin
                    RealC.Id := M + 1000;
                    RealC.Insert();
                    Back.Get(M + 1000);
                    Observer.Observe(N + 'copy get', TmDtm(Back));
                end;
            end else
                Observer.ObserveError(N + 'copy');
            Clear(RealA);
            RealA := TempR;
            Observer.Observe(N + 'assign var', TmDtm(RealA) + '|temporary=' + Format(RealA.IsTemporary()));
            if not RealA.IsTemporary() then begin
                RealA.Id := M + 2000;
                RealA.Insert();
                Back.Get(M + 2000);
                Observer.Observe(N + 'assign get', TmDtm(Back));
            end;
            // database -> temporary
            RealD.Init();
            RealD.Id := M + 3000;
            RealD.Tm := T;
            RealD.Dtm := DT;
            RealD.Insert();
            TempR.Init();
            TempR.TransferFields(RealD);
            TempR.Id := M + 3000;
            TempR.Insert();
            TempR.Init();
            TempR.Get(M + 3000);
            Observer.Observe(N + 'from var get', TmDtm(TempR));
            Back.Get(M + 3000);
            TempR.Init();
            TempR.TransferFields(Back);
            TempR.Id := M + 4000;
            TempR.Insert();
            TempR.Init();
            TempR.Get(M + 4000);
            Observer.Observe(N + 'from row get', TmDtm(TempR));
        end;
        Observer.Expect('1 tf var', '00:00:00.001|2024-03-25T00:00:00.001Z');
        Observer.Expect('1 tf get', '00:00:00|2024-03-25T00:00:00Z');
        Observer.Expect('1 copy var', '00:00:00.001|2024-03-25T00:00:00.001Z|temporary=No');
        Observer.Expect('1 copy get', '00:00:00|2024-03-25T00:00:00Z');
        Observer.Expect('1 assign var', '00:00:00.001|2024-03-25T00:00:00.001Z|temporary=No');
        Observer.Expect('1 assign get', '00:00:00|2024-03-25T00:00:00Z');
        Observer.Expect('1 from var get', '00:00:00.001|2024-03-25T00:00:00.001Z');
        Observer.Expect('1 from row get', '00:00:00|2024-03-25T00:00:00Z');
        Observer.Expect('998 tf var', '00:00:00.998|2024-03-25T00:00:00.998Z');
        Observer.Expect('998 tf get', '00:00:00.997|2024-03-25T00:00:00.997Z');
        Observer.Expect('998 copy var', '00:00:00.998|2024-03-25T00:00:00.998Z|temporary=No');
        Observer.Expect('998 copy get', '00:00:00.997|2024-03-25T00:00:00.997Z');
        Observer.Expect('998 assign var', '00:00:00.998|2024-03-25T00:00:00.998Z|temporary=No');
        Observer.Expect('998 assign get', '00:00:00.997|2024-03-25T00:00:00.997Z');
        Observer.Expect('998 from var get', '00:00:00.998|2024-03-25T00:00:00.998Z');
        Observer.Expect('998 from row get', '00:00:00.997|2024-03-25T00:00:00.997Z');
        Observer.Expect('999 tf var', '00:00:00.999|2024-03-25T00:00:00.999Z');
        Observer.Expect('999 tf get', '00:00:01|2024-03-25T00:00:01Z');
        Observer.Expect('999 copy var', '00:00:00.999|2024-03-25T00:00:00.999Z|temporary=No');
        Observer.Expect('999 copy get', '00:00:01|2024-03-25T00:00:01Z');
        Observer.Expect('999 assign var', '00:00:00.999|2024-03-25T00:00:00.999Z|temporary=No');
        Observer.Expect('999 assign get', '00:00:01|2024-03-25T00:00:01Z');
        Observer.Expect('999 from var get', '00:00:00.999|2024-03-25T00:00:00.999Z');
        Observer.Expect('999 from row get', '00:00:01|2024-03-25T00:00:01Z');
        Observer.Verify();
    end;

    local procedure KeyTime(var K: Record "LT RH Time Key Row"): Text
    begin
        exit(K."Entry Code" + '|' + Format(K."Entry Time", 0, 9) + '|' + Format(K."Entry Time" - 000000T) + '|' + K.Note);
    end;

    local procedure GetTime(var Observer: Codeunit "Probe Observer"; Name: Text; Code: Code[20]; T: Time)
    var
        K: Record "LT RH Time Key Row";
    begin
        if K.Get(Code, T) then
            Observer.Observe(Name, 'found|' + KeyTime(K))
        else
            Observer.Observe(Name, 'not found');
    end;

    // al-runner issue 5689: a Time primary key field written with milliseconds the SQL column rounds (.001 -> .000, .002 -> .003, 23:59:59.999 -> midnight):
    // what Insert answers, what the record variable holds after Insert, which values Get finds the row by, what FindFirst reads back, a second Insert whose value
    // rounds to the same key, Modify, Rename and Delete through the unrounded value.
    // Measured on 27.5, 28.5 and 29.0 (the same): the variable keeps .001 after Insert, Get with .001 or .000 finds the row and reads 10:00:00; Insert with a
    // return value of a key that rounds to an existing one answers false; without a return value the Insert raises nothing and the duplicate error
    // (DB:RecordExists) comes at the next read of the table (Count).
    [Test]
    procedure RH_TimeKey_Milliseconds_InsertGet()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT RH Time Key Row";
        Stage: Text;
        Cnt: Integer;
    begin
        K.DeleteAll();
        K.Init();
        K."Entry Code" := 'A';
        K."Entry Time" := 100000T + 1;
        K.Note := 'first';
        Observer.Observe('insert', Format(K.Insert(true)));
        Observer.Observe('var after insert', KeyTime(K));
        GetTime(Observer, 'get .001', 'A', 100000T + 1);
        GetTime(Observer, 'get .000', 'A', 100000T);
        GetTime(Observer, 'get .002', 'A', 100000T + 2);
        K.Reset();
        K.FindFirst();
        Observer.Observe('findfirst', KeyTime(K));
        Observer.Observe('count', Format(K.Count()));
        K.SetRange("Entry Time", 100000T + 1);
        Observer.Observe('setrange .001 count', Format(K.Count()));
        K.Reset();

        K.Init();
        K."Entry Code" := 'A';
        K."Entry Time" := 100000T;
        K.Note := 'second';
        Observer.Observe('insert .000 return', Format(K.Insert()));
        // Insert without a return value: where the duplicate key error is raised (Stage names the last step that ran).
        ClearLastError();
        asserterror begin
            Stage := 'insert';
            K.Init();
            K."Entry Code" := 'A';
            K."Entry Time" := 100000T;
            K.Note := 'third';
            K.Insert();
            Stage := 'count';
            K.Reset();
            Cnt := K.Count();
            Stage := 'done';
        end;
        Observer.Observe('plain insert .000 stage', Stage);
        Observer.ObserveError('plain insert .000 error');
        K.Reset();
        Observer.Observe('count after duplicate', Format(K.Count()));
        if K.FindSet() then
            repeat
                Observer.Observe('row after duplicate', KeyTime(K));
            until K.Next() = 0;

        K.Init();
        K."Entry Code" := 'A';
        K."Entry Time" := 100000T + 2;
        K.Note := 'two';
        Observer.Observe('insert .002', Format(K.Insert()));
        GetTime(Observer, 'get .003', 'A', 100000T + 3);
        GetTime(Observer, 'get .002 after', 'A', 100000T + 2);
        K.Reset();
        Observer.Observe('count after .002', Format(K.Count()));

        K.Init();
        K."Entry Code" := 'B';
        K."Entry Time" := 235959.999T;
        K.Note := 'late';
        Observer.Observe('insert .999', Format(K.Insert()));
        GetTime(Observer, 'get .999', 'B', 235959.999T);
        GetTime(Observer, 'get midnight', 'B', 000000T);
        Observer.Expect('insert', 'Yes');
        Observer.Expect('var after insert', 'A|10:00:00.001|36000001|first');
        Observer.Expect('get .001', 'found|A|10:00:00|36000000|first');
        Observer.Expect('get .000', 'found|A|10:00:00|36000000|first');
        Observer.Expect('get .002', 'not found');
        Observer.Expect('findfirst', 'A|10:00:00|36000000|first');
        Observer.Expect('count', '1');
        Observer.Expect('setrange .001 count', '1');
        Observer.Expect('insert .000 return', 'No');
        Observer.Expect('plain insert .000 stage', 'count');
        Observer.Expect('plain insert .000 error|text', 'The record in table LT RH Time Key Row already exists. Identification fields and values: Entry Code=''A'',Entry Time=''10:00:00 AM''');
        Observer.Expect('plain insert .000 error|code', 'DB:RecordExists');
        Observer.Expect('count after duplicate', '0');
        Observer.Expect('insert .002', 'Yes');
        Observer.Expect('get .003', 'found|A|10:00:00.003|36000003|two');
        Observer.Expect('get .002 after', 'found|A|10:00:00.003|36000003|two');
        Observer.Expect('count after .002', '1');
        Observer.Expect('insert .999', 'Yes');
        Observer.Expect('get .999', 'found|B|00:00:00|0|late');
        Observer.Expect('get midnight', 'found|B|00:00:00|0|late');
        Observer.Verify();
    end;

    [Test]
    procedure RH_TimeKey_Milliseconds_ModifyRenameDelete()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT RH Time Key Row";
    begin
        K.DeleteAll();
        K.Init();
        K."Entry Code" := 'A';
        K."Entry Time" := 100000T + 1;
        K.Note := 'first';
        K.Insert();
        K.Note := 'modified';
        Observer.Observe('modify var', Format(K.Modify()));
        GetTime(Observer, 'after modify', 'A', 100000T);

        K.Get('A', 100000T + 1);
        Observer.Observe('rename', Format(K.Rename('A', 120000T + 1)));
        Observer.Observe('var after rename', KeyTime(K));
        GetTime(Observer, 'get renamed .000', 'A', 120000T);
        GetTime(Observer, 'get old .000', 'A', 100000T);

        K.Init();
        K."Entry Code" := 'A';
        K."Entry Time" := 120000T + 1;
        Observer.Observe('delete unrounded', Format(K.Delete()));
        K.Reset();
        Observer.Observe('count after delete', Format(K.Count()));
        Observer.Expect('modify var', 'Yes');
        Observer.Expect('after modify', 'found|A|10:00:00|36000000|modified');
        Observer.Expect('rename', 'Yes');
        Observer.Expect('var after rename', 'A|12:00:00.001|43200001|modified');
        Observer.Expect('get renamed .000', 'found|A|12:00:00|43200000|modified');
        Observer.Expect('get old .000', 'not found');
        Observer.Expect('delete unrounded', 'Yes');
        Observer.Expect('count after delete', '0');
        Observer.Verify();
    end;

    // The same for a DateTime primary key field.
    [Test]
    procedure RH_DateTimeKey_Milliseconds_InsertGet()
    var
        Observer: Codeunit "Probe Observer";
        K: Record "LT RH DateTime Key Row";
        Base: DateTime;
        Stage: Text;
        Cnt: Integer;
    begin
        Base := CreateDateTime(20240325D, 100000T);
        K.DeleteAll();
        K.Init();
        K."At" := Base + 1;
        K.Note := 'first';
        Observer.Observe('insert', Format(K.Insert()));
        Observer.Observe('var after insert', Format(K."At", 0, 9));
        Clear(K);
        Observer.Observe('get .001', Format(K.Get(Base + 1)) + '|' + Format(K."At", 0, 9));
        Clear(K);
        Observer.Observe('get .000', Format(K.Get(Base)) + '|' + Format(K."At", 0, 9));
        K.Reset();
        K.FindFirst();
        Observer.Observe('findfirst', Format(K."At", 0, 9) + '|' + Format(K."At" - Base));
        K.Init();
        K."At" := Base;
        K.Note := 'second';
        Observer.Observe('insert .000 return', Format(K.Insert()));
        ClearLastError();
        asserterror begin
            Stage := 'insert';
            K.Init();
            K."At" := Base;
            K.Note := 'third';
            K.Insert();
            Stage := 'count';
            K.Reset();
            Cnt := K.Count();
            Stage := 'done';
        end;
        Observer.Observe('plain insert .000 stage', Stage);
        Observer.ObserveError('plain insert .000 error');
        K.Reset();
        Observer.Observe('count after duplicate', Format(K.Count()));
        K.Init();
        K."At" := CreateDateTime(20240325D, 235959.999T);
        K.Note := 'late';
        Observer.Observe('insert .999', Format(K.Insert()));
        Clear(K);
        Observer.Observe('get next day', Format(K.Get(CreateDateTime(20240326D, 000000T))) + '|' + Format(K."At", 0, 9));
        K.Reset();
        Observer.Observe('count', Format(K.Count()));
        if K.FindSet() then
            repeat
                Observer.Observe('row', Format(K."At", 0, 9) + '|' + K.Note);
            until K.Next() = 0;
        Observer.Expect('insert', 'Yes');
        Observer.Expect('var after insert', '2024-03-25T10:00:00.001Z');
        Observer.Expect('get .001', 'Yes|2024-03-25T10:00:00Z');
        Observer.Expect('get .000', 'Yes|2024-03-25T10:00:00Z');
        Observer.Expect('findfirst', '2024-03-25T10:00:00Z|');
        Observer.Expect('insert .000 return', 'No');
        Observer.Expect('plain insert .000 stage', 'count');
        Observer.Expect('plain insert .000 error|text', 'The record in table LT RH DateTime Key Row already exists. Identification fields and values: At=''03/25/24 10:00 AM''');
        Observer.Expect('plain insert .000 error|code', 'DB:RecordExists');
        Observer.Expect('count after duplicate', '0');
        Observer.Expect('insert .999', 'Yes');
        Observer.Expect('get next day', 'Yes|2024-03-26T00:00:00Z');
        Observer.Expect('count', '1');
        Observer.Expect('row', '2024-03-26T00:00:00Z|late');
        Observer.Verify();
    end;
}

// al-runner issue 5689: tables with a Time and a DateTime field in the primary key (object ids 88000 and 88001).
table 88000 "LT RH Time Key Row"
{
    fields
    {
        field(1; "Entry Code"; Code[20]) { }
        field(2; "Entry Time"; Time) { }
        field(3; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Entry Code", "Entry Time") { Clustered = true; }
    }
}

table 88001 "LT RH DateTime Key Row"
{
    fields
    {
        field(1; "At"; DateTime) { }
        field(2; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "At") { Clustered = true; }
    }
}
