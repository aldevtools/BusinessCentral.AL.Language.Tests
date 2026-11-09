// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained objects codeunits 65100 65101 65102 65103, page 65104
// Probe: shape of the FULL call stack text, including the frames below the test procedure (the tail that PnD09_CallstackSources.al and
//   TestSessionCallstackSourcesContracts.al cut off). A Text method that reads such a text sees the tail too.
// Facts: for SessionInformation.Callstack, the Callstack of a collected ErrorInfo, GetLastErrorCallStack after a failed TryFunction and
//   GetLastErrorCallStack after asserterror, each read in a test procedure, in a codeunit run with Codeunit.Run, in an event subscriber and in a
//   page trigger of a TestPage: length, number of CR, LF and backslash characters, number of frames of this app, the last character and the text
//   after the last frame of this app (the tail).
// local object: the contexts (Codeunit.Run, event subscriber, page trigger) each need an object of their own that reads the call stack.
// BC versions: 27, 28, 29

codeunit 65101 "LT AG Cs Holder"
{
    SingleInstance = true;

    var
        Seen: Dictionary of [Text, Text];

    procedure ResetSeen()
    begin
        Clear(Seen);
    end;

    procedure Capture(ContextName: Text)
    var
        Info: ErrorInfo;
        Worker: Codeunit "LT AG Cs Worker";
    begin
        Put(ContextName + '.session', SessionInformation.Callstack);
        CollectOne(Info);
        Put(ContextName + '.collected', Info.Callstack);
        if not Worker.TryFail() then
            Put(ContextName + '.lasttry', GetLastErrorCallStack());
        ClearLastError();
        AssertErrorOne();
        Put(ContextName + '.lastassert', GetLastErrorCallStack());
        ClearLastError();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectOne(var Info: ErrorInfo)
    var
        Errors: List of [ErrorInfo];
        Worker: Codeunit "LT AG Cs Worker";
    begin
        Worker.RaiseCollectible();
        Errors := GetCollectedErrors(true);
        Errors.Get(1, Info);
    end;

    local procedure AssertErrorOne()
    begin
        asserterror Error('raised for the call stack');
    end;

    local procedure Put(KeyName: Text; Stack: Text)
    begin
        if Seen.ContainsKey(KeyName) then
            Seen.Set(KeyName, Stack)
        else
            Seen.Add(KeyName, Stack);
    end;

    procedure Get(KeyName: Text): Text
    begin
        if Seen.ContainsKey(KeyName) then
            exit(Seen.Get(KeyName));
        exit('<not set>');
    end;

    procedure Count(Value: Text; Needle: Text): Integer
    begin
        if (Value = '') or (Needle = '') then
            exit(0);
        exit((StrLen(Value) - StrLen(Value.Replace(Needle, ''))) div StrLen(Needle));
    end;

    procedure LastCharCode(Value: Text): Integer
    begin
        if Value = '' then
            exit(-1);
        exit(Value[StrLen(Value)]);
    end;

    procedure TailAfterLastOwnFrame(Value: Text): Text
    var
        Marker: Text;
        At: Integer;
        Last: Integer;
    begin
        Marker := 'AL Language Coverage Tests by AL Language version';
        At := Value.IndexOf(Marker);
        while At > 0 do begin
            Last := At;
            At := Value.IndexOf(Marker, Last + 1);
        end;
        if Last = 0 then
            exit(Value);
        exit(CopyStr(Value, Last + StrLen(Marker)));
    end;

    // BC 27.5 appends six frames of Microsoft's test runner below the test procedure (BC 28.5 and 29.0 do not). The shape is read from the
    // text up to the first runner frame; the number of runner frames is observed apart, so the observations are the same on every version.
    procedure Shape(ContextName: Text; var Observer: Codeunit "Probe Observer")
    var
        Source: Text;
        Value: Text;
        Prefix: Text;
        Cr: Text[1];
        Lf: Text[1];
        RunnerAt: Integer;
    begin
        Cr[1] := 13;
        Lf[1] := 10;
        foreach Source in ShapeSources() do begin
            Value := Get(ContextName + '.' + Source);
            Prefix := Value;
            RunnerAt := Value.IndexOf('"Test Runner - Mgt"');
            if RunnerAt > 0 then
                Prefix := CopyStr(Value, 1, RunnerAt - 1);
            Observer.Observe(ContextName + '.' + Source + '.runnerframes', Format(Count(Value, 'Test Runner by Microsoft')));
            Observer.Observe(ContextName + '.' + Source + '.shape',
                'len=' + Format(StrLen(Prefix)) + ';cr=' + Format(Count(Prefix, Cr)) + ';lf=' + Format(Count(Prefix, Lf)) +
                ';bs=' + Format(Count(Prefix, '\')) + ';own=' + Format(Count(Prefix, 'AL Language Coverage Tests by AL Language version')) +
                ';last=' + Format(LastCharCode(Prefix)) + ';crlf-lines=' + Format(Prefix.Split(Cr + Lf).Count()) + ';lf-lines=' + Format(Prefix.Split(Lf).Count()));
            Observer.Observe(ContextName + '.' + Source + '.tail', TailAfterLastOwnFrame(Prefix));
        end;
    end;

    local procedure ShapeSources() Result: List of [Text]
    begin
        Result.Add('session');
        Result.Add('collected');
        Result.Add('lasttry');
        Result.Add('lastassert');
    end;
}

codeunit 65100 "LT AG Cs Worker"
{
    [IntegrationEvent(false, false)]
    procedure OnProbe()
    begin
    end;

    procedure RaiseProbe()
    begin
        OnProbe();
    end;

    procedure RaiseCollectible()
    var
        Info: ErrorInfo;
    begin
        Info.Collectible := true;
        Info.Message := 'collected for the call stack';
        Error(Info);
    end;

    [TryFunction]
    procedure TryFail()
    begin
        Error('try failed for the call stack');
    end;
}

codeunit 65102 "LT AG Cs Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT AG Cs Worker", 'OnProbe', '', false, false)]
    local procedure OnProbeSubscriber()
    var
        Holder: Codeunit "LT AG Cs Holder";
    begin
        Holder.Capture('event');
    end;
}

codeunit 65103 "LT AG Cs Runner"
{
    trigger OnRun()
    var
        Holder: Codeunit "LT AG Cs Holder";
    begin
        Holder.Capture('run');
    end;
}

page 65104 "LT AG Cs Card"
{
    PageType = Card;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Dummy; DummyText)
            {
                ApplicationArea = All;
            }
        }
    }

    var
        DummyText: Text;

    trigger OnOpenPage()
    var
        Holder: Codeunit "LT AG Cs Holder";
    begin
        Holder.Capture('page');
    end;
}

codeunit 65105 "LT AG Callstack Full Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CallstackFullText_ReadInTestProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
    begin
        Holder.ResetSeen();
        Holder.Capture('test');
        Holder.Shape('test', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackFullText_ReadInCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Runner.Run();
        Holder.Shape('run', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackFullText_ReadInEventSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Worker: Codeunit "LT AG Cs Worker";
    begin
        Holder.ResetSeen();
        Worker.RaiseProbe();
        Holder.Shape('event', Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackFullText_ReadInPageTriggerOfTestPage()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Card: TestPage "LT AG Cs Card";
    begin
        Holder.ResetSeen();
        Card.OpenView();
        Card.Close();
        Holder.Shape('page', Observer);
        Observer.Finish();
    end;
}
