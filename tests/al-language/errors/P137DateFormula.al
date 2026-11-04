// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: date formula texts with angle brackets inside the text (8D+<1D>, <8D+<1D>>, <8D>+<1D>, <8D><1D>, brackets around one part): Evaluate into a DateFormula (result, stored formula, the date it gives from 2024-01-31) and CalcDate(Text, Date) (the date or the error text and code)
// BC versions: 29 (27 and 28 by CI)

codeunit 74431 "LT P137 Date Formula"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Txt: Text; var Result: Date)
    begin
        Result := CalcDate(Txt, 20240131D);
    end;

    local procedure Ev(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        F: DateFormula;
        Ok: Boolean;
        R: Date;
        Applied: Text;
    begin
        Ok := Evaluate(F, Txt);
        Applied := '';
        if Ok then begin
            if TryCalc(Format(F), R) then
                Applied := Format(R, 0, 9)
            else begin
                Applied := 'calc error:' + GetLastErrorText();
                ClearLastError();
            end;
        end;
        Observer.Observe(Name, CopyStr(Format(Ok) + '|[' + Format(F) + ']|' + Applied, 1, 800));
    end;

    local procedure Calc(var Observer: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        R: Date;
    begin
        if TryCalc(Txt, R) then
            Observer.Observe(Name, 'ok|' + Format(R, 0, 9))
        else begin
            Observer.Observe(Name, CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 800));
            ClearLastError();
        end;
    end;

    [Test]
    procedure P137_Evaluate_BracketsInsideTheText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Ev(Observer, 'ev_8d_plus_1d_brackets', '8D+<1D>');
        Ev(Observer, 'ev_outer_and_inner', '<8D+<1D>>');
        Ev(Observer, 'ev_two_bracketed_parts', '<8D>+<1D>');
        Ev(Observer, 'ev_two_bracketed_no_sign', '<8D><1D>');
        Ev(Observer, 'ev_first_bracketed', '<8D>+1D');
        Ev(Observer, 'ev_second_bracketed_minus', '8D-<1D>');
        Ev(Observer, 'ev_cm_plus_bracketed', 'CM+<1D>');
        Ev(Observer, 'ev_bracketed_cm_plus', '<CM>+1D');
        Ev(Observer, 'ev_unclosed_inner', '8D+<1D');
        Ev(Observer, 'ev_unopened_inner', '8D+1D>');
        Ev(Observer, 'ev_empty_inner', '8D+<>');
        Ev(Observer, 'ev_empty_brackets', '<>');
        Ev(Observer, 'ev_reversed', '>8D<');
        Ev(Observer, 'ev_double', '<<8D>>');
        Ev(Observer, 'ev_bracket_then_text', '<1D>1W');
        Ev(Observer, 'ev_text_then_bracket', '1D<1W>');
        Observer.Expect('ev_8d_plus_1d_brackets', 'Yes|[8D+1D]|2024-02-09');
        Observer.Expect('ev_outer_and_inner', 'Yes|[8D+1D]|2024-02-09');
        Observer.Expect('ev_two_bracketed_parts', 'Yes|[8D+1D]|2024-02-09');
        Observer.Expect('ev_two_bracketed_no_sign', 'No|[]|');
        Observer.Expect('ev_first_bracketed', 'Yes|[8D+1D]|2024-02-09');
        Observer.Expect('ev_second_bracketed_minus', 'Yes|[8D-1D]|2024-02-07');
        Observer.Expect('ev_cm_plus_bracketed', 'Yes|[CM+1D]|2024-02-01');
        Observer.Expect('ev_bracketed_cm_plus', 'Yes|[CM+1D]|2024-02-01');
        Observer.Expect('ev_unclosed_inner', 'Yes|[8D+1D]|2024-02-09');
        Observer.Expect('ev_unopened_inner', 'Yes|[8D+1D]|2024-02-09');
        Observer.Expect('ev_empty_inner', 'No|[]|');
        Observer.Expect('ev_empty_brackets', 'Yes|[]|2024-01-31');
        Observer.Expect('ev_reversed', 'Yes|[8D]|2024-02-08');
        Observer.Expect('ev_double', 'Yes|[8D]|2024-02-08');
        Observer.Expect('ev_bracket_then_text', 'No|[]|');
        Observer.Expect('ev_text_then_bracket', 'No|[]|');
        Observer.Verify();
    end;

    [Test]
    procedure P137_CalcDate_BracketsInsideTheText()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Calc(Observer, 'calc_8d_plus_1d_brackets', '8D+<1D>');
        Calc(Observer, 'calc_outer_and_inner', '<8D+<1D>>');
        Calc(Observer, 'calc_two_bracketed_parts', '<8D>+<1D>');
        Calc(Observer, 'calc_two_bracketed_no_sign', '<8D><1D>');
        Calc(Observer, 'calc_first_bracketed', '<8D>+1D');
        Calc(Observer, 'calc_second_bracketed_minus', '8D-<1D>');
        Calc(Observer, 'calc_cm_plus_bracketed', 'CM+<1D>');
        Calc(Observer, 'calc_bracketed_cm_plus', '<CM>+1D');
        Calc(Observer, 'calc_unclosed_inner', '8D+<1D');
        Calc(Observer, 'calc_unopened_inner', '8D+1D>');
        Calc(Observer, 'calc_empty_inner', '8D+<>');
        Calc(Observer, 'calc_empty_brackets', '<>');
        Calc(Observer, 'calc_double', '<<8D>>');
        Calc(Observer, 'calc_plain_sum', '8D+1D');
        Calc(Observer, 'calc_plain_sum_brackets', '<8D+1D>');
        Observer.Expect('calc_8d_plus_1d_brackets', 'ok|2024-02-09');
        Observer.Expect('calc_outer_and_inner', 'ok|2024-02-09');
        Observer.Expect('calc_two_bracketed_parts', 'ok|2024-02-09');
        Observer.Expect('calc_two_bracketed_no_sign', 'error:The date formula ''8D><1D'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('calc_first_bracketed', 'ok|2024-02-09');
        Observer.Expect('calc_second_bracketed_minus', 'ok|2024-02-07');
        Observer.Expect('calc_cm_plus_bracketed', 'ok|2024-02-01');
        Observer.Expect('calc_bracketed_cm_plus', 'ok|2024-02-01');
        Observer.Expect('calc_unclosed_inner', 'ok|2024-02-09');
        Observer.Expect('calc_unopened_inner', 'ok|2024-02-09');
        Observer.Expect('calc_empty_inner', 'error:The date formula ''8D+<>'' should include a number.|Evaluate');
        Observer.Expect('calc_empty_brackets', 'ok|2024-01-31');
        Observer.Expect('calc_double', 'ok|2024-02-08');
        Observer.Expect('calc_plain_sum', 'ok|2024-02-09');
        Observer.Expect('calc_plain_sum_brackets', 'ok|2024-02-09');
        Observer.Verify();
    end;
}
