// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-string-date-method
// Scope: in-scope. CalcDate whose result falls after 9999-12-31 or before 0001-01-01, in every way a caller can catch the error: Codeunit.Run
//   with its return value used, a [TryFunction] whose Boolean is read, asserterror with and without reading the error. Formulas: +1Y, +1D,
//   CM+1D from 9999-12-31; +10000Y from Today and from WorkDate (one argument); +9999Y from Today; -1D and -1Y from 0001-01-01; +1D from the
//   closing date C9999-12-31; the DateFormula overload. Limits: +0D and CY from 9999-12-31, +0D, -1D and CY from C9999-12-31, +0D, +1D
//   and -CY from 0001-01-01, +0D, -1D and -2D from 0001-01-02, -1D from 0001-01-03, +1Y from 9998-12-31.
// Fixtures used: Probe Observer (69160); self-contained codeunits 73815 (test) and 73816 (the codeunit that Codeunit.Run runs).
// Probe: written for al-runner issue 7944, observed by the corpus CI legs 27.5, 28.5 and 29.0. Every literal asserted below is what BC produced.
// Facts: <case> run is the return value of Codeunit.Run, <case> try the return value of the [TryFunction]; <case>|text and <case>|code are
//   GetLastErrorText and GetLastErrorCode after a failed call; <case> result is Format(date, 0, 9) after a call that did not fail;
//   D after is Format(D, 0, 9) of the target variable (set to 2024-01-01 before) after the failed statement.
// Results (same on 27.5, 28.5 and 29.0): a result after 9999-12-31 or before 0001-01-01 raises 'The date is not valid.' with code
//   DateInvalid; Codeunit.Run and the [TryFunction] return false, and the target variable keeps its old value (also after asserterror).
//   Any CalcDate with the base 0001-01-01 raises the same error, even +0D and +1D. A number above 9999 in the formula (+10000Y) raises
//   the formula error 'The date formula ''+10000Y'' contains a number that is too large.' (code Evaluate) before any date is computed.
//   +0D and CY from 9999-12-31 and +1Y from 9998-12-31 give 9999-12-31 without an error.
// BC versions: 27, 28, 29

codeunit 73816 "LT DtT CalcDate Ovf Run"
{
    var
        CaseNo: Integer;
        Result: Date;

    trigger OnRun()
    var
        DF: DateFormula;
    begin
        case CaseNo of
            1:
                Result := CalcDate('<+1Y>', 99991231D);
            2:
                Result := CalcDate('<+1D>', 99991231D);
            3:
                Result := CalcDate('<CM+1D>', 99991231D);
            4:
                Result := CalcDate('<+10000Y>', Today());
            5:
                Result := CalcDate('<-1D>', 00010101D);
            6:
                Result := CalcDate('<-1Y>', 00010101D);
            7:
                Result := CalcDate('<+1D>', ClosingDate(99991231D));
            8:
                begin
                    Evaluate(DF, '<+1Y>');
                    Result := CalcDate(DF, 99991231D);
                end;
            9:
                Result := CalcDate('<+10000Y>');
            10:
                Result := CalcDate('<+0D>', 99991231D);
            11:
                Result := CalcDate('<CY>', 99991231D);
            12:
                Result := CalcDate('<+0D>', ClosingDate(99991231D));
            13:
                Result := CalcDate('<+0D>', 00010101D);
            14:
                Result := CalcDate('<+1D>', 00010101D);
            15:
                Result := CalcDate('<-CY>', 00010101D);
            16:
                Result := CalcDate('<+1Y>', 99981231D);
            17:
                Result := CalcDate('<+9999Y>', Today());
            18:
                Result := CalcDate('<+0D>', 00010102D);
            19:
                Result := CalcDate('<-1D>', 00010102D);
            20:
                Result := CalcDate('<-1D>', 00010103D);
            21:
                Result := CalcDate('<-2D>', 00010102D);
        end;
    end;

    procedure SetCase(NewCaseNo: Integer)
    begin
        CaseNo := NewCaseNo;
        Result := 20240101D;
    end;

    procedure GetResult(): Date
    begin
        exit(Result);
    end;
}

