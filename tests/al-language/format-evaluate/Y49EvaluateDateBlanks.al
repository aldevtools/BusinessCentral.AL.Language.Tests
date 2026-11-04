// Probe: Evaluate into a Date as a statement (result unused, inside a [TryFunction]) for texts with blanks and other characters
// ('not a date', '2024 03 05', '5. März', ...), with and without format number 9; the same texts with the result used; Evaluate statements into
// a Duration (number 0), DateFormula, Char and BigInteger that fail.
// Gap cycle 5, spec G5-11 (writer Y49). Object ids: codeunit 92945.
// Fixtures used: Probe Observer (codeunit 69160).
// Culture: the corpus tier runs en-US.

codeunit 92945 "LT Y49 Evaluate Date Blanks"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    [TryFunction]
    local procedure TryEvalDate(Txt: Text)
    var
        D: Date;
    begin
        Evaluate(D, Txt);
    end;

    [TryFunction]
    local procedure TryEvalDateN(Txt: Text; N: Integer)
    var
        D: Date;
    begin
        Evaluate(D, Txt, N);
    end;

    // The error text is observed once in full ('not a date'); for the other texts the observation says whether the text is the same with the
    // input in place of 'not a date' (the observer keeps about 1800 characters per test).
    local procedure ObsStmt(Txt: Text; N: Integer)
    var
        Name: Text;
        Ok: Boolean;
        Template: Text;
    begin
        Name := '[' + Txt + ']';
        ClearLastError();
        if TryEvalDate('not a date') then;
        Template := GetLastErrorText();
        ClearLastError();
        if N < 0 then
            Ok := TryEvalDate(Txt)
        else begin
            Ok := TryEvalDateN(Txt, N);
            Name += ' ' + Format(N);
        end;
        Observer.Observe(Name, Format(Ok));
        if not Ok then begin
            if Txt = 'not a date' then
                Observer.Observe(Name + '|text', GetLastErrorText())
            else
                Observer.Observe(Name + '|text is the not-a-date text with this input', Format(GetLastErrorText() = Template.Replace('not a date', Txt)));
            Observer.Observe(Name + '|code', GetLastErrorCode());
            ClearLastError();
        end;
    end;

    // A text that parses gets the year (and for some texts the month) of today: only the day is observed then.
    local procedure ObsUsed(Txt: Text)
    var
        D: Date;
        Ok: Boolean;
    begin
        D := 20000101D;
        ClearLastError();
        Ok := Evaluate(D, Txt);
        if Ok then
            Observer.Observe('[' + Txt + ']', 'Yes day ' + Format(Date2DMY(D, 1)) + ' err=' + Format(GetLastErrorText() <> ''))
        else
            Observer.Observe('[' + Txt + ']', 'No ' + Format(D, 0, 9) + ' err=' + Format(GetLastErrorText() <> ''));
        ClearLastError();
    end;

    [Test]
    procedure EvalStmt_Date_TextWithBlanks()
    begin
        ObsStmt('not a date', -1);
        ObsStmt('abc def', -1);
        ObsStmt('a b', -1);
        ObsStmt(' x', -1);
        ObsStmt('12 34', -1);
        ObsStmt('2024 03 05', -1);
        Observer.Expect('[not a date]', 'No');
        Observer.Expect('[not a date]|text', 'The format of the Date ''not a date'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('[not a date]|code', 'Evaluate');
        Observer.Expect('[abc def]', 'No');
        Observer.Expect('[abc def]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[abc def]|code', 'Evaluate');
        Observer.Expect('[a b]', 'No');
        Observer.Expect('[a b]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[a b]|code', 'Evaluate');
        Observer.Expect('[ x]', 'No');
        Observer.Expect('[ x]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[ x]|code', 'Evaluate');
        Observer.Expect('[12 34]', 'No');
        Observer.Expect('[12 34]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[12 34]|code', 'Evaluate');
        Observer.Expect('[2024 03 05]', 'No');
        Observer.Expect('[2024 03 05]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[2024 03 05]|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure EvalStmt_Date_OtherChars()
    begin
        ObsStmt('5. März', -1);
        ObsStmt('abc,def', -1);
        ObsStmt('12:30', -1);
        ObsStmt('x_y', -1);
        ObsStmt('!', -1);
        Observer.Expect('[5. März]', 'Yes');
        Observer.Expect('[abc,def]', 'No');
        Observer.Expect('[abc,def]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[abc,def]|code', 'Evaluate');
        Observer.Expect('[12:30]', 'Yes');
        Observer.Expect('[x_y]', 'No');
        Observer.Expect('[x_y]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[x_y]|code', 'Evaluate');
        Observer.Expect('[!]', 'No');
        Observer.Expect('[!]|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[!]|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure EvalStmt_Date_TextWithBlanks_Number9()
    begin
        ObsStmt('not a date', 9);
        ObsStmt('abc def', 9);
        ObsStmt('a b', 9);
        ObsStmt(' x', 9);
        ObsStmt('12 34', 9);
        ObsStmt('2024 03 05', 9);
        Observer.Expect('[not a date] 9', 'No');
        Observer.Expect('[not a date] 9|text', 'The format of the Date ''not a date'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('[not a date] 9|code', 'Evaluate');
        Observer.Expect('[abc def] 9', 'No');
        Observer.Expect('[abc def] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[abc def] 9|code', 'Evaluate');
        Observer.Expect('[a b] 9', 'No');
        Observer.Expect('[a b] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[a b] 9|code', 'Evaluate');
        Observer.Expect('[ x] 9', 'No');
        Observer.Expect('[ x] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[ x] 9|code', 'Evaluate');
        Observer.Expect('[12 34] 9', 'No');
        Observer.Expect('[12 34] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[12 34] 9|code', 'Evaluate');
        Observer.Expect('[2024 03 05] 9', 'No');
        Observer.Expect('[2024 03 05] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[2024 03 05] 9|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure EvalStmt_Date_OtherChars_Number9()
    begin
        ObsStmt('5. März', 9);
        ObsStmt('abc,def', 9);
        ObsStmt('12:30', 9);
        ObsStmt('x_y', 9);
        ObsStmt('!', 9);
        ObsStmt('not a date', 0);
        Observer.Expect('[5. März] 9', 'No');
        Observer.Expect('[5. März] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[5. März] 9|code', 'Evaluate');
        Observer.Expect('[abc,def] 9', 'No');
        Observer.Expect('[abc,def] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[abc,def] 9|code', 'Evaluate');
        Observer.Expect('[12:30] 9', 'No');
        Observer.Expect('[12:30] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[12:30] 9|code', 'Evaluate');
        Observer.Expect('[x_y] 9', 'No');
        Observer.Expect('[x_y] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[x_y] 9|code', 'Evaluate');
        Observer.Expect('[!] 9', 'No');
        Observer.Expect('[!] 9|text is the not-a-date text with this input', 'Yes');
        Observer.Expect('[!] 9|code', 'Evaluate');
        Observer.Expect('[not a date] 0', 'No');
        Observer.Expect('[not a date] 0|text', 'The format of the Date ''not a date'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('[not a date] 0|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure EvalStmt_Date_Asserterror()
    var
        D: Date;
    begin
        asserterror Evaluate(D, 'not a date');
        Observer.ObserveError('asserterror not a date');
        asserterror Evaluate(D, 'not a date', 9);
        Observer.Observe('asserterror not a date 9|code', GetLastErrorCode());
        ClearLastError();
        Observer.Expect('asserterror not a date|text', 'The format of the Date ''not a date'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('asserterror not a date|code', 'Evaluate');
        Observer.Expect('asserterror not a date 9|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure EvalStmt_Date_ResultUsed_SameTexts()
    begin
        ObsUsed('not a date');
        ObsUsed('abc def');
        ObsUsed('a b');
        ObsUsed(' x');
        ObsUsed('12 34');
        ObsUsed('2024 03 05');
        ObsUsed('5. März');
        ObsUsed('abc,def');
        ObsUsed('12:30');
        ObsUsed('x_y');
        ObsUsed('!');
        Observer.Expect('[not a date]', 'No 2000-01-01 err=No');
        Observer.Expect('[abc def]', 'No 2000-01-01 err=No');
        Observer.Expect('[a b]', 'No 2000-01-01 err=No');
        Observer.Expect('[ x]', 'No 2000-01-01 err=No');
        Observer.Expect('[12 34]', 'No 2000-01-01 err=Yes');
        Observer.Expect('[2024 03 05]', 'No 2000-01-01 err=No');
        Observer.Expect('[5. März]', 'Yes day 5 err=No');
        Observer.Expect('[abc,def]', 'No 2000-01-01 err=No');
        Observer.Expect('[12:30]', 'Yes day 30 err=No');
        Observer.Expect('[x_y]', 'No 2000-01-01 err=No');
        Observer.Expect('[!]', 'No 2000-01-01 err=No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvalDur(Txt: Text)
    var
        Dur: Duration;
    begin
        Evaluate(Dur, Txt);
    end;

    [TryFunction]
    local procedure TryEvalDur0(Txt: Text)
    var
        Dur: Duration;
    begin
        Evaluate(Dur, Txt, 0);
    end;

    [Test]
    procedure EvalStmt_Duration_Number0()
    var
        Dur: Duration;
        Ok: Boolean;
    begin
        ClearLastError();
        Observer.Observe('dur', Format(TryEvalDur('abc')));
        Observer.ObserveError('dur');
        Observer.Observe('dur 0', Format(TryEvalDur0('abc')));
        Observer.ObserveError('dur 0');
        Ok := Evaluate(Dur, 'abc', 0);
        Observer.Observe('dur 0 used', Format(Ok));
        ClearLastError();
        Observer.Expect('dur', 'No');
        Observer.Expect('dur|text', 'The value "abc" can''t be evaluated into type Duration.');
        Observer.Expect('dur|code', 'Evaluate');
        Observer.Expect('dur 0', 'No');
        Observer.Expect('dur 0|text', 'The value "abc" can''t be evaluated into type Duration.');
        Observer.Expect('dur 0|code', 'Evaluate');
        Observer.Expect('dur 0 used', 'No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvalDf(Txt: Text)
    var
        Df: DateFormula;
    begin
        Evaluate(Df, Txt);
    end;

    [TryFunction]
    local procedure TryEvalCh(Txt: Text)
    var
        Ch: Char;
    begin
        Evaluate(Ch, Txt);
    end;

    [TryFunction]
    local procedure TryEvalBi(Txt: Text)
    var
        Bi: BigInteger;
    begin
        Evaluate(Bi, Txt);
    end;

    [Test]
    procedure EvalStmt_OtherTargets()
    begin
        ClearLastError();
        Observer.Observe('dateformula', Format(TryEvalDf('zz')));
        Observer.ObserveError('dateformula');
        Observer.Observe('char', Format(TryEvalCh('ab')));
        Observer.ObserveError('char');
        Observer.Observe('biginteger', Format(TryEvalBi('x')));
        Observer.ObserveError('biginteger');
        Observer.Expect('dateformula', 'No');
        Observer.Expect('dateformula|text', 'The date formula ''ZZ'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('dateformula|code', 'Evaluate');
        Observer.Expect('char', 'No');
        Observer.Expect('char|text', 'The value "ab" can''t be evaluated into type Char.');
        Observer.Expect('char|code', 'Evaluate');
        Observer.Expect('biginteger', 'No');
        Observer.Expect('biginteger|text', 'The value "x" can''t be evaluated into type BigInteger.');
        Observer.Expect('biginteger|code', 'Evaluate');
        Observer.Verify();
    end;
}
