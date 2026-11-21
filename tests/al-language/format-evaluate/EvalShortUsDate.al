// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-joker-text-integer-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own test codeunit 74074
// Probe (al-runner issues 8643 and 8644): Evaluate of a short US date (MM/DD/YY) into DateTime without a number and with number 0
//   (8643: 02/01/25, 01/01/25, 12/31/24, 01/01/28), and Evaluate of a date with a time (01/04/25 12:00 PM) into Date (8644).
// Area: texts of the forms M/D/YY, MM/DD/YY, MM/DD/YYYY, with and without a time (h:mm AM/PM, hh:mm, hh:mm:ss), a day or month that
//   does not exist, a time past 23:59, a time that is not one; targets Date and DateTime; no number, number 0 and number 9; the
//   Boolean-return form (return value, value, whether a last error is left) and the statement form (value or error text and code);
//   the reporter's two-step ParseDate procedure.
// Settings: date texts are read with the session's regional settings and DateTime texts in the session's time zone. The test
//   `Settings_OfTheSession` records them (the format of a known date and DateTime, GlobalLanguage, WindowsLanguage); every other
//   cell holds only under these settings.
// Existing pins: format-evaluate/P86Eval.al (DateTime from a date with a time; Date from 01/15/2024 and 1/15/24),
//   types/TestFormatEvaluateTextContracts.al (two-digit year window into Date).
// Facts: see the Expect lines; the values were observed on BC and converted, never typed by hand.
// BC versions: 27.5, 28.5, 29.0

