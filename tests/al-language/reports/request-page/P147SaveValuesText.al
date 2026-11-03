// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own report 70250 and test codeunit 70251
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// sets the request-page globals through a procedure (like SetParameters) and calls RunModal. Does the request page show the stored value or the caller's one?
// Probed for a Text, a Boolean and an Option ('Selected,All') field. Cancelled runs and OK'd runs after a caller value are both observed.
// BC versions: 29 (27 and 28 by CI)

report 70250 "LT P147 Saved Params"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(Content)
            {
                field(Remembered; RememberedTxt)
                {
                    ApplicationArea = All;
                }
                field(Flag; FlagBool)
                {
                    ApplicationArea = All;
                }
                field(Scope; ScopeOpt)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure SetParameters(NewText: Text[30]; NewFlag: Boolean; NewScope: Option Selected,All)
    begin
        RememberedTxt := NewText;
        FlagBool := NewFlag;
        ScopeOpt := NewScope;
    end;

    var
        RememberedTxt: Text[30];
        FlagBool: Boolean;
        ScopeOpt: Option Selected,All;
}

codeunit 70251 "LT P147 SaveValues Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer; // 0 read and Cancel, 1 set the Set* values and OK, 2 read and OK
        SetTxt: Text;
        SetFlag: Text;
        SetScope: Text;
        SeenTxt: Text;
        SeenFlag: Text;
        SeenScope: Text;
        HandlerRuns: Integer;

    local procedure RunPlain(RunMode: Integer)
    var
        Rep: Report "LT P147 Saved Params";
    begin
        Mode := RunMode;
        Rep.RunModal();
    end;

    local procedure RunWithCaller(RunMode: Integer; CallerTxt: Text[30]; CallerFlag: Boolean; CallerScope: Option Selected,All)
    var
        Rep: Report "LT P147 Saved Params";
    begin
        Mode := RunMode;
        Rep.SetParameters(CallerTxt, CallerFlag, CallerScope);
        Rep.RunModal();
    end;

    local procedure Seed(StoredTxt: Text; StoredFlag: Text; StoredScope: Text)
    begin
        SetTxt := StoredTxt;
        SetFlag := StoredFlag;
        SetScope := StoredScope;
        RunPlain(1);
    end;

    local procedure ObserveSeen(var Observer: Codeunit "Probe Observer"; Name: Text)
    begin
        Observer.Observe(Name + ' text', '[' + SeenTxt + ']');
        Observer.Observe(Name + ' flag', SeenFlag);
        Observer.Observe(Name + ' scope', SeenScope);
    end;

    [Test]
    [HandlerFunctions('SavedParamsHandler')]
    procedure P147_Text_StoredVsCaller_Cancel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HandlerRuns := 0;
        Seed('stored', 'Yes', 'All');
        Observer.Observe('runs after seed', Format(HandlerRuns));

        RunPlain(0);
        ObserveSeen(Observer, 'plain after seed');

        RunWithCaller(0, 'caller', false, 0);
        ObserveSeen(Observer, 'caller set, cancel');

        RunPlain(0);
        ObserveSeen(Observer, 'plain after a cancelled caller run');

        RunWithCaller(0, '', false, 0);
        ObserveSeen(Observer, 'caller set to blank/default values');
        Observer.Observe('runs total', Format(HandlerRuns));
        Observer.Expect('runs after seed', '1');
        Observer.Expect('plain after seed text', '[stored]');
        Observer.Expect('plain after seed flag', 'Yes');
        Observer.Expect('plain after seed scope', 'All');
        Observer.Expect('caller set, cancel text', '[caller]');
        Observer.Expect('caller set, cancel flag', 'No');
        Observer.Expect('caller set, cancel scope', 'Selected');
        Observer.Expect('plain after a cancelled caller run text', '[stored]');
        Observer.Expect('plain after a cancelled caller run flag', 'Yes');
        Observer.Expect('plain after a cancelled caller run scope', 'All');
        Observer.Expect('caller set to blank/default values text', '[]');
        Observer.Expect('caller set to blank/default values flag', 'No');
        Observer.Expect('caller set to blank/default values scope', 'Selected');
        Observer.Expect('runs total', '5');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedParamsHandler')]
    procedure P147_Text_StoredVsCaller_Ok()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HandlerRuns := 0;
        Seed('stored two', 'No', 'Selected');

        RunWithCaller(2, 'caller two', true, 1);
        ObserveSeen(Observer, 'caller set, OK');

        RunPlain(0);
        ObserveSeen(Observer, 'plain after an OK on a caller run');
        Observer.Expect('caller set, OK text', '[caller two]');
        Observer.Expect('caller set, OK flag', 'Yes');
        Observer.Expect('caller set, OK scope', 'All');
        Observer.Expect('plain after an OK on a caller run text', '[caller two]');
        Observer.Expect('plain after an OK on a caller run flag', 'Yes');
        Observer.Expect('plain after an OK on a caller run scope', 'All');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedParamsHandler')]
    procedure P147_Boolean_CallerFalseOverStoredTrue()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HandlerRuns := 0;
        Seed('x', 'Yes', 'Selected');
        RunWithCaller(0, 'x', false, 0);
        ObserveSeen(Observer, 'caller false over stored true');

        Seed('x', 'No', 'Selected');
        RunWithCaller(0, 'x', true, 0);
        ObserveSeen(Observer, 'caller true over stored false');
        Observer.Expect('caller false over stored true text', '[x]');
        Observer.Expect('caller false over stored true flag', 'No');
        Observer.Expect('caller false over stored true scope', 'Selected');
        Observer.Expect('caller true over stored false text', '[x]');
        Observer.Expect('caller true over stored false flag', 'Yes');
        Observer.Expect('caller true over stored false scope', 'Selected');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SavedParamsHandler')]
    procedure P147_Option_CallerSelectedOverStoredAll()
    var
        Observer: Codeunit "Probe Observer";
    begin
        HandlerRuns := 0;
        Seed('y', 'No', 'All');
        RunWithCaller(0, 'y', false, 0);
        ObserveSeen(Observer, 'caller Selected over stored All');

        Seed('y', 'No', 'Selected');
        RunWithCaller(0, 'y', false, 1);
        ObserveSeen(Observer, 'caller All over stored Selected');
        Observer.Expect('caller Selected over stored All text', '[y]');
        Observer.Expect('caller Selected over stored All flag', 'No');
        Observer.Expect('caller Selected over stored All scope', 'Selected');
        Observer.Expect('caller All over stored Selected text', '[y]');
        Observer.Expect('caller All over stored Selected flag', 'No');
        Observer.Expect('caller All over stored Selected scope', 'All');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure SavedParamsHandler(var RequestPage: TestRequestPage "LT P147 Saved Params")
    begin
        HandlerRuns += 1;
        if Mode = 1 then begin
            RequestPage.Remembered.SetValue(SetTxt);
            RequestPage.Flag.SetValue(SetFlag);
            RequestPage.Scope.SetValue(SetScope);
            RequestPage.OK().Invoke();
        end else begin
            SeenTxt := RequestPage.Remembered.Value();
            SeenFlag := RequestPage.Flag.Value();
            SeenScope := RequestPage.Scope.Value();
            if Mode = 2 then
                RequestPage.OK().Invoke()
            else
                RequestPage.Cancel().Invoke();
        end;
    end;
}
