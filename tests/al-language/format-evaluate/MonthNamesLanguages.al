// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: month names of the standard formats 4 and 7 under GlobalLanguage for languages that format-evaluate/AxLanguageFormats.al
//   (1033, 1031, 1036, 3082) and EvalLanguageBoolean.al (December only, 1030, 1043, 2067) do not cover.
// Facts: Format(DMY2Date(5, m, 2026), 0, 4) and Format(DMY2Date(5, m, 2026), 0, 7) for every month 1 to 12, and both formats for
//   15 March 2026, with GlobalLanguage set to 2067, 1043, 1030, 2060, 1044, 1053, 1035, 2055, 3079 and 4108; whether setting the
//   language raises an error. Each test sets GlobalLanguage back before it records its values. The full text is asserted.
// BC versions: 27 - 29

codeunit 76404 "LT Month Names Languages"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySetLanguage(Language: Integer)
    begin
        GlobalLanguage(Language);
    end;

    local procedure Run(var Observer: Codeunit "Probe Observer"; Language: Integer)
    var
        Saved: Integer;
        F4: List of [Text];
        F7: List of [Text];
        D15F4: Text;
        D15F7: Text;
        Ok: Boolean;
        ErrorText: Text;
        M: Integer;
    begin
        Saved := GlobalLanguage();
        ClearLastError();
        Ok := TrySetLanguage(Language);
        if Ok then begin
            for M := 1 to 12 do begin
                F4.Add(Format(DMY2Date(5, M, 2026), 0, 4));
                F7.Add(Format(DMY2Date(5, M, 2026), 0, 7));
            end;
            D15F4 := Format(DMY2Date(15, 3, 2026), 0, 4);
            D15F7 := Format(DMY2Date(15, 3, 2026), 0, 7);
        end else
            ErrorText := GetLastErrorText();
        GlobalLanguage(Saved);
        ClearLastError();
        Observer.Observe('set language ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('set language error', ErrorText);
            exit;
        end;
        for M := 1 to 12 do
            Observer.Observe('f4 m' + Format(M), F4.Get(M));
        for M := 1 to 12 do
            Observer.Observe('f7 m' + Format(M), F7.Get(M));
        Observer.Observe('f4 15 March', D15F4);
        Observer.Observe('f7 15 March', D15F7);
        Observer.Observe('language restored', Format(GlobalLanguage() = Saved));
    end;

    [Test]
    procedure Months_Dutch_Belgium_2067()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2067);
        Observer.Finish();
    end;

    [Test]
    procedure Months_Dutch_1043()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1043);
        Observer.Finish();
    end;

    [Test]
    procedure Months_Danish_1030()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1030);
        Observer.Finish();
    end;

    [Test]
    procedure Months_French_Belgium_2060()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2060);
        Observer.Finish();
    end;

    [Test]
    procedure Months_Norwegian_1044()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1044);
        Observer.Finish();
    end;

    [Test]
    procedure Months_Swedish_1053()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1053);
        Observer.Finish();
    end;

    [Test]
    procedure Months_Finnish_1035()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 1035);
        Observer.Finish();
    end;

    [Test]
    procedure Months_German_Switzerland_2055()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 2055);
        Observer.Finish();
    end;

    [Test]
    procedure Months_German_Austria_3079()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 3079);
        Observer.Finish();
    end;

    [Test]
    procedure Months_French_Switzerland_4108()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Run(Observer, 4108);
        Observer.Finish();
    end;
}
