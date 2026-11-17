// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Scope: in-scope. Format and Evaluate of a Boolean under GlobalLanguage 1033, 1030, 1031, 1036, 1044 and 1053.
// Fixtures used: Probe Observer (codeunit 69160); own objects 75400 (LT GL Boolean Words)
// Probe: from al-runner issues 8178, 8182, 8183, 8197, 8199 and 8200 (an outside reporter measured BC 28.4 W1, en-US region). Observed on
//   Windows BC containers 27.5, 28.5 and 29.0; every literal asserted below is what BC produced. The corpus CI matrix checks it on BC on Linux.
// Facts: TODO
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
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_Danish1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_German1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1031);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_French1036()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1036);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_Norwegian1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure Boolean_FormatEvaluate_Swedish1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1053);
        Observer.Finish();
    end;
}
