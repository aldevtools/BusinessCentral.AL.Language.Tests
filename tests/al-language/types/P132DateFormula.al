// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-function
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 73701 "LT P132 DateFormula"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure EvalOne(var Observer: Codeunit "Probe Observer"; ObsName: Text; Input: Text)
    var
        F: DateFormula;
    begin
        if not Evaluate(F, Input) then begin
            Observer.Observe(ObsName, 'false');
            exit;
        end;
        Observer.Observe(ObsName, 'true [' + Format(F) + ']');
    end;

    [TryFunction]
    local procedure TryCalc(Formula: Text; var Result: Date)
    begin
        Result := CalcDate(Formula, 20240131D);
    end;

    local procedure CalcOne(var Observer: Codeunit "Probe Observer"; ObsName: Text; Formula: Text)
    var
        Result: Date;
    begin
        if TryCalc(Formula, Result) then
            Observer.Observe(ObsName, 'ok ' + Format(Result, 0, 9))
        else begin
            Observer.Observe(ObsName, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure P132_Evaluate_InnerBrackets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvalOne(Observer, 'inner_second', '8D+<1D>');
        EvalOne(Observer, 'wrapped_inner', '<8D+<1D>>');
        EvalOne(Observer, 'two_wrapped', '<8D>+<1D>');
        EvalOne(Observer, 'plus_6w_open', '<+6W');
        EvalOne(Observer, 'plus_6w_close', '+6W>');
        EvalOne(Observer, 'double_wrap', '<<1D>>');
        EvalOne(Observer, 'open_only', '<1D');
        EvalOne(Observer, 'close_only', '1D>');
        EvalOne(Observer, 'double_close', '<1D>>');
        EvalOne(Observer, 'reversed', '>1D<');
        EvalOne(Observer, 'two_groups_nosign', '<1D><1W>');
        EvalOne(Observer, 'two_groups_sign', '<1D>+<1W>');
        EvalOne(Observer, 'trailing_sign', '<1D+>');
        EvalOne(Observer, 'only_plus', '<+>');
        EvalOne(Observer, 'only_open', '<');
        EvalOne(Observer, 'only_close', '>');
        EvalOne(Observer, 'empty_double', '<<>>');
        EvalOne(Observer, 'open_inner_open', '8D+<1D');
        EvalOne(Observer, 'close_inner', '8D+1D>');
        EvalOne(Observer, 'three_parts', '1D+<1W>+2D');
        EvalOne(Observer, 'minus_inner', '-<1D>');
        EvalOne(Observer, 'wrapped_minus_inner', '<-<1D>>');
        EvalOne(Observer, 'inner_then_minus', '<1D>-1W');
        EvalOne(Observer, 'plain_control', '8D+1D');
        EvalOne(Observer, 'wrapped_control', '<8D+1D>');
        Observer.Expect('inner_second', 'true [8D+1D]');
        Observer.Expect('wrapped_inner', 'true [8D+1D]');
        Observer.Expect('two_wrapped', 'true [8D+1D]');
        Observer.Expect('plus_6w_open', 'true [+6W]');
        Observer.Expect('plus_6w_close', 'true [+6W]');
        Observer.Expect('double_wrap', 'true [1D]');
        Observer.Expect('open_only', 'true [1D]');
        Observer.Expect('close_only', 'true [1D]');
        Observer.Expect('double_close', 'true [1D]');
        Observer.Expect('reversed', 'true [1D]');
        Observer.Expect('two_groups_nosign', 'false');
        Observer.Expect('two_groups_sign', 'true [1D+1W]');
        Observer.Expect('trailing_sign', 'false');
        Observer.Expect('only_plus', 'false');
        Observer.Expect('only_open', 'true []');
        Observer.Expect('only_close', 'true []');
        Observer.Expect('empty_double', 'true []');
        Observer.Expect('open_inner_open', 'true [8D+1D]');
        Observer.Expect('close_inner', 'true [8D+1D]');
        Observer.Expect('three_parts', 'true [1D+1W+2D]');
        Observer.Expect('minus_inner', 'true [-1D]');
        Observer.Expect('wrapped_minus_inner', 'true [-1D]');
        Observer.Expect('inner_then_minus', 'true [1D-1W]');
        Observer.Expect('plain_control', 'true [8D+1D]');
        Observer.Expect('wrapped_control', 'true [8D+1D]');
        Observer.Verify();
    end;

    [Test]
    procedure P132_CalcDate_InnerBrackets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcOne(Observer, 'inner_second', '8D+<1D>');
        CalcOne(Observer, 'wrapped_inner', '<8D+<1D>>');
        CalcOne(Observer, 'two_wrapped', '<8D>+<1D>');
        CalcOne(Observer, 'plus_6w_open', '<+6W');
        CalcOne(Observer, 'plus_6w_close', '+6W>');
        CalcOne(Observer, 'double_wrap', '<<1D>>');
        CalcOne(Observer, 'open_only', '<1D');
        CalcOne(Observer, 'close_only', '1D>');
        CalcOne(Observer, 'double_close', '<1D>>');
        CalcOne(Observer, 'reversed', '>1D<');
        CalcOne(Observer, 'two_groups_nosign', '<1D><1W>');
        CalcOne(Observer, 'two_groups_sign', '<1D>+<1W>');
        CalcOne(Observer, 'trailing_sign', '<1D+>');
        CalcOne(Observer, 'only_plus', '<+>');
        CalcOne(Observer, 'only_open', '<');
        CalcOne(Observer, 'only_close', '>');
        CalcOne(Observer, 'empty_double', '<<>>');
        CalcOne(Observer, 'open_inner_open', '8D+<1D');
        CalcOne(Observer, 'close_inner', '8D+1D>');
        CalcOne(Observer, 'three_parts', '1D+<1W>+2D');
        CalcOne(Observer, 'minus_inner', '-<1D>');
        CalcOne(Observer, 'wrapped_minus_inner', '<-<1D>>');
        CalcOne(Observer, 'inner_then_minus', '<1D>-1W');
        CalcOne(Observer, 'plain_control', '8D+1D');
        CalcOne(Observer, 'wrapped_control', '<8D+1D>');
        Observer.Expect('inner_second', 'ok 2024-02-09');
        Observer.Expect('wrapped_inner', 'ok 2024-02-09');
        Observer.Expect('two_wrapped', 'ok 2024-02-09');
        Observer.Expect('plus_6w_open', 'ok 2024-03-13');
        Observer.Expect('plus_6w_close', 'ok 2024-03-13');
        Observer.Expect('double_wrap', 'ok 2024-02-01');
        Observer.Expect('open_only', 'ok 2024-02-01');
        Observer.Expect('close_only', 'ok 2024-02-01');
        Observer.Expect('double_close', 'ok 2024-02-01');
        Observer.Expect('reversed', 'ok 2024-02-01');
        Observer.Expect('two_groups_nosign', 'error:The date formula ''1D><1W'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('two_groups_sign', 'ok 2024-02-08');
        Observer.Expect('trailing_sign', 'error:The date formula ''1D+'' should include a number.|Evaluate');
        Observer.Expect('only_plus', 'error:The date formula ''+'' should include a number.|Evaluate');
        Observer.Expect('only_open', 'ok 2024-01-31');
        Observer.Expect('only_close', 'ok 2024-01-31');
        Observer.Expect('empty_double', 'ok 2024-01-31');
        Observer.Expect('open_inner_open', 'ok 2024-02-09');
        Observer.Expect('close_inner', 'ok 2024-02-09');
        Observer.Expect('three_parts', 'ok 2024-02-10');
        Observer.Expect('minus_inner', 'ok 2024-01-30');
        Observer.Expect('wrapped_minus_inner', 'ok 2024-01-30');
        Observer.Expect('inner_then_minus', 'ok 2024-01-25');
        Observer.Expect('plain_control', 'ok 2024-02-09');
        Observer.Expect('wrapped_control', 'ok 2024-02-09');
        Observer.Verify();
    end;

    [Test]
    procedure P132_CalcDate_MissingSignErrors()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // the Microsoft tests meet "The date formula ... must include plus (+) or minus (-)." after such formulas
        CalcOne(Observer, 'two_nosign', '1D1W');
        CalcOne(Observer, 'two_nosign_wrapped', '<1D1W>');
        CalcOne(Observer, 'cm_then_d', '<CM1D>');
        CalcOne(Observer, 'cm_plus', '<CM+1D>');
        CalcOne(Observer, 'wd_nosign', '<1D2WD>');
        CalcOne(Observer, 'inner_nosign', '8D<1D>');
        CalcOne(Observer, 'inner_nosign_wrapped', '<8D<1D>>');
        CalcOne(Observer, 'inner_nosign_open', '<8D<1D');
        CalcOne(Observer, 'blank', '');
        CalcOne(Observer, 'spaces', '   ');
        CalcOne(Observer, 'letters_only', 'D');
        CalcOne(Observer, 'wrapped_letters_only', '<D>');
        CalcOne(Observer, 'lower_inner', '8d+<1d>');
        CalcOne(Observer, 'space_inner', '8D + < 1D >');
        Observer.Expect('two_nosign', 'error:The date formula ''1D1W'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('two_nosign_wrapped', 'error:The date formula ''1D1W'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('cm_then_d', 'error:The date formula ''CM1D'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('cm_plus', 'ok 2024-02-01');
        Observer.Expect('wd_nosign', 'error:The date formula ''1D2WD'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('inner_nosign', 'error:The date formula ''8D<1D>'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('inner_nosign_wrapped', 'error:The date formula ''8D<1D>'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('inner_nosign_open', 'error:The date formula ''<8D<1D'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('blank', 'ok 2024-01-31');
        Observer.Expect('spaces', 'ok 2024-01-31');
        Observer.Expect('letters_only', 'error:The date formula ''D'' should include a number.|Evaluate');
        Observer.Expect('wrapped_letters_only', 'error:The date formula ''D'' should include a number.|Evaluate');
        Observer.Expect('lower_inner', 'ok 2024-02-09');
        Observer.Expect('space_inner', 'ok 2024-02-09');
        Observer.Verify();
    end;

    [Test]
    procedure P132_CalcDate_DateOverload_InnerBrackets()
    var
        Observer: Codeunit "Probe Observer";
        F: DateFormula;
    begin
        if Evaluate(F, '8D+<1D>') then
            Observer.Observe('formula_inner', Format(CalcDate(F, 20240131D), 0, 9))
        else
            Observer.Observe('formula_inner', 'evaluate false');
        if Evaluate(F, '<+6W') then
            Observer.Observe('formula_plus6w_open', Format(CalcDate(F, 20240131D), 0, 9))
        else
            Observer.Observe('formula_plus6w_open', 'evaluate false');
        if Evaluate(F, '<8D>+<1D>') then
            Observer.Observe('formula_two_wrapped', Format(CalcDate(F, 20240131D), 0, 9))
        else
            Observer.Observe('formula_two_wrapped', 'evaluate false');
        Observer.Expect('formula_inner', '2024-02-09');
        Observer.Expect('formula_plus6w_open', '2024-03-13');
        Observer.Expect('formula_two_wrapped', '2024-02-09');
        Observer.Verify();
    end;
}
