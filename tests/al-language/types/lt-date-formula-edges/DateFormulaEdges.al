// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: date formula texts at the edge of the grammar, from the anchor date 15 January 2024 (a Monday): %N placeholders (<+%2D>, <+%1M>, +%1D>, <-%1D>),
// other signs and digit counts (<+D>, <+5>, <5>), a missing closing bracket (<+6W, <-1D, <+1M), W and WD units (W, 2WD, <1WD>), and the texts 01/01/26, Y
// and 8D+<1D>; each through CalcDate and through Evaluate into a DateFormula (the stored formula and the CalcDate with it).
// Settles: date-formula-evaluate-percent-placeholder, calcdate-closing-bracket-missing-after-plus. Object id 67857.
// Writer TV (2026-10-29, TV_* tests): unit letters with a number other than D and WD: M2 (M0, M1, M12, M13, -M2, CM+M2, M2+D10, 1Y+M2), W2, Q2, Y2.

codeunit 67857 "LT Date Formula Edges"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; var Result: Text)
    begin
        Result := Format(CalcDate(Formula, 20240115D), 0, 9);
    end;

    [TryFunction]
    local procedure TryEvaluate(Formula: Text; var Stored: Text; var Calculated: Text)
    var
        DF: DateFormula;
    begin
        Evaluate(DF, Formula);
        Stored := Format(DF);
        Calculated := Format(CalcDate(DF, 20240115D), 0, 9);
    end;

    local procedure Calc(Formula: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryCalc(Formula, Result) then
            exit('ok:' + Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Eval(Formula: Text): Text
    var
        Stored: Text;
        Calculated: Text;
    begin
        ClearLastError();
        if TryEvaluate(Formula, Stored, Calculated) then
            exit('ok:stored=' + Stored + '|calc=' + Calculated);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Both(var Observer: Codeunit "Probe Observer"; Formula: Text)
    begin
        Observer.Observe('calc ' + Formula, Calc(Formula));
        Observer.Observe('eval ' + Formula, Eval(Formula));
    end;

    [Test]
    procedure Placeholders_PercentN()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '<+%2D>');
        Both(Observer, '<+%1M>');
        Both(Observer, '+%1D>');
        Both(Observer, '<-%1D>');
        Both(Observer, '<+%1D>');
        Both(Observer, '<+%2W>');
        Both(Observer, '+%1D');
        Both(Observer, '%1D');
        Both(Observer, '<%1D>');
        Both(Observer, '<+%D>');
        Both(Observer, '<+%0D>');
        Observer.Expect('calc <+%2D>', 'ok:2024-01-17');
        Observer.Expect('eval <+%2D>', 'ok:stored=+2D|calc=2024-01-17');
        Observer.Expect('calc <+%1M>', 'ok:2024-02-15');
        Observer.Expect('eval <+%1M>', 'ok:stored=+1M|calc=2024-02-15');
        Observer.Expect('calc +%1D>', 'ok:2024-01-16');
        Observer.Expect('eval +%1D>', 'ok:stored=+1D|calc=2024-01-16');
        Observer.Expect('calc <-%1D>', 'ok:2024-01-14');
        Observer.Expect('eval <-%1D>', 'ok:stored=-1D|calc=2024-01-14');
        Observer.Expect('calc <+%1D>', 'ok:2024-01-16');
        Observer.Expect('eval <+%1D>', 'ok:stored=+1D|calc=2024-01-16');
        Observer.Expect('calc <+%2W>', 'ok:2024-01-29');
        Observer.Expect('eval <+%2W>', 'ok:stored=+2W|calc=2024-01-29');
        Observer.Expect('calc +%1D', 'ok:2024-01-16');
        Observer.Expect('eval +%1D', 'ok:stored=+1D|calc=2024-01-16');
        Observer.Expect('calc %1D', 'ok:2024-01-16');
        Observer.Expect('eval %1D', 'ok:stored=1D|calc=2024-01-16');
        Observer.Expect('calc <%1D>', 'ok:2024-01-16');
        Observer.Expect('eval <%1D>', 'ok:stored=1D|calc=2024-01-16');
        Observer.Expect('calc <+%D>', 'error:The date formula ''+%D'' should include a number.|Evaluate');
        Observer.Expect('eval <+%D>', 'error:The date formula ''+%D'' should include a number.|Evaluate');
        Observer.Expect('calc <+%0D>', 'ok:2024-01-15');
        Observer.Expect('eval <+%0D>', 'ok:stored=+0D|calc=2024-01-15');
        Observer.Verify();
    end;

    [Test]
    procedure SignsAndDigits_ErrorTexts()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '<+D>');
        Both(Observer, '<-D>');
        Both(Observer, '<D>');
        Both(Observer, '<+5>');
        Both(Observer, '<5>');
        Both(Observer, '<+0D>');
        Both(Observer, '<+10D>');
        Both(Observer, '<+123D>');
        Both(Observer, '<++1D>');
        Both(Observer, '<+-1D>');
        Observer.Expect('calc <+D>', 'error:The date formula ''+D'' should include a number.|Evaluate');
        Observer.Expect('eval <+D>', 'error:The date formula ''+D'' should include a number.|Evaluate');
        Observer.Expect('calc <-D>', 'error:The date formula ''-D'' should include a number.|Evaluate');
        Observer.Expect('eval <-D>', 'error:The date formula ''-D'' should include a number.|Evaluate');
        Observer.Expect('calc <D>', 'error:The date formula ''D'' should include a number.|Evaluate');
        Observer.Expect('eval <D>', 'error:The date formula ''D'' should include a number.|Evaluate');
        Observer.Expect('calc <+5>', 'error:The date formula ''+5'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('eval <+5>', 'error:The date formula ''+5'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('calc <5>', 'error:The date formula ''5'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('eval <5>', 'error:The date formula ''5'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('calc <+0D>', 'ok:2024-01-15');
        Observer.Expect('eval <+0D>', 'ok:stored=+0D|calc=2024-01-15');
        Observer.Expect('calc <+10D>', 'ok:2024-01-25');
        Observer.Expect('eval <+10D>', 'ok:stored=+10D|calc=2024-01-25');
        Observer.Expect('calc <+123D>', 'ok:2024-05-17');
        Observer.Expect('eval <+123D>', 'ok:stored=+123D|calc=2024-05-17');
        Observer.Expect('calc <++1D>', 'error:The date formula ''++1D'' should include a number.|Evaluate');
        Observer.Expect('eval <++1D>', 'error:The date formula ''++1D'' should include a number.|Evaluate');
        Observer.Expect('calc <+-1D>', 'error:The date formula ''+-1D'' should include a number.|Evaluate');
        Observer.Expect('eval <+-1D>', 'error:The date formula ''+-1D'' should include a number.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure ClosingBracket_MissingAfterPlus()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '<+6W');
        Both(Observer, '<-1D');
        Both(Observer, '<+1M');
        Both(Observer, '<1D');
        Both(Observer, '1D>');
        Both(Observer, '<1D>>');
        Both(Observer, '<<1D>');
        Both(Observer, '<>');
        Both(Observer, '<');
        Both(Observer, '');
        Observer.Expect('calc <+6W', 'ok:2024-02-26');
        Observer.Expect('eval <+6W', 'ok:stored=+6W|calc=2024-02-26');
        Observer.Expect('calc <-1D', 'ok:2024-01-14');
        Observer.Expect('eval <-1D', 'ok:stored=-1D|calc=2024-01-14');
        Observer.Expect('calc <+1M', 'ok:2024-02-15');
        Observer.Expect('eval <+1M', 'ok:stored=+1M|calc=2024-02-15');
        Observer.Expect('calc <1D', 'ok:2024-01-16');
        Observer.Expect('eval <1D', 'ok:stored=1D|calc=2024-01-16');
        Observer.Expect('calc 1D>', 'ok:2024-01-16');
        Observer.Expect('eval 1D>', 'ok:stored=1D|calc=2024-01-16');
        Observer.Expect('calc <1D>>', 'ok:2024-01-16');
        Observer.Expect('eval <1D>>', 'ok:stored=1D|calc=2024-01-16');
        Observer.Expect('calc <<1D>', 'ok:2024-01-16');
        Observer.Expect('eval <<1D>', 'ok:stored=1D|calc=2024-01-16');
        Observer.Expect('calc <>', 'ok:2024-01-15');
        Observer.Expect('eval <>', 'ok:stored=|calc=2024-01-15');
        Observer.Expect('calc <', 'ok:2024-01-15');
        Observer.Expect('eval <', 'ok:stored=|calc=2024-01-15');
        Observer.Expect('calc ', 'ok:2024-01-15');
        Observer.Expect('eval ', 'ok:stored=|calc=2024-01-15');
        Observer.Verify();
    end;

    [Test]
    procedure WeekAndWeekdayUnits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, 'W');
        Both(Observer, '2WD');
        Both(Observer, '<W>');
        Both(Observer, '<2WD>');
        Both(Observer, '<1WD>');
        Both(Observer, '<WD>');
        Both(Observer, '<+1W>');
        Both(Observer, '<CW>');
        Both(Observer, '<-CW>');
        Both(Observer, '<1WD+1D>');
        Observer.Expect('calc W', 'error:The date formula ''W'' should include a number.|Evaluate');
        Observer.Expect('eval W', 'error:The date formula ''W'' should include a number.|Evaluate');
        Observer.Expect('calc 2WD', 'ok:2024-01-17');
        Observer.Expect('eval 2WD', 'ok:stored=2WD|calc=2024-01-17');
        Observer.Expect('calc <W>', 'error:The date formula ''W'' should include a number.|Evaluate');
        Observer.Expect('eval <W>', 'error:The date formula ''W'' should include a number.|Evaluate');
        Observer.Expect('calc <2WD>', 'ok:2024-01-17');
        Observer.Expect('eval <2WD>', 'ok:stored=2WD|calc=2024-01-17');
        Observer.Expect('calc <1WD>', 'ok:2024-01-16');
        Observer.Expect('eval <1WD>', 'ok:stored=1WD|calc=2024-01-16');
        Observer.Expect('calc <WD>', 'error:The date formula ''WD'' should include a number.|Evaluate');
        Observer.Expect('eval <WD>', 'error:The date formula ''WD'' should include a number.|Evaluate');
        Observer.Expect('calc <+1W>', 'ok:2024-01-22');
        Observer.Expect('eval <+1W>', 'ok:stored=+1W|calc=2024-01-22');
        Observer.Expect('calc <CW>', 'ok:2024-01-21');
        Observer.Expect('eval <CW>', 'ok:stored=CW|calc=2024-01-21');
        Observer.Expect('calc <-CW>', 'ok:2024-01-15');
        Observer.Expect('eval <-CW>', 'ok:stored=-CW|calc=2024-01-15');
        Observer.Expect('calc <1WD+1D>', 'ok:2024-01-17');
        Observer.Expect('eval <1WD+1D>', 'ok:stored=1WD+1D|calc=2024-01-17');
        Observer.Verify();
    end;

    [Test]
    procedure TextsFromTheTestLibraries()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Both(Observer, '01/01/26');
        Both(Observer, 'Y');
        Both(Observer, '<Y>');
        Both(Observer, '8D+<1D>');
        Both(Observer, '<8D+<1D>>');
        Both(Observer, '<8D>+<1D>');
        Both(Observer, '1Y+1M');
        Both(Observer, '<1Y+1M>');
        Observer.Expect('calc 01/01/26', 'error:The date formula ''01/01/26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('eval 01/01/26', 'error:The date formula ''01/01/26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('calc Y', 'error:The date formula ''Y'' should include a number.|Evaluate');
        Observer.Expect('eval Y', 'error:The date formula ''Y'' should include a number.|Evaluate');
        Observer.Expect('calc <Y>', 'error:The date formula ''Y'' should include a number.|Evaluate');
        Observer.Expect('eval <Y>', 'error:The date formula ''Y'' should include a number.|Evaluate');
        Observer.Expect('calc 8D+<1D>', 'ok:2024-01-24');
        Observer.Expect('eval 8D+<1D>', 'ok:stored=8D+1D|calc=2024-01-24');
        Observer.Expect('calc <8D+<1D>>', 'ok:2024-01-24');
        Observer.Expect('eval <8D+<1D>>', 'ok:stored=8D+1D|calc=2024-01-24');
        Observer.Expect('calc <8D>+<1D>', 'ok:2024-01-24');
        Observer.Expect('eval <8D>+<1D>', 'ok:stored=8D+1D|calc=2024-01-24');
        Observer.Expect('calc 1Y+1M', 'ok:2025-02-15');
        Observer.Expect('eval 1Y+1M', 'ok:stored=1Y+1M|calc=2025-02-15');
        Observer.Expect('calc <1Y+1M>', 'ok:2025-02-15');
        Observer.Expect('eval <1Y+1M>', 'ok:stored=1Y+1M|calc=2025-02-15');
        Observer.Verify();
    end;

    // ---- Writer SG (2026-10-27): the day-of-month unit D with a number (<D31>, <D1>, <D15>, <-D15>, <CM+D5>) from several dates,
    // month ends and February included. CalcDate with the formula text, and Evaluate into a DateFormula (stored text, CalcDate). ----

    [TryFunction]
    local procedure SgTryCalcAt(Formula: Text; At: Date; var Result: Text)
    begin
        Result := Format(CalcDate(Formula, At), 0, 9);
    end;

    local procedure SgCalcAt(Formula: Text; At: Date): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if SgTryCalcAt(Formula, At, Result) then
            exit('ok:' + Result);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure SgDates(var Observer: Codeunit "Probe Observer"; Formula: Text)
    begin
        Observer.Observe(Formula + ' 01-10', SgCalcAt(Formula, 20240110D));
        Observer.Observe(Formula + ' 01-15', SgCalcAt(Formula, 20240115D));
        Observer.Observe(Formula + ' 01-31', SgCalcAt(Formula, 20240131D));
        Observer.Observe(Formula + ' 02-29', SgCalcAt(Formula, 20240229D));
        Observer.Observe(Formula + ' 2023-02-28', SgCalcAt(Formula, 20230228D));
        Observer.Observe(Formula + ' 04-30', SgCalcAt(Formula, 20240430D));
        Observer.Observe(Formula + ' 12-31', SgCalcAt(Formula, 20241231D));
    end;

    [Test]
    procedure SG_DayOfMonth_D1_D15()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgDates(Observer, '<D1>');
        SgDates(Observer, '<D15>');
        Observer.Expect('<D1> 01-10', 'ok:2024-02-01');
        Observer.Expect('<D1> 01-15', 'ok:2024-02-01');
        Observer.Expect('<D1> 01-31', 'ok:2024-02-01');
        Observer.Expect('<D1> 02-29', 'ok:2024-03-01');
        Observer.Expect('<D1> 2023-02-28', 'ok:2023-03-01');
        Observer.Expect('<D1> 04-30', 'ok:2024-05-01');
        Observer.Expect('<D1> 12-31', 'ok:2025-01-01');
        Observer.Expect('<D15> 01-10', 'ok:2024-01-15');
        Observer.Expect('<D15> 01-15', 'ok:2024-02-15');
        Observer.Expect('<D15> 01-31', 'ok:2024-02-15');
        Observer.Expect('<D15> 02-29', 'ok:2024-03-15');
        Observer.Expect('<D15> 2023-02-28', 'ok:2023-03-15');
        Observer.Expect('<D15> 04-30', 'ok:2024-05-15');
        Observer.Expect('<D15> 12-31', 'ok:2025-01-15');
        Observer.Verify();
    end;

    [Test]
    procedure SG_DayOfMonth_D29_D30_D31()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgDates(Observer, '<D29>');
        SgDates(Observer, '<D30>');
        SgDates(Observer, '<D31>');
        Observer.Expect('<D29> 01-10', 'ok:2024-01-29');
        Observer.Expect('<D29> 01-15', 'ok:2024-01-29');
        Observer.Expect('<D29> 01-31', 'ok:2024-02-29');
        Observer.Expect('<D29> 02-29', 'ok:2024-03-29');
        Observer.Expect('<D29> 2023-02-28', 'ok:2023-02-28');
        Observer.Expect('<D29> 04-30', 'ok:2024-05-29');
        Observer.Expect('<D29> 12-31', 'ok:2025-01-29');
        Observer.Expect('<D30> 01-10', 'ok:2024-01-30');
        Observer.Expect('<D30> 01-15', 'ok:2024-01-30');
        Observer.Expect('<D30> 01-31', 'ok:2024-02-29');
        Observer.Expect('<D30> 02-29', 'ok:2024-02-29');
        Observer.Expect('<D30> 2023-02-28', 'ok:2023-02-28');
        Observer.Expect('<D30> 04-30', 'ok:2024-05-30');
        Observer.Expect('<D30> 12-31', 'ok:2025-01-30');
        Observer.Expect('<D31> 01-10', 'ok:2024-01-31');
        Observer.Expect('<D31> 01-15', 'ok:2024-01-31');
        Observer.Expect('<D31> 01-31', 'ok:2024-02-29');
        Observer.Expect('<D31> 02-29', 'ok:2024-02-29');
        Observer.Expect('<D31> 2023-02-28', 'ok:2023-02-28');
        Observer.Expect('<D31> 04-30', 'ok:2024-04-30');
        Observer.Expect('<D31> 12-31', 'ok:2025-01-31');
        Observer.Verify();
    end;

    [Test]
    procedure SG_DayOfMonth_Backward()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgDates(Observer, '<-D1>');
        SgDates(Observer, '<-D15>');
        SgDates(Observer, '<-D31>');
        Observer.Expect('<-D1> 01-10', 'ok:2024-01-01');
        Observer.Expect('<-D1> 01-15', 'ok:2024-01-01');
        Observer.Expect('<-D1> 01-31', 'ok:2024-01-01');
        Observer.Expect('<-D1> 02-29', 'ok:2024-02-01');
        Observer.Expect('<-D1> 2023-02-28', 'ok:2023-02-01');
        Observer.Expect('<-D1> 04-30', 'ok:2024-04-01');
        Observer.Expect('<-D1> 12-31', 'ok:2024-12-01');
        Observer.Expect('<-D15> 01-10', 'ok:2023-12-15');
        Observer.Expect('<-D15> 01-15', 'ok:2023-12-15');
        Observer.Expect('<-D15> 01-31', 'ok:2024-01-15');
        Observer.Expect('<-D15> 02-29', 'ok:2024-02-15');
        Observer.Expect('<-D15> 2023-02-28', 'ok:2023-02-15');
        Observer.Expect('<-D15> 04-30', 'ok:2024-04-15');
        Observer.Expect('<-D15> 12-31', 'ok:2024-12-15');
        Observer.Expect('<-D31> 01-10', 'ok:2023-12-31');
        Observer.Expect('<-D31> 01-15', 'ok:2023-12-31');
        Observer.Expect('<-D31> 01-31', 'ok:2023-12-31');
        Observer.Expect('<-D31> 02-29', 'ok:2024-01-31');
        Observer.Expect('<-D31> 2023-02-28', 'ok:2023-01-31');
        Observer.Expect('<-D31> 04-30', 'ok:2024-03-31');
        Observer.Expect('<-D31> 12-31', 'ok:2024-11-30');
        Observer.Verify();
    end;

    [Test]
    procedure SG_DayOfMonth_Combined()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgDates(Observer, '<CM+D5>');
        SgDates(Observer, '<-CM+D5>');
        SgDates(Observer, '<1M+D15>');
        SgDates(Observer, '<D15+1M>');
        Observer.Expect('<CM+D5> 01-10', 'ok:2024-02-05');
        Observer.Expect('<CM+D5> 01-15', 'ok:2024-02-05');
        Observer.Expect('<CM+D5> 01-31', 'ok:2024-02-05');
        Observer.Expect('<CM+D5> 02-29', 'ok:2024-03-05');
        Observer.Expect('<CM+D5> 2023-02-28', 'ok:2023-03-05');
        Observer.Expect('<CM+D5> 04-30', 'ok:2024-05-05');
        Observer.Expect('<CM+D5> 12-31', 'ok:2025-01-05');
        Observer.Expect('<-CM+D5> 01-10', 'ok:2024-01-05');
        Observer.Expect('<-CM+D5> 01-15', 'ok:2024-01-05');
        Observer.Expect('<-CM+D5> 01-31', 'ok:2024-01-05');
        Observer.Expect('<-CM+D5> 02-29', 'ok:2024-02-05');
        Observer.Expect('<-CM+D5> 2023-02-28', 'ok:2023-02-05');
        Observer.Expect('<-CM+D5> 04-30', 'ok:2024-04-05');
        Observer.Expect('<-CM+D5> 12-31', 'ok:2024-12-05');
        Observer.Expect('<1M+D15> 01-10', 'ok:2024-02-15');
        Observer.Expect('<1M+D15> 01-15', 'ok:2024-03-15');
        Observer.Expect('<1M+D15> 01-31', 'ok:2024-03-15');
        Observer.Expect('<1M+D15> 02-29', 'ok:2024-04-15');
        Observer.Expect('<1M+D15> 2023-02-28', 'ok:2023-04-15');
        Observer.Expect('<1M+D15> 04-30', 'ok:2024-06-15');
        Observer.Expect('<1M+D15> 12-31', 'ok:2025-02-15');
        Observer.Expect('<D15+1M> 01-10', 'ok:2024-02-15');
        Observer.Expect('<D15+1M> 01-15', 'ok:2024-03-15');
        Observer.Expect('<D15+1M> 01-31', 'ok:2024-03-15');
        Observer.Expect('<D15+1M> 02-29', 'ok:2024-04-15');
        Observer.Expect('<D15+1M> 2023-02-28', 'ok:2023-04-15');
        Observer.Expect('<D15+1M> 04-30', 'ok:2024-06-15');
        Observer.Expect('<D15+1M> 12-31', 'ok:2025-02-15');
        Observer.Verify();
    end;

    [Test]
    procedure SG_DayOfMonth_EdgeNumbersAndEvaluate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<D0>', SgCalcAt('<D0>', 20240115D));
        Observer.Observe('<D32>', SgCalcAt('<D32>', 20240115D));
        Observer.Observe('<2D15>', SgCalcAt('<2D15>', 20240115D));
        Observer.Observe('<D>', SgCalcAt('<D>', 20240115D));
        Observer.Observe('D15 no brackets', SgCalcAt('D15', 20240115D));
        Observer.Observe('eval <D15>', Eval('<D15>'));
        Observer.Observe('eval <D31>', Eval('<D31>'));
        Observer.Observe('eval <CM+D5>', Eval('<CM+D5>'));
        Observer.Observe('eval <-D1>', Eval('<-D1>'));
        Observer.Expect('<D0>', 'error:The date formula ''D0'' contains a number that is too large.\\The number must be in the range 1 - 31.|Evaluate');
        Observer.Expect('<D32>', 'error:The date formula ''D32'' contains a number that is too large.\\The number must be in the range 1 - 31.|Evaluate');
        Observer.Expect('<2D15>', 'error:The date formula ''2D15'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('<D>', 'error:The date formula ''D'' should include a number.|Evaluate');
        Observer.Expect('D15 no brackets', 'ok:2024-02-15');
        Observer.Expect('eval <D15>', 'ok:stored=D15|calc=2024-02-15');
        Observer.Expect('eval <D31>', 'ok:stored=D31|calc=2024-01-31');
        Observer.Expect('eval <CM+D5>', 'ok:stored=CM+D5|calc=2024-02-05');
        Observer.Expect('eval <-D1>', 'ok:stored=-D1|calc=2024-01-01');
        Observer.Verify();
    end;

    // ---- Writer TV (NP lane, 2026-10-29): a unit letter followed by a number other than D and WD: M2 (and M1, M12, M13, M0, -M2, CM+M2,
    // 1Y+M2), W2, Q2 and Y2. CalcDate from several dates and Evaluate into a DateFormula. ----

    [Test]
    procedure TV_MonthNumber_M2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgDates(Observer, '<M2>');
        Observer.Observe('eval <M2>', Eval('<M2>'));
        Observer.Observe('M2 no brackets', SgCalcAt('M2', 20240115D));
        Observer.Expect('<M2> 01-10', 'ok:2024-02-01');
        Observer.Expect('<M2> 01-15', 'ok:2024-02-01');
        Observer.Expect('<M2> 01-31', 'ok:2024-02-01');
        Observer.Expect('<M2> 02-29', 'ok:2025-02-01');
        Observer.Expect('<M2> 2023-02-28', 'ok:2024-02-01');
        Observer.Expect('<M2> 04-30', 'ok:2025-02-01');
        Observer.Expect('<M2> 12-31', 'ok:2025-02-01');
        Observer.Expect('eval <M2>', 'ok:stored=M2|calc=2024-02-01');
        Observer.Expect('M2 no brackets', 'ok:2024-02-01');
        Observer.Verify();
    end;

    [Test]
    procedure TV_MonthNumber_M1_M12()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SgDates(Observer, '<M1>');
        SgDates(Observer, '<M12>');
        Observer.Expect('<M1> 01-10', 'ok:2025-01-01');
        Observer.Expect('<M1> 01-15', 'ok:2025-01-01');
        Observer.Expect('<M1> 01-31', 'ok:2025-01-01');
        Observer.Expect('<M1> 02-29', 'ok:2025-01-01');
        Observer.Expect('<M1> 2023-02-28', 'ok:2024-01-01');
        Observer.Expect('<M1> 04-30', 'ok:2025-01-01');
        Observer.Expect('<M1> 12-31', 'ok:2025-01-01');
        Observer.Expect('<M12> 01-10', 'ok:2024-12-01');
        Observer.Expect('<M12> 01-15', 'ok:2024-12-01');
        Observer.Expect('<M12> 01-31', 'ok:2024-12-01');
        Observer.Expect('<M12> 02-29', 'ok:2024-12-01');
        Observer.Expect('<M12> 2023-02-28', 'ok:2023-12-01');
        Observer.Expect('<M12> 04-30', 'ok:2024-12-01');
        Observer.Expect('<M12> 12-31', 'ok:2025-12-01');
        Observer.Verify();
    end;

    [Test]
    procedure TV_MonthNumber_EdgesAndCombined()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<M0>', SgCalcAt('<M0>', 20240115D));
        Observer.Observe('<M13>', SgCalcAt('<M13>', 20240115D));
        Observer.Observe('<-M2> 01-15', SgCalcAt('<-M2>', 20240115D));
        Observer.Observe('<-M2> 04-30', SgCalcAt('<-M2>', 20240430D));
        Observer.Observe('<-M2> 02-29', SgCalcAt('<-M2>', 20240229D));
        Observer.Observe('<CM+M2> 01-15', SgCalcAt('<CM+M2>', 20240115D));
        Observer.Observe('<M2+D10> 01-15', SgCalcAt('<M2+D10>', 20240115D));
        Observer.Observe('<1Y+M2> 01-15', SgCalcAt('<1Y+M2>', 20240115D));
        Observer.Observe('<2M2>', SgCalcAt('<2M2>', 20240115D));
        Observer.Observe('eval <-M2>', Eval('<-M2>'));
        Observer.Observe('eval <M12>', Eval('<M12>'));
        Observer.Expect('<M0>', 'error:The date formula ''M0'' contains a number that is too large.\\The number must be in the range 1 - 12.|Evaluate');
        Observer.Expect('<M13>', 'error:The date formula ''M13'' contains a number that is too large.\\The number must be in the range 1 - 12.|Evaluate');
        Observer.Expect('<-M2> 01-15', 'ok:2023-02-01');
        Observer.Expect('<-M2> 04-30', 'ok:2024-02-01');
        Observer.Expect('<-M2> 02-29', 'ok:2023-02-01');
        Observer.Expect('<CM+M2> 01-15', 'ok:2024-02-01');
        Observer.Expect('<M2+D10> 01-15', 'ok:2024-02-10');
        Observer.Expect('<1Y+M2> 01-15', 'ok:2025-02-01');
        Observer.Expect('<2M2>', 'error:The date formula ''2M2'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('eval <-M2>', 'ok:stored=-M2|calc=2023-02-01');
        Observer.Expect('eval <M12>', 'ok:stored=M12|calc=2024-12-01');
        Observer.Verify();
    end;

    [Test]
    procedure TV_OtherUnitsWithNumber_W2_Q2_Y2()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<W2> 01-15', SgCalcAt('<W2>', 20240115D));
        Observer.Observe('<W2> 12-31', SgCalcAt('<W2>', 20241231D));
        Observer.Observe('<W53> 01-15', SgCalcAt('<W53>', 20240115D));
        Observer.Observe('<Q2> 01-15', SgCalcAt('<Q2>', 20240115D));
        Observer.Observe('<Q2> 05-20', SgCalcAt('<Q2>', 20240520D));
        Observer.Observe('<Q5> 01-15', SgCalcAt('<Q5>', 20240115D));
        Observer.Observe('<Y2> 01-15', SgCalcAt('<Y2>', 20240115D));
        Observer.Observe('eval <W2>', Eval('<W2>'));
        Observer.Observe('eval <Q2>', Eval('<Q2>'));
        Observer.Expect('<W2> 01-15', 'ok:2025-01-06');
        Observer.Expect('<W2> 12-31', 'ok:2025-01-06');
        Observer.Expect('<W53> 01-15', 'ok:2024-12-23');
        Observer.Expect('<Q2> 01-15', 'ok:2024-04-01');
        Observer.Expect('<Q2> 05-20', 'ok:2025-04-01');
        Observer.Expect('<Q5> 01-15', 'error:The date formula ''Q5'' contains a number that is too large.\\The number must be in the range 1 - 4.|Evaluate');
        Observer.Expect('<Y2> 01-15', 'ok:2102-01-01');
        Observer.Expect('eval <W2>', 'ok:stored=W2|calc=2025-01-06');
        Observer.Expect('eval <Q2>', 'ok:stored=Q2|calc=2024-04-01');
        Observer.Verify();
    end;
}
