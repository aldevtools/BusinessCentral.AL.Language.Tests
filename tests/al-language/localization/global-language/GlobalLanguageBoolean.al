// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope. Format and Evaluate of a Boolean under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75400 (LT GL Boolean Words)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts (identical on 27.5, 28.5 and 29.0):
//   - Format(Boolean), std 0 and std 1 give the words of the GlobalLanguage: 1033 Yes/No, 1030 Ja/Nej, 1031 Ja/Nein, 1036 Oui/Non,
//     1044 Ja/Nei, 1053 Ja/Nej. Std 2 gives 1/0 and std 9 true/false in every language. Format(B, 6) pads on the right.
//   - Evaluate(Boolean, Text) accepts the words of the current language in any case, plus true/false and 1/0 in every language.
//     Words of another language and the empty text return false and leave the variable unchanged.
//   - One exception: under 1036 Evaluate also accepts No (gives false), while Yes is refused.
//   - Evaluate without a return value raises the localized "The value "Maybe" can't be evaluated into type Boolean." with code Evaluate.
// BC versions: 27, 28, 29

codeunit 75400 "LT GL Boolean Words"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEvaluate(var B: Boolean; Word: Text; var Ok: Boolean)
    begin
        Ok := Evaluate(B, Word);
    end;

    [TryFunction]
    local procedure TryEvaluateRaise(var B: Boolean; Word: Text)
    begin
        Evaluate(B, Word);
    end;

    [TryFunction]
    local procedure TryFormatStd(B: Boolean; Std: Integer; var Txt: Text)
    begin
        Txt := Format(B, 0, Std);
    end;

    // ok flag | value after Evaluate when the variable held false | value after Evaluate when it held true
    local procedure EvalWord(Word: Text): Text
    var
        B: Boolean;
        Ok: Boolean;
        Result: Text;
    begin
        B := false;
        ClearLastError();
        if not TryEvaluate(B, Word, Ok) then
            exit('error:' + GetLastErrorText());
        Result := Format(Ok, 0, 9) + '|' + Format(B, 0, 9);
        B := true;
        if not TryEvaluate(B, Word, Ok) then
            exit('error:' + GetLastErrorText());
        exit(Result + '|' + Format(B, 0, 9));
    end;

    local procedure Std(B: Boolean; N: Integer): Text
    var
        Txt: Text;
    begin
        ClearLastError();
        if TryFormatStd(B, N, Txt) then
            exit('[' + Txt + ']');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Lang: Integer)
    var
        Words: List of [Text];
        Results: List of [Text];
        W: Text;
        Formats: Text;
        Standards: Text;
        RaiseText: Text;
        B: Boolean;
        i: Integer;
    begin
        Words.AddRange('Ja', 'ja', 'JA', 'Nej', 'Nei', 'Nein', 'Yes', 'No', 'yes', 'Oui', 'Non', 'Sand', 'Falsk', 'true', 'False', '1', '0', '');
        GlobalLanguage(Lang);
        foreach W in Words do
            Results.Add(EvalWord(W));
        Formats := '[' + Format(true) + '][' + Format(false) + '][' + Format(true, 6) + '][' + Format(false, -6) + ']';
        Standards := Std(true, 0) + Std(false, 0) + Std(true, 1) + Std(false, 1) + Std(true, 2) + Std(false, 2) + Std(true, 9) + Std(false, 9);
        ClearLastError();
        if TryEvaluateRaise(B, 'Maybe') then
            RaiseText := 'no error'
        else
            RaiseText := GetLastErrorText() + '|' + GetLastErrorCode();
        GlobalLanguage(1033);
        Observer.Observe('Format true, false, (true, 6), (false, -6)', Formats);
        Observer.Observe('Format std 0, 1, 2, 9 of true and false', Standards);
        for i := 1 to Words.Count() do
            Observer.Observe('Evaluate [' + Words.Get(i) + ']', Results.Get(i));
        Observer.Observe('Evaluate Maybe without return value', RaiseText);
    end;

    [Test]
    procedure Boolean_FormatEvaluate_English1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1033);
        Observer.Expect('Format true, false, (true, 6), (false, -6)', '[Yes][No][Yes   ][No]');
        Observer.Expect('Format std 0, 1, 2, 9 of true and false', '[Yes][No][Yes][No][1][0][true][false]');
        Observer.Expect('Evaluate [Ja]', 'false|false|true');
        Observer.Expect('Evaluate [ja]', 'false|false|true');
        Observer.Expect('Evaluate [JA]', 'false|false|true');
        Observer.Expect('Evaluate [Nej]', 'false|false|true');
        Observer.Expect('Evaluate [Nei]', 'false|false|true');
        Observer.Expect('Evaluate [Nein]', 'false|false|true');
        Observer.Expect('Evaluate [Yes]', 'true|true|true');
        Observer.Expect('Evaluate [No]', 'true|false|false');
        Observer.Expect('Evaluate [yes]', 'true|true|true');
        Observer.Expect('Evaluate [Oui]', 'false|false|true');
        Observer.Expect('Evaluate [Non]', 'false|false|true');
        Observer.Expect('Evaluate [Sand]', 'false|false|true');
        Observer.Expect('Evaluate [Falsk]', 'false|false|true');
        Observer.Expect('Evaluate [true]', 'true|true|true');
        Observer.Expect('Evaluate [False]', 'true|false|false');
        Observer.Expect('Evaluate [1]', 'true|true|true');
        Observer.Expect('Evaluate [0]', 'true|false|false');
        Observer.Expect('Evaluate []', 'false|false|true');
        Observer.Expect('Evaluate Maybe without return value', 'The value "Maybe" can''t be evaluated into type Boolean.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1030);
        Observer.Expect('Format true, false, (true, 6), (false, -6)', '[Ja][Nej][Ja    ][Nej]');
        Observer.Expect('Format std 0, 1, 2, 9 of true and false', '[Ja][Nej][Ja][Nej][1][0][true][false]');
        Observer.Expect('Evaluate [Ja]', 'true|true|true');
        Observer.Expect('Evaluate [ja]', 'true|true|true');
        Observer.Expect('Evaluate [JA]', 'true|true|true');
        Observer.Expect('Evaluate [Nej]', 'true|false|false');
        Observer.Expect('Evaluate [Nei]', 'false|false|true');
        Observer.Expect('Evaluate [Nein]', 'false|false|true');
        Observer.Expect('Evaluate [Yes]', 'false|false|true');
        Observer.Expect('Evaluate [No]', 'false|false|true');
        Observer.Expect('Evaluate [yes]', 'false|false|true');
        Observer.Expect('Evaluate [Oui]', 'false|false|true');
        Observer.Expect('Evaluate [Non]', 'false|false|true');
        Observer.Expect('Evaluate [Sand]', 'false|false|true');
        Observer.Expect('Evaluate [Falsk]', 'false|false|true');
        Observer.Expect('Evaluate [true]', 'true|true|true');
        Observer.Expect('Evaluate [False]', 'true|false|false');
        Observer.Expect('Evaluate [1]', 'true|true|true');
        Observer.Expect('Evaluate [0]', 'true|false|false');
        Observer.Expect('Evaluate []', 'false|false|true');
        Observer.Expect('Evaluate Maybe without return value', 'Værdien "Maybe" kan ikke evalueres til typen Boolean.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1031);
        Observer.Expect('Format true, false, (true, 6), (false, -6)', '[Ja][Nein][Ja    ][Nein]');
        Observer.Expect('Format std 0, 1, 2, 9 of true and false', '[Ja][Nein][Ja][Nein][1][0][true][false]');
        Observer.Expect('Evaluate [Ja]', 'true|true|true');
        Observer.Expect('Evaluate [ja]', 'true|true|true');
        Observer.Expect('Evaluate [JA]', 'true|true|true');
        Observer.Expect('Evaluate [Nej]', 'false|false|true');
        Observer.Expect('Evaluate [Nei]', 'true|false|false');
        Observer.Expect('Evaluate [Nein]', 'true|false|false');
        Observer.Expect('Evaluate [Yes]', 'false|false|true');
        Observer.Expect('Evaluate [No]', 'false|false|true');
        Observer.Expect('Evaluate [yes]', 'false|false|true');
        Observer.Expect('Evaluate [Oui]', 'false|false|true');
        Observer.Expect('Evaluate [Non]', 'false|false|true');
        Observer.Expect('Evaluate [Sand]', 'false|false|true');
        Observer.Expect('Evaluate [Falsk]', 'false|false|true');
        Observer.Expect('Evaluate [true]', 'true|true|true');
        Observer.Expect('Evaluate [False]', 'true|false|false');
        Observer.Expect('Evaluate [1]', 'true|true|true');
        Observer.Expect('Evaluate [0]', 'true|false|false');
        Observer.Expect('Evaluate []', 'false|false|true');
        Observer.Expect('Evaluate Maybe without return value', 'Der Wert „Maybe“ kann nicht in Typ Boolean ausgewertet werden.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1036);
        Observer.Expect('Format true, false, (true, 6), (false, -6)', '[Oui][Non][Oui   ][Non]');
        Observer.Expect('Format std 0, 1, 2, 9 of true and false', '[Oui][Non][Oui][Non][1][0][true][false]');
        Observer.Expect('Evaluate [Ja]', 'false|false|true');
        Observer.Expect('Evaluate [ja]', 'false|false|true');
        Observer.Expect('Evaluate [JA]', 'false|false|true');
        Observer.Expect('Evaluate [Nej]', 'false|false|true');
        Observer.Expect('Evaluate [Nei]', 'false|false|true');
        Observer.Expect('Evaluate [Nein]', 'false|false|true');
        Observer.Expect('Evaluate [Yes]', 'false|false|true');
        Observer.Expect('Evaluate [No]', 'true|false|false');
        Observer.Expect('Evaluate [yes]', 'false|false|true');
        Observer.Expect('Evaluate [Oui]', 'true|true|true');
        Observer.Expect('Evaluate [Non]', 'true|false|false');
        Observer.Expect('Evaluate [Sand]', 'false|false|true');
        Observer.Expect('Evaluate [Falsk]', 'false|false|true');
        Observer.Expect('Evaluate [true]', 'true|true|true');
        Observer.Expect('Evaluate [False]', 'true|false|false');
        Observer.Expect('Evaluate [1]', 'true|true|true');
        Observer.Expect('Evaluate [0]', 'true|false|false');
        Observer.Expect('Evaluate []', 'false|false|true');
        Observer.Expect('Evaluate Maybe without return value', 'La valeur « Maybe » ne peut pas être évaluée en type Boolean.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1044);
        Observer.Expect('Format true, false, (true, 6), (false, -6)', '[Ja][Nei][Ja    ][Nei]');
        Observer.Expect('Format std 0, 1, 2, 9 of true and false', '[Ja][Nei][Ja][Nei][1][0][true][false]');
        Observer.Expect('Evaluate [Ja]', 'true|true|true');
        Observer.Expect('Evaluate [ja]', 'true|true|true');
        Observer.Expect('Evaluate [JA]', 'true|true|true');
        Observer.Expect('Evaluate [Nej]', 'false|false|true');
        Observer.Expect('Evaluate [Nei]', 'true|false|false');
        Observer.Expect('Evaluate [Nein]', 'false|false|true');
        Observer.Expect('Evaluate [Yes]', 'false|false|true');
        Observer.Expect('Evaluate [No]', 'false|false|true');
        Observer.Expect('Evaluate [yes]', 'false|false|true');
        Observer.Expect('Evaluate [Oui]', 'false|false|true');
        Observer.Expect('Evaluate [Non]', 'false|false|true');
        Observer.Expect('Evaluate [Sand]', 'false|false|true');
        Observer.Expect('Evaluate [Falsk]', 'false|false|true');
        Observer.Expect('Evaluate [true]', 'true|true|true');
        Observer.Expect('Evaluate [False]', 'true|false|false');
        Observer.Expect('Evaluate [1]', 'true|true|true');
        Observer.Expect('Evaluate [0]', 'true|false|false');
        Observer.Expect('Evaluate []', 'false|false|true');
        Observer.Expect('Evaluate Maybe without return value', 'Verdien Maybe kan ikke evalueres til typen Boolean.|Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1053);
        Observer.Expect('Format true, false, (true, 6), (false, -6)', '[Ja][Nej][Ja    ][Nej]');
        Observer.Expect('Format std 0, 1, 2, 9 of true and false', '[Ja][Nej][Ja][Nej][1][0][true][false]');
        Observer.Expect('Evaluate [Ja]', 'true|true|true');
        Observer.Expect('Evaluate [ja]', 'true|true|true');
        Observer.Expect('Evaluate [JA]', 'true|true|true');
        Observer.Expect('Evaluate [Nej]', 'true|false|false');
        Observer.Expect('Evaluate [Nei]', 'false|false|true');
        Observer.Expect('Evaluate [Nein]', 'false|false|true');
        Observer.Expect('Evaluate [Yes]', 'false|false|true');
        Observer.Expect('Evaluate [No]', 'false|false|true');
        Observer.Expect('Evaluate [yes]', 'false|false|true');
        Observer.Expect('Evaluate [Oui]', 'false|false|true');
        Observer.Expect('Evaluate [Non]', 'false|false|true');
        Observer.Expect('Evaluate [Sand]', 'false|false|true');
        Observer.Expect('Evaluate [Falsk]', 'false|false|true');
        Observer.Expect('Evaluate [true]', 'true|true|true');
        Observer.Expect('Evaluate [False]', 'true|false|false');
        Observer.Expect('Evaluate [1]', 'true|true|true');
        Observer.Expect('Evaluate [0]', 'true|false|false');
        Observer.Expect('Evaluate []', 'false|false|true');
        Observer.Expect('Evaluate Maybe without return value', 'Det går inte att utvärdera värdet Maybe till typen Boolean.|Evaluate');
        Observer.Verify();
    end;
}
