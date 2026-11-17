// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope. Evaluate and Format of a DateFormula and CalcDate with a formula text, under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75403 (LT GL Date Formula)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
// BC versions: 27, 28, 29

codeunit 75403 "LT GL Date Formula"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEvaluate(var DF: DateFormula; Txt: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(DF, Txt);
    end;

    [TryFunction]
    local procedure TryEvaluate9(var DF: DateFormula; Txt: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(DF, Txt, 9);
    end;

    [TryFunction]
    local procedure TryCalcDate(Txt: Text; var D: Date)
    begin
        D := CalcDate(Txt, DMY2Date(15, 3, 2024));
    end;

    // ok flag | Format(DF, 0, 9) | Format(DF); the variable held <1Y> before the Evaluate
    local procedure Eval(Prior: DateFormula; Txt: Text): Text
    var
        DF: DateFormula;
        Ok: Boolean;
    begin
        DF := Prior;
        ClearLastError();
        if not TryEvaluate(DF, Txt, Ok) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Format(Ok, 0, 9) + '|' + Format(DF, 0, 9) + '|' + Format(DF));
    end;

    // ok flag | Format(DF) | Format(DF, 0, 9) after Evaluate(DF, text, 9)
    local procedure Eval9(Prior: DateFormula; Txt: Text): Text
    var
        DF: DateFormula;
        Ok: Boolean;
    begin
        DF := Prior;
        ClearLastError();
        if not TryEvaluate9(DF, Txt, Ok) then
            exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Format(Ok, 0, 9) + '|' + Format(DF) + '|' + Format(DF, 0, 9));
    end;

    local procedure Calc(Txt: Text): Text
    var
        D: Date;
    begin
        ClearLastError();
        if TryCalcDate(Txt, D) then
            exit(Format(D, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Prior(): DateFormula
    var
        DF: DateFormula;
    begin
        Evaluate(DF, '<1Y>');
        exit(DF);
    end;

    local procedure EvaluateTexts(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Texts: List of [Text];
        Results: List of [Text];
        P: DateFormula;
        T: Text;
        I: Integer;
    begin
        P := Prior();
        Texts.AddRange('1D', '1W', '1M', '1Q', '1Y', '1U', '1K', '1Å', '1T', '1J', '1S', '1A', '1V', '1Ä');
        Texts.AddRange('CM', 'LM', 'AM', 'CW', 'LU', 'CY', 'LÅ', 'LJ', 'WD1', 'UD1', 'WT1', '-1D', '1Y+1M');
        GlobalLanguage(Lang);
        foreach T in Texts do
            Results.Add(Eval(P, T));
        GlobalLanguage(1033);
        for I := 1 to Texts.Count() do
            Observer.Observe(Texts.Get(I), Results.Get(I));
    end;

    local procedure FormatAfterEvaluate9(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Texts: List of [Text];
        Results: List of [Text];
        P: DateFormula;
        T: Text;
        I: Integer;
    begin
        P := Prior();
        Texts.AddRange('CM+1D', '1Y+1M+1D', '-CW', 'WD1', '-1D', '1M', '1W', '1Q', 'CQ+1Q', 'CY', '<CD>', '1U', '1T', '1Å', '1J');
        GlobalLanguage(Lang);
        foreach T in Texts do
            Results.Add(Eval9(P, T));
        GlobalLanguage(1033);
        for I := 1 to Texts.Count() do
            Observer.Observe('9:' + Texts.Get(I), Results.Get(I));
    end;

    local procedure CalcDates(var Observer: Codeunit "Probe Observer"; Lang: Integer; Texts: List of [Text])
    var
        Results: List of [Text];
        T: Text;
        I: Integer;
    begin
        GlobalLanguage(Lang);
        foreach T in Texts do
            Results.Add(Calc(T));
        GlobalLanguage(1033);
        for I := 1 to Texts.Count() do
            Observer.Observe('CalcDate ' + Texts.Get(I) + ' of 2024-03-15', Results.Get(I));
    end;

    local procedure CalcDatesKnown(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Texts: List of [Text];
    begin
        Texts.AddRange('<1D>', '<1W>', '<1M>', '<1Q>', '<1Y>', '<CM>', '<WD1>', '<-1D>', '1D');
        CalcDates(Observer, Lang, Texts);
    end;

    local procedure CalcDatesLetters1(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Texts: List of [Text];
    begin
        Texts.AddRange('<1U>', '<1K>', '<1Å>');
        CalcDates(Observer, Lang, Texts);
    end;

    local procedure CalcDatesLetters2(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Texts: List of [Text];
    begin
        Texts.AddRange('<1T>', '<1J>', '<1Z>');
        CalcDates(Observer, Lang, Texts);
    end;

    [Test]
    procedure DateFormula_Evaluate_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_Evaluate_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_Evaluate_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_Evaluate_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_Evaluate_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_Evaluate_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_Units_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_Units_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_Units_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_Units_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_Units_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_Units_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1053);
        Observer.Finish();
    end;
}