codeunit 74074 "FE ShortUsDate Tests"
{
    Subtype = Test;

    local procedure RDate(Txt: Text; Fmt: Integer): Text
    var
        V: Date;
        Ok: Boolean;
    begin
        V := 0D;
        ClearLastError();
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V, 0, 9) + '|lasterr=' + GetLastErrorCode());
    end;

    local procedure RDT(Txt: Text; Fmt: Integer): Text
    var
        V: DateTime;
        Ok: Boolean;
    begin
        V := 0DT;
        ClearLastError();
        if Fmt < 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(V, 0, 9) + '|lasterr=' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryDate(Txt: Text; Fmt: Integer; var V: Date)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    [TryFunction]
    local procedure TryDT(Txt: Text; Fmt: Integer; var V: DateTime)
    begin
        if Fmt < 0 then
            Evaluate(V, Txt)
        else
            Evaluate(V, Txt, Fmt);
    end;

    local procedure EDate(Txt: Text; Fmt: Integer): Text
    var
        V: Date;
    begin
        V := 0D;
        ClearLastError();
        if TryDate(Txt, Fmt, V) then
            exit('ok|' + Format(V, 0, 9));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    local procedure EDT(Txt: Text; Fmt: Integer): Text
    var
        V: DateTime;
    begin
        V := 0DT;
        ClearLastError();
        if TryDT(Txt, Fmt, V) then
            exit('ok|' + Format(V, 0, 9));
        exit('err:' + GetLastErrorText() + '|' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    // The reporter's procedure (al-runner issue 8643), unchanged apart from the names.
    local procedure ParseDate(Value: Text; var EnteredDate: Date)
    var
        AsDateTime: DateTime;
    begin
        if Evaluate(EnteredDate, Value) then
            exit;
        if Evaluate(AsDateTime, Value) then
            EnteredDate := DT2Date(AsDateTime);
    end;

    // The same without the first Evaluate (the mutant of issue 8643).
    local procedure ParseDateViaDateTime(Value: Text; var EnteredDate: Date)
    var
        AsDateTime: DateTime;
    begin
        if Evaluate(AsDateTime, Value) then
            EnteredDate := DT2Date(AsDateTime);
    end;

    local procedure ShortDates(var Observer: Codeunit "Probe Observer"; ToDateTime: Boolean; Fmt: Integer)
    begin
        Cell(Observer, '02/01/25', ToDateTime, Fmt);
        Cell(Observer, '01/01/25', ToDateTime, Fmt);
        Cell(Observer, '12/31/24', ToDateTime, Fmt);
        Cell(Observer, '01/01/28', ToDateTime, Fmt);
        Cell(Observer, '1/4/25', ToDateTime, Fmt);
        Cell(Observer, '01/04/2025', ToDateTime, Fmt);
        Cell(Observer, '12/31/29', ToDateTime, Fmt);
        Cell(Observer, '01/01/30', ToDateTime, Fmt);
        Cell(Observer, '13/01/25', ToDateTime, Fmt);
        Cell(Observer, '02/30/25', ToDateTime, Fmt);
        Cell(Observer, '00/01/25', ToDateTime, Fmt);
        Cell(Observer, '010425', ToDateTime, Fmt);
        Cell(Observer, '01-04-25', ToDateTime, Fmt);
        Cell(Observer, '01/04', ToDateTime, Fmt);
    end;

    local procedure DatesWithTime(var Observer: Codeunit "Probe Observer"; ToDateTime: Boolean; Fmt: Integer)
    begin
        Cell(Observer, '01/04/25 12:00 PM', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 12:00 AM', ToDateTime, Fmt);
        Cell(Observer, '1/4/25 1:20 AM', ToDateTime, Fmt);
        Cell(Observer, '01/04/2025 12:00 PM', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 12:00', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 23:59:59', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 00:00', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 25:00', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 13:00 PM', ToDateTime, Fmt);
        Cell(Observer, '01/04/25 noon', ToDateTime, Fmt);
        Cell(Observer, '13/04/25 12:00 PM', ToDateTime, Fmt);
        Cell(Observer, '01/04/25  12:00 PM', ToDateTime, Fmt);
        Cell(Observer, '01/04/25T12:00', ToDateTime, Fmt);
    end;

    local procedure Cell(var Observer: Codeunit "Probe Observer"; Txt: Text; ToDateTime: Boolean; Fmt: Integer)
    begin
        if ToDateTime then
            Observer.Observe(Txt, RDT(Txt, Fmt))
        else
            Observer.Observe(Txt, RDate(Txt, Fmt));
    end;

    local procedure StatementCell(var Observer: Codeunit "Probe Observer"; Txt: Text; ToDateTime: Boolean; Fmt: Integer)
    begin
        if ToDateTime then
            Observer.Observe(Txt, EDT(Txt, Fmt))
        else
            Observer.Observe(Txt, EDate(Txt, Fmt));
    end;

    local procedure StatementTexts(var Observer: Codeunit "Probe Observer"; ToDateTime: Boolean; Fmt: Integer)
    begin
        StatementCell(Observer, '02/01/25', ToDateTime, Fmt);
        StatementCell(Observer, '13/01/25', ToDateTime, Fmt);
        StatementCell(Observer, '02/30/25', ToDateTime, Fmt);
        StatementCell(Observer, '01/04/25 12:00 PM', ToDateTime, Fmt);
        StatementCell(Observer, '01/04/25 25:00', ToDateTime, Fmt);
        StatementCell(Observer, '01/04/25 noon', ToDateTime, Fmt);
        StatementCell(Observer, '13/04/25 12:00 PM', ToDateTime, Fmt);
    end;

    [Test]
    procedure Settings_OfTheSession()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('format date', Format(DMY2Date(4, 1, 2025)));
        Observer.Observe('format datetime', Format(CreateDateTime(DMY2Date(4, 1, 2025), 120000T)));
        Observer.Observe('local noon in utc', Format(CreateDateTime(DMY2Date(4, 1, 2025), 120000T), 0, 9));
        Observer.Observe('globallanguage', Format(GlobalLanguage()));
        Observer.Observe('windowslanguage', Format(WindowsLanguage()));
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_ShortDate_NoNumber_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShortDates(Observer, true, -1);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_ShortDate_Number0_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShortDates(Observer, true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_ShortDate_Number9_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShortDates(Observer, true, 9);
        Observer.Finish();
    end;

    [Test]
    procedure Date_ShortDate_NoNumber_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShortDates(Observer, false, -1);
        Observer.Finish();
    end;

    [Test]
    procedure Date_ShortDate_Number0_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ShortDates(Observer, false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Date_WithTime_NoNumber_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DatesWithTime(Observer, false, -1);
        Observer.Finish();
    end;

    [Test]
    procedure Date_WithTime_Number0_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DatesWithTime(Observer, false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Date_WithTime_Number9_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DatesWithTime(Observer, false, 9);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_WithTime_NoNumber_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DatesWithTime(Observer, true, -1);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_WithTime_Number0_Return()
    var
        Observer: Codeunit "Probe Observer";
    begin
        DatesWithTime(Observer, true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure Date_Statement_NoNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StatementTexts(Observer, false, -1);
        Observer.Finish();
    end;

    [Test]
    procedure Date_Statement_Number0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StatementTexts(Observer, false, 0);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Statement_NoNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StatementTexts(Observer, true, -1);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Statement_Number0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StatementTexts(Observer, true, 0);
        Observer.Finish();
    end;

    [Test]
    procedure ParseDate_ReporterProcedure()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 0D;
        ParseDate('02/01/25', D);
        Observer.Observe('both 02/01/25', Format(D, 0, 9));
        D := 0D;
        ParseDate('01/04/25 12:00 PM', D);
        Observer.Observe('both 01/04/25 12:00 PM', Format(D, 0, 9));
        D := 0D;
        ParseDateViaDateTime('02/01/25', D);
        Observer.Observe('datetime only 02/01/25', Format(D, 0, 9));
        D := 0D;
        ParseDateViaDateTime('12/31/24', D);
        Observer.Observe('datetime only 12/31/24', Format(D, 0, 9));
        D := 0D;
        ParseDateViaDateTime('01/04/25 12:00 PM', D);
        Observer.Observe('datetime only 01/04/25 12:00 PM', Format(D, 0, 9));
        Observer.Finish();
    end;
}
