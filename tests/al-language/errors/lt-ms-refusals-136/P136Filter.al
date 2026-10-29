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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
