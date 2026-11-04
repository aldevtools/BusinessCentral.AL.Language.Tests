// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: CalcDate with every DateFormula form, fixed dates only
// BC versions: 29 (27 and 28 by CI)

codeunit 73800 "LT DtT CalcDate A"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Text)
    var
        DF: DateFormula;
    begin
        if not Evaluate(DF, Formula) then begin
            Result := 'eval-error';
            exit;
        end;
        Result := Format(CalcDate(DF, Base), 0, 9);
    end;

    local procedure Calc(Formula: Text; Base: Date): Text
    var
        Result: Text;
    begin
        if TryCalc(Formula, Base, Result) then
            exit(Result);
        exit('ERR:' + GetLastErrorText());
    end;

    local procedure CalcF(Formula: Text; Base: Date): Text
    begin
        exit(Format(CalcDate(Formula, Base), 0, 9));
    end;

    [Test]
    procedure Days()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1D', Calc('<1D>', 20240115D));
        Observer.Observe('-1D', Calc('<-1D>', 20240115D));
        Observer.Observe('+1D', Calc('<+1D>', 20240115D));
        Observer.Observe('0D', Calc('<0D>', 20240115D));
        Observer.Observe('30D', Calc('<30D>', 20240115D));
        Observer.Observe('365D', Calc('<365D>', 20240115D));
        Observer.Observe('366D', Calc('<366D>', 20240115D));
        Observer.Observe('-365D', Calc('<-365D>', 20240115D));
        Observer.Observe('1D leap', Calc('<1D>', 20240228D));
        Observer.Observe('2D leap', Calc('<2D>', 20240228D));
        Observer.Observe('1D nonleap', Calc('<1D>', 20230228D));
        Observer.Observe('1D yearend', Calc('<1D>', 20231231D));
        Observer.Observe('-1D yearstart', Calc('<-1D>', 20240101D));
        Observer.Observe('no brackets', Calc('1D', 20240115D));
        Observer.Observe('lower d', Calc('<1d>', 20240115D));
        Observer.Observe('CalcDate text', CalcF('<1D>', 20240115D));
        Observer.Expect('1D', '2024-01-16');
        Observer.Expect('-1D', '2024-01-14');
        Observer.Expect('+1D', '2024-01-16');
        Observer.Expect('0D', '2024-01-15');
        Observer.Expect('30D', '2024-02-14');
        Observer.Expect('365D', '2025-01-14');
        Observer.Expect('366D', '2025-01-15');
        Observer.Expect('-365D', '2023-01-15');
        Observer.Expect('1D leap', '2024-02-29');
        Observer.Expect('2D leap', '2024-03-01');
        Observer.Expect('1D nonleap', '2023-03-01');
        Observer.Expect('1D yearend', '2024-01-01');
        Observer.Expect('-1D yearstart', '2023-12-31');
        Observer.Expect('no brackets', '2024-01-16');
        Observer.Expect('lower d', '2024-01-16');
        Observer.Expect('CalcDate text', '2024-01-16');
        Observer.Verify();
    end;

    [Test]
    procedure Weeks()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1W', Calc('<1W>', 20240115D));
        Observer.Observe('-1W', Calc('<-1W>', 20240115D));
        Observer.Observe('2W', Calc('<2W>', 20240115D));
        Observer.Observe('0W', Calc('<0W>', 20240115D));
        Observer.Observe('52W', Calc('<52W>', 20240115D));
        Observer.Observe('1W+1D', Calc('<1W+1D>', 20240115D));
        Observer.Observe('1W-1D', Calc('<1W-1D>', 20240115D));
        Observer.Observe('CW mon', Calc('<CW>', 20240115D));
        Observer.Observe('CW wed', Calc('<CW>', 20240117D));
        Observer.Observe('CW sun', Calc('<CW>', 20240121D));
        Observer.Observe('CW sat', Calc('<CW>', 20240120D));
        Observer.Observe('-CW wed', Calc('<-CW>', 20240117D));
        Observer.Observe('+CW wed', Calc('<+CW>', 20240117D));
        Observer.Observe('1W+CW', Calc('<1W+CW>', 20240117D));
        Observer.Observe('CW+1W', Calc('<CW+1W>', 20240117D));
        Observer.Observe('-1W+CW', Calc('<-1W+CW>', 20240117D));
        Observer.Observe('2CW', Calc('<2CW>', 20240117D));
        Observer.Expect('1W', '2024-01-22');
        Observer.Expect('-1W', '2024-01-08');
        Observer.Expect('2W', '2024-01-29');
        Observer.Expect('0W', '2024-01-15');
        Observer.Expect('52W', '2025-01-13');
        Observer.Expect('1W+1D', '2024-01-23');
        Observer.Expect('1W-1D', '2024-01-21');
        Observer.Expect('CW mon', '2024-01-21');
        Observer.Expect('CW wed', '2024-01-21');
        Observer.Expect('CW sun', '2024-01-21');
        Observer.Expect('CW sat', '2024-01-21');
        Observer.Expect('-CW wed', '2024-01-15');
        Observer.Expect('+CW wed', '2024-01-21');
        Observer.Expect('1W+CW', '2024-01-28');
        Observer.Expect('CW+1W', '2024-01-28');
        Observer.Expect('-1W+CW', '2024-01-14');
        Observer.Expect('2CW', 'eval-error');
        Observer.Verify();
    end;

    [Test]
    procedure WeekdayNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // 2024-01-17 is a Wednesday
        Observer.Observe('MON', Calc('<MON>', 20240117D));
        Observer.Observe('TUE', Calc('<TUE>', 20240117D));
        Observer.Observe('WED', Calc('<WED>', 20240117D));
        Observer.Observe('THU', Calc('<THU>', 20240117D));
        Observer.Observe('FRI', Calc('<FRI>', 20240117D));
        Observer.Observe('SAT', Calc('<SAT>', 20240117D));
        Observer.Observe('SUN', Calc('<SUN>', 20240117D));
        Observer.Observe('-MON', Calc('<-MON>', 20240117D));
        Observer.Observe('-WED', Calc('<-WED>', 20240117D));
        Observer.Observe('-SUN', Calc('<-SUN>', 20240117D));
        Observer.Observe('+WED', Calc('<+WED>', 20240117D));
        Observer.Observe('2MON', Calc('<2MON>', 20240117D));
        Observer.Observe('-2FRI', Calc('<-2FRI>', 20240117D));
        Observer.Observe('1MON', Calc('<1MON>', 20240117D));
        Observer.Observe('0MON', Calc('<0MON>', 20240117D));
        Observer.Observe('mon lower', Calc('<mon>', 20240117D));
        Observer.Observe('Mon mixed', Calc('<Mon>', 20240117D));
        Observer.Observe('MON on monday', Calc('<MON>', 20240115D));
        Observer.Observe('SUN on sunday', Calc('<SUN>', 20240121D));
        Observer.Observe('1M+FRI', Calc('<1M+FRI>', 20240117D));
        Observer.Expect('MON', 'eval-error');
        Observer.Expect('TUE', 'eval-error');
        Observer.Expect('WED', 'eval-error');
        Observer.Expect('THU', 'eval-error');
        Observer.Expect('FRI', 'eval-error');
        Observer.Expect('SAT', 'eval-error');
        Observer.Expect('SUN', 'eval-error');
        Observer.Expect('-MON', 'eval-error');
        Observer.Expect('-WED', 'eval-error');
        Observer.Expect('-SUN', 'eval-error');
        Observer.Expect('+WED', 'eval-error');
        Observer.Expect('2MON', 'eval-error');
        Observer.Expect('-2FRI', 'eval-error');
        Observer.Expect('1MON', 'eval-error');
        Observer.Expect('0MON', 'eval-error');
        Observer.Expect('mon lower', 'eval-error');
        Observer.Expect('Mon mixed', 'eval-error');
        Observer.Expect('MON on monday', 'eval-error');
        Observer.Expect('SUN on sunday', 'eval-error');
        Observer.Expect('1M+FRI', 'eval-error');
        Observer.Verify();
    end;

    [Test]
    procedure WD_Numbers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('WD1', Calc('<WD1>', 20240117D));
        Observer.Observe('WD2', Calc('<WD2>', 20240117D));
        Observer.Observe('WD3', Calc('<WD3>', 20240117D));
        Observer.Observe('WD4', Calc('<WD4>', 20240117D));
        Observer.Observe('WD5', Calc('<WD5>', 20240117D));
        Observer.Observe('WD6', Calc('<WD6>', 20240117D));
        Observer.Observe('WD7', Calc('<WD7>', 20240117D));
        Observer.Observe('-WD1', Calc('<-WD1>', 20240117D));
        Observer.Observe('-WD7', Calc('<-WD7>', 20240117D));
        Observer.Observe('1W+WD1', Calc('<1W+WD1>', 20240117D));
        Observer.Observe('WD3 on wed', Calc('<WD3>', 20240117D));
        Observer.Observe('WD1 on mon', Calc('<WD1>', 20240115D));
        Observer.Observe('2WD1', Calc('<2WD1>', 20240117D));
        Observer.Observe('WD0', Calc('<WD0>', 20240117D));
        Observer.Observe('WD8', Calc('<WD8>', 20240117D));
        Observer.Observe('WD', Calc('<WD>', 20240117D));
        Observer.Expect('WD1', '2024-01-22');
        Observer.Expect('WD2', '2024-01-23');
        Observer.Expect('WD3', '2024-01-24');
        Observer.Expect('WD4', '2024-01-18');
        Observer.Expect('WD5', '2024-01-19');
        Observer.Expect('WD6', '2024-01-20');
        Observer.Expect('WD7', '2024-01-21');
        Observer.Expect('-WD1', '2024-01-15');
        Observer.Expect('-WD7', '2024-01-14');
        Observer.Expect('1W+WD1', '2024-01-29');
        Observer.Expect('WD3 on wed', '2024-01-24');
        Observer.Expect('WD1 on mon', '2024-01-22');
        Observer.Expect('2WD1', 'eval-error');
        Observer.Expect('WD0', 'eval-error');
        Observer.Expect('WD8', 'eval-error');
        Observer.Expect('WD', 'eval-error');
        Observer.Verify();
    end;

    [Test]
    procedure Months()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1M', Calc('<1M>', 20240115D));
        Observer.Observe('-1M', Calc('<-1M>', 20240115D));
        Observer.Observe('1M jan31', Calc('<1M>', 20240131D));
        Observer.Observe('1M jan31 nonleap', Calc('<1M>', 20230131D));
        Observer.Observe('1M mar31', Calc('<1M>', 20240331D));
        Observer.Observe('-1M mar31', Calc('<-1M>', 20240331D));
        Observer.Observe('-1M mar30', Calc('<-1M>', 20240330D));
        Observer.Observe('12M', Calc('<12M>', 20240229D));
        Observer.Observe('-12M', Calc('<-12M>', 20240229D));
        Observer.Observe('13M', Calc('<13M>', 20240115D));
        Observer.Observe('0M', Calc('<0M>', 20240115D));
        Observer.Observe('1M dec', Calc('<1M>', 20231215D));
        Observer.Observe('CM', Calc('<CM>', 20240115D));
        Observer.Observe('CM feb leap', Calc('<CM>', 20240210D));
        Observer.Observe('CM feb', Calc('<CM>', 20230210D));
        Observer.Observe('-CM', Calc('<-CM>', 20240115D));
        Observer.Observe('1M+CM', Calc('<1M+CM>', 20240115D));
        Observer.Observe('CM+1D', Calc('<CM+1D>', 20240115D));
        Observer.Observe('-1M+CM', Calc('<-1M+CM>', 20240115D));
        Observer.Observe('-CM-1D', Calc('<-CM-1D>', 20240115D));
        Observer.Observe('1M+1D', Calc('<1M+1D>', 20240115D));
        Observer.Observe('1M+1W', Calc('<1M+1W>', 20240115D));
        Observer.Expect('1M', '2024-02-15');
        Observer.Expect('-1M', '2023-12-15');
        Observer.Expect('1M jan31', '2024-02-29');
        Observer.Expect('1M jan31 nonleap', '2023-02-28');
        Observer.Expect('1M mar31', '2024-04-30');
        Observer.Expect('-1M mar31', '2024-02-29');
        Observer.Expect('-1M mar30', '2024-02-29');
        Observer.Expect('12M', '2025-02-28');
        Observer.Expect('-12M', '2023-02-28');
        Observer.Expect('13M', '2025-02-15');
        Observer.Expect('0M', '2024-01-15');
        Observer.Expect('1M dec', '2024-01-15');
        Observer.Expect('CM', '2024-01-31');
        Observer.Expect('CM feb leap', '2024-02-29');
        Observer.Expect('CM feb', '2023-02-28');
        Observer.Expect('-CM', '2024-01-01');
        Observer.Expect('1M+CM', '2024-02-29');
        Observer.Expect('CM+1D', '2024-02-01');
        Observer.Expect('-1M+CM', '2023-12-31');
        Observer.Expect('-CM-1D', '2023-12-31');
        Observer.Expect('1M+1D', '2024-02-16');
        Observer.Expect('1M+1W', '2024-02-22');
        Observer.Verify();
    end;

    [Test]
    procedure Quarters()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1Q', Calc('<1Q>', 20240115D));
        Observer.Observe('-1Q', Calc('<-1Q>', 20240115D));
        Observer.Observe('1Q nov30', Calc('<1Q>', 20231130D));
        Observer.Observe('1Q nov30 leap', Calc('<1Q>', 20231130D));
        Observer.Observe('1Q aug31', Calc('<1Q>', 20230831D));
        Observer.Observe('4Q', Calc('<4Q>', 20240115D));
        Observer.Observe('CQ jan', Calc('<CQ>', 20240115D));
        Observer.Observe('CQ feb', Calc('<CQ>', 20240215D));
        Observer.Observe('CQ mar31', Calc('<CQ>', 20240331D));
        Observer.Observe('CQ apr1', Calc('<CQ>', 20240401D));
        Observer.Observe('CQ jun30', Calc('<CQ>', 20240630D));
        Observer.Observe('CQ jul1', Calc('<CQ>', 20240701D));
        Observer.Observe('CQ oct', Calc('<CQ>', 20241015D));
        Observer.Observe('CQ dec31', Calc('<CQ>', 20241231D));
        Observer.Observe('-CQ jan', Calc('<-CQ>', 20240115D));
        Observer.Observe('-CQ may', Calc('<-CQ>', 20240515D));
        Observer.Observe('-CQ nov', Calc('<-CQ>', 20241115D));
        Observer.Observe('1Q+CQ', Calc('<1Q+CQ>', 20240115D));
        Observer.Observe('-1Q+CQ', Calc('<-1Q+CQ>', 20240115D));
        Observer.Expect('1Q', '2024-04-15');
        Observer.Expect('-1Q', '2023-10-15');
        Observer.Expect('1Q nov30', '2024-02-29');
        Observer.Expect('1Q nov30 leap', '2024-02-29');
        Observer.Expect('1Q aug31', '2023-11-30');
        Observer.Expect('4Q', '2025-01-15');
        Observer.Expect('CQ jan', '2024-03-31');
        Observer.Expect('CQ feb', '2024-03-31');
        Observer.Expect('CQ mar31', '2024-03-31');
        Observer.Expect('CQ apr1', '2024-06-30');
        Observer.Expect('CQ jun30', '2024-06-30');
        Observer.Expect('CQ jul1', '2024-09-30');
        Observer.Expect('CQ oct', '2024-12-31');
        Observer.Expect('CQ dec31', '2024-12-31');
        Observer.Expect('-CQ jan', '2024-01-01');
        Observer.Expect('-CQ may', '2024-04-01');
        Observer.Expect('-CQ nov', '2024-10-01');
        Observer.Expect('1Q+CQ', '2024-06-30');
        Observer.Expect('-1Q+CQ', '2023-12-31');
        Observer.Verify();
    end;

    [Test]
    procedure Years()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1Y', Calc('<1Y>', 20240115D));
        Observer.Observe('-1Y', Calc('<-1Y>', 20240115D));
        Observer.Observe('1Y feb29', Calc('<1Y>', 20240229D));
        Observer.Observe('-1Y feb29', Calc('<-1Y>', 20240229D));
        Observer.Observe('4Y feb29', Calc('<4Y>', 20240229D));
        Observer.Observe('-4Y feb29', Calc('<-4Y>', 20240229D));
        Observer.Observe('100Y', Calc('<100Y>', 20240115D));
        Observer.Observe('0Y', Calc('<0Y>', 20240115D));
        Observer.Observe('CY', Calc('<CY>', 20240615D));
        Observer.Observe('CY jan1', Calc('<CY>', 20240101D));
        Observer.Observe('CY dec31', Calc('<CY>', 20241231D));
        Observer.Observe('-CY', Calc('<-CY>', 20240615D));
        Observer.Observe('-CY jan1', Calc('<-CY>', 20240101D));
        Observer.Observe('1Y+CY', Calc('<1Y+CY>', 20240615D));
        Observer.Observe('-1Y+CY', Calc('<-1Y+CY>', 20240615D));
        Observer.Observe('CY+1D', Calc('<CY+1D>', 20240615D));
        Observer.Observe('-CY-1D', Calc('<-CY-1D>', 20240615D));
        Observer.Observe('1Y+1M+1D', Calc('<1Y+1M+1D>', 20240115D));
        Observer.Observe('1Y+1Q+1M+1W+1D', Calc('<1Y+1Q+1M+1W+1D>', 20240115D));
        Observer.Expect('1Y', '2025-01-15');
        Observer.Expect('-1Y', '2023-01-15');
        Observer.Expect('1Y feb29', '2025-02-28');
        Observer.Expect('-1Y feb29', '2023-02-28');
        Observer.Expect('4Y feb29', '2028-02-29');
        Observer.Expect('-4Y feb29', '2020-02-29');
        Observer.Expect('100Y', '2124-01-15');
        Observer.Expect('0Y', '2024-01-15');
        Observer.Expect('CY', '2024-12-31');
        Observer.Expect('CY jan1', '2024-12-31');
        Observer.Expect('CY dec31', '2024-12-31');
        Observer.Expect('-CY', '2024-01-01');
        Observer.Expect('-CY jan1', '2024-01-01');
        Observer.Expect('1Y+CY', '2025-12-31');
        Observer.Expect('-1Y+CY', '2023-12-31');
        Observer.Expect('CY+1D', '2025-01-01');
        Observer.Expect('-CY-1D', '2023-12-31');
        Observer.Expect('1Y+1M+1D', '2025-02-16');
        Observer.Expect('1Y+1Q+1M+1W+1D', '2025-05-23');
        Observer.Verify();
    end;

    [Test]
    procedure Combined_And_Syntax()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('CM+1D', Calc('<CM+1D>', 20240115D));
        Observer.Observe('1D+CM', Calc('<1D+CM>', 20240115D));
        Observer.Observe('-1M+CM+1D', Calc('<-1M+CM+1D>', 20240115D));
        Observer.Observe('CM-1D', Calc('<CM-1D>', 20240115D));
        Observer.Observe('CY+CM', Calc('<CY+CM>', 20240615D));
        Observer.Observe('CM+CY', Calc('<CM+CY>', 20240615D));
        Observer.Observe('CQ+CM', Calc('<CQ+CM>', 20240515D));
        Observer.Observe('CW+CM', Calc('<CW+CM>', 20240515D));
        Observer.Observe('1D1D', Calc('<1D1D>', 20240115D));
        Observer.Observe('1D 1D', Calc('<1D 1D>', 20240115D));
        Observer.Observe('1D+-1D', Calc('<1D+-1D>', 20240115D));
        Observer.Observe('1D+1D', Calc('<1D+1D>', 20240115D));
        Observer.Observe('1D-1D', Calc('<1D-1D>', 20240115D));
        Observer.Observe('1M1D', Calc('<1M1D>', 20240115D));
        Observer.Observe('1M+1D+1M', Calc('<1M+1D+1M>', 20240115D));
        Observer.Observe('CM-CM', Calc('<CM-CM>', 20240115D));
        Observer.Observe('LM', Calc('<LM>', 20240115D));
        Observer.Observe('CD', Calc('<CD>', 20240115D));
        Observer.Observe('empty', Calc('', 20240115D));
        Observer.Observe('only brackets', Calc('<>', 20240115D));
        Observer.Expect('CM+1D', '2024-02-01');
        Observer.Expect('1D+CM', '2024-01-31');
        Observer.Expect('-1M+CM+1D', '2024-01-01');
        Observer.Expect('CM-1D', '2024-01-30');
        Observer.Expect('CY+CM', '2024-12-31');
        Observer.Expect('CM+CY', '2024-12-31');
        Observer.Expect('CQ+CM', '2024-06-30');
        Observer.Expect('CW+CM', '2024-05-31');
        Observer.Expect('1D1D', 'eval-error');
        Observer.Expect('1D 1D', 'eval-error');
        Observer.Expect('1D+-1D', 'eval-error');
        Observer.Expect('1D+1D', '2024-01-17');
        Observer.Expect('1D-1D', '2024-01-15');
        Observer.Expect('1M1D', 'eval-error');
        Observer.Expect('1M+1D+1M', '2024-03-16');
        Observer.Expect('CM-CM', '2024-01-01');
        Observer.Expect('LM', 'eval-error');
        Observer.Expect('CD', '2024-01-15');
        Observer.Expect('empty', '2024-01-15');
        Observer.Expect('only brackets', '2024-01-15');
        Observer.Verify();
    end;

    [Test]
    procedure Invalid_Formula_Evaluate()
    var
        DF: DateFormula;
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Evaluate(DF, 'abc');
        Observer.ObserveError('abc');
        asserterror Evaluate(DF, '<1X>');
        Observer.ObserveError('1X');
        asserterror Evaluate(DF, '<D>');
        Observer.ObserveError('D alone');
        asserterror Evaluate(DF, '<1.5D>');
        Observer.ObserveError('1.5D');
        Evaluate(DF, '<1D');
        Observer.Observe('missing bracket', 'no error');
        Evaluate(DF, '1D>');
        Observer.Observe('missing open bracket', 'no error');
        asserterror Evaluate(DF, '<++1D>');
        Observer.ObserveError('double plus');
        asserterror Evaluate(DF, '<CM1>');
        Observer.ObserveError('CM1');
        asserterror Evaluate(DF, '<1CM>');
        Observer.ObserveError('1CM');
        asserterror Evaluate(DF, '<WD>');
        Observer.ObserveError('WD no number');
        asserterror Evaluate(DF, '<1MONDAY>');
        Observer.ObserveError('1MONDAY');
        Observer.Observe('evaluate ok', Format(Evaluate(DF, '<1D>')));
        Observer.Observe('evaluate bad', Format(Evaluate(DF, '<1X>')));
        Observer.Expect('abc|text', 'The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('abc|code', 'Evaluate');
        Observer.Expect('1X|text', 'The date formula ''1X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('1X|code', 'Evaluate');
        Observer.Expect('D alone|text', 'The date formula ''D'' should include a number.');
        Observer.Expect('D alone|code', 'Evaluate');
        Observer.Expect('1.5D|text', 'The date formula ''1.5D'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('1.5D|code', 'Evaluate');
        Observer.Expect('missing bracket', 'no error');
        Observer.Expect('missing open bracket', 'no error');
        Observer.Expect('double plus|text', 'The date formula ''++1D'' should include a number.');
        Observer.Expect('double plus|code', 'Evaluate');
        Observer.Expect('CM1|text', 'The date formula ''CM1'' must include plus (+) or minus (-).');
        Observer.Expect('CM1|code', 'Evaluate');
        Observer.Expect('1CM|text', 'The date formula ''1CM'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('1CM|code', 'Evaluate');
        Observer.Expect('WD no number|text', 'The date formula ''WD'' should include a number.');
        Observer.Expect('WD no number|code', 'Evaluate');
        Observer.Expect('1MONDAY|text', 'The date formula ''1MONDAY'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('1MONDAY|code', 'Evaluate');
        Observer.Expect('evaluate ok', 'Yes');
        Observer.Expect('evaluate bad', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Text_Overload_Errors()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        asserterror D := CalcDate('abc', 20240115D);
        Observer.ObserveError('abc');
        D := CalcDate('', 20240115D);
        Observer.Observe('empty', 'no error');
        asserterror D := CalcDate('<1X>', 20240115D);
        Observer.ObserveError('1X');
        asserterror D := CalcDate('<1D>', 99991231D);
        Observer.ObserveError('past max');
        asserterror D := CalcDate('<-1D>', 00010101D);
        Observer.ObserveError('before min');
        asserterror D := CalcDate('<1Y>', 99990101D);
        Observer.ObserveError('1Y past max');
        asserterror D := CalcDate('<-1Y>', 00010601D);
        Observer.ObserveError('-1Y before min');
        asserterror D := CalcDate('<1M>', 99991231D);
        Observer.ObserveError('1M past max');
        asserterror D := CalcDate('<1W>', 99991231D);
        Observer.ObserveError('1W past max');
        D := CalcDate('<CY>', 99991231D);
        Observer.Observe('CY at max', 'no error');
        Observer.Expect('abc|text', 'The date formula ''ABC'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('abc|code', 'Evaluate');
        Observer.Expect('empty', 'no error');
        Observer.Expect('1X|text', 'The date formula ''1X'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('1X|code', 'Evaluate');
        Observer.Expect('past max|text', 'The date is not valid.');
        Observer.Expect('past max|code', 'DateInvalid');
        Observer.Expect('before min|text', 'The date is not valid.');
        Observer.Expect('before min|code', 'DateInvalid');
        Observer.Expect('1Y past max|text', 'The date is not valid.');
        Observer.Expect('1Y past max|code', 'DateInvalid');
        Observer.Expect('-1Y before min|text', 'The date is not valid.');
        Observer.Expect('-1Y before min|code', 'DateInvalid');
        Observer.Expect('1M past max|text', 'The date is not valid.');
        Observer.Expect('1M past max|code', 'DateInvalid');
        Observer.Expect('1W past max|text', 'The date is not valid.');
        Observer.Expect('1W past max|code', 'DateInvalid');
        Observer.Expect('CY at max', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Undefined_Base()
    var
        Observer: Codeunit "Probe Observer";
        Original: Date;
    begin
        Original := WorkDate();
        WorkDate(20240115D);
        Observer.Observe('1D on 0D', Calc('<1D>', 0D));
        Observer.Observe('CM on 0D', Calc('<CM>', 0D));
        Observer.Observe('0D on 0D', Calc('<0D>', 0D));
        Observer.Observe('-1D on 0D', Calc('<-1D>', 0D));
        Observer.Observe('CY on 0D', Calc('<CY>', 0D));
        Observer.Observe('MON on 0D', Calc('<MON>', 0D));
        Observer.Observe('1W on 0D', Calc('<1W>', 0D));
        Observer.Observe('1M on 0D', Calc('<1M>', 0D));
        Observer.Observe('1Y on 0D', Calc('<1Y>', 0D));
        WorkDate(Original);
        Observer.Expect('1D on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: 1D.');
        Observer.Expect('CM on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: CM.');
        Observer.Expect('0D on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: 0D.');
        Observer.Expect('-1D on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: -1D.');
        Observer.Expect('CY on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: CY.');
        Observer.Expect('MON on 0D', 'eval-error');
        Observer.Expect('1W on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: 1W.');
        Observer.Expect('1M on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: 1M.');
        Observer.Expect('1Y on 0D', 'ERR:You cannot base a date calculation on an undefined date.\\Date: 0D\Formula: 1Y.');
        Observer.Verify();
    end;

    // Corpus issue 672 item 5: the example of the CalcDate page on Microsoft Learn (reference date 21 May 1996, a Tuesday; Learn
    // gives 07/20/96, 05/14/96 and 06/30/96). <-WD2> on a Tuesday: the previous Tuesday or the same day.
    [Test]
    procedure BT_LearnExample_1996()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('CQ+1M-10D', Calc('<CQ+1M-10D>', 19960521D));
        Observer.Observe('-WD2', Calc('<-WD2>', 19960521D));
        Observer.Observe('CM+30D', Calc('<CM+30D>', 19960521D));
        Observer.Observe('CQ+1M-10D text', CalcF('<CQ+1M-10D>', 19960521D));
        Observer.Observe('-WD2 text', CalcF('<-WD2>', 19960521D));
        Observer.Observe('CM+30D text', CalcF('<CM+30D>', 19960521D));
        Observer.Expect('CQ+1M-10D', '1996-07-20');
        Observer.Expect('-WD2', '1996-05-14');
        Observer.Expect('CM+30D', '1996-06-30');
        Observer.Expect('CQ+1M-10D text', '1996-07-20');
        Observer.Expect('-WD2 text', '1996-05-14');
        Observer.Expect('CM+30D text', '1996-06-30');
        Observer.Verify();
    end;
}
