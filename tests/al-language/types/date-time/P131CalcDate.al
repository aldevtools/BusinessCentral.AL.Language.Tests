// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73628
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CalcDate(Text, Date) and Evaluate(DateFormula, Text) with formulas whose angle brackets do not wrap the formula (one bracket,
//        brackets around a part such as 8D+<1D>, nested, doubled, empty brackets), the resulting date, error text and code, Format of the formula.
// BC versions: 29 (27 and 28 by CI)

codeunit 73628 "LT P131 CalcDate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, Base);
    end;

    local procedure Calc(Formula: Text): Text
    var
        D: Date;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryCalc(Formula, 20240115D, D);
        if not Ok then
            exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('ok|' + Format(D, 0, 9));
    end;

    local procedure Eval(Formula: Text): Text
    var
        DF: DateFormula;
        D: Date;
        Ok: Boolean;
    begin
        Ok := Evaluate(DF, Formula);
        if not Ok then
            exit('false|[' + Format(DF) + ']');
        D := CalcDate(DF, 20240115D);
        exit('true|[' + Format(DF) + ']|' + Format(D, 0, 9));
    end;

    [Test]
    procedure P131_CalcDate_OneBracket()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<+6W>', Calc('<+6W>'));
        Observer.Observe('<+6W', Calc('<+6W'));
        Observer.Observe('+6W>', Calc('+6W>'));
        Observer.Observe('+6W', Calc('+6W'));
        Observer.Observe('<1D', Calc('<1D'));
        Observer.Observe('1D>', Calc('1D>'));
        Observer.Observe('<-CM', Calc('<-CM'));
        Observer.Observe('CM>', Calc('CM>'));
        Observer.Observe('<CM', Calc('<CM'));
        Observer.Observe('<1D+1M', Calc('<1D+1M'));
        Observer.Observe('1D+1M>', Calc('1D+1M>'));
        Observer.Observe('<', Calc('<'));
        Observer.Observe('>', Calc('>'));
        Observer.Observe('<>', Calc('<>'));
        Observer.Observe('<+', Calc('<+'));
        Observer.Observe('<->', Calc('<->'));
        Observer.Expect('<+6W>', 'ok|2024-02-26');
        Observer.Expect('<+6W', 'ok|2024-02-26');
        Observer.Expect('+6W>', 'ok|2024-02-26');
        Observer.Expect('+6W', 'ok|2024-02-26');
        Observer.Expect('<1D', 'ok|2024-01-16');
        Observer.Expect('1D>', 'ok|2024-01-16');
        Observer.Expect('<-CM', 'ok|2024-01-01');
        Observer.Expect('CM>', 'ok|2024-01-31');
        Observer.Expect('<CM', 'ok|2024-01-31');
        Observer.Expect('<1D+1M', 'ok|2024-02-16');
        Observer.Expect('1D+1M>', 'ok|2024-02-16');
        Observer.Expect('<', 'ok|2024-01-15');
        Observer.Expect('>', 'ok|2024-01-15');
        Observer.Expect('<>', 'ok|2024-01-15');
        Observer.Expect('<+', 'error|The date formula ''<+'' should include a number.|Evaluate');
        Observer.Expect('<->', 'error|The date formula ''-'' should include a number.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure P131_CalcDate_BracketsAroundAPart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('8D+<1D>', Calc('8D+<1D>'));
        Observer.Observe('<8D+<1D>>', Calc('<8D+<1D>>'));
        Observer.Observe('<8D>+<1D>', Calc('<8D>+<1D>'));
        Observer.Observe('8D+1D', Calc('8D+1D'));
        Observer.Observe('<8D+1D>', Calc('<8D+1D>'));
        Observer.Observe('<1D><1D>', Calc('<1D><1D>'));
        Observer.Observe('<<1D>>', Calc('<<1D>>'));
        Observer.Observe('<1D>>', Calc('<1D>>'));
        Observer.Observe('<<1D>', Calc('<<1D>'));
        Observer.Observe('+<1D>', Calc('+<1D>'));
        Observer.Observe('<1D>+', Calc('<1D>+'));
        Observer.Observe('<1D+>', Calc('<1D+>'));
        Observer.Observe('1D+<1M>+<1D>', Calc('1D+<1M>+<1D>'));
        Observer.Observe('<1D>+1D', Calc('<1D>+1D'));
        Observer.Observe('<1D> +<1D>', Calc('<1D> +<1D>'));
        Observer.Observe('-<1D>', Calc('-<1D>'));
        Observer.Expect('8D+<1D>', 'ok|2024-01-24');
        Observer.Expect('<8D+<1D>>', 'ok|2024-01-24');
        Observer.Expect('<8D>+<1D>', 'ok|2024-01-24');
        Observer.Expect('8D+1D', 'ok|2024-01-24');
        Observer.Expect('<8D+1D>', 'ok|2024-01-24');
        Observer.Expect('<1D><1D>', 'error|The date formula ''1D><1D'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('<<1D>>', 'ok|2024-01-16');
        Observer.Expect('<1D>>', 'ok|2024-01-16');
        Observer.Expect('<<1D>', 'ok|2024-01-16');
        Observer.Expect('+<1D>', 'ok|2024-01-16');
        Observer.Expect('<1D>+', 'error|The date formula ''<1D>+'' should include a number.|Evaluate');
        Observer.Expect('<1D+>', 'error|The date formula ''1D+'' should include a number.|Evaluate');
        Observer.Expect('1D+<1M>+<1D>', 'ok|2024-02-17');
        Observer.Expect('<1D>+1D', 'ok|2024-01-17');
        Observer.Expect('<1D> +<1D>', 'ok|2024-01-17');
        Observer.Expect('-<1D>', 'ok|2024-01-14');
        Observer.Verify();
    end;

    [Test]
    procedure P131_EvaluateDateFormula_OddBrackets()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('<+6W', Eval('<+6W'));
        Observer.Observe('+6W>', Eval('+6W>'));
        Observer.Observe('8D+<1D>', Eval('8D+<1D>'));
        Observer.Observe('<8D+<1D>>', Eval('<8D+<1D>>'));
        Observer.Observe('<8D>+<1D>', Eval('<8D>+<1D>'));
        Observer.Observe('<1D><1D>', Eval('<1D><1D>'));
        Observer.Observe('<<1D>>', Eval('<<1D>>'));
        Observer.Observe('<>', Eval('<>'));
        Observer.Observe('<', Eval('<'));
        Observer.Observe('1D+<1D>', Eval('1D+<1D>'));
        Observer.Observe('<1D>+', Eval('<1D>+'));
        Observer.Observe('+<1D>', Eval('+<1D>'));
        Observer.Expect('<+6W', 'true|[+6W]|2024-02-26');
        Observer.Expect('+6W>', 'true|[+6W]|2024-02-26');
        Observer.Expect('8D+<1D>', 'true|[8D+1D]|2024-01-24');
        Observer.Expect('<8D+<1D>>', 'true|[8D+1D]|2024-01-24');
        Observer.Expect('<8D>+<1D>', 'true|[8D+1D]|2024-01-24');
        Observer.Expect('<1D><1D>', 'false|[]');
        Observer.Expect('<<1D>>', 'true|[1D]|2024-01-16');
        Observer.Expect('<>', 'true|[]|2024-01-15');
        Observer.Expect('<', 'true|[]|2024-01-15');
        Observer.Expect('1D+<1D>', 'true|[1D+1D]|2024-01-17');
        Observer.Expect('<1D>+', 'false|[]');
        Observer.Expect('+<1D>', 'true|[+1D]|2024-01-16');
        Observer.Verify();
    end;
}
