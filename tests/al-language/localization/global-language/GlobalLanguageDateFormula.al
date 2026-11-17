// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-calcdate-method
// Scope: in-scope. Evaluate and Format of a DateFormula and CalcDate with a formula text, under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75403 (LT GL Date Formula)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts (identical on 27.5, 28.5 and 29.0):
//   - Evaluate(DateFormula, Text) reads the unit letters of the GlobalLanguage. Accepted here: 1033 D W M Q Y, CM CW CY, WD;
//     1030 D U M K Å, LM LU LÅ, UD; 1031 T W M Q J, LM LJ, WT; 1036 J S M T A; 1044 D U M K Å, UD (LM and CM refused);
//     1053 D V M K Å, LM LÅ. Any other letter returns false and leaves the variable unchanged.
//   - Format(DateFormula) shows the letters of the current language; Format(DF, 0, 9) shows the English letters.
//     Current-period prefix in Format: 1033 C, 1030 L, 1031 L, 1036 F, 1044 N, 1053 L.
//   - Evaluate(DF, Text, 9) reads the English letters in every language and refuses the local ones.
//   - CalcDate with a formula text in angle brackets reads English letters in every language: <1U>, <1K>, <1Å>, <1T>, <1J>, <1Z>
//     raise the localized "should include a time unit" error, which lists the English units (code Evaluate).
//   - CalcDate with a text without brackets reads the local letters: '1D' raises under 1031 and 1036, with the error listing the
//     local units (T,WT,W,M,Q oder J; J,JS,S,M,T ou A).
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
        Observer.Expect('1D', 'true|1D|1D');
        Observer.Expect('1W', 'true|1W|1W');
        Observer.Expect('1M', 'true|1M|1M');
        Observer.Expect('1Q', 'true|1Q|1Q');
        Observer.Expect('1Y', 'true|1Y|1Y');
        Observer.Expect('1U', 'false|1Y|1Y');
        Observer.Expect('1K', 'false|1Y|1Y');
        Observer.Expect('1Å', 'false|1Y|1Y');
        Observer.Expect('1T', 'false|1Y|1Y');
        Observer.Expect('1J', 'false|1Y|1Y');
        Observer.Expect('1S', 'false|1Y|1Y');
        Observer.Expect('1A', 'false|1Y|1Y');
        Observer.Expect('1V', 'false|1Y|1Y');
        Observer.Expect('1Ä', 'false|1Y|1Y');
        Observer.Expect('CM', 'true|CM|CM');
        Observer.Expect('LM', 'false|1Y|1Y');
        Observer.Expect('AM', 'false|1Y|1Y');
        Observer.Expect('CW', 'true|CW|CW');
        Observer.Expect('LU', 'false|1Y|1Y');
        Observer.Expect('CY', 'true|CY|CY');
        Observer.Expect('LÅ', 'false|1Y|1Y');
        Observer.Expect('LJ', 'false|1Y|1Y');
        Observer.Expect('WD1', 'true|WD1|WD1');
        Observer.Expect('UD1', 'false|1Y|1Y');
        Observer.Expect('WT1', 'false|1Y|1Y');
        Observer.Expect('-1D', 'true|-1D|-1D');
        Observer.Expect('1Y+1M', 'true|1Y+1M|1Y+1M');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Evaluate_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1030);
        Observer.Expect('1D', 'true|1D|1D');
        Observer.Expect('1W', 'false|1Y|1Å');
        Observer.Expect('1M', 'true|1M|1M');
        Observer.Expect('1Q', 'false|1Y|1Å');
        Observer.Expect('1Y', 'false|1Y|1Å');
        Observer.Expect('1U', 'true|1W|1U');
        Observer.Expect('1K', 'true|1Q|1K');
        Observer.Expect('1Å', 'true|1Y|1Å');
        Observer.Expect('1T', 'false|1Y|1Å');
        Observer.Expect('1J', 'false|1Y|1Å');
        Observer.Expect('1S', 'false|1Y|1Å');
        Observer.Expect('1A', 'false|1Y|1Å');
        Observer.Expect('1V', 'false|1Y|1Å');
        Observer.Expect('1Ä', 'false|1Y|1Å');
        Observer.Expect('CM', 'false|1Y|1Å');
        Observer.Expect('LM', 'true|CM|LM');
        Observer.Expect('AM', 'false|1Y|1Å');
        Observer.Expect('CW', 'false|1Y|1Å');
        Observer.Expect('LU', 'true|CW|LU');
        Observer.Expect('CY', 'false|1Y|1Å');
        Observer.Expect('LÅ', 'true|CY|LÅ');
        Observer.Expect('LJ', 'false|1Y|1Å');
        Observer.Expect('WD1', 'false|1Y|1Å');
        Observer.Expect('UD1', 'true|WD1|UD1');
        Observer.Expect('WT1', 'false|1Y|1Å');
        Observer.Expect('-1D', 'true|-1D|-1D');
        Observer.Expect('1Y+1M', 'false|1Y|1Å');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Evaluate_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1031);
        Observer.Expect('1D', 'false|1Y|1J');
        Observer.Expect('1W', 'true|1W|1W');
        Observer.Expect('1M', 'true|1M|1M');
        Observer.Expect('1Q', 'true|1Q|1Q');
        Observer.Expect('1Y', 'false|1Y|1J');
        Observer.Expect('1U', 'false|1Y|1J');
        Observer.Expect('1K', 'false|1Y|1J');
        Observer.Expect('1Å', 'false|1Y|1J');
        Observer.Expect('1T', 'true|1D|1T');
        Observer.Expect('1J', 'true|1Y|1J');
        Observer.Expect('1S', 'false|1Y|1J');
        Observer.Expect('1A', 'false|1Y|1J');
        Observer.Expect('1V', 'false|1Y|1J');
        Observer.Expect('1Ä', 'false|1Y|1J');
        Observer.Expect('CM', 'false|1Y|1J');
        Observer.Expect('LM', 'true|CM|LM');
        Observer.Expect('AM', 'false|1Y|1J');
        Observer.Expect('CW', 'false|1Y|1J');
        Observer.Expect('LU', 'false|1Y|1J');
        Observer.Expect('CY', 'false|1Y|1J');
        Observer.Expect('LÅ', 'false|1Y|1J');
        Observer.Expect('LJ', 'true|CY|LJ');
        Observer.Expect('WD1', 'false|1Y|1J');
        Observer.Expect('UD1', 'false|1Y|1J');
        Observer.Expect('WT1', 'true|WD1|WT1');
        Observer.Expect('-1D', 'false|1Y|1J');
        Observer.Expect('1Y+1M', 'false|1Y|1J');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Evaluate_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1036);
        Observer.Expect('1D', 'false|1Y|1A');
        Observer.Expect('1W', 'false|1Y|1A');
        Observer.Expect('1M', 'true|1M|1M');
        Observer.Expect('1Q', 'false|1Y|1A');
        Observer.Expect('1Y', 'false|1Y|1A');
        Observer.Expect('1U', 'false|1Y|1A');
        Observer.Expect('1K', 'false|1Y|1A');
        Observer.Expect('1Å', 'false|1Y|1A');
        Observer.Expect('1T', 'true|1Q|1T');
        Observer.Expect('1J', 'true|1D|1J');
        Observer.Expect('1S', 'true|1W|1S');
        Observer.Expect('1A', 'true|1Y|1A');
        Observer.Expect('1V', 'false|1Y|1A');
        Observer.Expect('1Ä', 'false|1Y|1A');
        Observer.Expect('CM', 'false|1Y|1A');
        Observer.Expect('LM', 'false|1Y|1A');
        Observer.Expect('AM', 'false|1Y|1A');
        Observer.Expect('CW', 'false|1Y|1A');
        Observer.Expect('LU', 'false|1Y|1A');
        Observer.Expect('CY', 'false|1Y|1A');
        Observer.Expect('LÅ', 'false|1Y|1A');
        Observer.Expect('LJ', 'false|1Y|1A');
        Observer.Expect('WD1', 'false|1Y|1A');
        Observer.Expect('UD1', 'false|1Y|1A');
        Observer.Expect('WT1', 'false|1Y|1A');
        Observer.Expect('-1D', 'false|1Y|1A');
        Observer.Expect('1Y+1M', 'false|1Y|1A');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Evaluate_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1044);
        Observer.Expect('1D', 'true|1D|1D');
        Observer.Expect('1W', 'false|1Y|1Å');
        Observer.Expect('1M', 'true|1M|1M');
        Observer.Expect('1Q', 'false|1Y|1Å');
        Observer.Expect('1Y', 'false|1Y|1Å');
        Observer.Expect('1U', 'true|1W|1U');
        Observer.Expect('1K', 'true|1Q|1K');
        Observer.Expect('1Å', 'true|1Y|1Å');
        Observer.Expect('1T', 'false|1Y|1Å');
        Observer.Expect('1J', 'false|1Y|1Å');
        Observer.Expect('1S', 'false|1Y|1Å');
        Observer.Expect('1A', 'false|1Y|1Å');
        Observer.Expect('1V', 'false|1Y|1Å');
        Observer.Expect('1Ä', 'false|1Y|1Å');
        Observer.Expect('CM', 'false|1Y|1Å');
        Observer.Expect('LM', 'false|1Y|1Å');
        Observer.Expect('AM', 'false|1Y|1Å');
        Observer.Expect('CW', 'false|1Y|1Å');
        Observer.Expect('LU', 'false|1Y|1Å');
        Observer.Expect('CY', 'false|1Y|1Å');
        Observer.Expect('LÅ', 'false|1Y|1Å');
        Observer.Expect('LJ', 'false|1Y|1Å');
        Observer.Expect('WD1', 'false|1Y|1Å');
        Observer.Expect('UD1', 'true|WD1|UD1');
        Observer.Expect('WT1', 'false|1Y|1Å');
        Observer.Expect('-1D', 'true|-1D|-1D');
        Observer.Expect('1Y+1M', 'false|1Y|1Å');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Evaluate_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateTexts(Observer, 1053);
        Observer.Expect('1D', 'true|1D|1D');
        Observer.Expect('1W', 'false|1Y|1Å');
        Observer.Expect('1M', 'true|1M|1M');
        Observer.Expect('1Q', 'false|1Y|1Å');
        Observer.Expect('1Y', 'false|1Y|1Å');
        Observer.Expect('1U', 'false|1Y|1Å');
        Observer.Expect('1K', 'true|1Q|1K');
        Observer.Expect('1Å', 'true|1Y|1Å');
        Observer.Expect('1T', 'false|1Y|1Å');
        Observer.Expect('1J', 'false|1Y|1Å');
        Observer.Expect('1S', 'false|1Y|1Å');
        Observer.Expect('1A', 'false|1Y|1Å');
        Observer.Expect('1V', 'true|1W|1V');
        Observer.Expect('1Ä', 'false|1Y|1Å');
        Observer.Expect('CM', 'false|1Y|1Å');
        Observer.Expect('LM', 'true|CM|LM');
        Observer.Expect('AM', 'false|1Y|1Å');
        Observer.Expect('CW', 'false|1Y|1Å');
        Observer.Expect('LU', 'false|1Y|1Å');
        Observer.Expect('CY', 'false|1Y|1Å');
        Observer.Expect('LÅ', 'true|CY|LÅ');
        Observer.Expect('LJ', 'false|1Y|1Å');
        Observer.Expect('WD1', 'false|1Y|1Å');
        Observer.Expect('UD1', 'false|1Y|1Å');
        Observer.Expect('WT1', 'false|1Y|1Å');
        Observer.Expect('-1D', 'true|-1D|-1D');
        Observer.Expect('1Y+1M', 'false|1Y|1Å');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1033);
        Observer.Expect('9:CM+1D', 'true|CM+1D|CM+1D');
        Observer.Expect('9:1Y+1M+1D', 'true|1Y+1M+1D|1Y+1M+1D');
        Observer.Expect('9:-CW', 'true|-CW|-CW');
        Observer.Expect('9:WD1', 'true|WD1|WD1');
        Observer.Expect('9:-1D', 'true|-1D|-1D');
        Observer.Expect('9:1M', 'true|1M|1M');
        Observer.Expect('9:1W', 'true|1W|1W');
        Observer.Expect('9:1Q', 'true|1Q|1Q');
        Observer.Expect('9:CQ+1Q', 'true|CQ+1Q|CQ+1Q');
        Observer.Expect('9:CY', 'true|CY|CY');
        Observer.Expect('9:<CD>', 'true|CD|CD');
        Observer.Expect('9:1U', 'false|1Y|1Y');
        Observer.Expect('9:1T', 'false|1Y|1Y');
        Observer.Expect('9:1Å', 'false|1Y|1Y');
        Observer.Expect('9:1J', 'false|1Y|1Y');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1030);
        Observer.Expect('9:CM+1D', 'true|LM+1D|CM+1D');
        Observer.Expect('9:1Y+1M+1D', 'true|1Å+1M+1D|1Y+1M+1D');
        Observer.Expect('9:-CW', 'true|-LU|-CW');
        Observer.Expect('9:WD1', 'true|UD1|WD1');
        Observer.Expect('9:-1D', 'true|-1D|-1D');
        Observer.Expect('9:1M', 'true|1M|1M');
        Observer.Expect('9:1W', 'true|1U|1W');
        Observer.Expect('9:1Q', 'true|1K|1Q');
        Observer.Expect('9:CQ+1Q', 'true|LK+1K|CQ+1Q');
        Observer.Expect('9:CY', 'true|LÅ|CY');
        Observer.Expect('9:<CD>', 'true|LD|CD');
        Observer.Expect('9:1U', 'false|1Å|1Y');
        Observer.Expect('9:1T', 'false|1Å|1Y');
        Observer.Expect('9:1Å', 'false|1Å|1Y');
        Observer.Expect('9:1J', 'false|1Å|1Y');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1031);
        Observer.Expect('9:CM+1D', 'true|LM+1T|CM+1D');
        Observer.Expect('9:1Y+1M+1D', 'true|1J+1M+1T|1Y+1M+1D');
        Observer.Expect('9:-CW', 'true|-LW|-CW');
        Observer.Expect('9:WD1', 'true|WT1|WD1');
        Observer.Expect('9:-1D', 'true|-1T|-1D');
        Observer.Expect('9:1M', 'true|1M|1M');
        Observer.Expect('9:1W', 'true|1W|1W');
        Observer.Expect('9:1Q', 'true|1Q|1Q');
        Observer.Expect('9:CQ+1Q', 'true|LQ+1Q|CQ+1Q');
        Observer.Expect('9:CY', 'true|LJ|CY');
        Observer.Expect('9:<CD>', 'true|LT|CD');
        Observer.Expect('9:1U', 'false|1J|1Y');
        Observer.Expect('9:1T', 'false|1J|1Y');
        Observer.Expect('9:1Å', 'false|1J|1Y');
        Observer.Expect('9:1J', 'false|1J|1Y');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1036);
        Observer.Expect('9:CM+1D', 'true|FM+1J|CM+1D');
        Observer.Expect('9:1Y+1M+1D', 'true|1A+1M+1J|1Y+1M+1D');
        Observer.Expect('9:-CW', 'true|-FS|-CW');
        Observer.Expect('9:WD1', 'true|JS1|WD1');
        Observer.Expect('9:-1D', 'true|-1J|-1D');
        Observer.Expect('9:1M', 'true|1M|1M');
        Observer.Expect('9:1W', 'true|1S|1W');
        Observer.Expect('9:1Q', 'true|1T|1Q');
        Observer.Expect('9:CQ+1Q', 'true|FT+1T|CQ+1Q');
        Observer.Expect('9:CY', 'true|FA|CY');
        Observer.Expect('9:<CD>', 'true|FJ|CD');
        Observer.Expect('9:1U', 'false|1A|1Y');
        Observer.Expect('9:1T', 'false|1A|1Y');
        Observer.Expect('9:1Å', 'false|1A|1Y');
        Observer.Expect('9:1J', 'false|1A|1Y');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1044);
        Observer.Expect('9:CM+1D', 'true|NM+1D|CM+1D');
        Observer.Expect('9:1Y+1M+1D', 'true|1Å+1M+1D|1Y+1M+1D');
        Observer.Expect('9:-CW', 'true|-NU|-CW');
        Observer.Expect('9:WD1', 'true|UD1|WD1');
        Observer.Expect('9:-1D', 'true|-1D|-1D');
        Observer.Expect('9:1M', 'true|1M|1M');
        Observer.Expect('9:1W', 'true|1U|1W');
        Observer.Expect('9:1Q', 'true|1K|1Q');
        Observer.Expect('9:CQ+1Q', 'true|NK+1K|CQ+1Q');
        Observer.Expect('9:CY', 'true|NÅ|CY');
        Observer.Expect('9:<CD>', 'true|ND|CD');
        Observer.Expect('9:1U', 'false|1Å|1Y');
        Observer.Expect('9:1T', 'false|1Å|1Y');
        Observer.Expect('9:1Å', 'false|1Å|1Y');
        Observer.Expect('9:1J', 'false|1Å|1Y');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_FormatAfterEvaluate9_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatAfterEvaluate9(Observer, 1053);
        Observer.Expect('9:CM+1D', 'true|LM+1D|CM+1D');
        Observer.Expect('9:1Y+1M+1D', 'true|1Å+1M+1D|1Y+1M+1D');
        Observer.Expect('9:-CW', 'true|-LV|-CW');
        Observer.Expect('9:WD1', 'true|VD1|WD1');
        Observer.Expect('9:-1D', 'true|-1D|-1D');
        Observer.Expect('9:1M', 'true|1M|1M');
        Observer.Expect('9:1W', 'true|1V|1W');
        Observer.Expect('9:1Q', 'true|1K|1Q');
        Observer.Expect('9:CQ+1Q', 'true|LK+1K|CQ+1Q');
        Observer.Expect('9:CY', 'true|LÅ|CY');
        Observer.Expect('9:<CD>', 'true|LD|CD');
        Observer.Expect('9:1U', 'false|1Å|1Y');
        Observer.Expect('9:1T', 'false|1Å|1Y');
        Observer.Expect('9:1Å', 'false|1Å|1Y');
        Observer.Expect('9:1J', 'false|1Å|1Y');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Units_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1033);
        Observer.Expect('CalcDate <1D> of 2024-03-15', '2024-03-16');
        Observer.Expect('CalcDate <1W> of 2024-03-15', '2024-03-22');
        Observer.Expect('CalcDate <1M> of 2024-03-15', '2024-04-15');
        Observer.Expect('CalcDate <1Q> of 2024-03-15', '2024-06-15');
        Observer.Expect('CalcDate <1Y> of 2024-03-15', '2025-03-15');
        Observer.Expect('CalcDate <CM> of 2024-03-15', '2024-03-31');
        Observer.Expect('CalcDate <WD1> of 2024-03-15', '2024-03-18');
        Observer.Expect('CalcDate <-1D> of 2024-03-15', '2024-03-14');
        Observer.Expect('CalcDate 1D of 2024-03-15', '2024-03-16');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Units_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1030);
        Observer.Expect('CalcDate <1D> of 2024-03-15', '2024-03-16');
        Observer.Expect('CalcDate <1W> of 2024-03-15', '2024-03-22');
        Observer.Expect('CalcDate <1M> of 2024-03-15', '2024-04-15');
        Observer.Expect('CalcDate <1Q> of 2024-03-15', '2024-06-15');
        Observer.Expect('CalcDate <1Y> of 2024-03-15', '2025-03-15');
        Observer.Expect('CalcDate <CM> of 2024-03-15', '2024-03-31');
        Observer.Expect('CalcDate <WD1> of 2024-03-15', '2024-03-18');
        Observer.Expect('CalcDate <-1D> of 2024-03-15', '2024-03-14');
        Observer.Expect('CalcDate 1D of 2024-03-15', '2024-03-16');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Units_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1031);
        Observer.Expect('CalcDate <1D> of 2024-03-15', '2024-03-16');
        Observer.Expect('CalcDate <1W> of 2024-03-15', '2024-03-22');
        Observer.Expect('CalcDate <1M> of 2024-03-15', '2024-04-15');
        Observer.Expect('CalcDate <1Q> of 2024-03-15', '2024-06-15');
        Observer.Expect('CalcDate <1Y> of 2024-03-15', '2025-03-15');
        Observer.Expect('CalcDate <CM> of 2024-03-15', '2024-03-31');
        Observer.Expect('CalcDate <WD1> of 2024-03-15', '2024-03-18');
        Observer.Expect('CalcDate <-1D> of 2024-03-15', '2024-03-14');
        Observer.Expect('CalcDate 1D of 2024-03-15', 'error:Die Datumsformel „1D“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: T,WT,W,M,Q oder J.\L, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Units_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1036);
        Observer.Expect('CalcDate <1D> of 2024-03-15', '2024-03-16');
        Observer.Expect('CalcDate <1W> of 2024-03-15', '2024-03-22');
        Observer.Expect('CalcDate <1M> of 2024-03-15', '2024-04-15');
        Observer.Expect('CalcDate <1Q> of 2024-03-15', '2024-06-15');
        Observer.Expect('CalcDate <1Y> of 2024-03-15', '2025-03-15');
        Observer.Expect('CalcDate <CM> of 2024-03-15', '2024-03-31');
        Observer.Expect('CalcDate <WD1> of 2024-03-15', '2024-03-18');
        Observer.Expect('CalcDate <-1D> of 2024-03-15', '2024-03-14');
        Observer.Expect('CalcDate 1D of 2024-03-15', 'error:La formule de date « 1D » devrait inclure une unité de temps.\\Les unités de temps peuvent être : J,JS,S,M,T ou A.\F, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Units_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1044);
        Observer.Expect('CalcDate <1D> of 2024-03-15', '2024-03-16');
        Observer.Expect('CalcDate <1W> of 2024-03-15', '2024-03-22');
        Observer.Expect('CalcDate <1M> of 2024-03-15', '2024-04-15');
        Observer.Expect('CalcDate <1Q> of 2024-03-15', '2024-06-15');
        Observer.Expect('CalcDate <1Y> of 2024-03-15', '2025-03-15');
        Observer.Expect('CalcDate <CM> of 2024-03-15', '2024-03-31');
        Observer.Expect('CalcDate <WD1> of 2024-03-15', '2024-03-18');
        Observer.Expect('CalcDate <-1D> of 2024-03-15', '2024-03-14');
        Observer.Expect('CalcDate 1D of 2024-03-15', '2024-03-16');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_Units_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesKnown(Observer, 1053);
        Observer.Expect('CalcDate <1D> of 2024-03-15', '2024-03-16');
        Observer.Expect('CalcDate <1W> of 2024-03-15', '2024-03-22');
        Observer.Expect('CalcDate <1M> of 2024-03-15', '2024-04-15');
        Observer.Expect('CalcDate <1Q> of 2024-03-15', '2024-06-15');
        Observer.Expect('CalcDate <1Y> of 2024-03-15', '2025-03-15');
        Observer.Expect('CalcDate <CM> of 2024-03-15', '2024-03-31');
        Observer.Expect('CalcDate <WD1> of 2024-03-15', '2024-03-18');
        Observer.Expect('CalcDate <-1D> of 2024-03-15', '2024-03-14');
        Observer.Expect('CalcDate 1D of 2024-03-15', '2024-03-16');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1033);
        Observer.Expect('CalcDate <1U> of 2024-03-15', 'error:The date formula ''1U'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('CalcDate <1K> of 2024-03-15', 'error:The date formula ''1K'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('CalcDate <1Å> of 2024-03-15', 'error:The date formula ''1Å'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1030);
        Observer.Expect('CalcDate <1U> of 2024-03-15', 'error:Der skal indgå en tidsenhed i datoformlen ''1U''.\\Tidsenheder kan være: D,WD,W,M,Q eller Y.\C betyder den aktuelle tidsenhed baseret på dato, kan specificeres som et præfiks for tidsenheden.|Evaluate');
        Observer.Expect('CalcDate <1K> of 2024-03-15', 'error:Der skal indgå en tidsenhed i datoformlen ''1K''.\\Tidsenheder kan være: D,WD,W,M,Q eller Y.\C betyder den aktuelle tidsenhed baseret på dato, kan specificeres som et præfiks for tidsenheden.|Evaluate');
        Observer.Expect('CalcDate <1Å> of 2024-03-15', 'error:Der skal indgå en tidsenhed i datoformlen ''1Å''.\\Tidsenheder kan være: D,WD,W,M,Q eller Y.\C betyder den aktuelle tidsenhed baseret på dato, kan specificeres som et præfiks for tidsenheden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1031);
        Observer.Expect('CalcDate <1U> of 2024-03-15', 'error:Die Datumsformel „1U“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: D,WD,W,M,Q oder Y.\C, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Expect('CalcDate <1K> of 2024-03-15', 'error:Die Datumsformel „1K“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: D,WD,W,M,Q oder Y.\C, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Expect('CalcDate <1Å> of 2024-03-15', 'error:Die Datumsformel „1Å“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: D,WD,W,M,Q oder Y.\C, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1036);
        Observer.Expect('CalcDate <1U> of 2024-03-15', 'error:La formule de date « 1U » devrait inclure une unité de temps.\\Les unités de temps peuvent être : D,WD,W,M,Q ou Y.\C, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Expect('CalcDate <1K> of 2024-03-15', 'error:La formule de date « 1K » devrait inclure une unité de temps.\\Les unités de temps peuvent être : D,WD,W,M,Q ou Y.\C, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Expect('CalcDate <1Å> of 2024-03-15', 'error:La formule de date « 1Å » devrait inclure une unité de temps.\\Les unités de temps peuvent être : D,WD,W,M,Q ou Y.\C, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1044);
        Observer.Expect('CalcDate <1U> of 2024-03-15', 'error:Datoformelen 1U må inneholde en tidsenhet.\\Tidsenheter kan være: D,WD,W,M,Q eller Y.\C, som betyr nåværende tidsenhet basert på dato, kan angis som et prefiks til tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1K> of 2024-03-15', 'error:Datoformelen 1K må inneholde en tidsenhet.\\Tidsenheter kan være: D,WD,W,M,Q eller Y.\C, som betyr nåværende tidsenhet basert på dato, kan angis som et prefiks til tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1Å> of 2024-03-15', 'error:Datoformelen 1Å må inneholde en tidsenhet.\\Tidsenheter kan være: D,WD,W,M,Q eller Y.\C, som betyr nåværende tidsenhet basert på dato, kan angis som et prefiks til tidsenheten.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters1_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters1(Observer, 1053);
        Observer.Expect('CalcDate <1U> of 2024-03-15', 'error:Datumformeln ''1U'' ska inkludera en tidsenhet.\\Tidsenheter kan vara: D,WD,W,M,Q eller Y.\C, avser aktuell tidsenhet baserad på datum och kan anges som ett prefix till tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1K> of 2024-03-15', 'error:Datumformeln ''1K'' ska inkludera en tidsenhet.\\Tidsenheter kan vara: D,WD,W,M,Q eller Y.\C, avser aktuell tidsenhet baserad på datum och kan anges som ett prefix till tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1Å> of 2024-03-15', 'error:Datumformeln ''1Å'' ska inkludera en tidsenhet.\\Tidsenheter kan vara: D,WD,W,M,Q eller Y.\C, avser aktuell tidsenhet baserad på datum och kan anges som ett prefix till tidsenheten.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1033);
        Observer.Expect('CalcDate <1T> of 2024-03-15', 'error:The date formula ''1T'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('CalcDate <1J> of 2024-03-15', 'error:The date formula ''1J'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Expect('CalcDate <1Z> of 2024-03-15', 'error:The date formula ''1Z'' should include a time unit.\\Time units can be: D,WD,W,M,Q, or Y.\C, meaning current time unit based on date, can be specified as a prefix to the time unit.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1030);
        Observer.Expect('CalcDate <1T> of 2024-03-15', 'error:Der skal indgå en tidsenhed i datoformlen ''1T''.\\Tidsenheder kan være: D,WD,W,M,Q eller Y.\C betyder den aktuelle tidsenhed baseret på dato, kan specificeres som et præfiks for tidsenheden.|Evaluate');
        Observer.Expect('CalcDate <1J> of 2024-03-15', 'error:Der skal indgå en tidsenhed i datoformlen ''1J''.\\Tidsenheder kan være: D,WD,W,M,Q eller Y.\C betyder den aktuelle tidsenhed baseret på dato, kan specificeres som et præfiks for tidsenheden.|Evaluate');
        Observer.Expect('CalcDate <1Z> of 2024-03-15', 'error:Der skal indgå en tidsenhed i datoformlen ''1Z''.\\Tidsenheder kan være: D,WD,W,M,Q eller Y.\C betyder den aktuelle tidsenhed baseret på dato, kan specificeres som et præfiks for tidsenheden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1031);
        Observer.Expect('CalcDate <1T> of 2024-03-15', 'error:Die Datumsformel „1T“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: D,WD,W,M,Q oder Y.\C, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Expect('CalcDate <1J> of 2024-03-15', 'error:Die Datumsformel „1J“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: D,WD,W,M,Q oder Y.\C, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Expect('CalcDate <1Z> of 2024-03-15', 'error:Die Datumsformel „1Z“ muss eine Zeiteinheit enthalten.\\Mögliche Zeiteinheiten: D,WD,W,M,Q oder Y.\C, die laufende Zeiteinheit basierend auf dem Datum, kann als Präfix der Zeiteinheit angegeben werden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1036);
        Observer.Expect('CalcDate <1T> of 2024-03-15', 'error:La formule de date « 1T » devrait inclure une unité de temps.\\Les unités de temps peuvent être : D,WD,W,M,Q ou Y.\C, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Expect('CalcDate <1J> of 2024-03-15', 'error:La formule de date « 1J » devrait inclure une unité de temps.\\Les unités de temps peuvent être : D,WD,W,M,Q ou Y.\C, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Expect('CalcDate <1Z> of 2024-03-15', 'error:La formule de date « 1Z » devrait inclure une unité de temps.\\Les unités de temps peuvent être : D,WD,W,M,Q ou Y.\C, signifiant unité de temps actuelle basée sur la date, peut être spécifié comme préfixe de l’unité de temps.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1044);
        Observer.Expect('CalcDate <1T> of 2024-03-15', 'error:Datoformelen 1T må inneholde en tidsenhet.\\Tidsenheter kan være: D,WD,W,M,Q eller Y.\C, som betyr nåværende tidsenhet basert på dato, kan angis som et prefiks til tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1J> of 2024-03-15', 'error:Datoformelen 1J må inneholde en tidsenhet.\\Tidsenheter kan være: D,WD,W,M,Q eller Y.\C, som betyr nåværende tidsenhet basert på dato, kan angis som et prefiks til tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1Z> of 2024-03-15', 'error:Datoformelen 1Z må inneholde en tidsenhet.\\Tidsenheter kan være: D,WD,W,M,Q eller Y.\C, som betyr nåværende tidsenhet basert på dato, kan angis som et prefiks til tidsenheten.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure CalcDate_LocalLetters2_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        CalcDatesLetters2(Observer, 1053);
        Observer.Expect('CalcDate <1T> of 2024-03-15', 'error:Datumformeln ''1T'' ska inkludera en tidsenhet.\\Tidsenheter kan vara: D,WD,W,M,Q eller Y.\C, avser aktuell tidsenhet baserad på datum och kan anges som ett prefix till tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1J> of 2024-03-15', 'error:Datumformeln ''1J'' ska inkludera en tidsenhet.\\Tidsenheter kan vara: D,WD,W,M,Q eller Y.\C, avser aktuell tidsenhet baserad på datum och kan anges som ett prefix till tidsenheten.|Evaluate');
        Observer.Expect('CalcDate <1Z> of 2024-03-15', 'error:Datumformeln ''1Z'' ska inkludera en tidsenhet.\\Tidsenheter kan vara: D,WD,W,M,Q eller Y.\C, avser aktuell tidsenhet baserad på datum och kan anges som ett prefix till tidsenheten.|Evaluate');
        Observer.Verify();
    end;
}
