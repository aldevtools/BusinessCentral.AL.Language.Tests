// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); objects of CallstackFullText.al: Holder 65101, Runner 65103
// Probe: the exact text of the frames of Microsoft's test runner below the last frame of this app (the runner frames), frame by frame.
//   CallstackFullText.al counts them (six frames that name "Test Runner by Microsoft" on BC 27.5, none on 28.5 and 29.0); this file pins every character.
// Two shapes: a test without [HandlerFunctions] (on BC 28 and 29 the corpus CI runs it through its own hybrid runner, which adds no AL frame; BC 27.5 shows six
//   frames of Microsoft's runner) and a test with [HandlerFunctions] and a Message (routed to Microsoft's test runner page 130455 on every version).
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

    [MessageHandler]
    procedure AcceptMessage(Text: Text[1024])
    begin
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_session()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.session', Holder.Get('test.session'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_collected()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.collected', Holder.Get('test.collected'), true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.lasttry', Holder.Get('test.lasttry'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.lastassert', Holder.Get('test.lastassert'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_session()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.session', Holder.Get('run.session'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_collected()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.collected', Holder.Get('run.collected'), true, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.lasttry', Holder.Get('run.lasttry'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.lastassert', Holder.Get('run.lastassert'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_session()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.session', Holder.Get('test.session'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_collected()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.collected', Holder.Get('test.collected'), true, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.lasttry', Holder.Get('test.lasttry'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Holder.Capture('test');
        ObserveOne('test.lastassert', Holder.Get('test.lastassert'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_session()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.session', Holder.Get('run.session'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_collected()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.collected', Holder.Get('run.collected'), true, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.lasttry', Holder.Get('run.lasttry'), false, Observer);
        Observer.Finish();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Holder: Codeunit "LT AG Cs Holder";
        Runner: Codeunit "LT AG Cs Runner";
    begin
        Message('runner frames');
        Holder.ResetSeen();
        Runner.Run();
        ObserveOne('run.lastassert', Holder.Get('run.lastassert'), false, Observer);
        Observer.Finish();
    end;

    local procedure ObserveOne(KeyName: Text; Value: Text; CrLf: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Marker: Text;
        Separator: Text;
        Tail: Text;
        At: Integer;
        Last: Integer;
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
    end;
}
