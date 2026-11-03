// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73255
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: CalcDate and Evaluate into a DateFormula with a formula text that holds ONE angle bracket or brackets in the middle ('5D+<1D>', '<5D>+1D', '<5D>+<1D>', '<5D+1D', '5D+1D>', '<<1D>>'):
// the date, the stored formula text, the error text and code.
// BC versions: 29 (27 and 28 by CI)

codeunit 73255 "LT P129 Calc Date Angles"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCalc(Formula: Text; Base: Date; var Result: Date)
    begin
        Result := CalcDate(Formula, Base);
    end;

    [TryFunction]
    local procedure TryEval(Txt: Text; var DF: DateFormula)
    begin
        Evaluate(DF, Txt);
    end;

    local procedure Calc(Formula: Text): Text
    var
        Result: Date;
    begin
        ClearLastError();
        if TryCalc(Formula, 20240115D, Result) then
            exit('ok|' + Format(Result, 0, 9));
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Eval(Txt: Text): Text
    var
        DF: DateFormula;
    begin
        ClearLastError();
        if TryEval(Txt, DF) then
            exit('ok|' + Format(DF));
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P129_CalcDate_OneAngleBracket()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Txt: Text;
    begin
        Texts.Add('5D+<1D>');
        Texts.Add('<5D>+1D');
        Texts.Add('<5D>+<1D>');
        Texts.Add('<5D+1D');
        Texts.Add('5D+1D>');
        Texts.Add('<1D');
        Texts.Add('1D>');
        Texts.Add('<<1D>>');
        Texts.Add('<1D><1D>');
        Texts.Add('1D+<');
        Texts.Add('+<1D>');
        Texts.Add('-<1D>');
        Texts.Add('<-1D>');
        Texts.Add('5D<+1D>');
        Texts.Add('1M+<CM>');
        Texts.Add('<CM>+1D');
        Texts.Add('<>');
        Texts.Add('<');
        Texts.Add('>');
        Texts.Add('< 1D>');
        Texts.Add('<1D >');
        Texts.Add('5D+<1D>+2D');
        Texts.Add('<1D>>');
        Texts.Add('<<1D');
        foreach Txt in Texts do
            Observer.Observe('calc[' + Txt + ']', Calc(Txt));
        Observer.Expect('calc[5D+<1D>]', 'ok|2024-01-21');
        Observer.Expect('calc[<5D>+1D]', 'ok|2024-01-21');
        Observer.Expect('calc[<5D>+<1D>]', 'ok|2024-01-21');
        Observer.Expect('calc[<5D+1D]', 'ok|2024-01-21');
        Observer.Expect('calc[5D+1D>]', 'ok|2024-01-21');
        Observer.Expect('calc[<1D]', 'ok|2024-01-16');
        Observer.Expect('calc[1D>]', 'ok|2024-01-16');
        Observer.Expect('calc[<<1D>>]', 'ok|2024-01-16');
        Observer.Expect('calc[<1D><1D>]', 'err|The date formula ''1D><1D'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('calc[1D+<]', 'err|The date formula ''1D+<'' should include a number.|Evaluate');
        Observer.Expect('calc[+<1D>]', 'ok|2024-01-16');
        Observer.Expect('calc[-<1D>]', 'ok|2024-01-14');
        Observer.Expect('calc[<-1D>]', 'ok|2024-01-14');
        Observer.Expect('calc[5D<+1D>]', 'ok|2024-01-21');
        Observer.Expect('calc[1M+<CM>]', 'ok|2024-02-29');
        Observer.Expect('calc[<CM>+1D]', 'ok|2024-02-01');
        Observer.Expect('calc[<>]', 'ok|2024-01-15');
        Observer.Expect('calc[<]', 'ok|2024-01-15');
        Observer.Expect('calc[>]', 'ok|2024-01-15');
        Observer.Expect('calc[< 1D>]', 'ok|2024-01-16');
        Observer.Expect('calc[<1D >]', 'ok|2024-01-16');
        Observer.Expect('calc[5D+<1D>+2D]', 'ok|2024-01-23');
        Observer.Expect('calc[<1D>>]', 'ok|2024-01-16');
        Observer.Expect('calc[<<1D]', 'ok|2024-01-16');
        Observer.Verify();
    end;

    [Test]
    procedure P129_Evaluate_DateFormula_OneAngleBracket()
    var
        Observer: Codeunit "Probe Observer";
        Texts: List of [Text];
        Txt: Text;
    begin
        Texts.Add('5D+<1D>');
        Texts.Add('<5D>+1D');
        Texts.Add('<5D>+<1D>');
        Texts.Add('<5D+1D');
        Texts.Add('5D+1D>');
        Texts.Add('<<1D>>');
        Texts.Add('<1D><1D>');
        Texts.Add('1D+<');
        Texts.Add('+<1D>');
        Texts.Add('5D<+1D>');
        Texts.Add('<1D>>');
        Texts.Add('<<1D');
        foreach Txt in Texts do
            Observer.Observe('eval[' + Txt + ']', Eval(Txt));
        Observer.Expect('eval[5D+<1D>]', 'ok|5D+1D');
        Observer.Expect('eval[<5D>+1D]', 'ok|5D+1D');
        Observer.Expect('eval[<5D>+<1D>]', 'ok|5D+1D');
        Observer.Expect('eval[<5D+1D]', 'ok|5D+1D');
        Observer.Expect('eval[5D+1D>]', 'ok|5D+1D');
        Observer.Expect('eval[<<1D>>]', 'ok|1D');
        Observer.Expect('eval[<1D><1D>]', 'err|The date formula ''1D><1D'' must include plus (+) or minus (-).|Evaluate');
        Observer.Expect('eval[1D+<]', 'err|The date formula ''1D+<'' should include a number.|Evaluate');
        Observer.Expect('eval[+<1D>]', 'ok|+1D');
        Observer.Expect('eval[5D<+1D>]', 'ok|5D+1D');
        Observer.Expect('eval[<1D>>]', 'ok|1D');
        Observer.Expect('eval[<<1D]', 'ok|1D');
        Observer.Verify();
    end;
}
