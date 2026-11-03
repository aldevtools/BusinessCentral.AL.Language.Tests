// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of a text containing %1 with an Integer second argument (the Length parameter, not a substitution), the CalcDate outcome or error for a date formula text built that way, versus StrSubstNo
// BC versions: 29 (27 and 28 by CI)

codeunit 70004 "LT P146 Format CalcDate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, Base);
    end;

    [Test]
    procedure P146_Format_TextWithPlaceholder()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := Format('<+%1D>', 5);
        Observer.Observe('format len 5', T);
        Observer.Observe('format len 5 length', Format(StrLen(T)));
        Observer.Observe('format len 0', Format('<+%1D>', 0));
        Observer.Observe('format len 3', Format('<+%1D>', 3));
        Observer.Observe('format len 6', Format('<+%1D>', 6));
        Observer.Observe('format len 10', '[' + Format('<+%1D>', 10) + ']');
        Observer.Observe('format len 10 length', Format(StrLen(Format('<+%1D>', 10))));
        Observer.Observe('format no length', Format('<+%1D>'));
        Observer.Observe('format xml', Format('<+%1D>', 0, 9));
        Observer.Observe('strsubstno', StrSubstNo('<+%1D>', 5));
        Observer.Observe('strsubstno format', StrSubstNo('<+%1D>', Format(5)));
        Observer.Observe('format of 5', Format(5));
        Observer.Observe('format of code', Format('ab%1' + 'c', 2));
        Observer.Expect('format len 5', '<+%1D');
        Observer.Expect('format len 5 length', '5');
        Observer.Expect('format len 0', '<+%1D>');
        Observer.Expect('format len 3', '<+%');
        Observer.Expect('format len 6', '<+%1D>');
        Observer.Expect('format len 10', '[<+%1D>    ]');
        Observer.Expect('format len 10 length', '10');
        Observer.Expect('format no length', '<+%1D>');
        Observer.Expect('format xml', '<+%1D>');
        Observer.Expect('strsubstno', '<+5D>');
        Observer.Expect('strsubstno format', '<+5D>');
        Observer.Expect('format of 5', '5');
        Observer.Expect('format of code', 'ab');
        Observer.Verify();
    end;

    [Test]
    procedure P146_CalcDate_FormatBuilt_Formula()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Res: Date;
        Ok: Boolean;
    begin
        D := DMY2Date(15, 1, 2024);
        Ok := TryCalc(Format('<+%1D>', 5), D, Res);
        Observer.Observe('format 5 ok', Format(Ok));
        Observer.Observe('format 5 result', Format(Res, 0, 9));
        Observer.ObserveError('format 5 error');
        Clear(Res);
        Ok := TryCalc(Format('<+%1D>', 0), D, Res);
        Observer.Observe('format 0 ok', Format(Ok));
        Observer.Observe('format 0 result', Format(Res, 0, 9));
        Observer.ObserveError('format 0 error');
        Clear(Res);
        Ok := TryCalc(StrSubstNo('<+%1D>', 5), D, Res);
        Observer.Observe('strsubstno ok', Format(Ok));
        Observer.Observe('strsubstno result', Format(Res, 0, 9));
        Clear(Res);
        Ok := TryCalc(StrSubstNo('<%1D>', -5), D, Res);
        Observer.Observe('strsubstno neg ok', Format(Ok));
        Observer.Observe('strsubstno neg result', Format(Res, 0, 9));
        Clear(Res);
        Ok := TryCalc(StrSubstNo('<+%1M>', 2), D, Res);
        Observer.Observe('strsubstno month ok', Format(Ok));
        Observer.Observe('strsubstno month result', Format(Res, 0, 9));
        Clear(Res);
        Ok := TryCalc('<+%1D>', D, Res);
        Observer.Observe('literal placeholder ok', Format(Ok));
        Observer.Observe('literal placeholder result', Format(Res, 0, 9));
        Observer.ObserveError('literal placeholder error');
        Observer.Expect('format 5 ok', 'Yes');
        Observer.Expect('format 5 result', '2024-01-16');
        Observer.Expect('format 5 error|text', '');
        Observer.Expect('format 5 error|code', '');
        Observer.Expect('format 0 ok', 'Yes');
        Observer.Expect('format 0 result', '2024-01-16');
        Observer.Expect('format 0 error|text', '');
        Observer.Expect('format 0 error|code', '');
        Observer.Expect('strsubstno ok', 'Yes');
        Observer.Expect('strsubstno result', '2024-01-20');
        Observer.Expect('strsubstno neg ok', 'Yes');
        Observer.Expect('strsubstno neg result', '2024-01-10');
        Observer.Expect('strsubstno month ok', 'Yes');
        Observer.Expect('strsubstno month result', '2024-03-15');
        Observer.Expect('literal placeholder ok', 'Yes');
        Observer.Expect('literal placeholder result', '2024-01-16');
        Observer.Expect('literal placeholder error|text', '');
        Observer.Expect('literal placeholder error|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure P146_CalcDate_OtherFormulaTexts()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Res: Date;
        Ok: Boolean;
    begin
        D := DMY2Date(15, 1, 2024);
        Ok := TryCalc('<+D>', D, Res);
        Observer.Observe('plus d ok', Format(Ok));
        Observer.Observe('plus d result', Format(Res, 0, 9));
        Observer.ObserveError('plus d error');
        Clear(Res);
        Ok := TryCalc('<+5>', D, Res);
        Observer.Observe('plus 5 ok', Format(Ok));
        Observer.Observe('plus 5 result', Format(Res, 0, 9));
        Observer.ObserveError('plus 5 error');
        Clear(Res);
        Ok := TryCalc('', D, Res);
        Observer.Observe('empty ok', Format(Ok));
        Observer.Observe('empty result', Format(Res, 0, 9));
        Observer.ObserveError('empty error');
        Clear(Res);
        Ok := TryCalc(Format('<+5D>', 0), D, Res);
        Observer.Observe('format of valid formula ok', Format(Ok));
        Observer.Observe('format of valid formula result', Format(Res, 0, 9));
        Observer.ObserveError('format of valid formula error');
        Clear(Res);
        Ok := TryCalc(Format('<+%1D>', 5), D, Res);
        Observer.Observe('again ok', Format(Ok));
        Observer.ObserveError('again error');
        Observer.Expect('plus d ok', 'No');
        Observer.Expect('plus d result', '');
        Observer.Expect('plus d error|text', 'The date formula ''+D'' should include a number.');
        Observer.Expect('plus d error|code', 'Evaluate');
        Observer.Expect('plus 5 ok', 'No');
        Observer.Expect('plus 5 result', '');
        Observer.Expect('plus 5 error|text', 'The date formula ''+5'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.');
        Observer.Expect('plus 5 error|code', 'Evaluate');
        Observer.Expect('empty ok', 'Yes');
        Observer.Expect('empty result', '2024-01-15');
        Observer.Expect('empty error|text', '');
        Observer.Expect('empty error|code', '');
        Observer.Expect('format of valid formula ok', 'Yes');
        Observer.Expect('format of valid formula result', '2024-01-20');
        Observer.Expect('format of valid formula error|text', '');
        Observer.Expect('format of valid formula error|code', '');
        Observer.Expect('again ok', 'Yes');
        Observer.Expect('again error|text', '');
        Observer.Expect('again error|code', '');
        Observer.Verify();
    end;
}
