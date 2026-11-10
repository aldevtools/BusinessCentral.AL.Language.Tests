// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of CallstackFullText.al: Holder 65101, Runner 65103
// Probe: the exact text of the frames of Microsoft's test runner below the last frame of this app (the runner frames), frame by frame.
//   CallstackFullText.al counts them (six frames that name "Test Runner by Microsoft" on BC 27.5, none on 28.5 and 29.0); this file pins every character.
// Facts: for SessionInformation.Callstack, the Callstack of a collected ErrorInfo, GetLastErrorCallStack after a failed TryFunction and
//   GetLastErrorCallStack after asserterror, each read in a test procedure and in a codeunit run with Codeunit.Run: the number of runner
//   frames, each frame, the separator and trailing separator, StrLen of the whole text and of the tail, and whether the runner codeunits
//   130451 and 99903 are in the tail. The tail is the text after the version of the last frame of this app.
// New file with a reason: CallstackFullText.al is line sensitive (its expected lengths) and its objects are reused here, not copied.
// BC versions: 27, 28, 29
codeunit 69950 "LT RF Callstack Runner Frames"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CallstackRunnerFrames_ReadInTestProcedure()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
    begin
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveAll('test', Holder, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_ReadInCodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Runner.Run();
        ObserveAll('run', Holder, Observer);
        Observer.Finish();
    end;

    local procedure ObserveAll(ContextName: Text; var Holder: Codeunit "LT AG Cs Holder"; var Observer: Codeunit "Probe Observer")
    var
        Source: Text;
    begin
        foreach Source in Sources() do
            ObserveOne(ContextName + '.' + Source, Holder.Get(ContextName + '.' + Source), Source = 'collected', Observer);
    end;

    local procedure Sources() Result: List of [Text]
    begin
        Result.Add('session');
        Result.Add('collected');
        Result.Add('lasttry');
        Result.Add('lastassert');
    end;

    local procedure ObserveOne(KeyName: Text; Value: Text; CrLf: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Marker: Text;
        Separator: Text;
        Tail: Text;
        Frames: List of [Text];
        Frame: Text;
        At: Integer;
        Last: Integer;
        Index: Integer;
        Cr: Text[1];
        Lf: Text[1];
    begin
        Marker := 'AL Language Coverage Tests by AL Language version 1.0.0.0';
        Cr[1] := 13;
        Lf[1] := 10;
        if CrLf then
            Separator := Cr + Lf
        else
            Separator := '\';
        At := Value.IndexOf(Marker);
        while At > 0 do begin
            Last := At;
            At := Value.IndexOf(Marker, Last + 1);
        end;
        Tail := CopyStr(Value, Last + StrLen(Marker));
        Observer.Observe(KeyName + '.whole.len', Format(StrLen(Value)));
        Observer.Observe(KeyName + '.tail.len', Format(StrLen(Tail)));
        Observer.Observe(KeyName + '.tail', Tail);
        Observer.Observe(KeyName + '.tail.ends-with-separator', Format(Tail.EndsWith(Separator)));
        Observer.Observe(KeyName + '.tail.has130451', Format(Tail.Contains('(CodeUnit 130451)')));
        Observer.Observe(KeyName + '.tail.has99903', Format(Tail.Contains('(CodeUnit 99903)')));
        Observer.Observe(KeyName + '.tail.has130450', Format(Tail.Contains('(CodeUnit 130450)')));
        Observer.Observe(KeyName + '.tail.has130454', Format(Tail.Contains('(CodeUnit 130454)')));
        Frames := Tail.Split(Separator);
        Observer.Observe(KeyName + '.tail.pieces', Format(Frames.Count()));
        Index := 0;
        foreach Frame in Frames do begin
            Index += 1;
            Observer.Observe(KeyName + '.tail.piece' + Format(Index), Frame);
        end;
    end;
}
