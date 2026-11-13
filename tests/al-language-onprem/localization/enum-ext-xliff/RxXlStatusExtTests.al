// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-work-with-translation-files
// Scope: in-scope
// Fixtures used: Probe Observer (69160); enum RX Xl Status (80030) of the corpus app with its nl-NL units in
//   tests/al-language/Translations/AL Language Coverage Tests.nl-NL.xlf; this app's own file
//   Translations/AL Language Coverage Tests (OnPrem).nl-NL.xlf with the EnumExtension unit of value Extra (ExtPlain has no unit).
// Probe (al-runner issue 6924): enum value captions under GlobalLanguage 1043 (nl-NL), 2067 (nl-BE, no file of its own) and 1033 when
//   the enum's own app ships a translation file and another app extends the enum and ships its own file: Format of a base value with a
//   unit, a base value without a unit, an extension value with a unit (from the EnumExtension's own file) and one without; Evaluate of
//   the enum from the translated captions, the English captions, a value name and an ordinal.
// Lives in the OnPrem app only because it must be a second app that depends on the corpus app (no OnPrem scope is used).
// BC versions: 27 - 29

enumextension 98980 "RX Xl Status Ext" extends "RX Xl Status"
{
    value(10; Extra)
    {
        Caption = 'Extra EN';
    }
    value(11; ExtPlain)
    {
        Caption = 'ExtPlain EN';
    }
}

codeunit 98981 "RX Xl Status Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure FormatFacts(var Observer: Codeunit "Probe Observer"; Language: Integer)
    var
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(Language);
        Observer.Observe('Draft (base, unit)', Format(Enum::"RX Xl Status"::Draft));
        Observer.Observe('Ready (base, unit)', Format(Enum::"RX Xl Status"::Ready));
        Observer.Observe('Plain (base, no unit)', Format(Enum::"RX Xl Status"::Plain));
        Observer.Observe('Extra (extension, unit)', Format(Enum::"RX Xl Status"::Extra));
        Observer.Observe('ExtPlain (extension, no unit)', Format(Enum::"RX Xl Status"::ExtPlain));
        GlobalLanguage(Saved);
    end;

    local procedure EvalFact(var Observer: Codeunit "Probe Observer"; Input: Text)
    var
        Value: Enum "RX Xl Status";
        Ok: Boolean;
    begin
        Value := Enum::"RX Xl Status"::Plain;
        Ok := Evaluate(Value, Input);
        Observer.Observe('Evaluate ' + Input, Format(Ok) + ' ' + Format(Value.AsInteger()));
    end;

    local procedure EvaluateFacts(var Observer: Codeunit "Probe Observer"; Language: Integer)
    var
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(Language);
        EvalFact(Observer, 'Concept NL');
        EvalFact(Observer, 'Gereed NL');
        EvalFact(Observer, 'Extra NL');
        EvalFact(Observer, 'Draft EN');
        EvalFact(Observer, 'Extra EN');
        EvalFact(Observer, 'ExtPlain EN');
        EvalFact(Observer, 'Ready');
        EvalFact(Observer, 'Extra');
        EvalFact(Observer, '10');
        GlobalLanguage(Saved);
    end;

    [Test]
    procedure Format_Dutch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatFacts(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Belgian()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatFacts(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure Format_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        FormatFacts(Observer, 1033);
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_Dutch()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateFacts(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure Evaluate_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        EvaluateFacts(Observer, 1033);
        Observer.Finish();
    end;
}
