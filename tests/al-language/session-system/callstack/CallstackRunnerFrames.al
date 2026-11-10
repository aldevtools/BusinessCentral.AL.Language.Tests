// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/sessioninformation/sessioninformation-callstack-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 69953, 69954 (own copies of the holder and runner of CallstackFullText.al, which are SingleInstance and may be used by one test codeunit only)
// Probe: the exact text of the frames of Microsoft's test runner below the last frame of this app (the runner frames), frame by frame.
//   CallstackFullText.al counts them (six frames that name "Test Runner by Microsoft" on BC 27.5, none on 28.5 and 29.0); this file pins every character.
// Two shapes: a test without [HandlerFunctions] (on BC 28 and 29 the corpus CI runs it through its own hybrid runner, which adds no AL frame; BC 27.5 shows six
//   frames of Microsoft's runner) and a test with [HandlerFunctions] and a Message (routed to Microsoft's test runner page 130455 on every version).
// Facts: for SessionInformation.Callstack, the Callstack of a collected ErrorInfo, GetLastErrorCallStack after a failed TryFunction and
//   GetLastErrorCallStack after asserterror, each read in a test procedure and in a codeunit run with Codeunit.Run: the number of runner
//   frames, each frame, the separator and trailing separator, StrLen of the whole text and of the tail, and whether the runner codeunits
//   130451 and 99903 are in the tail. The tail is the text after the version of the last frame of this app.
// The runner version is a build number of the CI artifact (27.5.46862.57885, 28.5.54151.57916, 29.0.54011.55816 when measured): the frame texts are
//   asserted with the version replaced by <RunnerVersion>, and the major and minor part of the version is asserted apart per BC version. The line numbers
//   (RunTests line 26, ...) are lines of Microsoft's test runner source and are asserted as they are; they are the same on 27.5, 28.5 and 29.0.
// New file with a reason: CallstackFullText.al is line sensitive (its expected lengths) and its objects are reused here, not copied.
// BC versions: 27, 28, 29
codeunit 69950 "LT RF Callstack Frames Plain"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_session()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Holder.Capture('test');
        Helper.ObserveOne('test.session', Holder.Get('test.session'), false, Observer);