codeunit 73815 "LT DtT CalcDate Overflow"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CaseName(CaseNo: Integer): Text
    begin
        case CaseNo of
            1:
                exit('+1Y 9999-12-31');
            2:
                exit('+1D 9999-12-31');
            3:
                exit('CM+1D 9999-12-31');
            4:
                exit('+10000Y today');
            5:
                exit('-1D 0001-01-01');
            6:
                exit('-1Y 0001-01-01');
            7:
                exit('+1D C9999-12-31');
            8:
                exit('DateFormula +1Y 9999-12-31');
            9:
                exit('+10000Y workdate');
            10:
                exit('+0D 9999-12-31');
            11:
                exit('CY 9999-12-31');
            12:
                exit('+0D C9999-12-31');
            13:
                exit('+0D 0001-01-01');
            14:
                exit('+1D 0001-01-01');
            15:
                exit('-CY 0001-01-01');
            16:
                exit('+1Y 9998-12-31');
            17:
                exit('+9999Y today');
            18:
                exit('+0D 0001-01-02');
            19:
                exit('-1D 0001-01-02');
            20:
                exit('-1D 0001-01-03');
            21:
                exit('-2D 0001-01-02');
        end;
    end;

    [TryFunction]
    local procedure TryCase(CaseNo: Integer; var D: Date)
    var
        DF: DateFormula;
    begin
        case CaseNo of
            1:
                D := CalcDate('<+1Y>', 99991231D);
            2:
                D := CalcDate('<+1D>', 99991231D);
            3:
                D := CalcDate('<CM+1D>', 99991231D);
            4:
                D := CalcDate('<+10000Y>', Today());
            5:
                D := CalcDate('<-1D>', 00010101D);
            6:
                D := CalcDate('<-1Y>', 00010101D);
            7:
                D := CalcDate('<+1D>', ClosingDate(99991231D));
            8:
                begin
                    Evaluate(DF, '<+1Y>');
                    D := CalcDate(DF, 99991231D);
                end;
            9:
                D := CalcDate('<+10000Y>');
            10:
                D := CalcDate('<+0D>', 99991231D);
            11:
                D := CalcDate('<CY>', 99991231D);
            12:
                D := CalcDate('<+0D>', ClosingDate(99991231D));
            13:
                D := CalcDate('<+0D>', 00010101D);
            14:
                D := CalcDate('<+1D>', 00010101D);
            15:
                D := CalcDate('<-CY>', 00010101D);
            16:
                D := CalcDate('<+1Y>', 99981231D);
            17:
                D := CalcDate('<+9999Y>', Today());
            18:
                D := CalcDate('<+0D>', 00010102D);
            19:
                D := CalcDate('<-1D>', 00010102D);
            20:
                D := CalcDate('<-1D>', 00010103D);
            21:
                D := CalcDate('<-2D>', 00010102D);
        end;
    end;

    [TryFunction]
    local procedure TryPlusOneYear(var D: Date)
    begin
        D := CalcDate('<+1Y>', 99991231D);
    end;

    local procedure ObserveRun(var Observer: Codeunit "Probe Observer"; CaseNo: Integer)
    var
        Runner: Codeunit "LT DtT CalcDate Ovf Run";
        Ok: Boolean;
    begin
        ClearLastError();
        Runner.SetCase(CaseNo);
        Ok := Runner.Run();
        Observer.Observe(CaseName(CaseNo) + ' run', Format(Ok));
        if Ok then
            Observer.Observe(CaseName(CaseNo) + ' result', Format(Runner.GetResult(), 0, 9))
        else
            Observer.ObserveError(CaseName(CaseNo));
    end;

    local procedure ObserveTry(var Observer: Codeunit "Probe Observer"; CaseNo: Integer)
    var
        D: Date;
        Ok: Boolean;
    begin
        ClearLastError();
        D := 20240101D;
        Ok := TryCase(CaseNo, D);
        Observer.Observe(CaseName(CaseNo) + ' try', Format(Ok));
        if Ok then
            Observer.Observe(CaseName(CaseNo) + ' result', Format(D, 0, 9))
        else begin
            Observer.Observe(CaseName(CaseNo) + ' D after', Format(D, 0, 9));
            Observer.ObserveError(CaseName(CaseNo));
        end;
    end;

    [Test]
    procedure CodeunitRun_PlusOneYearFromMax_ReturnsFalse()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveRun(Observer, 1);
        Observer.Expect('+1Y 9999-12-31 run', 'No');
        Observer.Expect('+1Y 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('+1Y 9999-12-31|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_OverflowCases_ReturnFalse()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 2 to 9 do
            ObserveRun(Observer, CaseNo);
        Observer.Expect('+1D 9999-12-31 run', 'No');
        Observer.Expect('+1D 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('+1D 9999-12-31|code', 'DateInvalid');
        Observer.Expect('CM+1D 9999-12-31 run', 'No');
        Observer.Expect('CM+1D 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('CM+1D 9999-12-31|code', 'DateInvalid');
        Observer.Expect('+10000Y today run', 'No');
        Observer.Expect('+10000Y today|text', 'The date formula ''+10000Y'' contains a number that is too large.\\The number must be in the range 0 - 9999.');
        Observer.Expect('+10000Y today|code', 'Evaluate');
        Observer.Expect('-1D 0001-01-01 run', 'No');
        Observer.Expect('-1D 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('-1D 0001-01-01|code', 'DateInvalid');
        Observer.Expect('-1Y 0001-01-01 run', 'No');
        Observer.Expect('-1Y 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('-1Y 0001-01-01|code', 'DateInvalid');
        Observer.Expect('+1D C9999-12-31 run', 'No');
        Observer.Expect('+1D C9999-12-31|text', 'The date is not valid.');
        Observer.Expect('+1D C9999-12-31|code', 'DateInvalid');
        Observer.Expect('DateFormula +1Y 9999-12-31 run', 'No');
        Observer.Expect('DateFormula +1Y 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('DateFormula +1Y 9999-12-31|code', 'DateInvalid');
        Observer.Expect('+10000Y workdate run', 'No');
        Observer.Expect('+10000Y workdate|text', 'The date formula ''+10000Y'' contains a number that is too large.\\The number must be in the range 0 - 9999.');
        Observer.Expect('+10000Y workdate|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_BoundaryCases()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 10 to 16 do
            ObserveRun(Observer, CaseNo);
        Observer.Expect('+0D 9999-12-31 run', 'Yes');
        Observer.Expect('+0D 9999-12-31 result', '9999-12-31');
        Observer.Expect('CY 9999-12-31 run', 'Yes');
        Observer.Expect('CY 9999-12-31 result', '9999-12-31');
        Observer.Expect('+0D C9999-12-31 run', 'Yes');
        Observer.Expect('+0D C9999-12-31 result', '9999-12-31');
        Observer.Expect('+0D 0001-01-01 run', 'No');
        Observer.Expect('+0D 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('+0D 0001-01-01|code', 'DateInvalid');
        Observer.Expect('+1D 0001-01-01 run', 'No');
        Observer.Expect('+1D 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('+1D 0001-01-01|code', 'DateInvalid');
        Observer.Expect('-CY 0001-01-01 run', 'No');
        Observer.Expect('-CY 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('-CY 0001-01-01|code', 'DateInvalid');
        Observer.Expect('+1Y 9998-12-31 run', 'Yes');
        Observer.Expect('+1Y 9998-12-31 result', '9999-12-31');
        Observer.Verify();
    end;

    [Test]
    procedure CodeunitRun_MinDateNeighbors()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 17 to 21 do
            ObserveRun(Observer, CaseNo);
        Observer.Finish();
    end;

    [Test]
    procedure TryFunction_PlusOneYearFromMax_BooleanOnly()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240101D;
        Observer.Observe('try', Format(TryPlusOneYear(D)));
        Observer.Observe('D after', Format(D, 0, 9));
        Observer.Expect('try', 'No');
        Observer.Expect('D after', '2024-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_PlusOneYearFromMax_ErrorRead()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240101D;
        Observer.Observe('try', Format(TryPlusOneYear(D)));
        Observer.ObserveError('try');
        Observer.Expect('try', 'No');
        Observer.Expect('try|text', 'The date is not valid.');
        Observer.Expect('try|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_OverflowCases_ReturnFalse()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 2 to 5 do
            ObserveTry(Observer, CaseNo);
        Observer.Expect('+1D 9999-12-31 try', 'No');
        Observer.Expect('+1D 9999-12-31 D after', '2024-01-01');
        Observer.Expect('+1D 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('+1D 9999-12-31|code', 'DateInvalid');
        Observer.Expect('CM+1D 9999-12-31 try', 'No');
        Observer.Expect('CM+1D 9999-12-31 D after', '2024-01-01');
        Observer.Expect('CM+1D 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('CM+1D 9999-12-31|code', 'DateInvalid');
        Observer.Expect('+10000Y today try', 'No');
        Observer.Expect('+10000Y today D after', '2024-01-01');
        Observer.Expect('+10000Y today|text', 'The date formula ''+10000Y'' contains a number that is too large.\\The number must be in the range 0 - 9999.');
        Observer.Expect('+10000Y today|code', 'Evaluate');
        Observer.Expect('-1D 0001-01-01 try', 'No');
        Observer.Expect('-1D 0001-01-01 D after', '2024-01-01');
        Observer.Expect('-1D 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('-1D 0001-01-01|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_OverflowCases2_ReturnFalse()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 6 to 9 do
            ObserveTry(Observer, CaseNo);
        Observer.Expect('-1Y 0001-01-01 try', 'No');
        Observer.Expect('-1Y 0001-01-01 D after', '2024-01-01');
        Observer.Expect('-1Y 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('-1Y 0001-01-01|code', 'DateInvalid');
        Observer.Expect('+1D C9999-12-31 try', 'No');
        Observer.Expect('+1D C9999-12-31 D after', '2024-01-01');
        Observer.Expect('+1D C9999-12-31|text', 'The date is not valid.');
        Observer.Expect('+1D C9999-12-31|code', 'DateInvalid');
        Observer.Expect('DateFormula +1Y 9999-12-31 try', 'No');
        Observer.Expect('DateFormula +1Y 9999-12-31 D after', '2024-01-01');
        Observer.Expect('DateFormula +1Y 9999-12-31|text', 'The date is not valid.');
        Observer.Expect('DateFormula +1Y 9999-12-31|code', 'DateInvalid');
        Observer.Expect('+10000Y workdate try', 'No');
        Observer.Expect('+10000Y workdate D after', '2024-01-01');
        Observer.Expect('+10000Y workdate|text', 'The date formula ''+10000Y'' contains a number that is too large.\\The number must be in the range 0 - 9999.');
        Observer.Expect('+10000Y workdate|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_BoundaryCases()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 10 to 16 do
            ObserveTry(Observer, CaseNo);
        Observer.Expect('+0D 9999-12-31 try', 'Yes');
        Observer.Expect('+0D 9999-12-31 result', '9999-12-31');
        Observer.Expect('CY 9999-12-31 try', 'Yes');
        Observer.Expect('CY 9999-12-31 result', '9999-12-31');
        Observer.Expect('+0D C9999-12-31 try', 'Yes');
        Observer.Expect('+0D C9999-12-31 result', '9999-12-31');
        Observer.Expect('+0D 0001-01-01 try', 'No');
        Observer.Expect('+0D 0001-01-01 D after', '2024-01-01');
        Observer.Expect('+0D 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('+0D 0001-01-01|code', 'DateInvalid');
        Observer.Expect('+1D 0001-01-01 try', 'No');
        Observer.Expect('+1D 0001-01-01 D after', '2024-01-01');
        Observer.Expect('+1D 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('+1D 0001-01-01|code', 'DateInvalid');
        Observer.Expect('-CY 0001-01-01 try', 'No');
        Observer.Expect('-CY 0001-01-01 D after', '2024-01-01');
        Observer.Expect('-CY 0001-01-01|text', 'The date is not valid.');
        Observer.Expect('-CY 0001-01-01|code', 'DateInvalid');
        Observer.Expect('+1Y 9998-12-31 try', 'Yes');
        Observer.Expect('+1Y 9998-12-31 result', '9999-12-31');
        Observer.Verify();
    end;

    [Test]
    procedure AssertError_PlusOneYearFromMax_TextNotRead()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240101D;
        asserterror D := CalcDate('<+1Y>', 99991231D);
        Observer.Observe('reached', 'yes');
        Observer.Observe('D after', Format(D, 0, 9));
        Observer.Expect('reached', 'yes');
        Observer.Expect('D after', '2024-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure AssertError_PlusOneYearFromMax_ErrorRead()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240101D;
        asserterror D := CalcDate('<+1Y>', 99991231D);
        Observer.ObserveError('asserterror');
        Observer.Observe('D after', Format(D, 0, 9));
        Observer.Expect('asserterror|text', 'The date is not valid.');
        Observer.Expect('asserterror|code', 'DateInvalid');
        Observer.Expect('D after', '2024-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure TryFunction_MinDateNeighbors()
    var
        Observer: Codeunit "Probe Observer";
        CaseNo: Integer;
    begin
        for CaseNo := 17 to 21 do
            ObserveTry(Observer, CaseNo);
        Observer.Finish();
    end;

    [Test]
    procedure ClosingDate_Results_StayClosing()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := CalcDate('<+0D>', ClosingDate(99991231D));
        Observer.Observe('+0D C9999-12-31 is closing', Format(D = ClosingDate(D)));
        Observer.Observe('+0D C9999-12-31 format', Format(D));
        D := CalcDate('<-1D>', ClosingDate(99991231D));
        Observer.Observe('-1D C9999-12-31 is closing', Format(D = ClosingDate(D)));
        Observer.Observe('-1D C9999-12-31 result', Format(D, 0, 9));
        D := CalcDate('<CY>', ClosingDate(99991231D));
        Observer.Observe('CY C9999-12-31 is closing', Format(D = ClosingDate(D)));
        Observer.Observe('CY C9999-12-31 result', Format(D, 0, 9));
        Observer.Finish();
    end;
}
