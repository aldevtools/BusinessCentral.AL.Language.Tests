// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-setfilter-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 74333
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Record.SetFilter with a literal text (no %1 argument) on Date, DateFormula, Time and DateTime fields: empty text, the blank filter '', <>'', a formula such as 1M, a date in other spellings; observed by Count and GetFilter, or by the error
// Writer TV (2026-10-29, TV_* tests): SetView with DateTime filter values as text (GetView round trip with milliseconds, literal texts).
// BC versions: 29 (27 and 28 by CI)

table 74333 "LT P136 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; D; Date) { }
        field(3; DF; DateFormula) { }
        field(4; T; Time) { }
        field(5; DT; DateTime) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 74334 "LT P136 Filter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "LT P136 Row";
    begin
        R.DeleteAll();
        R.Init();
        R.Id := 1;
        R.D := 20240101D;
        Evaluate(R.DF, '<1M>');
        R.T := 080000T;
        R.DT := CreateDateTime(20240101D, 080000T);
        R.Insert();
        R.Init();
        R.Id := 2;
        R.D := 20240115D;
        Evaluate(R.DF, '<1D>');
        R.T := 120000T;
        R.DT := CreateDateTime(20240115D, 120000T);
        R.Insert();
        R.Init();
        R.Id := 3;
        R.Insert();
        R.Init();
        R.Id := 4;
        R.D := 20240229D;
        Evaluate(R.DF, '<1M>');
        R.T := 235959T;
        R.DT := CreateDateTime(20240229D, 235959T);
        R.Insert();
    end;

    [TryFunction]
    local procedure TryD(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(D, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(D);
    end;

    [TryFunction]
    local procedure TryDOnly(Txt: Text)
    var
        R: Record "LT P136 Row";
        N: Integer;
    begin
        R.SetFilter(D, Txt);
        N := R.Count();
    end;

    [TryFunction]
    local procedure TryDF(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(DF, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(DF);
    end;

    [TryFunction]
    local procedure TryT(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(T, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(T);
    end;

    [TryFunction]
    local procedure TryDT(Txt: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetFilter(DT, Txt);
        Outcome := Format(R.Count()) + '|' + R.GetFilter(DT);
    end;

    local procedure FD(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryD(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure FDOnly(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    begin
        if TryDOnly(Txt) then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    local procedure FDF(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryDF(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure FT(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryT(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure FDT(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        O: Text;
    begin
        if TryDT(Txt, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;









    [Test]
    procedure P136_SetFilter_Date_TodayFormulas()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FDOnly(Observer, 'T', 'T');
        FDOnly(Observer, 'W', 'W');
        FDOnly(Observer, 'CM', 'CM');
        FDOnly(Observer, 'CW', 'CW');
        FDOnly(Observer, 'CY', 'CY');
        FDOnly(Observer, 'CQ', 'CQ');
        FDOnly(Observer, 'lowerT', 't');
        FDOnly(Observer, 'tPlus', 'T+1D');
        FDOnly(Observer, 'tAngles', '<T>');
        FDOnly(Observer, 'cmAngles', '<CM>');
        FDOnly(Observer, 'cmRange', '<CM-1M>..<CM>');
        FDOnly(Observer, 'geT', '>=T');
        FDOnly(Observer, 'oneMDot', '..1M');
        FDOnly(Observer, 'oneDOnly', '1D');
        FDOnly(Observer, 'plusOneD', '+1D');
        FDOnly(Observer, 'plusOneDAngles', '<+1D>');
        FDOnly(Observer, 'angleOpenOnly', '<+1D');
        Observer.Expect('T', 'ok');
        Observer.Expect('W', 'ok');
        Observer.Expect('CM', 'ok');
        Observer.Expect('CW', 'ok');
        Observer.Expect('CY', 'ok');
        Observer.Expect('CQ', 'ok');
        Observer.Expect('lowerT', 'ok');
        Observer.Expect('tPlus', 'ok');
        Observer.Expect('tAngles|text', 'The filter "<T>" is not valid for the D field on the LT P136 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('tAngles|code', 'Filter:CSide');
        Observer.Expect('cmAngles', 'ok');
        Observer.Expect('cmRange', 'ok');
        Observer.Expect('geT', 'ok');
        Observer.Expect('oneMDot', 'ok');
        Observer.Expect('oneDOnly', 'ok');
        Observer.Expect('plusOneD', 'ok');
        Observer.Expect('plusOneDAngles', 'ok');
        Observer.Expect('angleOpenOnly', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P136_SetFilter_DateFormula()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        FDF(Observer, 'empty', '');
        FDF(Observer, 'blankQuotes', '''''');
        FDF(Observer, 'notBlankQuotes', '<>''''');
        FDF(Observer, 'oneM', '1M');
        FDF(Observer, 'oneMAngles', '<1M>');
        FDF(Observer, 'oneD', '1D');
        FDF(Observer, 'oneDAngles', '<1D>');
        FDF(Observer, 'notOneM', '<>1M');
        FDF(Observer, 'geOneD', '>=1D');
        FDF(Observer, 'orBoth', '1M|1D');
        FDF(Observer, 'range', '1D..1M');
        FDF(Observer, 'cm', 'CM');
        FDF(Observer, 'garbage', 'x');
        FDF(Observer, 'zero', '0D');
        FDF(Observer, 'lowerM', '1m');
        FDF(Observer, 'twoMonths', '2M');
        FDF(Observer, 'angleOpenOnly', '<1M');
        FDF(Observer, 'blankSpace', ' ');
        FDF(Observer, 'plusOneM', '+1M');
        FDF(Observer, 'wildcard', '*');
        FDF(Observer, 'wildcardM', '*M');
        Observer.Expect('empty', '4|');
        Observer.Expect('blankQuotes', '1|''''');
        Observer.Expect('notBlankQuotes', '3|<>''''');
        Observer.Expect('oneM', '2|1M');
        Observer.Expect('oneMAngles|text', 'The filter "<1M>" is not valid for the DF field on the LT P136 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('oneMAngles|code', 'Filter:CSide');
        Observer.Expect('oneD', '1|1D');
        Observer.Expect('oneDAngles|text', 'The filter "<1D>" is not valid for the DF field on the LT P136 Row table. An error occurred while interpreting the filter: Did not expect ''>''.\\For more information, see https://go.microsoft.com/fwlink/?linkid=2158058.');
        Observer.Expect('oneDAngles|code', 'Filter:CSide');
        Observer.Expect('notOneM', '2|<>1M');
        Observer.Expect('geOneD', '3|>=1D');
        Observer.Expect('orBoth', '2|1M|1D');
        Observer.Expect('range', '3|1D..1M');
        Observer.Expect('cm', '0|CM');
        Observer.Expect('garbage|text', 'The filter "x" is not valid for the DF field on the LT P136 Row table. The date formula ''X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('garbage|code', 'Filter:CSide');
        Observer.Expect('zero', '0|0D');
        Observer.Expect('lowerM', '2|1M');
        Observer.Expect('twoMonths', '0|2M');
        Observer.Expect('angleOpenOnly', '2|<1M');
        Observer.Expect('blankSpace', '4|');
        Observer.Expect('plusOneM', '0|+1M');
        Observer.Expect('wildcard', '1|''''');
        Observer.Expect('wildcardM|text', 'The filter "*M" is not valid for the DF field on the LT P136 Row table. The date formula ''*M'' should include a number.');
        Observer.Expect('wildcardM|code', 'Filter:CSide');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): SetView with a DateTime filter value written as text: the GetView text of a SetRange/SetFilter on a
    // DateTime with milliseconds read back by SetView, and literal texts in the month-first form with milliseconds (1, 2 and 3 digits), a range,
    // a date alone and an empty value. Observed by Count, GetFilter and the error. ----

    local procedure TvSeedMs()
    var
        R: Record "LT P136 Row";
    begin
        Seed();
        R.Init();
        R.Id := 5;
        R.DT := CreateDateTime(20261107D, 120000.033T);
        R.Insert();
        R.Init();
        R.Id := 6;
        R.DT := CreateDateTime(20261107D, 120000.034T);
        R.Insert();
        R.Init();
        R.Id := 7;
        R.DT := CreateDateTime(20261103D, 120000.08T);
        R.Insert();
        R.Init();
        R.Id := 8;
        R.DT := CreateDateTime(20261103D, 120011.767T);
        R.Insert();
    end;

    [TryFunction]
    local procedure TvTrySetView(View: Text; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        R.SetView(View);
        Outcome := Format(R.Count()) + '|' + Format(R.FindFirst()) + ':' + Format(R.Id);
    end;

    local procedure TvView(var Observer: Codeunit "Probe Observer"; Name: Text; View: Text)
    var
        O: Text;
    begin
        ClearLastError();
        if TvTrySetView(View, O) then
            Observer.Observe(Name, O)
        else
            Observer.ObserveError(Name);
    end;

    local procedure TvRoundTrip(var R: Record "LT P136 Row"): Text
    var
        R2: Record "LT P136 Row";
        V: Text;
    begin
        V := R.GetView();
        ClearLastError();
        if not TvTrySetView(V, V) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        R2.SetView(R.GetView());
        exit(R.GetFilter(DT) + '|' + V + '|same filter=' + Format(R2.GetFilter(DT) = R.GetFilter(DT)) + '|same view=' + Format(R2.GetView() = R.GetView()));
    end;

    [Test]
    procedure TV_SetView_DateTime_GetViewRoundTrip()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P136 Row";
    begin
        TvSeedMs();
        R.SetRange(DT, CreateDateTime(20261107D, 120000.033T));
        Observer.Observe('setrange .033', TvRoundTrip(R));
        R.SetRange(DT, CreateDateTime(20261103D, 120000.08T));
        Observer.Observe('setrange .08', TvRoundTrip(R));
        R.SetRange(DT, CreateDateTime(20261103D, 120011.767T));
        Observer.Observe('setrange 11.767', TvRoundTrip(R));
        R.SetRange(DT, CreateDateTime(20261103D, 0T), CreateDateTime(20261107D, 120000.033T));
        Observer.Observe('setrange range', TvRoundTrip(R));
        R.SetFilter(DT, '>%1', CreateDateTime(20261107D, 120000.033T));
        Observer.Observe('setfilter greater', TvRoundTrip(R));
        R.SetRange(DT, CreateDateTime(20240115D, 120000T));
        Observer.Observe('setrange whole second', TvRoundTrip(R));
        Observer.Expect('setrange .033', '11/07/26 12:00:00.033 PM|2|Yes:5|same filter=Yes|same view=Yes');
        Observer.Expect('setrange .08', '11/03/26 12:00:00.08 PM|1|Yes:7|same filter=Yes|same view=Yes');
        Observer.Expect('setrange 11.767', '11/03/26 12:00:11.767 PM|1|Yes:8|same filter=Yes|same view=Yes');
        Observer.Expect('setrange range', '11/03/26 12:00 AM..11/07/26 12:00:00.033 PM|4|Yes:5|same filter=Yes|same view=Yes');
        Observer.Expect('setfilter greater', '>11/07/26 12:00:00.033 PM|0|No:0|same filter=Yes|same view=Yes');
        Observer.Expect('setrange whole second', '01/15/24 12:00 PM|1|Yes:2|same filter=Yes|same view=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TV_SetView_DateTime_LiteralTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TvSeedMs();
        TvView(Observer, 'ms 3 digits', 'WHERE(DT=FILTER(11/07/26 12:00:00.033 PM))');
        TvView(Observer, 'ms 2 digits', 'WHERE(DT=FILTER(11/03/26 12:00:00.08 PM))');
        TvView(Observer, 'ms 1 digit', 'WHERE(DT=FILTER(11/03/26 12:00:00.8 PM))');
        TvView(Observer, 'seconds', 'WHERE(DT=FILTER(01/15/24 12:00:00 PM))');
        TvView(Observer, 'no seconds', 'WHERE(DT=FILTER(01/15/24 12:00 PM))');
        TvView(Observer, 'range', 'WHERE(DT=FILTER(11/03/26 12:00:00.08 PM..11/07/26 12:00:00.033 PM))');
        TvView(Observer, 'date only', 'WHERE(DT=FILTER(01/15/24))');
        TvView(Observer, 'empty', 'WHERE(DT=FILTER(''''))');
        TvView(Observer, '24 hour', 'WHERE(DT=FILTER(11/07/26 12:00:00.033))');
        Observer.Expect('ms 3 digits', '2|Yes:5');
        Observer.Expect('ms 2 digits', '1|Yes:7');
        Observer.Expect('ms 1 digit', '0|No:0');
        Observer.Expect('seconds', '1|Yes:2');
        Observer.Expect('no seconds', '1|Yes:2');
        Observer.Expect('range', '4|Yes:5');
        Observer.Expect('date only', '1|Yes:2');
        Observer.Expect('empty', '1|Yes:3');
        Observer.Expect('24 hour', '2|Yes:5');
        Observer.Verify();
    end;

    // Writer UN (2026-10-29, UN_* tests): DateTime filter texts that are a date alone or have an hour other than 12, as SetFilter text and inside SetView.
    local procedure UnRow(Id: Integer; Stamp: DateTime)
    var
        R: Record "LT P136 Row";
    begin
        R.Init();
        R.Id := Id;
        R.DT := Stamp;
        R.Insert();
    end;

    local procedure UnSeed()
    var
        R: Record "LT P136 Row";
    begin
        R.DeleteAll();
        UnRow(11, CreateDateTime(20250115D, 0T));
        UnRow(12, CreateDateTime(20250115D, 083000T));
        UnRow(13, CreateDateTime(20250115D, 083030T));
        UnRow(14, CreateDateTime(20250115D, 120000T));
        UnRow(15, CreateDateTime(20250115D, 174510.5T));
        UnRow(16, CreateDateTime(20250115D, 174500T));
        UnRow(17, CreateDateTime(20250115D, 235959.999T));
        UnRow(18, CreateDateTime(20250116D, 0T));
        UnRow(19, CreateDateTime(20250114D, 200000T));
    end;

    local procedure UnIds(var R: Record "LT P136 Row"): Text
    var
        Result: Text;
    begin
        if R.FindSet() then
            repeat
                Result += Format(R.Id) + ',';
            until R.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure UnTry(Txt: Text; AsView: Boolean; var Outcome: Text)
    var
        R: Record "LT P136 Row";
    begin
        if AsView then
            R.SetView('WHERE(DT=FILTER(' + Txt + '))')
        else
            R.SetFilter(DT, Txt);
        Outcome := 'ids=' + UnIds(R) + '|filter=' + R.GetFilter(DT) + '|view=' + R.GetView();
    end;

    local procedure UnProbe(var Observer: Codeunit "Probe Observer"; Txt: Text)
    var
        O: Text;
    begin
        ClearLastError();
        if UnTry(Txt, false, O) then
            Observer.Observe('filter ' + Txt, O)
        else
            Observer.ObserveError('filter ' + Txt);
        ClearLastError();
        if UnTry(Txt, true, O) then
            Observer.Observe('view ' + Txt, O)
        else
            Observer.ObserveError('view ' + Txt);
    end;

    [Test]
    procedure UN_DateTimeFilter_DateAlone()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeed();
        UnProbe(Observer, '01/15/25');
        UnProbe(Observer, '1/15/25');
        UnProbe(Observer, '15.01.25');
        UnProbe(Observer, '2025-01-15');
        UnProbe(Observer, '..01/15/25');
        UnProbe(Observer, '01/15/25..');
        UnProbe(Observer, '01/15/25..01/16/25');
        Observer.Finish();
    end;

    [Test]
    procedure UN_DateTimeFilter_HourNotTwelve()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeed();
        UnProbe(Observer, '01/15/25 08:30');
        UnProbe(Observer, '01/15/25 08:30 AM');
        UnProbe(Observer, '01/15/25 08:30 PM');
        UnProbe(Observer, '01/15/25 17:45:10.5');
        UnProbe(Observer, '01/15/25 05:45:10.5 PM');
        UnProbe(Observer, '01/15/25 17:45:10.500 PM');
        Observer.Finish();
    end;

    [Test]
    procedure UN_DateTimeFilter_MoreHourForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        UnSeed();
        UnProbe(Observer, '01/15/25 08:30:00');
        UnProbe(Observer, '01/15/25 12:00 AM');
        UnProbe(Observer, '01/15/25 00:00');
        UnProbe(Observer, '01/15/25 17:45');
        UnProbe(Observer, '>01/15/25 08:30');
        UnProbe(Observer, '01/15/25 08:30..01/15/25 17:45:10.5');
        UnProbe(Observer, '<01/15/25');
        UnProbe(Observer, '15.01.25 08:30');
        Observer.Finish();
    end;
}
