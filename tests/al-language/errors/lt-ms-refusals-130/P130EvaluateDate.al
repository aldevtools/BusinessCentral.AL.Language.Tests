// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope
// Fixtures used: self-contained codeunit 73552, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Evaluate into a Date of the 6 digit form (101010, 161026, 010120), of slash and dot forms with a 2 and a 4 digit year, and of month-first texts, with the default format
//   and with the format numbers 0 to 9 (9 is the XML form); result and the value (Format(D, 0, 9)); the day-month order of the session is visible in 010203 and 13/01/24
// Settles issue 130 reasons 12 and 28 (Evaluate of 101010 into Date; Evaluate of 10/16/26 into Date with format N)
// BC versions: 29 (27 and 28 by CI)

codeunit 73552 "LT P130 Evaluate Date"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ED(Txt: Text; Fmt: Integer): Text
    var
        D: Date;
        Ok: Boolean;
    begin
        D := 20000101D;
        Ok := Evaluate(D, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    local procedure EDDefault(Txt: Text): Text
    var
        D: Date;
        Ok: Boolean;
    begin
        D := 20000101D;
        Ok := Evaluate(D, Txt);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    [Test]
    procedure P130_EvaluateDate_Default_SixAndEightDigits()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('101010', EDDefault('101010'));
        Observer.Observe('161026', EDDefault('161026'));
        Observer.Observe('101626', EDDefault('101626'));
        Observer.Observe('010203', EDDefault('010203'));
        Observer.Observe('311299', EDDefault('311299'));
        Observer.Observe('010130', EDDefault('010130'));
        Observer.Observe('290224', EDDefault('290224'));
        Observer.Observe('290225', EDDefault('290225'));
        Observer.Observe('16102026', EDDefault('16102026'));
        Observer.Observe('10162026', EDDefault('10162026'));
        Observer.Observe('01022003', EDDefault('01022003'));
        Observer.Observe('1010', EDDefault('1010'));
        Observer.Observe('10101', EDDefault('10101'));
        Observer.Observe('1010101', EDDefault('1010101'));
        Observer.Observe('0', EDDefault('0'));
        Observer.Observe('000000', EDDefault('000000'));
        Observer.Observe('999999', EDDefault('999999'));
        Observer.Expect('101010', 'Yes|2010-10-10');
        Observer.Expect('161026', 'No|2000-01-01');
        Observer.Expect('101626', 'Yes|2026-10-16');
        Observer.Expect('010203', 'Yes|2003-01-02');
        Observer.Expect('311299', 'No|2000-01-01');
        Observer.Expect('010130', 'Yes|2030-01-01');
        Observer.Expect('290224', 'No|2000-01-01');
        Observer.Expect('290225', 'No|2000-01-01');
        Observer.Expect('16102026', 'No|2000-01-01');
        Observer.Expect('10162026', 'Yes|2026-10-16');
        Observer.Expect('01022003', 'Yes|2003-01-02');
        Observer.Expect('1010', 'Yes|' + Format(DMY2Date(10, 10, Date2DMY(Today(), 3)), 0, 9));
        Observer.Expect('10101', 'Yes|2001-10-10');
        Observer.Expect('1010101', 'Yes|0101-10-10');
        Observer.Expect('0', 'No|2000-01-01');
        Observer.Expect('000000', 'No|2000-01-01');
        Observer.Expect('999999', 'No|2000-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure P130_EvaluateDate_Default_SlashAndDotForms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('10/16/26', EDDefault('10/16/26'));
        Observer.Observe('16/10/26', EDDefault('16/10/26'));
        Observer.Observe('10/16/2026', EDDefault('10/16/2026'));
        Observer.Observe('16/10/2026', EDDefault('16/10/2026'));
        Observer.Observe('01/02/03', EDDefault('01/02/03'));
        Observer.Observe('13/01/24', EDDefault('13/01/24'));
        Observer.Observe('01/13/24', EDDefault('01/13/24'));
        Observer.Observe('1/2/3', EDDefault('1/2/3'));
        Observer.Observe('1/2/2003', EDDefault('1/2/2003'));
        Observer.Observe('16.10.26', EDDefault('16.10.26'));
        Observer.Observe('16.10.2026', EDDefault('16.10.2026'));
        Observer.Observe('10.16.26', EDDefault('10.16.26'));
        Observer.Observe('16-10-26', EDDefault('16-10-26'));
        Observer.Observe('10-16-2026', EDDefault('10-16-2026'));
        Observer.Observe('16/10', EDDefault('16/10'));
        Observer.Observe('16 10 26', EDDefault('16 10 26'));
        Observer.Observe('16 Oct 2026', EDDefault('16 Oct 2026'));
        Observer.Observe('Oct 16, 2026', EDDefault('Oct 16, 2026'));
        Observer.Expect('10/16/26', 'Yes|2026-10-16');
        Observer.Expect('16/10/26', 'No|2000-01-01');
        Observer.Expect('10/16/2026', 'Yes|2026-10-16');
        Observer.Expect('16/10/2026', 'No|2000-01-01');
        Observer.Expect('01/02/03', 'Yes|2003-01-02');
        Observer.Expect('13/01/24', 'No|2000-01-01');
        Observer.Expect('01/13/24', 'Yes|2024-01-13');
        Observer.Expect('1/2/3', 'Yes|2003-01-02');
        Observer.Expect('1/2/2003', 'Yes|2003-01-02');
        Observer.Expect('16.10.26', 'No|2000-01-01');
        Observer.Expect('16.10.2026', 'No|2000-01-01');
        Observer.Expect('10.16.26', 'Yes|2026-10-16');
        Observer.Expect('16-10-26', 'No|2000-01-01');
        Observer.Expect('10-16-2026', 'Yes|2026-10-16');
        Observer.Expect('16/10', 'No|2000-01-01');
        Observer.Expect('16 10 26', 'No|2000-01-01');
        Observer.Expect('16 Oct 2026', 'Yes|2026-10-16');
        Observer.Expect('Oct 16, 2026', 'No|2000-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure P130_EvaluateDate_Format9_Forms()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('10/16/26', ED('10/16/26', 9));
        Observer.Observe('16/10/26', ED('16/10/26', 9));
        Observer.Observe('10/16/2026', ED('10/16/2026', 9));
        Observer.Observe('16/10/2026', ED('16/10/2026', 9));
        Observer.Observe('101010', ED('101010', 9));
        Observer.Observe('161026', ED('161026', 9));
        Observer.Observe('16102026', ED('16102026', 9));
        Observer.Observe('20261016', ED('20261016', 9));
        Observer.Observe('2026-10-16', ED('2026-10-16', 9));
        Observer.Observe('2026-10-16T00:00:00', ED('2026-10-16T00:00:00', 9));
        Observer.Observe('16.10.26', ED('16.10.26', 9));
        Observer.Observe('01/02/03', ED('01/02/03', 9));
        Observer.Observe('1/2/3', ED('1/2/3', 9));
        Observer.Expect('10/16/26', 'No|2000-01-01');
        Observer.Expect('16/10/26', 'No|2000-01-01');
        Observer.Expect('10/16/2026', 'No|2000-01-01');
        Observer.Expect('16/10/2026', 'No|2000-01-01');
        Observer.Expect('101010', 'No|2000-01-01');
        Observer.Expect('161026', 'No|2000-01-01');
        Observer.Expect('16102026', 'No|2000-01-01');
        Observer.Expect('20261016', 'No|2000-01-01');
        Observer.Expect('2026-10-16', 'Yes|2026-10-16');
        Observer.Expect('2026-10-16T00:00:00', 'No|2000-01-01');
        Observer.Expect('16.10.26', 'No|2000-01-01');
        Observer.Expect('01/02/03', 'No|2000-01-01');
        Observer.Expect('1/2/3', 'No|2000-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure P130_EvaluateDate_EveryFormat_OfSlashForm()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('10/16/26 fmt ' + Format(i), ED('10/16/26', i));
        for i := 0 to 9 do
            Observer.Observe('16/10/26 fmt ' + Format(i), ED('16/10/26', i));
        Observer.Expect('10/16/26 fmt 0', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 1', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 2', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 3', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 4', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 5', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 6', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 7', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 8', 'Yes|2026-10-16');
        Observer.Expect('10/16/26 fmt 9', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 0', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 1', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 2', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 3', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 4', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 5', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 6', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 7', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 8', 'No|2000-01-01');
        Observer.Expect('16/10/26 fmt 9', 'No|2000-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure P130_EvaluateDate_EveryFormat_OfSixDigitForm()
    var
        Observer: Codeunit "Probe Observer";
        i: Integer;
    begin
        for i := 0 to 9 do
            Observer.Observe('101010 fmt ' + Format(i), ED('101010', i));
        for i := 0 to 9 do
            Observer.Observe('161026 fmt ' + Format(i), ED('161026', i));
        Observer.Expect('101010 fmt 0', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 1', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 2', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 3', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 4', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 5', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 6', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 7', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 8', 'Yes|2010-10-10');
        Observer.Expect('101010 fmt 9', 'No|2000-01-01');
        Observer.Expect('161026 fmt 0', 'No|2000-01-01');
        Observer.Expect('161026 fmt 1', 'No|2000-01-01');
        Observer.Expect('161026 fmt 2', 'No|2000-01-01');
        Observer.Expect('161026 fmt 3', 'No|2000-01-01');
        Observer.Expect('161026 fmt 4', 'No|2000-01-01');
        Observer.Expect('161026 fmt 5', 'No|2000-01-01');
        Observer.Expect('161026 fmt 6', 'No|2000-01-01');
        Observer.Expect('161026 fmt 7', 'No|2000-01-01');
        Observer.Expect('161026 fmt 8', 'No|2000-01-01');
        Observer.Expect('161026 fmt 9', 'No|2000-01-01');
        Observer.Verify();
    end;

    [Test]
    procedure P130_EvaluateDate_Raises_OnFormat9WithSlashForm()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        asserterror Evaluate(D, '10/16/26', 9);
        Observer.ObserveError('slash_two_digit_year_format9');
        Observer.Expect('slash_two_digit_year_format9|text', 'The format of the Date ''10/16/26'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('slash_two_digit_year_format9|code', 'Evaluate');
        Observer.Verify();
    end;

    // Writer UN (2026-10-29): Evaluate used as a statement (result unused) with a text that is no value of the target type, formats 0 and 9.
    [Test]
    procedure UN_Evaluate_Statement_NotADate_ByTarget()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        DT: DateTime;
        T: Time;
        I: Integer;
        Dec: Decimal;
        B: Boolean;
    begin
        asserterror Evaluate(D, 'not-a-date', 9);
        Observer.ObserveError('date 9');
        asserterror Evaluate(D, 'not-a-date', 0);
        Observer.ObserveError('date 0');
        asserterror Evaluate(D, 'not-a-date');
        Observer.ObserveError('date default');
        asserterror Evaluate(DT, 'not-a-date', 9);
        Observer.ObserveError('datetime 9');
        asserterror Evaluate(DT, 'not-a-date', 0);
        Observer.ObserveError('datetime 0');
        asserterror Evaluate(T, 'not-a-date', 9);
        Observer.ObserveError('time 9');
        asserterror Evaluate(T, 'not-a-date', 0);
        Observer.ObserveError('time 0');
        asserterror Evaluate(I, 'not-a-date', 9);
        Observer.ObserveError('integer 9');
        asserterror Evaluate(Dec, 'not-a-date', 9);
        Observer.ObserveError('decimal 9');
        asserterror Evaluate(B, 'not-a-date', 9);
        Observer.ObserveError('boolean 9');
        Observer.Finish();
    end;
}