#if BC28PLUS
        Observer.Expect('test.session.whole.len', '265');
        Observer.Expect('test.session.tail.len', '1');
        Observer.Expect('test.session.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.session.tail.nframes', '0');
        Observer.Expect('test.session.tail.has130450', 'No');
        Observer.Expect('test.session.tail.has130454', 'No');
        Observer.Expect('test.session.tail.has130451', 'No');
        Observer.Expect('test.session.tail.has99903', 'No');
        Observer.Expect('test.session.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('test.session.whole.len', '946');
        Observer.Expect('test.session.tail.len', '682');
        Observer.Expect('test.session.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.session.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.has130450', 'Yes');
        Observer.Expect('test.session.tail.has130454', 'Yes');
        Observer.Expect('test.session.tail.has130451', 'No');
        Observer.Expect('test.session.tail.has99903', 'No');
        Observer.Expect('test.session.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_collected()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Holder.Capture('test');
        Helper.ObserveOne('test.collected', Holder.Get('test.collected'), true, Observer);
#if BC28PLUS
        Observer.Expect('test.collected.whole.len', '501');
        Observer.Expect('test.collected.tail.len', '2');
        Observer.Expect('test.collected.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.collected.tail.nframes', '0');
        Observer.Expect('test.collected.tail.has130450', 'No');
        Observer.Expect('test.collected.tail.has130454', 'No');
        Observer.Expect('test.collected.tail.has130451', 'No');
        Observer.Expect('test.collected.tail.has99903', 'No');
        Observer.Expect('test.collected.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('test.collected.whole.len', '1188');
        Observer.Expect('test.collected.tail.len', '689');
        Observer.Expect('test.collected.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.collected.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.has130450', 'Yes');
        Observer.Expect('test.collected.tail.has130454', 'Yes');
        Observer.Expect('test.collected.tail.has130451', 'No');
        Observer.Expect('test.collected.tail.has99903', 'No');
        Observer.Expect('test.collected.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Holder.Capture('test');
        Helper.ObserveOne('test.lasttry', Holder.Get('test.lasttry'), false, Observer);
#if BC28PLUS
        Observer.Expect('test.lasttry.whole.len', '374');
        Observer.Expect('test.lasttry.tail.len', '1');
        Observer.Expect('test.lasttry.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.lasttry.tail.nframes', '0');
        Observer.Expect('test.lasttry.tail.has130450', 'No');
        Observer.Expect('test.lasttry.tail.has130454', 'No');
        Observer.Expect('test.lasttry.tail.has130451', 'No');
        Observer.Expect('test.lasttry.tail.has99903', 'No');
        Observer.Expect('test.lasttry.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('test.lasttry.whole.len', '1055');
        Observer.Expect('test.lasttry.tail.len', '682');
        Observer.Expect('test.lasttry.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.lasttry.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.has130450', 'Yes');
        Observer.Expect('test.lasttry.tail.has130454', 'Yes');
        Observer.Expect('test.lasttry.tail.has130451', 'No');
        Observer.Expect('test.lasttry.tail.has99903', 'No');
        Observer.Expect('test.lasttry.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Test_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Holder.Capture('test');
        Helper.ObserveOne('test.lastassert', Holder.Get('test.lastassert'), false, Observer);
#if BC28PLUS
        Observer.Expect('test.lastassert.whole.len', '385');
        Observer.Expect('test.lastassert.tail.len', '1');
        Observer.Expect('test.lastassert.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.lastassert.tail.nframes', '0');
        Observer.Expect('test.lastassert.tail.has130450', 'No');
        Observer.Expect('test.lastassert.tail.has130454', 'No');
        Observer.Expect('test.lastassert.tail.has130451', 'No');
        Observer.Expect('test.lastassert.tail.has99903', 'No');
        Observer.Expect('test.lastassert.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('test.lastassert.whole.len', '1066');
        Observer.Expect('test.lastassert.tail.len', '682');
        Observer.Expect('test.lastassert.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.lastassert.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.has130450', 'Yes');
        Observer.Expect('test.lastassert.tail.has130454', 'Yes');
        Observer.Expect('test.lastassert.tail.has130451', 'No');
        Observer.Expect('test.lastassert.tail.has99903', 'No');
        Observer.Expect('test.lastassert.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_session()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Runner.Run();
        Helper.ObserveOne('run.session', Runner.Get('run.session'), false, Observer);
#if BC28PLUS
        Observer.Expect('run.session.whole.len', '380');
        Observer.Expect('run.session.tail.len', '1');
        Observer.Expect('run.session.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.session.tail.nframes', '0');
        Observer.Expect('run.session.tail.has130450', 'No');
        Observer.Expect('run.session.tail.has130454', 'No');
        Observer.Expect('run.session.tail.has130451', 'No');
        Observer.Expect('run.session.tail.has99903', 'No');
        Observer.Expect('run.session.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('run.session.whole.len', '1061');
        Observer.Expect('run.session.tail.len', '682');
        Observer.Expect('run.session.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.session.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.has130450', 'Yes');
        Observer.Expect('run.session.tail.has130454', 'Yes');
        Observer.Expect('run.session.tail.has130451', 'No');
        Observer.Expect('run.session.tail.has99903', 'No');
        Observer.Expect('run.session.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_collected()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Runner.Run();
        Helper.ObserveOne('run.collected', Runner.Get('run.collected'), true, Observer);
#if BC28PLUS
        Observer.Expect('run.collected.whole.len', '617');
        Observer.Expect('run.collected.tail.len', '2');
        Observer.Expect('run.collected.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.collected.tail.nframes', '0');
        Observer.Expect('run.collected.tail.has130450', 'No');
        Observer.Expect('run.collected.tail.has130454', 'No');
        Observer.Expect('run.collected.tail.has130451', 'No');
        Observer.Expect('run.collected.tail.has99903', 'No');
        Observer.Expect('run.collected.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('run.collected.whole.len', '1304');
        Observer.Expect('run.collected.tail.len', '689');
        Observer.Expect('run.collected.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.collected.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.has130450', 'Yes');
        Observer.Expect('run.collected.tail.has130454', 'Yes');
        Observer.Expect('run.collected.tail.has130451', 'No');
        Observer.Expect('run.collected.tail.has99903', 'No');
        Observer.Expect('run.collected.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Runner.Run();
        Helper.ObserveOne('run.lasttry', Runner.Get('run.lasttry'), false, Observer);
#if BC28PLUS
        Observer.Expect('run.lasttry.whole.len', '489');
        Observer.Expect('run.lasttry.tail.len', '1');
        Observer.Expect('run.lasttry.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.lasttry.tail.nframes', '0');
        Observer.Expect('run.lasttry.tail.has130450', 'No');
        Observer.Expect('run.lasttry.tail.has130454', 'No');
        Observer.Expect('run.lasttry.tail.has130451', 'No');
        Observer.Expect('run.lasttry.tail.has99903', 'No');
        Observer.Expect('run.lasttry.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('run.lasttry.whole.len', '1170');
        Observer.Expect('run.lasttry.tail.len', '682');
        Observer.Expect('run.lasttry.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.lasttry.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.has130450', 'Yes');
        Observer.Expect('run.lasttry.tail.has130454', 'Yes');
        Observer.Expect('run.lasttry.tail.has130451', 'No');
        Observer.Expect('run.lasttry.tail.has99903', 'No');
        Observer.Expect('run.lasttry.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure CallstackRunnerFrames_Plain_Run_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Runner.Run();
        Helper.ObserveOne('run.lastassert', Runner.Get('run.lastassert'), false, Observer);
#if BC28PLUS
        Observer.Expect('run.lastassert.whole.len', '500');
        Observer.Expect('run.lastassert.tail.len', '1');
        Observer.Expect('run.lastassert.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.lastassert.tail.nframes', '0');
        Observer.Expect('run.lastassert.tail.has130450', 'No');
        Observer.Expect('run.lastassert.tail.has130454', 'No');
        Observer.Expect('run.lastassert.tail.has130451', 'No');
        Observer.Expect('run.lastassert.tail.has99903', 'No');
        Observer.Expect('run.lastassert.tail.runner-version-prefix', 'Yes');
#else
        Observer.Expect('run.lastassert.whole.len', '1181');
        Observer.Expect('run.lastassert.tail.len', '682');
        Observer.Expect('run.lastassert.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.lastassert.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.has130450', 'Yes');
        Observer.Expect('run.lastassert.tail.has130454', 'Yes');
        Observer.Expect('run.lastassert.tail.has130451', 'No');
        Observer.Expect('run.lastassert.tail.has99903', 'No');
        Observer.Expect('run.lastassert.tail.runner-version-prefix', 'Yes');
#endif
        Observer.Verify();
    end;
}

codeunit 69951 "LT RF Callstack Frames Handler"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [MessageHandler]
    procedure AcceptMessage(Text: Text[1024])
    begin
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_session()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Message('runner frames');
        Holder.Capture('test');
        Helper.ObserveOne('test.session', Holder.Get('test.session'), false, Observer);
        Observer.Expect('test.session.whole.len', '948');
        Observer.Expect('test.session.tail.len', '682');
        Observer.Expect('test.session.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.session.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.session.tail.has130450', 'Yes');
        Observer.Expect('test.session.tail.has130454', 'Yes');
        Observer.Expect('test.session.tail.has130451', 'No');
        Observer.Expect('test.session.tail.has99903', 'No');
        Observer.Expect('test.session.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_collected()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Message('runner frames');
        Holder.Capture('test');
        Helper.ObserveOne('test.collected', Holder.Get('test.collected'), true, Observer);
        Observer.Expect('test.collected.whole.len', '1190');
        Observer.Expect('test.collected.tail.len', '689');
        Observer.Expect('test.collected.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.collected.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.collected.tail.has130450', 'Yes');
        Observer.Expect('test.collected.tail.has130454', 'Yes');
        Observer.Expect('test.collected.tail.has130451', 'No');
        Observer.Expect('test.collected.tail.has99903', 'No');
        Observer.Expect('test.collected.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Message('runner frames');
        Holder.Capture('test');
        Helper.ObserveOne('test.lasttry', Holder.Get('test.lasttry'), false, Observer);
        Observer.Expect('test.lasttry.whole.len', '1057');
        Observer.Expect('test.lasttry.tail.len', '682');
        Observer.Expect('test.lasttry.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.lasttry.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lasttry.tail.has130450', 'Yes');
        Observer.Expect('test.lasttry.tail.has130454', 'Yes');
        Observer.Expect('test.lasttry.tail.has130451', 'No');
        Observer.Expect('test.lasttry.tail.has99903', 'No');
        Observer.Expect('test.lasttry.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Test_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Holder: Codeunit "LT RF Callstack Holder";
    begin
        Message('runner frames');
        Holder.Capture('test');
        Helper.ObserveOne('test.lastassert', Holder.Get('test.lastassert'), false, Observer);
        Observer.Expect('test.lastassert.whole.len', '1068');
        Observer.Expect('test.lastassert.tail.len', '682');
        Observer.Expect('test.lastassert.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('test.lastassert.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('test.lastassert.tail.has130450', 'Yes');
        Observer.Expect('test.lastassert.tail.has130454', 'Yes');
        Observer.Expect('test.lastassert.tail.has130451', 'No');
        Observer.Expect('test.lastassert.tail.has99903', 'No');
        Observer.Expect('test.lastassert.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_session()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Message('runner frames');
        Runner.Run();
        Helper.ObserveOne('run.session', Runner.Get('run.session'), false, Observer);
        Observer.Expect('run.session.whole.len', '1063');
        Observer.Expect('run.session.tail.len', '682');
        Observer.Expect('run.session.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.session.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.session.tail.has130450', 'Yes');
        Observer.Expect('run.session.tail.has130454', 'Yes');
        Observer.Expect('run.session.tail.has130451', 'No');
        Observer.Expect('run.session.tail.has99903', 'No');
        Observer.Expect('run.session.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_collected()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Message('runner frames');
        Runner.Run();
        Helper.ObserveOne('run.collected', Runner.Get('run.collected'), true, Observer);
        Observer.Expect('run.collected.whole.len', '1306');
        Observer.Expect('run.collected.tail.len', '689');
        Observer.Expect('run.collected.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.collected.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.collected.tail.has130450', 'Yes');
        Observer.Expect('run.collected.tail.has130454', 'Yes');
        Observer.Expect('run.collected.tail.has130451', 'No');
        Observer.Expect('run.collected.tail.has99903', 'No');
        Observer.Expect('run.collected.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_lasttry()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Message('runner frames');
        Runner.Run();
        Helper.ObserveOne('run.lasttry', Runner.Get('run.lasttry'), false, Observer);
        Observer.Expect('run.lasttry.whole.len', '1172');
        Observer.Expect('run.lasttry.tail.len', '682');
        Observer.Expect('run.lasttry.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.lasttry.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lasttry.tail.has130450', 'Yes');
        Observer.Expect('run.lasttry.tail.has130454', 'Yes');
        Observer.Expect('run.lasttry.tail.has130451', 'No');
        Observer.Expect('run.lasttry.tail.has99903', 'No');
        Observer.Expect('run.lasttry.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AcceptMessage')]
    procedure CallstackRunnerFrames_Handler_Run_lastassert()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RF Callstack Helper";
        Runner: Codeunit "LT RF Callstack Runner";
    begin
        Message('runner frames');
        Runner.Run();
        Helper.ObserveOne('run.lastassert', Runner.Get('run.lastassert'), false, Observer);
        Observer.Expect('run.lastassert.whole.len', '1183');
        Observer.Expect('run.lastassert.tail.len', '682');
        Observer.Expect('run.lastassert.tail.separator-first-and-last', 'Yes Yes');
        Observer.Expect('run.lastassert.tail.frame1', '"Test Runner - Mgt"(CodeUnit 130454).RunTests line 26 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame2', '"Test Runner - Isol. Codeunit"(CodeUnit 130450).OnRun(Trigger) line 4 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame3', '"Test Suite Mgt."(CodeUnit 130456).RunTests line 2 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame4', '"Test Suite Mgt."(CodeUnit 130456).RunSelectedTests line 35 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame5', '"Test Suite Mgt."(CodeUnit 130456).RunNextTest line 20 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.frame6', '"Command Line Test Tool"(Page 130455)."RunNextTest - OnAction"(Trigger) line 7 - Test Runner by Microsoft version <RunnerVersion>');
        Observer.Expect('run.lastassert.tail.has130450', 'Yes');
        Observer.Expect('run.lastassert.tail.has130454', 'Yes');
        Observer.Expect('run.lastassert.tail.has130451', 'No');
        Observer.Expect('run.lastassert.tail.has99903', 'No');
        Observer.Expect('run.lastassert.tail.runner-version-prefix', 'Yes');
        Observer.Verify();
    end;
}

// local object: the holder keeps what it read in the state of its own instance (no SingleInstance: a SingleInstance fixture may be used by one test
// codeunit only), and the runner runs it from Codeunit.Run. Same reads as codeunits 65101 and 65103 of CallstackFullText.al.
codeunit 69953 "LT RF Callstack Holder"
{
    var
        Seen: Dictionary of [Text, Text];

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
}

// local object: see codeunit 69953.
codeunit 69954 "LT RF Callstack Runner"
{
    var
        Holder: Codeunit "LT RF Callstack Holder";

    trigger OnRun()
    begin
        Holder.Capture('run');
    end;

    procedure Get(KeyName: Text): Text
    begin
        exit(Holder.Get(KeyName));
    end;
}

// Shared by the two test codeunits above. Not a test codeunit.
codeunit 69952 "LT RF Callstack Helper"
{
    procedure ObserveOne(KeyName: Text; Value: Text; CrLf: Boolean; var Observer: Codeunit "Probe Observer")
    var
        Marker: Text;
        Separator: Text;
        Tail: Text;
        Inner: Text;
        Frames: List of [Text];
        Frame: Text;
        At: Integer;
        Last: Integer;
        Index: Integer;
        Cr: Text[1];
        Lf: Text[1];
        VersionOk: Boolean;
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
        VersionOk := (Tail = Separator) or Tail.Contains(RunnerVersionPrefix());
        Observer.Observe(KeyName + '.whole.len', Format(StrLen(Value)));
        Observer.Observe(KeyName + '.tail.len', Format(StrLen(Tail)));
        Observer.Observe(KeyName + '.tail.separator-first-and-last', Format(Tail.StartsWith(Separator)) + ' ' + Format(Tail.EndsWith(Separator)));
        Tail := NormalizeVersion(Tail);
        if StrLen(Tail) <= StrLen(Separator) then
            Observer.Observe(KeyName + '.tail.nframes', '0')
        else begin
            Inner := CopyStr(Tail, StrLen(Separator) + 1, StrLen(Tail) - 2 * StrLen(Separator));
            Frames := Inner.Split(Separator);
            Index := 0;
            foreach Frame in Frames do begin
                Index += 1;
                Observer.Observe(KeyName + '.tail.frame' + Format(Index), Frame);
            end;
        end;
        Observer.Observe(KeyName + '.tail.has130450', Format(Tail.Contains('(CodeUnit 130450)')));
        Observer.Observe(KeyName + '.tail.has130454', Format(Tail.Contains('(CodeUnit 130454)')));
        Observer.Observe(KeyName + '.tail.has130451', Format(Tail.Contains('(CodeUnit 130451)')));
        Observer.Observe(KeyName + '.tail.has99903', Format(Tail.Contains('(CodeUnit 99903)')));
        Observer.Observe(KeyName + '.tail.runner-version-prefix', Format(VersionOk));
    end;

    // The build number of the runner is specific to the CI artifact: only its major and minor part is asserted (the BC 27.5 build is 27.5.x).
    local procedure RunnerVersionPrefix(): Text
    begin
#if BC29PLUS
        exit('Test Runner by Microsoft version 29.0.');
#else
#if BC28PLUS
        exit('Test Runner by Microsoft version 28.5.');
#else
        exit('Test Runner by Microsoft version 27.5.');
#endif
#endif
    end;

    local procedure NormalizeVersion(Tail: Text): Text
    var
        Prefix: Text;
        Result: Text;
        Rest: Text;
        At: Integer;
        Stop: Integer;
        Index: Integer;
        Code: Integer;
    begin
        Prefix := 'Test Runner by Microsoft version ';
        Rest := Tail;
        At := Rest.IndexOf(Prefix);
        while At > 0 do begin
            Result += CopyStr(Rest, 1, At - 1) + Prefix + '<RunnerVersion>';
            Rest := CopyStr(Rest, At + StrLen(Prefix));
            Stop := StrLen(Rest) + 1;
            for Index := 1 to StrLen(Rest) do begin
                Code := Rest[Index];
                if (Code = 92) or (Code = 13) then begin
                    Stop := Index;
                    break;
                end;
            end;
            Rest := CopyStr(Rest, Stop);
            At := Rest.IndexOf(Prefix);
        end;
        exit(Result + Rest);
    end;
}
