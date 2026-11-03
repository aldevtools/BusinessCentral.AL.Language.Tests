// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against BC 29 (P93); the lead measures the facts on a local BC 29 and turns them into assertions.
// Facts: Date.Day, Month, Year, ToText (no argument and Invariant true/false) against Format, for normal, closing and 0D dates
// BC versions: 29 (27 and 28 by CI)

codeunit 70320 "LT P93 Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryParts(D: Date; var R: Text)
    begin
        R := Format(D.Day()) + '|' + Format(D.Month()) + '|' + Format(D.Year());
    end;

    [TryFunction]
    local procedure TryToText(D: Date; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := D.ToText();
            1:
                R := D.ToText(true);
            2:
                R := D.ToText(false);
        end;
    end;

    local procedure Parts(D: Date): Text
    var
        R: Text;
    begin
        if TryParts(D, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TT(D: Date; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryToText(D, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DayMonthYear_Normal()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('mid', Parts(20240315D));
        Observer.Observe('first', Parts(20240101D));
        Observer.Observe('dec31', Parts(20231231D));
        Observer.Observe('feb29', Parts(20240229D));
        Observer.Observe('feb28', Parts(20230228D));
        asserterror Observer.Observe('min', Parts(00010101D));
        Observer.ObserveError('af60');
        Observer.Observe('max', Parts(99991231D));
        Observer.Observe('y1753', Parts(17530101D));
        Observer.Observe('y1900', Parts(19000301D));
        Observer.Observe('apr30', Parts(20240430D));
        Observer.Expect('mid', '15|3|2024');
        Observer.Expect('first', '1|1|2024');
        Observer.Expect('dec31', '31|12|2023');
        Observer.Expect('feb29', '29|2|2024');
        Observer.Expect('feb28', '28|2|2023');
        Observer.Expect('af60|text', 'The date is not valid.');
        Observer.Expect('af60|code', 'DateInvalid');
        Observer.Expect('max', '31|12|9999');
        Observer.Expect('y1753', '1|1|1753');
        Observer.Expect('y1900', '1|3|1900');
        Observer.Expect('apr30', '30|4|2024');
        Observer.Verify();
    end;

    [Test]
    procedure DayMonthYear_Zero()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('zero-var', Parts(D));
        Observer.Observe('zero-lit', Parts(0D));
        Observer.Observe('zero-format', Format(D));
        Observer.Observe('zero-isdefault', Format(D = 0D));
        Observer.Expect('zero-var', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('zero-lit', 'error:The date is not valid.|DateInvalid');
        Observer.Expect('zero-format', '');
        Observer.Expect('zero-isdefault', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure DayMonthYear_ClosingDates()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := ClosingDate(20231231D);
        Observer.Observe('closing-parts', Parts(D));
        Observer.Observe('closing-format', Format(D));
        Observer.Observe('closing-isclosing', Format(D = ClosingDate(20231231D)));
        Observer.Observe('closing-eq-normal', Format(D = 20231231D));
        Observer.Observe('closing-tt', TT(D, 0));
        Observer.Observe('closing-tt-inv', TT(D, 1));
        Observer.Observe('closing-tt-false', TT(D, 2));
        Observer.Observe('closing-feb29', Parts(ClosingDate(20240229D)));
        Observer.Observe('normalize', Format(NormalDate(D)));
        Observer.Expect('closing-parts', '31|12|2023');
        Observer.Expect('closing-format', 'C12/31/23');
        Observer.Expect('closing-isclosing', 'Yes');
        Observer.Expect('closing-eq-normal', 'No');
        Observer.Expect('closing-tt', 'C12/31/23');
        Observer.Expect('closing-tt-inv', '2023-12-31');
        Observer.Expect('closing-tt-false', 'C12/31/23');
        Observer.Expect('closing-feb29', '29|2|2024');
        Observer.Expect('normalize', '12/31/23');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_Normal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240315D;
        Observer.Observe('tt', TT(D, 0));
        Observer.Observe('tt-true', TT(D, 1));
        Observer.Observe('tt-false', TT(D, 2));
        Observer.Observe('format', Format(D));
        Observer.Observe('format-9', Format(D, 0, 9));
        Observer.Observe('format-0', Format(D, 0, 0));
        Observer.Observe('format-1', Format(D, 0, 1));
        Observer.Observe('format-2', Format(D, 0, 2));
        Observer.Observe('format-4', Format(D, 0, 4));
        Observer.Observe('format-custom', Format(D, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Expect('tt', '03/15/24');
        Observer.Expect('tt-true', '2024-03-15');
        Observer.Expect('tt-false', '03/15/24');
        Observer.Expect('format', '03/15/24');
        Observer.Expect('format-9', '2024-03-15');
        Observer.Expect('format-0', '03/15/24');
        Observer.Expect('format-1', '03/15/24');
        Observer.Expect('format-2', '031524D');
        Observer.Expect('format-4', 'March 15, 2024');
        Observer.Expect('format-custom', '15.03.2024');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_Closing()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('dec31', TT(20231231D, 0));
        Observer.Observe('dec31-true', TT(20231231D, 1));
        Observer.Observe('dec31-false', TT(20231231D, 2));
        Observer.Observe('dec31-format-9', Format(20231231D, 0, 9));
        Observer.Observe('feb29', TT(20240229D, 0));
        Observer.Observe('feb29-true', TT(20240229D, 1));
        Observer.Observe('feb29-false', TT(20240229D, 2));
        Observer.Observe('feb29-format', Format(20240229D));
        Observer.Observe('feb29-format-9', Format(20240229D, 0, 9));
        asserterror Observer.Observe('min', TT(00010101D, 0));
        Observer.ObserveError('af135');
        asserterror Observer.Observe('min-true', TT(00010101D, 1));
        Observer.ObserveError('af137');
        Observer.Observe('max', TT(99991231D, 0));
        Observer.Observe('max-true', TT(99991231D, 1));
        Observer.Expect('dec31', '12/31/23');
        Observer.Expect('dec31-true', '2023-12-31');
        Observer.Expect('dec31-false', '12/31/23');
        Observer.Expect('dec31-format-9', '2023-12-31');
        Observer.Expect('feb29', '02/29/24');
        Observer.Expect('feb29-true', '2024-02-29');
        Observer.Expect('feb29-false', '02/29/24');
        Observer.Expect('feb29-format', '02/29/24');
        Observer.Expect('feb29-format-9', '2024-02-29');
        Observer.Expect('af135|text', 'The date is not valid.');
        Observer.Expect('af135|code', 'DateInvalid');
        Observer.Expect('af137|text', 'The date is not valid.');
        Observer.Expect('af137|code', 'DateInvalid');
        Observer.Expect('max', '12/31/9999');
        Observer.Expect('max-true', '9999-12-31');
        Observer.Verify();
    end;

    [Test]
    procedure ToText_Zero()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('tt', TT(D, 0));
        Observer.Observe('tt-true', TT(D, 1));
        Observer.Observe('tt-false', TT(D, 2));
        Observer.Observe('format', Format(D));
        Observer.Observe('format-9', Format(D, 0, 9));
        Observer.Observe('format-0', Format(D, 0, 0));
        Observer.Observe('format-len', Format(StrLen(Format(D, 0, 9))));
        Observer.Expect('tt', '');
        Observer.Expect('tt-true', '');
        Observer.Expect('tt-false', '');
        Observer.Expect('format', '');
        Observer.Expect('format-9', '');
        Observer.Expect('format-0', '');
        Observer.Expect('format-len', '0');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWeekParts(D: Date; var R: Text)
    begin
        R := Format(D.DayOfWeek()) + '|' + Format(D.WeekNo()) + '|' + Format(D.Year());
    end;

    [TryFunction]
    local procedure TryDwy(D: Date; var R: Text)
    begin
        R := Format(Date2DWY(D, 1)) + ',' + Format(Date2DWY(D, 2)) + ',' + Format(Date2DWY(D, 3));
    end;

    local procedure WeekParts(D: Date): Text
    var
        R: Text;
        R2: Text;
    begin
        if not TryWeekParts(D, R) then
            R := 'error:' + GetLastErrorText() + '|' + GetLastErrorCode();
        if not TryDwy(D, R2) then
            R2 := 'error';
        exit(R + '|dwy:' + R2);
    end;

    // Corpus issue 672 item 7: Date.DayOfWeek / WeekNo / Year (DayOfWeek|WeekNo|Year|dwy:Date2DWY 1,2,3) at ISO week-year boundaries
    // (2024-12-30 is a Monday in ISO week 1 of 2025; 2026-01-01 is a Thursday), for a closing date and for 0D.
    [Test]
    procedure BT_DayOfWeek_WeekNo_Year()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('2026-01-01', WeekParts(20260101D));
        Observer.Observe('2024-12-30', WeekParts(20241230D));
        Observer.Observe('2027-01-01', WeekParts(20270101D));
        Observer.Observe('2021-01-03', WeekParts(20210103D));
        Observer.Observe('2020-12-31', WeekParts(20201231D));
        Observer.Observe('closing 2024-12-30', WeekParts(ClosingDate(20241230D)));
        Observer.Observe('0D', WeekParts(0D));
        Observer.Expect('2026-01-01', '4|1|2026|dwy:4,1,2026');
        Observer.Expect('2024-12-30', '1|1|2024|dwy:1,1,2025');
        Observer.Expect('2027-01-01', '5|53|2027|dwy:5,53,2026');
        Observer.Expect('2021-01-03', '7|53|2021|dwy:7,53,2020');
        Observer.Expect('2020-12-31', '4|53|2020|dwy:4,53,2020');
        Observer.Expect('closing 2024-12-30', '1|1|2024|dwy:1,1,2025');
        Observer.Expect('0D', 'error:The date is not valid.|DateInvalid|dwy:error');
        Observer.Verify();
    end;
}
