// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73146
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CalcDate and Evaluate(DateFormula) with a formula text that has an angle bracket in the MIDDLE or around one part only (5D+<1D>, <5D>+1D, <5D>+<1D>, 5D+<1D, 5D+1D>), and with a text
// that is a date and not a formula (10/16/26 and other spellings). The one-bracket forms at the ends of the text are drafted in issue 136 (drafts/p136/P136Text.al); this file adds the others.
// Base date 15 January 2024 (a fixed date).
// BC versions: 29 (27 and 28 by CI)

codeunit 73146 "LT P128 CalcDate Forms"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(F: Text; D: Date; var R: Date)
    begin
        R := CalcDate(F, D);
    end;

    local procedure Calc(var Observer: Codeunit "Probe Observer"; Name: Text; F: Text; D: Date)
    var
        R: Date;
    begin
        if TryCalc(F, D, R) then
            Observer.Observe(Name, Format(R, 0, 9))
        else
            Observer.ObserveError(Name);
    end;

    local procedure Eval(var Observer: Codeunit "Probe Observer"; Name: Text; F: Text)
    var
        DF: DateFormula;
        Ok: Boolean;
    begin
        Ok := Evaluate(DF, F);
        Observer.Observe(Name, Format(Ok) + '|' + Format(DF));
    end;

    [Test]
    procedure P128_CalcDate_BracketInTheMiddle()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240115D;
        Calc(Observer, 'plain 5D+1D', '5D+1D', D);
        Calc(Observer, '5D+<1D>', '5D+<1D>', D);
        Calc(Observer, '<5D>+1D', '<5D>+1D', D);
        Calc(Observer, '<5D>+<1D>', '<5D>+<1D>', D);
        Calc(Observer, '<5D+<1D>>', '<5D+<1D>>', D);
        Calc(Observer, '5D+<1D', '5D+<1D', D);
        Calc(Observer, '5D+1D>', '5D+1D>', D);
        Calc(Observer, '5D<+1D>', '5D<+1D>', D);
        Calc(Observer, '<5D>-<1D>', '<5D>-<1D>', D);
        Calc(Observer, '1M+<CM>', '1M+<CM>', D);
        Calc(Observer, '<CM>+1D', '<CM>+1D', D);
        Calc(Observer, '-<1D>', '-<1D>', D);
        Calc(Observer, '+<1D>', '+<1D>', D);
        Observer.Expect('plain 5D+1D', '2024-01-21');
        Observer.Expect('5D+<1D>', '2024-01-21');
        Observer.Expect('<5D>+1D', '2024-01-21');
        Observer.Expect('<5D>+<1D>', '2024-01-21');
        Observer.Expect('<5D+<1D>>', '2024-01-21');
        Observer.Expect('5D+<1D', '2024-01-21');
        Observer.Expect('5D+1D>', '2024-01-21');
        Observer.Expect('5D<+1D>', '2024-01-21');
        Observer.Expect('<5D>-<1D>', '2024-01-19');
        Observer.Expect('1M+<CM>', '2024-02-29');
        Observer.Expect('<CM>+1D', '2024-02-01');
        Observer.Expect('-<1D>', '2024-01-14');
        Observer.Expect('+<1D>', '2024-01-16');
        Observer.Verify();
    end;

    [Test]
    procedure P128_Evaluate_DateFormula_BracketInTheMiddle()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Eval(Observer, '5D+<1D>', '5D+<1D>');
        Eval(Observer, '<5D>+1D', '<5D>+1D');
        Eval(Observer, '<5D>+<1D>', '<5D>+<1D>');
        Eval(Observer, '<5D+<1D>>', '<5D+<1D>>');
        Eval(Observer, '5D+<1D', '5D+<1D');
        Eval(Observer, '5D+1D>', '5D+1D>');
        Eval(Observer, '1M+<CM>', '1M+<CM>');
        Eval(Observer, '-<1D>', '-<1D>');
        Observer.Expect('5D+<1D>', 'Yes|5D+1D');
        Observer.Expect('<5D>+1D', 'Yes|5D+1D');
        Observer.Expect('<5D>+<1D>', 'Yes|5D+1D');
        Observer.Expect('<5D+<1D>>', 'Yes|5D+1D');
        Observer.Expect('5D+<1D', 'Yes|5D+1D');
        Observer.Expect('5D+1D>', 'Yes|5D+1D');
        Observer.Expect('1M+<CM>', 'Yes|1M+CM');
        Observer.Expect('-<1D>', 'Yes|-1D');
        Observer.Verify();
    end;

    [Test]
    procedure P128_CalcDate_DateTextIsNotAFormula()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240115D;
        Calc(Observer, '10/16/26', '10/16/26', D);
        Calc(Observer, '16/10/26', '16/10/26', D);
        Calc(Observer, '10/16/2026', '10/16/2026', D);
        Calc(Observer, '2026-10-16', '2026-10-16', D);
        Calc(Observer, '161026', '161026', D);
        Calc(Observer, '10-16-26', '10-16-26', D);
        Calc(Observer, '<10/16/26>', '<10/16/26>', D);
        Calc(Observer, '1/2/24', '1/2/24', D);
        Calc(Observer, '1D/1D', '1D/1D', D);
        Calc(Observer, 'Format of a date', Format(20261016D), D);
        Calc(Observer, 'Format of a date 9', Format(20261016D, 0, 9), D);
        Calc(Observer, 'blank', ' ', D);
        Observer.Expect('10/16/26|text', 'The date formula ''10/16/26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('10/16/26|code', 'Evaluate');
        Observer.Expect('16/10/26|text', 'The date formula ''16/10/26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('16/10/26|code', 'Evaluate');
        Observer.Expect('10/16/2026|text', 'The date formula ''10/16/2026'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('10/16/2026|code', 'Evaluate');
        Observer.Expect('2026-10-16|text', 'The date formula ''2026-10-16'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('2026-10-16|code', 'Evaluate');
        Observer.Expect('161026|text', 'The date formula ''161026'' contains a number that is too large.\\The number must be in the range 0 - 9999.');
        Observer.Expect('161026|code', 'Evaluate');
        Observer.Expect('10-16-26|text', 'The date formula ''10-16-26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('10-16-26|code', 'Evaluate');
        Observer.Expect('<10/16/26>|text', 'The date formula ''10/16/26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('<10/16/26>|code', 'Evaluate');
        Observer.Expect('1/2/24|text', 'The date formula ''1/2/24'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('1/2/24|code', 'Evaluate');
        Observer.Expect('1D/1D|text', 'The date formula ''1D/1D'' must include plus (+) or minus (-).');
        Observer.Expect('1D/1D|code', 'Evaluate');
        Observer.Expect('Format of a date|text', 'The date formula ''10/16/26'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('Format of a date|code', 'Evaluate');
        Observer.Expect('Format of a date 9|text', 'The date formula ''2026-10-16'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('Format of a date 9|code', 'Evaluate');
        Observer.Expect('blank', '2024-01-15');
        Observer.Verify();
    end;





    [Test]
    procedure P128_Evaluate_DateFormula_DateText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Eval(Observer, '10/16/26', '10/16/26');
        Eval(Observer, '16/10/26', '16/10/26');
        Eval(Observer, '10/16/2026', '10/16/2026');
        Eval(Observer, '2026-10-16', '2026-10-16');
        Eval(Observer, '161026', '161026');
        Eval(Observer, '10-16-26', '10-16-26');
        Eval(Observer, 'Format of a date', Format(20261016D));
        Eval(Observer, 'Format of a date 9', Format(20261016D, 0, 9));
        Observer.Expect('10/16/26', 'No|');
        Observer.Expect('16/10/26', 'No|');
        Observer.Expect('10/16/2026', 'No|');
        Observer.Expect('2026-10-16', 'No|');
        Observer.Expect('161026', 'No|');
        Observer.Expect('10-16-26', 'No|');
        Observer.Expect('Format of a date', 'No|');
        Observer.Expect('Format of a date 9', 'No|');
        Observer.Verify();
    end;
}
